import { BusinessRuleError } from '../domain-errors';
import {
  isFinalTaskStatus,
  OWNED_TASK_STATUSES,
  Task,
  TaskPriority,
  TaskStatus,
} from './task.models';

/** Forward moves (CANCELLED is reachable from every open status). */
const NEXT_STATUSES: Partial<Record<TaskStatus, readonly TaskStatus[]>> = {
  PENDING: ['ASSIGNED'],
  ASSIGNED: ['IN_PROGRESS', 'COMPLETED'],
  IN_PROGRESS: ['COMPLETED'],
};

export interface TaskTransitionCommand {
  to: TaskStatus;
  ownerStaffId?: string;
  ownerName?: string;
  /** Completion confirmation; required for COMPLETED. */
  note?: string;
  reason?: string;
}

export interface TaskPatch {
  title?: string;
  category?: string;
  priority?: TaskPriority;
  dueAt?: string | null;
  ownerStaffId?: string | null;
  ownerName?: string | null;
}

function isBlank(value: string | null | undefined): boolean {
  return !value || value.trim().length === 0;
}

function assertEditable(task: Task): void {
  if (isFinalTaskStatus(task.status)) {
    throw new BusinessRuleError(`Task is ${task.status}, a final status; it cannot change`);
  }
}

function assertOwnerInvariant(task: Task): void {
  if (OWNED_TASK_STATUSES.includes(task.status) && isBlank(task.ownerStaffId)) {
    throw new BusinessRuleError(`A ${task.status} task needs an owner`, ['ownerStaffId is required']);
  }
}

function assertMoveAllowed(from: TaskStatus, to: TaskStatus): void {
  if (to === 'CANCELLED') return;
  if (!(NEXT_STATUSES[from] ?? []).includes(to)) {
    throw new BusinessRuleError(`Cannot move a task from ${from} to ${to}`);
  }
}

/**
 * Pure status change: ASSIGNED (and later) needs an owner, COMPLETED needs a completion note
 * (stored with who and when). Final statuses never change. Never mutates `task`.
 */
export function transitionTask(task: Task, command: TaskTransitionCommand, actor: string, at: string): Task {
  assertEditable(task);
  assertMoveAllowed(task.status, command.to);
  const next: Task = {
    ...structuredClone(task),
    ...(command.ownerStaffId !== undefined ? { ownerStaffId: command.ownerStaffId.trim() } : {}),
    ...(command.ownerName !== undefined ? { ownerName: command.ownerName.trim() } : {}),
    status: command.to,
    updatedAt: at,
    updatedBy: actor,
  };
  assertOwnerInvariant(next);
  if (command.to === 'COMPLETED') {
    if (isBlank(command.note)) {
      throw new BusinessRuleError('Cannot complete the task', ['note is required to confirm completion']);
    }
    next.completion = { at, by: actor, note: (command.note as string).trim() };
  }
  if (command.to === 'CANCELLED') next.cancellationReason = command.reason?.trim() || null;
  next.statusHistory.push({ from: task.status, to: command.to, at, by: actor });
  return next;
}

/** Edits the descriptive fields of an open task; status only moves through `transitionTask`. */
export function applyTaskPatch(task: Task, patch: TaskPatch, actor: string, at: string): Task {
  assertEditable(task);
  if (patch.title !== undefined && isBlank(patch.title)) {
    throw new BusinessRuleError('Invalid task', ['title must not be blank']);
  }
  const next: Task = {
    ...structuredClone(task),
    ...(patch.title !== undefined ? { title: patch.title.trim() } : {}),
    ...(patch.category !== undefined ? { category: patch.category.trim() } : {}),
    ...(patch.priority !== undefined ? { priority: patch.priority } : {}),
    ...(patch.dueAt !== undefined ? { dueAt: patch.dueAt } : {}),
    ...(patch.ownerStaffId !== undefined ? { ownerStaffId: patch.ownerStaffId?.trim() || null } : {}),
    ...(patch.ownerName !== undefined ? { ownerName: patch.ownerName?.trim() || null } : {}),
    updatedAt: at,
    updatedBy: actor,
  };
  assertOwnerInvariant(next);
  return next;
}
