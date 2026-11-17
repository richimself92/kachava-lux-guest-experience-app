import { OperationalAlert } from '../../src/domain/models/domain.models';
import {
  arrivalNotification,
  filterNotifications,
  levelOf,
  notificationFromAlert,
  taskOverdueNotification,
  tripUnconfirmedNotification,
} from '../../src/domain/notifications/notification-rules';
import { stayFixture } from '../support/stay-fixtures';
import { taskFixture } from '../support/task-fixtures';
import { tripFixture } from '../support/trip-fixtures';

function alert(overrides: Partial<OperationalAlert> = {}): OperationalAlert {
  return {
    alertId: 'alt-1', stayId: 'stay-1', villaId: 'villa-a', villaName: 'Test Villa', guestNames: 'Test Guest',
    category: 'CONCIERGE', severity: 'NORMAL', title: 'Title', summary: 'Summary',
    sourceDocumentPath: 'stays/stay-1/concierge_requests/req-1', assignedDepartment: 'CONCIERGE',
    isAcknowledged: false, acknowledgedByStaffId: null, acknowledgedAt: null, createdAt: '2026-11-20T10:00:00.000Z',
    ...overrides,
  };
}

describe('levelOf', () => {
  it('test_severityMapsToLevel', () => {
    expect(levelOf('NORMAL')).toBe('INFO');
    expect(levelOf('HIGH')).toBe('ACTION');
    expect(levelOf('URGENT')).toBe('URGENT');
  });
});

describe('notificationFromAlert', () => {
  it('test_storedAlert_mapsLevelReadStateAndTargetFromTheSourcePath', () => {
    const n = notificationFromAlert(alert({ isAcknowledged: true, acknowledgedAt: '2026-11-20T11:00:00.000Z' }));

    expect(n).toEqual({
      id: 'alt-1', event: 'GUEST_REQUEST', level: 'INFO', category: 'CONCIERGE', title: 'Title', summary: 'Summary',
      stayId: 'stay-1', villaId: 'villa-a', villaName: 'Test Villa', guestName: 'Test Guest',
      createdAt: '2026-11-20T10:00:00.000Z', read: true, readAt: '2026-11-20T11:00:00.000Z', playSound: false,
      targetRef: { type: 'REQUEST', id: 'req-1', stayId: 'stay-1' },
    });
  });

  it.each([
    ['stays/stay-1', { type: 'STAY', id: 'stay-1' }],
    ['stays/stay-1/midstay_feedback/fb-1', { type: 'FEEDBACK', id: 'fb-1' }],
    ['trips/trip-1', { type: 'TRIP', id: 'trip-1' }],
  ])('test_sourcePath_%s_isTheTarget', (path, target) => {
    expect(notificationFromAlert(alert({ sourceDocumentPath: path })).targetRef).toEqual({ ...target, stayId: 'stay-1' });
  });

  it('test_explicitTargetAndEvent_win_andUrgentPlaysSound', () => {
    const n = notificationFromAlert(alert({
      severity: 'URGENT', event: 'ITINERARY_CHANGE', targetRef: { type: 'TRIP', id: 'trip-9' },
    }));

    expect(n).toMatchObject({ level: 'URGENT', playSound: true, event: 'ITINERARY_CHANGE', targetRef: { type: 'TRIP', id: 'trip-9', stayId: 'stay-1' } });
  });

  it('test_transferWithoutEvent_isAnItineraryChange', () => {
    expect(notificationFromAlert(alert({ category: 'TRANSFER', sourceDocumentPath: 'stays/stay-1' })).event).toBe('ITINERARY_CHANGE');
  });
});

describe('computed notifications', () => {
  it('test_arrivalDay_isInfoAboutTheStay', () => {
    const stay = stayFixture({ checkInDate: '2026-12-01' });

    const n = arrivalNotification(stay, '2026-12-01T05:00:00.000Z');

    expect(n).toMatchObject({
      id: 'arrival_stay-test-1_2026-12-01', event: 'ARRIVAL_DAY', level: 'INFO', category: 'ARRIVAL',
      createdAt: '2026-12-01T05:00:00.000Z', read: false, playSound: false,
      targetRef: { type: 'STAY', id: 'stay-test-1', stayId: 'stay-test-1' },
    });
  });

  it('test_overdueTask_isAction_orUrgentForUrgentTasks', () => {
    const n = taskOverdueNotification(taskFixture());
    const urgent = taskOverdueNotification(taskFixture({ priority: 'URGENT' }));

    expect(n).toMatchObject({
      id: 'task-overdue_task-1', event: 'TASK_OVERDUE', level: 'ACTION', category: 'TASK',
      createdAt: '2026-11-21T10:00:00.000Z', targetRef: { type: 'TASK', id: 'task-1', stayId: 'stay-test-1' },
    });
    expect(urgent).toMatchObject({ level: 'URGENT', playSound: true });
  });

  it('test_unconfirmedTrip_isUrgent_fromTheMomentItBecameDue', () => {
    const n = tripUnconfirmedNotification(tripFixture(), 12);

    expect(n).toMatchObject({
      id: 'trip-unconfirmed_trip-1', event: 'TRIP_UNCONFIRMED', level: 'URGENT', playSound: true, category: 'TRANSFER',
      createdAt: '2026-12-01T07:30:00.000Z', targetRef: { type: 'TRIP', id: 'trip-1', stayId: 'stay-test-1' },
    });
  });
});

describe('filterNotifications', () => {
  const list = [
    notificationFromAlert(alert({ alertId: 'a', severity: 'URGENT', createdAt: '2026-11-20T10:00:00.000Z' })),
    notificationFromAlert(alert({ alertId: 'b', category: 'BOOKING', isAcknowledged: true, createdAt: '2026-11-21T10:00:00.000Z' })),
    notificationFromAlert(alert({ alertId: 'c', createdAt: '2026-11-22T10:00:00.000Z' })),
  ];
  const ids = (filter: Parameters<typeof filterNotifications>[1]) => filterNotifications(list, filter).map((n) => n.id);

  it('test_filtersByLevelReadCategoryAndWindow', () => {
    expect(ids({ level: 'URGENT' })).toEqual(['a']);
    expect(ids({ read: true })).toEqual(['b']);
    expect(ids({ read: false })).toEqual(['a', 'c']);
    expect(ids({ category: 'BOOKING' })).toEqual(['b']);
    expect(ids({ fromIso: '2026-11-21T00:00:00.000Z', toIsoExclusive: '2026-11-22T00:00:00.000Z' })).toEqual(['b']);
    expect(ids({})).toEqual(['a', 'b', 'c']);
  });
});
