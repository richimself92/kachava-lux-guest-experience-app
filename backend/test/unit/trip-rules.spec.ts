import { BusinessRuleError, SettingsRequiredError } from '../../src/domain/domain-errors';
import { ResortSettings, unconfiguredSettings } from '../../src/domain/models/resort-config.models';
import {
  assertGuestLeadTime,
  assertServiceServesAirport,
  capacityProblems,
  flightChanged,
  isUnconfirmedDue,
  requireLeadHours,
  resolveAirport,
  suggestedPickupAt,
  tripShapeProblems,
} from '../../src/domain/trips/trip-rules';
import { toAdminTripView, toGuestTripView } from '../../src/domain/trips/trip-views';
import { TripServiceSnapshot } from '../../src/domain/trips/trip.models';
import { serviceFixture } from '../support/catalog-fixtures';
import { tripFixture } from '../support/trip-fixtures';

const NOW = new Date('2026-12-01T12:00:00.000Z');

function settingsWith(overrides: Partial<ResortSettings> = {}): ResortSettings {
  return {
    ...unconfiguredSettings(),
    timeZone: 'America/Cancun',
    airports: [
      { code: 'AAA', name: 'Test Airport A', departureBufferHours: 3, isActive: true },
      { code: 'BBB', name: 'Test Airport B', departureBufferHours: 2.5, isActive: false },
    ],
    transportAlertLeadHours: 12,
    ...overrides,
  };
}

describe('resolveAirport (Settings decide which airports exist)', () => {
  it('test_activeConfiguredAirport_isReturned', () => {
    expect(resolveAirport(settingsWith(), 'AAA')).toMatchObject({ code: 'AAA', departureBufferHours: 3 });
  });

  it('test_unknownAirport_isSettingsRequired', () => {
    const attempt = () => resolveAirport(settingsWith(), 'ZZZ');

    expect(attempt).toThrow(SettingsRequiredError);
    expect(attempt).toThrow('airports.ZZZ');
  });

  it('test_inactiveAirport_isPlainBusinessRule', () => {
    let caught: unknown;
    try {
      resolveAirport(settingsWith(), 'BBB');
    } catch (error) {
      caught = error;
    }

    expect(caught).toBeInstanceOf(BusinessRuleError);
    expect(caught).not.toBeInstanceOf(SettingsRequiredError);
  });

  it('test_airportWithoutBuffer_isSettingsRequired', () => {
    const settings = settingsWith({
      airports: [{ code: 'AAA', name: 'A', isActive: true } as unknown as ResortSettings['airports'][number]],
    });

    expect(() => resolveAirport(settings, 'AAA')).toThrow('airports.AAA.departureBufferHours');
  });
});

describe('suggestedPickupAt', () => {
  const airport = { code: 'AAA', name: 'A', departureBufferHours: 2.5, isActive: true };

  it('test_departure_isFlightTimeMinusAirportBuffer', () => {
    expect(suggestedPickupAt('DEPARTURE', '2026-12-05T18:00:00.000Z', airport)).toBe('2026-12-05T15:30:00.000Z');
  });

  it('test_arrival_isTheLandingTime', () => {
    expect(suggestedPickupAt('ARRIVAL', '2026-12-05T18:00:00.000Z', airport)).toBe('2026-12-05T18:00:00.000Z');
  });
});

describe('requireLeadHours', () => {
  it('test_configured_isReturned', () => {
    expect(requireLeadHours(settingsWith())).toBe(12);
  });

  it('test_missing_isSettingsRequired', () => {
    expect(() => requireLeadHours(settingsWith({ transportAlertLeadHours: null }))).toThrow('transportAlertLeadHours');
  });
});

describe('tripShapeProblems', () => {
  it('test_completeArrival_hasNoProblems', () => {
    expect(tripShapeProblems(tripFixture())).toEqual([]);
  });

  it('test_airportTrip_needsAirportAndFlight_andNoLocalOptions', () => {
    const trip = tripFixture({ type: 'DEPARTURE', airportCode: null, flight: null, roundTrip: true, waitMinutes: 15 });

    expect(tripShapeProblems(trip)).toEqual([
      'airportCode is required for DEPARTURE trips',
      'flight is required for DEPARTURE trips',
      'roundTrip applies to LOCAL trips only',
      'waitMinutes applies to LOCAL trips only',
    ]);
  });

  it('test_localTrip_needsOriginAndDestination_andNoFlight', () => {
    const trip = tripFixture({ type: 'LOCAL', origin: ' ', destination: null });

    expect(tripShapeProblems(trip)).toEqual([
      'origin is required for LOCAL trips',
      'destination is required for LOCAL trips',
      'airportCode applies to airport trips only',
      'flight applies to airport trips only',
    ]);
  });
});

describe('capacityProblems (vehicle item capacity)', () => {
  const snapshot = { vehicleCapacity: { passengers: 4, luggage: 3 } } as TripServiceSnapshot;

  it('test_withinCapacity_isFine', () => {
    expect(capacityProblems(tripFixture({ snapshot, passengers: 4, luggage: 3 }))).toEqual([]);
  });

  it('test_overCapacity_listsBoth', () => {
    expect(capacityProblems(tripFixture({ snapshot, passengers: 5, luggage: 4 }))).toEqual([
      'passengers exceed the vehicle capacity of 4',
      'luggage exceeds the vehicle capacity of 3',
    ]);
  });

  it('test_noVehicleChosen_hasNoCapacityLimit', () => {
    expect(capacityProblems(tripFixture({ snapshot: null, passengers: 40 }))).toEqual([]);
  });
});

describe('assertGuestLeadTime (service minLeadHours)', () => {
  it('test_enoughNotice_passes', () => {
    expect(() => assertGuestLeadTime('2026-12-02T12:00:00.000Z', NOW, 24)).not.toThrow();
  });

  it('test_tooLittleNotice_isRejected', () => {
    expect(() => assertGuestLeadTime('2026-12-02T11:59:00.000Z', NOW, 24)).toThrow('at least 24 hours');
  });

  it('test_pastPickup_isRejectedEvenWithoutLeadTime', () => {
    expect(() => assertGuestLeadTime('2026-12-01T11:00:00.000Z', NOW, null)).toThrow('future');
  });
});

describe('assertServiceServesAirport (service.transport.airportCodes)', () => {
  const transport = { airportCodes: ['AAA'], priceBasis: null, flightDetailsRequired: true };

  it('test_listedAirport_passes', () => {
    expect(() => assertServiceServesAirport(serviceFixture({ transport }), 'AAA')).not.toThrow();
  });

  it('test_unlistedAirport_isRejected', () => {
    expect(() => assertServiceServesAirport(serviceFixture({ transport }), 'CCC')).toThrow(BusinessRuleError);
  });

  it('test_serviceWithoutAirportList_servesAnyConfiguredAirport', () => {
    expect(() => assertServiceServesAirport(serviceFixture({ transport: null }), 'CCC')).not.toThrow();
  });
});

describe('isUnconfirmedDue (computed on read)', () => {
  it('test_unconfirmedWithinLead_isDue', () => {
    expect(isUnconfirmedDue(tripFixture({ pickupAt: '2026-12-01T23:59:00.000Z' }), NOW, 12)).toBe(true);
  });

  it('test_unconfirmedPastPickup_isStillDue', () => {
    expect(isUnconfirmedDue(tripFixture({ status: 'SENT_TO_PROVIDER', pickupAt: '2026-12-01T10:00:00.000Z' }), NOW, 12)).toBe(true);
  });

  it('test_beyondLead_isNotDue', () => {
    expect(isUnconfirmedDue(tripFixture({ pickupAt: '2026-12-02T00:01:00.000Z' }), NOW, 12)).toBe(false);
  });

  it.each(['CONFIRMED', 'EN_ROUTE', 'COMPLETED', 'CANCELLED'] as const)('test_%s_isNeverDue', (status) => {
    expect(isUnconfirmedDue(tripFixture({ status, pickupAt: '2026-12-01T13:00:00.000Z' }), NOW, 12)).toBe(false);
  });

  it('test_leadHoursNotConfigured_isUnknown', () => {
    expect(isUnconfirmedDue(tripFixture(), NOW, null)).toBeNull();
  });
});

describe('flightChanged', () => {
  const flight = { airline: 'Test Air', number: 'TA 100', scheduledAt: '2026-12-01T19:30:00.000Z' };

  it('test_sameFlight_isUnchanged', () => {
    expect(flightChanged(tripFixture({ flight }), tripFixture({ flight: { ...flight } }))).toBe(false);
  });

  it.each([{ number: 'TA 101' }, { scheduledAt: '2026-12-01T20:00:00.000Z' }, { airline: 'Other' }])(
    'test_changed_%j_isDetected',
    (change) => {
      expect(flightChanged(tripFixture({ flight }), tripFixture({ flight: { ...flight, ...change } }))).toBe(true);
    },
  );
});

describe('trip projections', () => {
  const confirmed = tripFixture({
    status: 'CONFIRMED',
    providerId: 'prov-1',
    driver: { name: 'Test Driver', phone: '+52 000' },
    vehicle: { description: 'Van', plate: 'TEST-01' },
    notes: 'internal: VIP, pay provider in cash',
    guestNotes: 'child seat please',
  });

  it('test_guestView_isAllowListWithoutInternalNotesProviderOrHistory', () => {
    const view = toGuestTripView(confirmed) as Record<string, unknown>;

    expect(view).toMatchObject({ id: 'trip-1', status: 'CONFIRMED', guestNotes: 'child seat please' });
    expect(view.driver).toEqual({ name: 'Test Driver', phone: '+52 000' });
    for (const hidden of ['notes', 'providerId', 'statusHistory', 'updatedBy', 'createdByActor', 'stayId']) {
      expect(view).not.toHaveProperty(hidden);
    }
    expect(JSON.stringify(view)).not.toContain('internal: VIP');
  });

  it('test_adminView_addsIdAndUnconfirmedDueFlag', () => {
    const view = toAdminTripView(tripFixture({ pickupAt: '2026-12-01T13:00:00.000Z' }), NOW, 12);

    expect(view).toMatchObject({ id: 'trip-1', tripId: 'trip-1', unconfirmedDue: true, notes: '' });
  });
});
