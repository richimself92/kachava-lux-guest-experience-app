import { BusinessRuleError } from '../../src/domain/domain-errors';
import { applyTaskPatch, transitionTask } from '../../src/domain/tasks/task-transitions';
import { isTaskOverdue, sourceTaskId, Task, TaskStatus } from '../../src/domain/tasks/task.models';
import { taskFixture } from '../support/task-fixtures';

const AT = '2026-11-22T12:00:00.000Z';
const ACTOR = 'staff@test.local';
const OWNER = { ownerStaffId: 'staff-7', ownerName: 'Test Owner' };

function owned(status: TaskStatus, overrides: Partial<Task> = {}): Task {
  return taskFixture({ status, ...OWNER, ...overrides });
}

describe('transitionTask: legal moves', () => {
  it('test_pending_toAssigned_withOwner_setsOwnerHistoryAndAudit', () => {
    const task = taskFixture();

    const next = transitionTask(task, { to: 'ASSIGNED', ...OWNER }, ACTOR, AT);

    expect(next).toMatchObject({ status: 'ASSIGNED', ...OWNER, updatedAt: AT, updatedBy: ACTOR });
    expect(next.statusHistory.at(-1)).toEqual({ from: 'PENDING', to: 'ASSIGNED', at: AT, by: ACTOR });
    expect(task.status).toBe('PENDING');
  });

  it('test_assigned_toInProgress_toCompleted_withNote_recordsCompletion', () => {
    const started = transitionTask(owned('ASSIGNED'), { to: 'IN_PROGRESS' }, ACTOR, AT);

    const done = transitionTask(started, { to: 'COMPLETED', note: '  Pillows placed  ' }, ACTOR, AT);

    expect(done.status).toBe('COMPLETED');
    expect(done.completion).toEqual({ at: AT, by: ACTOR, note: 'Pillows placed' });
  });

  it('test_assigned_canCompleteDirectly', () => {
    expect(transitionTask(owned('ASSIGNED'), { to: 'COMPLETED', note: 'Done' }, ACTOR, AT).status).toBe('COMPLETED');
  });

  it.each(['PENDING', 'ASSIGNED', 'IN_PROGRESS'] as const)('test_%s_canBeCancelled_keepingTheReason', (status) => {
    const next = transitionTask(owned(status), { to: 'CANCELLED', reason: 'Guest declined' }, ACTOR, AT);

    expect(next).toMatchObject({ status: 'CANCELLED', cancellationReason: 'Guest declined' });
  });
});

describe('transitionTask: rejected moves', () => {
  it('test_assigned_withoutOwner_isRejected', () => {
    expect(() => transitionTask(taskFixture(), { to: 'ASSIGNED' }, ACTOR, AT)).toThrow(BusinessRuleError);
    expect(() => transitionTask(taskFixture(), { to: 'ASSIGNED', ownerStaffId: '  ' }, ACTOR, AT)).toThrow(/owner/);
  });

  it('test_completed_withoutNote_isRejected', () => {
    expect(() => transitionTask(owned('IN_PROGRESS'), { to: 'COMPLETED' }, ACTOR, AT)).toThrow(/note/);
    expect(() => transitionTask(owned('IN_PROGRESS'), { to: 'COMPLETED', note: ' ' }, ACTOR, AT)).toThrow(BusinessRuleError);
  });

  it.each([
    ['PENDING', 'IN_PROGRESS'],
    ['PENDING', 'COMPLETED'],
    ['IN_PROGRESS', 'ASSIGNED'],
    ['ASSIGNED', 'PENDING'],
  ] as const)('test_%s_to_%s_isIllegal', (from, to) => {
    expect(() => transitionTask(owned(from), { to, note: 'n' }, ACTOR, AT)).toThrow(BusinessRuleError);
  });

  it.each(['COMPLETED', 'CANCELLED'] as const)('test_final_%s_cannotMove', (status) => {
    expect(() => transitionTask(owned(status), { to: 'CANCELLED' }, ACTOR, AT)).toThrow(/final/);
  });
});

describe('applyTaskPatch', () => {
  it('test_editsFields_andAudit_withoutTouchingStatus', () => {
    const next = applyTaskPatch(taskFixture(), { title: ' New title ', priority: 'URGENT', dueAt: null }, ACTOR, AT);

    expect(next).toMatchObject({ title: 'New title', priority: 'URGENT', dueAt: null, status: 'PENDING', updatedBy: ACTOR });
  });

  it('test_clearingTheOwnerOfAnAssignedTask_isRejected', () => {
    expect(() => applyTaskPatch(owned('ASSIGNED'), { ownerStaffId: null }, ACTOR, AT)).toThrow(/owner/);
  });

  it('test_finalTask_cannotBeEdited', () => {
    expect(() => applyTaskPatch(owned('COMPLETED'), { title: 'x' }, ACTOR, AT)).toThrow(/final/);
  });

  it('test_blankTitle_isRejected', () => {
    expect(() => applyTaskPatch(taskFixture(), { title: '  ' }, ACTOR, AT)).toThrow(/title/);
  });
});

describe('overdue and source ids', () => {
  const now = new Date('2026-11-22T00:00:00.000Z');

  it('test_openTaskPastDue_isOverdue_finalOrUndatedIsNot', () => {
    expect(isTaskOverdue(taskFixture({ dueAt: '2026-11-21T23:59:00.000Z' }), now)).toBe(true);
    expect(isTaskOverdue(taskFixture({ dueAt: '2026-11-22T00:01:00.000Z' }), now)).toBe(false);
    expect(isTaskOverdue(taskFixture({ dueAt: null }), now)).toBe(false);
    expect(isTaskOverdue(owned('COMPLETED', { dueAt: '2026-11-01T00:00:00.000Z' }), now)).toBe(false);
  });

  it('test_sourceTaskId_isDeterministicAndPathSafe', () => {
    expect(sourceTaskId('BOOKING', 'bk_1')).toBe('task_booking_bk_1');
    expect(sourceTaskId('ORDER', 'stay/1 svc')).toBe('task_order_stay_1_svc');
  });
});
