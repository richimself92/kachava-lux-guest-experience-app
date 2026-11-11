import { BusinessRuleError } from '../../src/domain/domain-errors';
import { statusRequirementProblems, transitionTrip } from '../../src/domain/trips/trip-transitions';
import { Trip, TripStatus } from '../../src/domain/trips/trip.models';
import { tripFixture } from '../support/trip-fixtures';

const AT = '2026-11-30T12:00:00.000Z';
const ACTOR = 'staff@test.local';
const DRIVER = { name: 'Test Driver', phone: '+52 000 000 0000' };

function readyToConfirm(overrides: Partial<Trip> = {}): Trip {
  return tripFixture({ status: 'SENT_TO_PROVIDER', providerId: 'prov-1', ...overrides });
}

describe('transitionTrip: forward flow', () => {
  it('test_requested_toSentToProvider_withProvider_recordsHistoryAndAudit', () => {
    const trip = tripFixture();

    const next = transitionTrip(trip, { to: 'SENT_TO_PROVIDER', providerId: 'prov-1' }, ACTOR, AT);

    expect(next).toMatchObject({ status: 'SENT_TO_PROVIDER', providerId: 'prov-1', updatedAt: AT, updatedBy: ACTOR });
    expect(next.statusHistory.at(-1)).toEqual({ from: 'REQUESTED', to: 'SENT_TO_PROVIDER', at: AT, by: ACTOR, reason: null });
    expect(trip.status).toBe('REQUESTED');
  });

  it('test_sentToProvider_toConfirmed_withDriverAndVehicle_storesThem', () => {
    const vehicle = { description: 'Test van', plate: 'TEST-01' };

    const next = transitionTrip(readyToConfirm(), { to: 'CONFIRMED', driver: DRIVER, vehicle }, ACTOR, AT);

    expect(next).toMatchObject({ status: 'CONFIRMED', driver: DRIVER, vehicle });
  });

  it('test_confirmedToEnRouteToCompleted', () => {
    const confirmed = readyToConfirm({ status: 'CONFIRMED', driver: DRIVER });

    const completed = transitionTrip(transitionTrip(confirmed, { to: 'EN_ROUTE' }, ACTOR, AT), { to: 'COMPLETED' }, ACTOR, AT);

    expect(completed.status).toBe('COMPLETED');
    expect(completed.statusHistory.map((h) => h.to)).toEqual(['REQUESTED', 'EN_ROUTE', 'COMPLETED']);
  });
});

describe('transitionTrip: rejected moves', () => {
  it.each<[TripStatus, TripStatus]>([
    ['REQUESTED', 'CONFIRMED'],
    ['REQUESTED', 'EN_ROUTE'],
    ['REQUESTED', 'REQUESTED'],
    ['SENT_TO_PROVIDER', 'REQUESTED'],
    ['CONFIRMED', 'COMPLETED'],
    ['EN_ROUTE', 'CONFIRMED'],
  ])('test_%s_to_%s_isRejected', (from, to) => {
    const trip = tripFixture({ status: from, providerId: 'prov-1', driver: DRIVER });

    expect(() => transitionTrip(trip, { to }, ACTOR, AT)).toThrow(/Cannot move a trip from/);
  });

  it.each<TripStatus>(['COMPLETED', 'CANCELLED'])('test_finalStatus_%s_cannotChange', (status) => {
    const trip = tripFixture({ status, providerId: 'prov-1', driver: DRIVER });

    expect(() => transitionTrip(trip, { to: 'CANCELLED', reason: 'late' }, ACTOR, AT)).toThrow(/final/);
  });

  it('test_sentToProvider_withoutProvider_isRejected', () => {
    expect(() => transitionTrip(tripFixture(), { to: 'SENT_TO_PROVIDER' }, ACTOR, AT)).toThrow('providerId is required');
  });

  it('test_confirmed_requiresProviderAndDriverNameAndPhone', () => {
    const attempt = () => transitionTrip(readyToConfirm(), { to: 'CONFIRMED', driver: { name: 'Only Name', phone: ' ' } }, ACTOR, AT);

    expect(attempt).toThrow(BusinessRuleError);
    expect(attempt).toThrow('driver.phone is required');
  });

  it('test_confirmed_withoutAnyDriver_listsBothDriverFields', () => {
    expect(() => transitionTrip(readyToConfirm(), { to: 'CONFIRMED' }, ACTOR, AT)).toThrow(
      'driver.name is required; driver.phone is required',
    );
  });
});

describe('transitionTrip: cancellation', () => {
  it.each<TripStatus>(['REQUESTED', 'SENT_TO_PROVIDER', 'CONFIRMED', 'EN_ROUTE'])(
    'test_cancel_from_%s_withReason_isAllowed',
    (status) => {
      const trip = tripFixture({ status, providerId: 'prov-1', driver: DRIVER });

      const next = transitionTrip(trip, { to: 'CANCELLED', reason: '  Flight cancelled  ' }, ACTOR, AT);

      expect(next).toMatchObject({ status: 'CANCELLED', cancellationReason: 'Flight cancelled' });
      expect(next.statusHistory.at(-1)).toMatchObject({ from: status, to: 'CANCELLED', reason: 'Flight cancelled' });
    },
  );

  it.each([undefined, '', '   '])('test_cancel_withoutReason_%j_isRejected', (reason) => {
    expect(() => transitionTrip(tripFixture(), { to: 'CANCELLED', reason }, ACTOR, AT)).toThrow('reason is required');
  });
});

describe('statusRequirementProblems (invariants that edits must keep)', () => {
  it('test_requested_hasNoRequirements', () => {
    expect(statusRequirementProblems(tripFixture())).toEqual([]);
  });

  it('test_enRoute_withoutDriverPhone_isReported', () => {
    const trip = tripFixture({ status: 'EN_ROUTE', providerId: 'prov-1', driver: { name: 'Test Driver', phone: '' } });

    expect(statusRequirementProblems(trip)).toEqual(['driver.phone is required']);
  });
});
