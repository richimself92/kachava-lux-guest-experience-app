import { EntityConflictError, EntityNotFoundError, ListScanLimitError } from '../../src/domain/domain-errors';
import { TaskPageQuery } from '../../src/domain/ports/repository.ports';
import { Task } from '../../src/domain/tasks/task.models';
import {
  FirestoreTaskRepository,
  TASKS_COLLECTION,
} from '../../src/infrastructure/repositories/firestore-task.repository';
import { FirestoreNotificationReadRepository } from '../../src/infrastructure/repositories/firestore-notification-read.repository';
import { FakeFirestore } from '../support/fake-firestore';
import { taskFixture } from '../support/task-fixtures';

const PAGE: TaskPageQuery = { page: 1, pageSize: 25, direction: 'asc' };
const NOW = '2026-11-22T00:00:00.000Z';

describe('FirestoreTaskRepository', () => {
  let fake: FakeFirestore;
  let repo: FirestoreTaskRepository;
  const ids = (tasks: { data: Task[] }) => tasks.data.map((t) => t.taskId);

  beforeEach(async () => {
    fake = new FakeFirestore();
    repo = new FirestoreTaskRepository(fake.asFirestore());
    await repo.create(taskFixture({ taskId: 't1', title: 'Prepare pillows', dueAt: '2026-11-21T10:00:00.000Z' }));
    await repo.create(taskFixture({
      taskId: 't2', title: 'Stock villa', dueAt: '2026-11-23T10:00:00.000Z', priority: 'HIGH',
      status: 'ASSIGNED', ownerStaffId: 'staff-7', villaId: 'villa-b', guestName: 'Bruno Peña',
    }));
    await repo.create(taskFixture({ taskId: 't3', title: 'Old task', dueAt: '2026-11-20T10:00:00.000Z', status: 'COMPLETED' }));
  });

  it('test_page_ordersByDueAt_countsTotal_andHidesTheDerivedSearchField', async () => {
    const asc = await repo.page(PAGE);
    const desc = await repo.page({ ...PAGE, direction: 'desc', pageSize: 2 });

    expect(ids(asc)).toEqual(['t3', 't1', 't2']);
    expect(ids(desc)).toEqual(['t2', 't1']);
    expect(desc.meta).toEqual({ page: 1, pageSize: 2, total: 3 });
    expect(asc.data[0]).not.toHaveProperty('searchKeywords');
  });

  it('test_page_filtersInFirestore', async () => {
    expect(ids(await repo.page({ ...PAGE, status: 'ASSIGNED' }))).toEqual(['t2']);
    expect(ids(await repo.page({ ...PAGE, priority: 'HIGH' }))).toEqual(['t2']);
    expect(ids(await repo.page({ ...PAGE, ownerStaffId: 'staff-7' }))).toEqual(['t2']);
    expect(ids(await repo.page({ ...PAGE, villaId: 'villa-b' }))).toEqual(['t2']);
    expect(ids(await repo.page({ ...PAGE, q: 'pena' }))).toEqual(['t2']);
    expect(ids(await repo.page({ ...PAGE, q: 'pill' }))).toEqual(['t1']);
  });

  it('test_page_overdue_isOpenAndPastDue_combinableWithStatus', async () => {
    expect(ids(await repo.page({ ...PAGE, overdueBefore: NOW }))).toEqual(['t1']);
    expect(ids(await repo.page({ ...PAGE, overdueBefore: NOW, status: 'PENDING' }))).toEqual(['t1']);
    expect((await repo.page({ ...PAGE, overdueBefore: NOW, status: 'COMPLETED' })).meta.total).toBe(0);
  });

  it('test_createIfAbsent_isIdempotentPerId', async () => {
    const first = await repo.createIfAbsent(taskFixture({ taskId: 'auto-1', title: 'First' }));
    const second = await repo.createIfAbsent(taskFixture({ taskId: 'auto-1', title: 'Second' }));

    expect(first.created).toBe(true);
    expect(second).toEqual({ task: expect.objectContaining({ title: 'First' }), created: false });
    await expect(repo.create(taskFixture({ taskId: 'auto-1' }))).rejects.toThrow(EntityConflictError);
  });

  it('test_update_isTransactional_andUnknownIdIsNotFound', async () => {
    const next = await repo.update('t1', (t) => ({ ...t, title: 'Renamed' }));

    expect(next.title).toBe('Renamed');
    expect(fake.store(TASKS_COLLECTION).get('t1')?.searchKeywords).toContain('renamed');
    await expect(repo.update('missing', (t) => t)).rejects.toThrow(EntityNotFoundError);
  });

  it('test_listOverdue_andCountByStatuses', async () => {
    expect((await repo.listOverdue(NOW)).map((t) => t.taskId)).toEqual(['t1']);
    expect(await repo.countByStatuses(['PENDING', 'ASSIGNED', 'IN_PROGRESS'])).toBe(2);
  });

  it('test_listOverdue_beyondTheScanLimit_failsLoudly', async () => {
    const small = new FirestoreTaskRepository(fake.asFirestore(), 0);

    await expect(small.listOverdue(NOW)).rejects.toThrow(ListScanLimitError);
  });
});

describe('FirestoreNotificationReadRepository', () => {
  it('test_markRead_thenReadAtOf_returnsOnlyMarkedIds', async () => {
    const reads = new FirestoreNotificationReadRepository(new FakeFirestore().asFirestore());

    await reads.markRead(['a', 'b'], 'staff-1', NOW);

    expect(await reads.readAtOf(['a', 'c'])).toEqual(new Map([['a', NOW]]));
    expect(await reads.readAtOf([])).toEqual(new Map());
  });
});
