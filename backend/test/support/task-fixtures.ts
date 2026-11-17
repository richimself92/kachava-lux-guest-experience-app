import { Task } from '../../src/domain/tasks/task.models';

const AT = '2026-11-20T10:00:00.000Z';

/** Neutral test-only task (manual, pending); exists only under test/. */
export function taskFixture(overrides: Partial<Task> = {}): Task {
  return {
    taskId: 'task-1',
    title: 'Test task',
    source: { type: 'MANUAL', refId: null, stayId: 'stay-test-1' },
    villaId: 'villa-a',
    villaName: 'Test Villa',
    guestName: 'Test Guest',
    category: 'Housekeeping',
    ownerStaffId: null,
    ownerName: null,
    priority: 'NORMAL',
    dueAt: '2026-11-21T10:00:00.000Z',
    status: 'PENDING',
    completion: null,
    cancellationReason: null,
    statusHistory: [{ from: null, to: 'PENDING', at: AT, by: 'staff@test.local' }],
    createdAt: AT,
    createdBy: 'staff@test.local',
    updatedAt: AT,
    updatedBy: 'staff@test.local',
    ...overrides,
  };
}
