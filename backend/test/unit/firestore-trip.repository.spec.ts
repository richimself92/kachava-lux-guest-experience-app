import { EntityConflictError, EntityNotFoundError, ListScanLimitError } from '../../src/domain/domain-errors';
import { OperationalAlert } from '../../src/domain/models/domain.models';
import { Trip } from '../../src/domain/trips/trip.models';
import { ALERTS_COLLECTION } from '../../src/infrastructure/repositories/firestore-alert.repository';
import { FirestoreTripRepository, TRIPS_COLLECTION } from '../../src/infrastructure/repositories/firestore-trip.repository';
import { FakeFirestore } from '../support/fake-firestore';
import { tripFixture } from '../support/trip-fixtures';

function alertFixture(id: string): OperationalAlert {
  return {
    alertId: id, stayId: 'stay-test-1', villaId: 'villa-a', villaName: 'Test Villa', guestNames: 'Test Guest',
    category: 'TRANSFER', severity: 'HIGH', title: 't', summary: 's', sourceDocumentPath: 'trips/trip-1',
    assignedDepartment: 'TRANSPORT', isAcknowledged: false, acknowledgedByStaffId: null, acknowledgedAt: null,
    createdAt: '2026-11-20T10:00:00.000Z', targetRef: { type: 'TRIP', id: 'trip-1' },
  };
}

function at(tripId: string, pickupAt: string, overrides: Partial<Trip> = {}): Trip {
  return tripFixture({
    tripId, pickupAt, flight: { airline: 'A', number: tripId, scheduledAt: pickupAt }, ...overrides,
  });
}

describe('FirestoreTripRepository', () => {
  let fake: FakeFirestore;
  let repo: FirestoreTripRepository;

  beforeEach(() => {
    fake = new FakeFirestore();
    repo = new FirestoreTripRepository(fake.asFirestore());
  });

  it('test_create_thenFindById_roundTrips', async () => {
    await repo.create(tripFixture());

    expect(await repo.findById('trip-1')).toEqual(tripFixture());
    expect(await repo.findById('nope')).toBeNull();
  });

  it('test_create_withAlert_commitsBothDocuments', async () => {
    await repo.create(tripFixture(), alertFixture('alt-1'));

    expect(fake.store(TRIPS_COLLECTION).has('trip-1')).toBe(true);
    expect(fake.store(ALERTS_COLLECTION).get('alt-1')).toMatchObject({ targetRef: { type: 'TRIP', id: 'trip-1' } });
  });

  it('test_create_alertWriteFails_persistsNeither', async () => {
    fake.failWritesWith(new Error('alerts down'), ALERTS_COLLECTION);

    await expect(repo.create(tripFixture(), alertFixture('alt-1'))).rejects.toThrow('alerts down');

    expect(fake.store(TRIPS_COLLECTION).size).toBe(0);
  });

  it('test_create_existingId_isConflict', async () => {
    await repo.create(tripFixture());

    await expect(repo.create(tripFixture())).rejects.toBeInstanceOf(EntityConflictError);
  });

  it('test_update_appliesMutation_andAlertSeesPreviousAndNext', async () => {
    await repo.create(tripFixture());
    const alertOf = jest.fn((next: Trip, previous: Trip) => (next.notes !== previous.notes ? alertFixture('alt-2') : null));

    const updated = await repo.update('trip-1', (current) => ({ ...current, notes: 'changed' }), alertOf);

    expect(updated.notes).toBe('changed');
    expect((await repo.findById('trip-1'))?.notes).toBe('changed');
    expect(fake.store(ALERTS_COLLECTION).has('alt-2')).toBe(true);
  });

  it('test_update_missingTrip_isNotFound', async () => {
    await expect(repo.update('nope', (t) => t)).rejects.toBeInstanceOf(EntityNotFoundError);
  });

  it('test_listInWindow_byPickup_isHalfOpenAndOrdered', async () => {
    await repo.create(at('t3', '2026-12-03T05:00:00.000Z'));
    await repo.create(at('t1', '2026-12-01T05:00:00.000Z'));
    await repo.create(at('t2', '2026-12-02T23:00:00.000Z'));

    const trips = await repo.listInWindow({
      field: 'pickupAt', fromIso: '2026-12-01T05:00:00.000Z', toIsoExclusive: '2026-12-03T05:00:00.000Z',
    });

    expect(trips.map((t) => t.tripId)).toEqual(['t1', 't2']);
  });

  it('test_listInWindow_byFlightTime_skipsTripsWithoutFlight', async () => {
    await repo.create(at('flight', '2026-12-02T10:00:00.000Z'));
    await repo.create(at('local', '2026-12-02T10:00:00.000Z', { type: 'LOCAL', flight: null, airportCode: null }));

    const trips = await repo.listInWindow({ field: 'flight.scheduledAt', fromIso: '2026-12-02T00:00:00.000Z' });

    expect(trips.map((t) => t.tripId)).toEqual(['flight']);
  });

  it('test_listInWindow_withoutWindow_returnsAll', async () => {
    await repo.create(at('a', '2026-12-02T10:00:00.000Z'));
    await repo.create(at('b', '2025-01-02T10:00:00.000Z'));

    expect((await repo.listInWindow({ field: 'pickupAt' })).length).toBe(2);
  });

  it('test_listInWindow_beyondScanLimit_isRejected', async () => {
    const bounded = new FirestoreTripRepository(fake.asFirestore(), 2);
    for (const id of ['a', 'b', 'c']) await bounded.create(at(id, '2026-12-02T10:00:00.000Z'));

    await expect(bounded.listInWindow({ field: 'pickupAt' })).rejects.toBeInstanceOf(ListScanLimitError);
  });

  it('test_listForStay_returnsOnlyThatStay', async () => {
    await repo.create(at('mine', '2026-12-02T10:00:00.000Z'));
    await repo.create(at('other', '2026-12-02T10:00:00.000Z', { stayId: 'stay-2' }));

    expect((await repo.listForStay('stay-test-1')).map((t) => t.tripId)).toEqual(['mine']);
  });

  it('test_listUnconfirmedUntil_onlyOpenUnconfirmedUpToCutoff', async () => {
    await repo.create(at('due-late', '2026-12-01T20:00:00.000Z', { status: 'SENT_TO_PROVIDER', providerId: 'p' }));
    await repo.create(at('due-early', '2026-12-01T08:00:00.000Z'));
    await repo.create(at('confirmed', '2026-12-01T09:00:00.000Z', { status: 'CONFIRMED' }));
    await repo.create(at('later', '2026-12-05T09:00:00.000Z'));

    const trips = await repo.listUnconfirmedUntil('2026-12-02T00:00:00.000Z');

    expect(trips.map((t) => t.tripId)).toEqual(['due-early', 'due-late']);
  });
});
