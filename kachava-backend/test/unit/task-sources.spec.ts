import {
  bookingTaskFor,
  orderTaskFor,
  resortWallTimeIso,
  tripTaskFor,
} from '../../src/domain/tasks/task-sources';
import { serviceFixture } from '../support/catalog-fixtures';
import { populatedStayFixture } from '../support/stay-fixtures';
import { tripFixture } from '../support/trip-fixtures';

const AT = '2026-11-20T10:00:00.000Z';
const ACTOR = 'guest:stay-test-1';
const SCHEDULE = { timeZone: 'America/Cancun', checkInTime: '15:00' };

describe('resortWallTimeIso', () => {
  it('test_dateAndTime_areReadInTheResortZone', () => {
    expect(resortWallTimeIso('2026-12-01', '15:00', 'America/Cancun')).toBe('2026-12-01T20:00:00.000Z');
    expect(resortWallTimeIso('2026-12-01', '', 'America/Cancun')).toBe('2026-12-01T05:00:00.000Z');
  });

  it('test_missingZoneOrDate_hasNoDeadline', () => {
    expect(resortWallTimeIso('2026-12-01', '15:00', null)).toBeNull();
    expect(resortWallTimeIso(undefined, '15:00', 'America/Cancun')).toBeNull();
  });
});

describe('bookingTaskFor', () => {
  const stay = populatedStayFixture();
  const booking = stay.experienceBookings[0];

  it('test_preferenceChoice_createsAPreparationTaskDueAtCheckIn', () => {
    const service = serviceFixture({ kind: 'PREFERENCE', usageType: 'PREFERENCE', section: 'IN_VILLA' });
    const choice = { ...booking, bookingId: 'bk-pref', usageType: 'PREFERENCE' as const };

    const task = bookingTaskFor({ stay, booking: choice, service, schedule: SCHEDULE, actor: ACTOR, at: AT });

    expect(task).toMatchObject({
      taskId: 'task_preference_bk-pref',
      source: { type: 'PREFERENCE', refId: 'bk-pref', stayId: stay.stayId },
      villaId: stay.villaId, guestName: 'Test Guest', category: 'IN_VILLA',
      priority: 'NORMAL', status: 'PENDING', dueAt: '2026-12-01T20:00:00.000Z', createdBy: ACTOR,
    });
    expect(task?.title).toContain('Prepare');
  });

  it('test_bookingRequiringConfirmation_createsAConfirmationTaskDueAtTheSlot', () => {
    const base = serviceFixture();
    const service = { ...base, operation: { ...base.operation, requiresConfirmation: true, responsibleStaffId: 'staff-9' } };

    const task = bookingTaskFor({ stay, booking, service, schedule: SCHEDULE, actor: ACTOR, at: AT });

    expect(task).toMatchObject({
      taskId: 'task_booking_bk-test-1', source: { type: 'BOOKING', refId: 'bk-test-1' },
      ownerStaffId: 'staff-9', status: 'ASSIGNED', dueAt: '2026-12-03T15:00:00.000Z',
    });
    expect(task?.title).toContain('Confirm');
  });

  it('test_bookingWithoutConfirmation_createsNoTask', () => {
    const base = serviceFixture();
    const service = { ...base, operation: { ...base.operation, requiresConfirmation: false } };

    expect(bookingTaskFor({ stay, booking, service, schedule: SCHEDULE, actor: ACTOR, at: AT })).toBeNull();
  });
});

describe('orderTaskFor and tripTaskFor', () => {
  it('test_stockingOrder_isOneTaskPerStayAndService', () => {
    const stay = populatedStayFixture();
    const service = serviceFixture({ serviceId: 'svc-stock', kind: 'VILLA_STOCKING', usageType: 'ORDER', section: 'IN_VILLA' });

    const task = orderTaskFor({ stay, service, lineCount: 3, schedule: SCHEDULE, actor: ACTOR, at: AT });

    expect(task).toMatchObject({
      taskId: 'task_order_stay-test-1_svc-stock',
      source: { type: 'ORDER', refId: 'stay-test-1_svc-stock', stayId: 'stay-test-1' },
      dueAt: '2026-12-01T20:00:00.000Z',
    });
  });

  it('test_trip_createsAHighPriorityCoordinationTaskDueAtPickup', () => {
    const trip = tripFixture();

    const task = tripTaskFor(trip, ACTOR, AT);

    expect(task).toMatchObject({
      taskId: 'task_trip_trip-1', source: { type: 'TRIP', refId: 'trip-1', stayId: 'stay-test-1' },
      category: 'TRANSPORTATION', priority: 'HIGH', dueAt: trip.pickupAt, guestName: 'Test Guest',
    });
    expect(task.title).toContain('Coordinate');
  });
});
