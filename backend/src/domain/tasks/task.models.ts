/**
 * Operational tasks (ADR-006, ADR-011): one document per task in the top-level `tasks`
 * collection. `overdue` is never stored; it is derived on read from `dueAt` and `status`.
 */
export const TASK_STATUSES = ['PENDING', 'ASSIGNED', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED'] as const;
export type TaskStatus = (typeof TASK_STATUSES)[number];

export const TASK_PRIORITIES = ['LOW', 'NORMAL', 'HIGH', 'URGENT'] as const;
export type TaskPriority = (typeof TASK_PRIORITIES)[number];

/** What generated the task. Automatic sources are idempotent: one task per source record. */
export const TASK_SOURCE_TYPES = ['MANUAL', 'PREFERENCE', 'ORDER', 'BOOKING', 'TRIP'] as const;
export type TaskSourceType = (typeof TASK_SOURCE_TYPES)[number];

export const FINAL_TASK_STATUSES: readonly TaskStatus[] = ['COMPLETED', 'CANCELLED'];
export const OPEN_TASK_STATUSES: readonly TaskStatus[] = ['PENDING', 'ASSIGNED', 'IN_PROGRESS'];
/** Statuses that need an owner. */
export const OWNED_TASK_STATUSES: readonly TaskStatus[] = ['ASSIGNED', 'IN_PROGRESS', 'COMPLETED'];

export interface TaskSource {
  type: TaskSourceType;
  /** Id of the originating record (booking, order, trip...); null for manual tasks. */
  refId: string | null;
  stayId: string | null;
}

export interface TaskCompletion {
  at: string;
  by: string;
  note: string;
}

export interface TaskStatusChange {
  from: TaskStatus | null;
  to: TaskStatus;
  at: string;
  by: string;
}

export interface Task {
  taskId: string;
  title: string;
  source: TaskSource;
  villaId: string | null;
  villaName: string | null;
  guestName: string | null;
  category: string;
  ownerStaffId: string | null;
  ownerName: string | null;
  priority: TaskPriority;
  /** UTC ISO instant; null when the task has no deadline. */
  dueAt: string | null;
  status: TaskStatus;
  completion: TaskCompletion | null;
  cancellationReason: string | null;
  statusHistory: TaskStatusChange[];
  createdAt: string;
  createdBy: string;
  updatedAt: string;
  updatedBy: string;
}

export function isFinalTaskStatus(status: TaskStatus): boolean {
  return FINAL_TASK_STATUSES.includes(status);
}

/** Open and past its deadline at `now`. */
export function isTaskOverdue(task: Pick<Task, 'dueAt' | 'status'>, now: Date): boolean {
  if (!task.dueAt || isFinalTaskStatus(task.status)) return false;
  return Date.parse(task.dueAt) < now.getTime();
}

/** Deterministic id of the task an automatic source generates (idempotency key). */
export function sourceTaskId(type: TaskSourceType, refId: string): string {
  return `task_${type.toLowerCase()}_${refId.replace(/[^A-Za-z0-9_-]/g, '_')}`;
}
