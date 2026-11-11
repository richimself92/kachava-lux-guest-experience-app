import { SettingsRequiredError } from '../../src/domain/domain-errors';
import { FlightTransfer, StayAggregate } from '../../src/domain/models/domain.models';
import { ResortSettings, unconfiguredSettings } from '../../src/domain/models/resort-config.models';
import { legacyArrivalTripId, planLegacyArrival } from '../../src/domain/trips/legacy-transfer-migration';
import { SETTINGS_COLLECTION, SETTINGS_DOCUMENT_ID } from '../../src/infrastructure/repositories/firestore-settings.repository';
import { STAYS_COLLECTION } from '../../src/infrastructure/repositories/firestore-stay.repository';
import { TRIPS_COLLECTION } from '../../src/infrastructure/repositories/firestore-trip.repository';
import {
  assertMigrationTarget,
  migrateFlightTransfers,
  parseMigrationArgs,
} from '../../src/scripts/migrate-flight-transfers';
import { FakeFirestore } from '../support/fake-firestore';
import { stayFixture } from '../support/stay-fixtures';

const AT = '2026-11-02T12:00:00.000Z';
const settings: ResortSettings = {
  ...unconfiguredSettings(),
  timeZone: 'America/Cancun',
  airports: [{ code: 'AAA', name: 'Test Airport', departureBufferHours: 3, isActive: true }],
};

function legacyStay(transfer: Partial<FlightTransfer>, overrides: Partial<StayAggregate> = {}): StayAggregate {
  const stay = stayFixture(overrides);
  return {
    ...stay,
    flightTransfer: {
      ...stay.flightTransfer,
      arrivalDate: '2026-11-12', arrivalAirport: 'Test International (AAA)', airline: 'Test Air', flightNumber: 'TA 172',
      estimatedLanding: '11:35 AM', partySize: 2, luggageChecked: 3, luggageCarryOn: 2, status: 'Pending',
      ...transfer,
    },
  };
}

describe('planLegacyArrival (pure)', () => {
  it('test_pendingTransfer_becomesRequestedArrivalTrip', () => {
    const plan = planLegacyArrival(legacyStay({ notes: 'two kids', adminDispatchNotes: 'VIP', meetingPoint: 'Gate 4' }), settings, AT);

    expect(plan).toEqual({
      trip: expect.objectContaining({
        tripId: legacyArrivalTripId('stay-test-1'), stayId: 'stay-test-1', type: 'ARRIVAL', status: 'REQUESTED',
        airportCode: 'AAA', flight: { airline: 'Test Air', number: 'TA 172', scheduledAt: '2026-11-12T16:35:00.000Z' },
        pickupAt: '2026-11-12T16:35:00.000Z', passengers: 2, luggage: 5, guestNotes: 'two kids', notes: 'VIP',
        origin: 'Gate 4', serviceId: null, snapshot: null, createdBy: 'GUEST', createdByActor: 'migration:flightTransfer',
      }),
    });
  });

  it('test_confirmedTransfer_keepsDriverVehicleAndStatus', () => {
    const plan = planLegacyArrival(
      legacyStay({ status: 'Confirmed', assignedDriver: 'Test Driver', driverPhone: '+52 1', vehicleModel: 'Van', fleetNumber: 'F-1', arrivalTime: '14:05' }),
      settings, AT,
    );

    expect(plan).toEqual({
      trip: expect.objectContaining({
        status: 'CONFIRMED', driver: { name: 'Test Driver', phone: '+52 1' }, vehicle: { description: 'Van', plate: 'F-1' },
        pickupAt: '2026-11-12T19:05:00.000Z',
      }),
    });
  });

  it('test_missingDate_fallsBackToStayCheckIn', () => {
    const plan = planLegacyArrival(legacyStay({ arrivalDate: '' }), settings, AT);

    expect('trip' in plan && plan.trip.pickupAt).toBe('2026-12-01T16:35:00.000Z');
  });

  it.each([
    [{ status: 'Not Requested' }, 'not requested'],
    [{ flightNumber: '  ' }, 'no flight number'],
    [{ arrivalAirport: 'Somewhere (ZZZ)' }, 'airport'],
    [{ estimatedLanding: 'soon', arrivalTime: '' }, 'landing time'],
    [{ partySize: 0 }, 'party size'],
  ])('test_unusableTransfer_%j_isSkippedWithReason', (transfer, reason) => {
    const plan = planLegacyArrival(legacyStay(transfer, { guestsCount: 0 }), settings, AT);

    expect('skip' in plan && plan.skip).toContain(reason);
  });

  it('test_settingsWithoutTimeZoneOrAirports_isSettingsRequired', () => {
    expect(() => planLegacyArrival(legacyStay({}), { ...settings, timeZone: null }, AT)).toThrow(SettingsRequiredError);
    expect(() => planLegacyArrival(legacyStay({}), { ...settings, airports: [] }, AT)).toThrow(SettingsRequiredError);
  });
});

describe('migrateFlightTransfers (idempotent runner over Firestore)', () => {
  let fake: FakeFirestore;

  beforeEach(() => {
    fake = new FakeFirestore();
    fake.store(SETTINGS_COLLECTION).set(SETTINGS_DOCUMENT_ID, JSON.parse(JSON.stringify(settings)));
    const stays = [
      legacyStay({}),
      legacyStay({ status: 'Not Requested' }, { stayId: 'stay-empty' }),
    ];
    for (const stay of stays) fake.store(STAYS_COLLECTION).set(stay.stayId, JSON.parse(JSON.stringify(stay)));
  });

  it('test_dryRun_reportsButWritesNothing', async () => {
    const report = await migrateFlightTransfers(fake.asFirestore(), { dryRun: true, at: AT });

    expect(report).toMatchObject({ dryRun: true, scanned: 2, created: [legacyArrivalTripId('stay-test-1')], alreadyMigrated: [] });
    expect(report.skipped).toEqual([{ stayId: 'stay-empty', reason: expect.stringContaining('not requested') }]);
    expect(fake.store(TRIPS_COLLECTION).size).toBe(0);
  });

  it('test_secondRun_createsNothingNew', async () => {
    const first = await migrateFlightTransfers(fake.asFirestore(), { dryRun: false, at: AT });
    const second = await migrateFlightTransfers(fake.asFirestore(), { dryRun: false, at: AT });

    expect(first.created).toEqual([legacyArrivalTripId('stay-test-1')]);
    expect(second).toMatchObject({ created: [], alreadyMigrated: [legacyArrivalTripId('stay-test-1')] });
    expect(fake.store(TRIPS_COLLECTION).size).toBe(1);
    expect(fake.store(STAYS_COLLECTION).get('stay-test-1')).toHaveProperty('flightTransfer.flightNumber', 'TA 172');
  });
});

describe('migration CLI guard', () => {
  const EMULATORS = { USE_FIRESTORE: 'true', FIRESTORE_EMULATOR_HOST: '127.0.0.1:8085', FIREBASE_STORAGE_EMULATOR_HOST: '127.0.0.1:9199' };

  it('test_parseArgs_knownFlags', () => {
    expect(parseMigrationArgs(['--dry-run'])).toEqual({ dryRun: true, allowProduction: false });
    expect(parseMigrationArgs([])).toEqual({ dryRun: false, allowProduction: false });
  });

  it('test_parseArgs_unknownFlag_isRejected_soATypoNeverWritesForReal', () => {
    expect(() => parseMigrationArgs(['--dryrun'])).toThrow(/Unknown argument/);
  });

  it('test_emulatorTarget_isAllowed', () => {
    expect(() => assertMigrationTarget(EMULATORS, { dryRun: false, allowProduction: false })).not.toThrow();
  });

  it('test_localWithoutEmulator_isRefused', () => {
    expect(() => assertMigrationTarget({ USE_FIRESTORE: 'true' }, { dryRun: true, allowProduction: false })).toThrow(/EMULATOR/);
  });

  it('test_production_needsExplicitOwnerApprovedFlag', () => {
    const production = { USE_FIRESTORE: 'true', NODE_ENV: 'production' };

    expect(() => assertMigrationTarget(production, { dryRun: true, allowProduction: false })).toThrow(/--allow-production/);
    expect(() => assertMigrationTarget(production, { dryRun: true, allowProduction: true })).not.toThrow();
  });
});
