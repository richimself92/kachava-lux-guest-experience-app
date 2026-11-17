import type { CollectionReference, DocumentData, Firestore, Query } from 'firebase-admin/firestore';
import { normalizeSearchText, PaginatedResult } from '../../common/listing/list-query';
import { EntityConflictError, EntityNotFoundError, ListScanLimitError } from '../../domain/domain-errors';
import { TaskPageQuery, TaskRepositoryPort } from '../../domain/ports/repository.ports';
import { OPEN_TASK_STATUSES, Task, TaskStatus } from '../../domain/tasks/task.models';
import { toFirestoreDocument } from './firestore-document.mapper';
import { guestSearchKeywords, MAX_SEARCH_KEYWORD_LENGTH } from './firestore-stay.repository';

export const TASKS_COLLECTION = 'tasks';
/** Derived, storage-only field used for `array-contains` search on title, guest and villa. */
export const TASK_SEARCH_FIELD = 'searchKeywords';
export const TASK_SCAN_LIMIT = 1000;
const DUE_FIELD = 'dueAt';

/**
 * `tasks/{taskId}`, read on every call. Filters, search and the `dueAt` order run in Firestore
 * (`count()` + offset paging, like stays); writes run in transactions.
 */
export class FirestoreTaskRepository implements TaskRepositoryPort {
  constructor(
    private readonly db: Firestore,
    private readonly scanLimit = TASK_SCAN_LIMIT,
  ) {}

  async create(task: Task): Promise<Task> {
    const { task: stored, created } = await this.createIfAbsent(task);
    if (!created) throw new EntityConflictError(`Task ${task.taskId} already exists.`);
    return stored;
  }

  createIfAbsent(task: Task): Promise<{ task: Task; created: boolean }> {
    return this.db.runTransaction(async (tx) => {
      const ref = this.tasks().doc(task.taskId);
      const existing = await tx.get(ref);
      if (existing.exists) return { task: toTask(existing.data()), created: false };
      tx.set(ref, toTaskDocument(task));
      return { task: structuredClone(task), created: true };
    });
  }

  async findById(taskId: string): Promise<Task | null> {
    const snapshot = await this.tasks().doc(taskId).get();
    return snapshot.exists ? toTask(snapshot.data()) : null;
  }

  update(taskId: string, mutate: (current: Task) => Task): Promise<Task> {
    return this.db.runTransaction(async (tx) => {
      const ref = this.tasks().doc(taskId);
      const snapshot = await tx.get(ref);
      if (!snapshot.exists) throw new EntityNotFoundError('Task', taskId);
      const next = { ...mutate(toTask(snapshot.data())), taskId };
      tx.set(ref, toTaskDocument(next));
      return structuredClone(next);
    });
  }

  async page(query: TaskPageQuery): Promise<PaginatedResult<Task>> {
    const meta = { page: query.page, pageSize: query.pageSize };
    if (query.overdueBefore && query.status && !OPEN_TASK_STATUSES.includes(query.status)) {
      return new PaginatedResult<Task>([], { ...meta, total: 0 });
    }
    const ordered = this.filtered(query).orderBy(DUE_FIELD, query.direction);
    const [countSnapshot, pageSnapshot] = await Promise.all([
      ordered.count().get(),
      ordered.offset((query.page - 1) * query.pageSize).limit(query.pageSize).get(),
    ]);
    return new PaginatedResult(
      pageSnapshot.docs.map((doc) => toTask(doc.data())),
      { ...meta, total: countSnapshot.data().count },
    );
  }

  async listOverdue(nowIso: string): Promise<Task[]> {
    const query = this.openTasks().where(DUE_FIELD, '<', nowIso).orderBy(DUE_FIELD, 'asc');
    const snapshot = await query.limit(this.scanLimit + 1).get();
    if (snapshot.docs.length > this.scanLimit) throw new ListScanLimitError(TASKS_COLLECTION, this.scanLimit);
    return snapshot.docs.map((doc) => toTask(doc.data()));
  }

  async countByStatuses(statuses: readonly TaskStatus[]): Promise<number> {
    const snapshot = await this.tasks().where('status', 'in', [...statuses]).count().get();
    return snapshot.data().count;
  }

  private filtered(query: TaskPageQuery): Query {
    let filtered: Query = this.tasks();
    if (query.status) filtered = filtered.where('status', '==', query.status);
    else if (query.overdueBefore) filtered = this.openTasks();
    if (query.priority) filtered = filtered.where('priority', '==', query.priority);
    if (query.ownerStaffId) filtered = filtered.where('ownerStaffId', '==', query.ownerStaffId);
    if (query.villaId) filtered = filtered.where('villaId', '==', query.villaId);
    if (query.sourceTypes?.length === 1) filtered = filtered.where('source.type', '==', query.sourceTypes[0]);
    else if (query.sourceTypes) filtered = filtered.where('source.type', 'in', [...query.sourceTypes]);
    if (query.q) {
      const keyword = normalizeSearchText(query.q).slice(0, MAX_SEARCH_KEYWORD_LENGTH);
      filtered = filtered.where(TASK_SEARCH_FIELD, 'array-contains', keyword);
    }
    if (query.overdueBefore) filtered = filtered.where(DUE_FIELD, '<', query.overdueBefore);
    return filtered;
  }

  private openTasks(): Query {
    return this.tasks().where('status', 'in', [...OPEN_TASK_STATUSES]);
  }

  private tasks(): CollectionReference {
    return this.db.collection(TASKS_COLLECTION);
  }
}

function taskSearchKeywords(task: Task): string[] {
  const phrases = [task.title, task.guestName ?? '', task.villaName ?? ''];
  return Array.from(new Set(phrases.flatMap((phrase) => guestSearchKeywords(phrase))));
}

function toTaskDocument(task: Task): Record<string, unknown> {
  return { ...toFirestoreDocument(task), [TASK_SEARCH_FIELD]: taskSearchKeywords(task) };
}

function toTask(data: DocumentData | undefined): Task {
  const stored = { ...(data ?? {}) } as Task & Record<string, unknown>;
  delete stored[TASK_SEARCH_FIELD];
  return stored;
}
