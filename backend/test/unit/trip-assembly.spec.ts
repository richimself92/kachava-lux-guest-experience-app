import { BusinessRuleError } from '../../src/domain/domain-errors';
import { ResortSettings, unconfiguredSettings } from '../../src/domain/models/resort-config.models';
import { tripAlert } from '../../src/domain/trips/trip-alerts';
import { applyTripPatch, resolveSchedule } from '../../src/domain/trips/trip-assembly';
import { filterTrips } from '../../src/domain/trips/trip-listing';
import { serviceFixture } from '../support/catalog-fixtures';
import { tripFixture } from '../support/trip-fixtures';

const AT = '2026-11-25T12:00:00.000Z';
const settings: ResortSettings = {
  ...unconfiguredSettings(),
  timeZone: 'America/Cancun',
  airports: [
    { code: 'AAA', name: 'A', departureBufferHours: 3, isActive: true },
    { code: 'BBB', name: 'B', departureBufferHours: 1, isActive: true },
  ],
  transportAlertLeadHours: 12,
};
const transportService = serviceFixture({
  kind: 'TRANSPORT', section: 'TRANSPORTATION', usageType: 'TRIP', experience: null,
  transport: { airportCodes: [], priceBasis: null, flightDetailsRequired: true },
});

describe('resolveSchedule', () => {
  const flight = { airline: 'Test Air', number: 'TA 1', scheduledAt: '2026-12-04T12:00' };

  it('test_departure_suggestsPickupFromBuffer_inResortTime', () => {
    expect(resolveSchedule({ type: 'DEPARTURE', airportCode: 'AAA', flight }, settings, transportService)).toEqual({
      airportCode: 'AAA',
      flight: { airline: 'Test Air', number: 'TA 1', scheduledAt: '2026-12-04T17:00:00.000Z' },
      pickupAt: '2026-12-04T14:00:00.000Z',
    });
  });

  it('test_explicitPickup_overridesSuggestion', () => {
    const schedule = resolveSchedule({ type: 'DEPARTURE', airportCode: 'AAA', flight, pickupAt: '2026-12-04T08:00' }, settings, transportService);

    expect(schedule.pickupAt).toBe('2026-12-04T13:00:00.000Z');
  });

  it('test_airportTripMissingFlight_isInvalid', () => {
    expect(() => resolveSchedule({ type: 'ARRIVAL', airportCode: 'AAA' }, settings, transportService)).toThrow(
      'flight is required for ARRIVAL trips',
    );
  });

  it('test_localTrip_needsPickup', () => {
    expect(() => resolveSchedule({ type: 'LOCAL' }, settings, transportService)).toThrow('pickupAt is required for LOCAL trips');
  });
});

describe('applyTripPatch', () => {
  const departure = tripFixture({
    type: 'DEPARTURE', airportCode: 'AAA',
    flight: { airline: 'Test Air', number: 'TA 1', scheduledAt: '2026-12-04T17:00:00.000Z' },
    pickupAt: '2026-12-04T14:00:00.000Z',
  });

  it('test_airportChange_recomputesPickupWithNewBuffer', () => {
    const next = applyTripPatch(departure, { airportCode: 'BBB' }, settings, 'staff', AT);

    expect(next).toMatchObject({ airportCode: 'BBB', pickupAt: '2026-12-04T16:00:00.000Z', updatedAt: AT, updatedBy: 'staff' });
  });

  it('test_explicitPickupInSamePatch_wins', () => {
    const next = applyTripPatch(
      departure,
      { flight: { airline: 'Test Air', number: 'TA 1', scheduledAt: '2026-12-04T20:00:00Z' }, pickupAt: '2026-12-04T09:30' },
      settings, 'staff', AT,
    );

    expect(next.pickupAt).toBe('2026-12-04T14:30:00.000Z');
    expect(next.flight?.scheduledAt).toBe('2026-12-04T20:00:00.000Z');
  });

  it('test_plainFieldsAndNullables_areApplied', () => {
    const next = applyTripPatch(departure, { notes: 'n', guestNotes: 'g', providerId: null, vehicle: null, luggage: 0 }, settings, 'staff', AT);

    expect(next).toMatchObject({ notes: 'n', guestNotes: 'g', providerId: null, vehicle: null, luggage: 0, pickupAt: departure.pickupAt });
  });

  it('test_finalTrip_cannotBeEdited', () => {
    expect(() => applyTripPatch(tripFixture({ status: 'COMPLETED' }), { notes: 'x' }, settings, 'staff', AT)).toThrow(BusinessRuleError);
  });

  it('test_patchBreakingShape_isRejected', () => {
    expect(() => applyTripPatch(departure, { waitMinutes: 10 }, settings, 'staff', AT)).toThrow('waitMinutes applies to LOCAL trips only');
  });
});

describe('filterTrips (in-memory filters and search)', () => {
  const trips = [
    tripFixture({ tripId: 'a', guestName: 'José Núñez', flight: { airline: 'X', number: 'AB 12', scheduledAt: AT } }),
    tripFixture({ tripId: 'b', guestName: 'Ana Test', type: 'LOCAL', flight: null, villaId: 'villa-b', providerId: 'p1', status: 'SENT_TO_PROVIDER' }),
  ];
  const idsOf = (filter: Parameters<typeof filterTrips>[1]) => filterTrips(trips, filter).map((t) => t.tripId);

  it('test_equalityFilters', () => {
    expect(idsOf({ status: 'SENT_TO_PROVIDER' })).toEqual(['b']);
    expect(idsOf({ type: 'ARRIVAL' })).toEqual(['a']);
    expect(idsOf({ providerId: 'p1', villaId: 'villa-b' })).toEqual(['b']);
    expect(idsOf({})).toEqual(['a', 'b']);
  });

  it('test_searchMatchesAccentFreeGuestNameOrSpacelessFlightNumber', () => {
    expect(idsOf({ q: 'nunez' })).toEqual(['a']);
    expect(idsOf({ q: 'ab12' })).toEqual(['a']);
    expect(idsOf({ q: 'ab 1' })).toEqual(['a']);
    expect(idsOf({ q: 'zz' })).toEqual([]);
  });
});

describe('tripAlert', () => {
  it('test_requestedAlert_isHighTransferWithTargetRef', () => {
    const alert = tripAlert(tripFixture(), 'REQUESTED', 'alt-1', AT);

    expect(alert).toMatchObject({
      alertId: 'alt-1', category: 'TRANSFER', severity: 'HIGH', assignedDepartment: 'TRANSPORT', isAcknowledged: false,
      stayId: 'stay-test-1', villaName: 'Test Villa', guestNames: 'Test Guest', sourceDocumentPath: 'trips/trip-1',
      targetRef: { type: 'TRIP', id: 'trip-1' }, createdAt: AT,
    });
    expect(alert.title).toContain('ARRIVAL');
  });

  it('test_flightChangedAlert_namesTheFlight', () => {
    expect(tripAlert(tripFixture(), 'FLIGHT_CHANGED', 'alt-2', AT).summary).toContain('TA 100');
  });
});
