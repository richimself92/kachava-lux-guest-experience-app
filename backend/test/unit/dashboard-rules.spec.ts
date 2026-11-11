import {
  activityDetails,
  buildActivity,
  computeDashboardKpis,
  deriveActivityStatus,
} from '../../src/domain/dashboard/dashboard-rules';
import { StayAggregate } from '../../src/domain/models/domain.models';
import { populatedStayFixture, stayFixture, villaFixture } from '../support/stay-fixtures';
import { tripFixture } from '../support/trip-fixtures';

const TODAY = '2026-12-10';

function stay(overrides: Partial<StayAggregate>): StayAggregate {
  return stayFixture({ checkInDate: '2026-12-08', checkOutDate: '2026-12-12', status: 'ACTIVE_STAY', ...overrides });
}

describe('deriveActivityStatus', () => {
  it('test_checkInToday_isArrival_evenBeforeCheckIn', () => {
    expect(deriveActivityStatus(stay({ status: 'PRE_ARRIVAL', checkInDate: TODAY }), TODAY))
      .toEqual({ status: 'ARRIVAL', overdue: false });
    expect(deriveActivityStatus(stay({ status: 'ACTIVE_STAY', checkInDate: TODAY }), TODAY))
      .toEqual({ status: 'ARRIVAL', overdue: false });
  });

  it('test_checkOutToday_isDeparture_andWinsOverArrivalOnTheSameDay', () => {
    expect(deriveActivityStatus(stay({ checkOutDate: TODAY }), TODAY)).toEqual({ status: 'DEPARTURE', overdue: false });
    expect(deriveActivityStatus(stay({ status: 'PRE_ARRIVAL', checkInDate: TODAY, checkOutDate: TODAY }), TODAY))
      .toEqual({ status: 'DEPARTURE', overdue: false });
  });

  it('test_checkedIn_isInHouse', () => {
    expect(deriveActivityStatus(stay({}), TODAY)).toEqual({ status: 'IN_HOUSE', overdue: false });
  });

  it('test_inHouseAfterCheckOutDate_isOverdue', () => {
    expect(deriveActivityStatus(stay({ checkOutDate: '2026-12-09' }), TODAY)).toEqual({ status: 'IN_HOUSE', overdue: true });
  });

  it.each([
    ['future', { status: 'PRE_ARRIVAL' as const, checkInDate: '2026-12-11', checkOutDate: '2026-12-14' }],
    ['not checked in yet', { status: 'PRE_ARRIVAL' as const, checkInDate: '2026-12-09' }],
    ['cancelled', { status: 'CANCELLED' as const, checkInDate: TODAY }],
    ['checked out', { status: 'CHECKED_OUT' as const, checkOutDate: TODAY }],
    ['expired', { status: 'EXPIRED' as const }],
  ])('test_%s_isExcluded', (_label, overrides) => {
    expect(deriveActivityStatus(stay(overrides), TODAY)).toBeNull();
  });
});

describe('buildActivity', () => {
  it('test_rows_areCappedAtTheLimit_withTotalOfAllRows_overdueFirst', () => {
    const stays = [
      stay({ stayId: 's-arr', checkInDate: TODAY, status: 'PRE_ARRIVAL' }),
      stay({ stayId: 's-in' }),
      stay({ stayId: 's-dep', checkOutDate: TODAY }),
      stay({ stayId: 's-over', checkOutDate: '2026-12-01' }),
      stay({ stayId: 's-future', status: 'PRE_ARRIVAL', checkInDate: '2026-12-20', checkOutDate: '2026-12-22' }),
    ];

    const activity = buildActivity(stays, TODAY, 3);

    expect(activity.total).toBe(4);
    expect(activity.rows.map((r) => r.stayId)).toEqual(['s-over', 's-dep', 's-arr']);
    expect(activity.rows[0]).toEqual({
      stayId: 's-over', guestName: 'Test Guest', villaId: 'villa-a', villaName: 'Test Villa',
      status: 'IN_HOUSE', overdue: true,
    });
  });
});

describe('computeDashboardKpis', () => {
  const villas = [
    villaFixture({ villaId: 'v1' }),
    villaFixture({ villaId: 'v2' }),
    villaFixture({ villaId: 'v3', operationalStatus: 'MAINTENANCE' }),
    villaFixture({ villaId: 'v4', operationalStatus: 'BLOCKED' }),
    villaFixture({ villaId: 'v5', isActive: false }),
  ];

  it('test_occupancyArrivalsDepartures_followThePlanFormulas', () => {
    const stays = [
      stay({ villaId: 'v1' }),
      stay({ villaId: 'v3', checkOutDate: TODAY }),
      stay({ villaId: 'v2', status: 'PRE_ARRIVAL', checkInDate: TODAY }),
      stay({ villaId: 'v2', status: 'PRE_ARRIVAL', checkInDate: '2026-12-20', checkOutDate: '2026-12-22' }),
    ];

    const kpis = computeDashboardKpis({ villas, stays, today: TODAY, openTrips: 0, openTasks: 0 });

    // occupied: v1 and v3 (in-house); out of service and not occupied: v4; available: 4 - 2 - 1.
    expect(kpis).toEqual({
      occupiedVillas: 2, availableVillas: 1, occupancyPct: 50, arrivals: 1, departures: 1, openRequests: 0,
    });
  });

  it('test_noActiveVillas_isZeroPercent', () => {
    const kpis = computeDashboardKpis({ villas: [], stays: [], today: TODAY, openTrips: 0, openTasks: 0 });

    expect(kpis.occupancyPct).toBe(0);
    expect(kpis.availableVillas).toBe(0);
  });

  it('test_openRequests_countsOpenOrdersBookingsTripsAndTasks', () => {
    const open = populatedStayFixture();
    const closedBooking = { ...open.experienceBookings[0], bookingId: 'bk-done', status: 'COMPLETED' as const };
    const stockedLine = { ...open.larderOrders[0], orderItemId: 'l-2', serviceId: 'svc-other', provisioningStatus: 'Stocked in Villa' };
    const secondLineSameOrder = { ...open.larderOrders[0], orderItemId: 'l-3' };
    const withClosed = {
      ...open,
      experienceBookings: [...open.experienceBookings, closedBooking],
      larderOrders: [...open.larderOrders, secondLineSameOrder, stockedLine],
    };

    const kpis = computeDashboardKpis({ villas, stays: [withClosed], today: TODAY, openTrips: 2, openTasks: 3 });

    // 1 open order (one stay+service), 1 open booking, 2 trips, 3 tasks.
    expect(kpis.openRequests).toBe(7);
  });
});

describe('activityDetails', () => {
  const arrivalRow = { status: 'ARRIVAL' as const, overdue: false };

  it('test_arrivalDay_nextIsTheFlight_withTheTransferState', () => {
    const s = populatedStayFixture({ status: 'PRE_ARRIVAL', checkInDate: TODAY });
    const noDriver = tripFixture({ stayId: s.stayId, status: 'SENT_TO_PROVIDER' });
    const confirmed = tripFixture({ stayId: s.stayId, status: 'CONFIRMED' });

    expect(activityDetails(arrivalRow, s, [noDriver], TODAY).next).toEqual({
      kind: 'FLIGHT', at: '2026-12-01T19:30:00.000Z', flightNumber: 'Test Air TA 100',
      transfer: 'NO_DRIVER', title: null, date: null, time: null,
    });
    expect(activityDetails(arrivalRow, s, [confirmed], TODAY).next?.transfer).toBe('DRIVER_CONFIRMED');
    expect(activityDetails(arrivalRow, s, [], TODAY).next).toMatchObject({ kind: 'FLIGHT', transfer: 'NONE', at: null });
    expect(activityDetails(arrivalRow, s, [tripFixture({ type: 'DEPARTURE' })], TODAY).next?.transfer).toBe('NONE');
  });

  it('test_inHouse_nextIsTheNextOpenBooking_elseNull', () => {
    const s = populatedStayFixture({});
    s.experienceBookings[0] = { ...s.experienceBookings[0], scheduledDate: '2026-12-11', scheduledTimeSlot: '16:00' };
    const details = activityDetails({ status: 'IN_HOUSE', overdue: false }, s, [], TODAY);

    expect(details.next).toMatchObject({ kind: 'BOOKING', date: '2026-12-11', time: '16:00' });
    expect(details.next?.title?.en).toBeTruthy();
    const past = populatedStayFixture({});
    expect(activityDetails({ status: 'IN_HOUSE', overdue: false }, past, [], TODAY).next).toBeNull();
  });

  it('test_pending_countsOpenRequestsTripsAndUnreadGuestMessages_andStayStatus', () => {
    const s = populatedStayFixture({ status: 'PRE_ARRIVAL', checkInDate: TODAY });
    const details = activityDetails(arrivalRow, s, [tripFixture(), tripFixture({ status: 'CANCELLED' })], TODAY);

    expect(details.pending).toEqual({ requests: 3, messages: 1 }); // order + booking + open trip
    expect(details.stayStatus).toBe('PRE_ARRIVAL');
  });
});
