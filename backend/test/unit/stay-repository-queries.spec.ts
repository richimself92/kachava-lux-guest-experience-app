import { ListScanLimitError } from '../../src/domain/domain-errors';
import { OperationalAlert, StayAggregate } from '../../src/domain/models/domain.models';
import { ALERTS_COLLECTION } from '../../src/infrastructure/repositories/firestore-alert.repository';
import { FirestoreStayRepository } from '../../src/infrastructure/repositories/firestore-stay.repository';
import { FirestoreTripRepository } from '../../src/infrastructure/repositories/firestore-trip.repository';
import { FakeFirestore } from '../support/fake-firestore';
import { populatedStayFixture } from '../support/stay-fixtures';
import { tripFixture } from '../support/trip-fixtures';

let tokenSeq = 0;
function stay(stayId: string, overrides: Partial<StayAggregate> = {}): StayAggregate {
  tokenSeq += 1;
  const token = `00000000-0000-4000-8000-${String(tokenSeq).padStart(12, '0')}`;
  const base = populatedStayFixture();
  return {
    ...base,
    stayId,
    guestTokenUuid: token,
    experienceBookings: base.experienceBookings.map((b) => ({ ...b, bookingId: `bk-${stayId}`, stayId })),
    conciergeRequests: base.conciergeRequests.map((r) => ({ ...r, requestId: `req-${stayId}`, stayId })),
    larderOrders: base.larderOrders.map((o) => ({ ...o, orderItemId: `larder-${stayId}`, stayId })),
    ...overrides,
  };
}

describe('FirestoreStayRepository bounded queries', () => {
  let fake: FakeFirestore;
  let repo: FirestoreStayRepository;

  beforeEach(async () => {
    fake = new FakeFirestore();
    repo = new FirestoreStayRepository(fake.asFirestore(), 2);
    await repo.createStay(stay('s1', { status: 'PRE_ARRIVAL', checkInDate: '2026-12-10', checkOutDate: '2026-12-14' }));
    await repo.createStay(stay('s2', { status: 'ACTIVE_STAY', checkInDate: '2026-12-01', checkOutDate: '2026-12-20' }));
    await repo.createStay(stay('s3', { status: 'CHECKED_OUT', checkInDate: '2026-11-01', checkOutDate: '2026-11-03' }));
  });

  it('test_listStaysByStatuses_queriesByStatus', async () => {
    const open = await repo.listStaysByStatuses(['PRE_ARRIVAL', 'ACTIVE_STAY']);

    expect(open.map((s) => s.stayId).sort()).toEqual(['s1', 's2']);
  });

  it('test_listStaysByStatuses_beyondTheScanLimit_failsLoudly', async () => {
    await expect(repo.listStaysByStatuses(['PRE_ARRIVAL', 'ACTIVE_STAY', 'CHECKED_OUT'])).rejects.toThrow(ListScanLimitError);
  });

  it('test_listStaysCheckingInOn_matchesTheArrivalDate', async () => {
    expect((await repo.listStaysCheckingInOn('2026-12-10')).map((s) => s.stayId)).toEqual(['s1']);
  });

  it('test_pageStays_byCheckOutDate_ordersAndRangesThatField', async () => {
    const page = await repo.pageStays({ page: 1, pageSize: 10, direction: 'desc', dateField: 'checkOutDate', from: '2026-12-01' });

    expect(page.data.map((s) => s.stayId)).toEqual(['s2', 's1']);
    expect(page.meta.total).toBe(2);
  });

  it('test_crossStayLookups_useTheChildIndex_evenForClosedStays', async () => {
    const queriesBefore = fake.queryCount;

    const request = await repo.findConciergeRequestById('req-s3');
    const updated = await repo.updateBookingAssignment('bk-s3', { status: 'CONFIRMED' });

    expect(request?.stayId).toBe('s3');
    expect(updated?.status).toBe('CONFIRMED');
    expect(fake.queryCount - queriesBefore).toBe(2);
    expect(fake.store('stays').get('s3')?.childRefIds).toEqual(['bk-s3', 'larder-s3', 'req-s3']);
  });

  it('test_crossStayLists_coverOpenStaysOnly', async () => {
    const bookings = await repo.listBookingsAcrossStays();

    expect(bookings.map((b) => b.stayId).sort()).toEqual(['s1', 's2']);
  });

  it('test_createStay_withAlert_commitsBoth_andDuplicateIdConflicts', async () => {
    const alert = { alertId: 'alt-new', stayId: 's4' } as OperationalAlert;

    await repo.createStay(stay('s4'), alert);

    expect(fake.store(ALERTS_COLLECTION).has('alt-new')).toBe(true);
    await expect(repo.createStay(stay('s4'))).rejects.toThrow(/already exists/);
  });

  it('test_updateStay_readsModifiesAndWritesOneStay', async () => {
    const next = await repo.updateStay('s1', (current) => ({ ...current, internalNotes: 'VIP' }));

    expect(next.internalNotes).toBe('VIP');
    expect((await repo.findByStayId('s1'))?.internalNotes).toBe('VIP');
    await expect(repo.updateStay('missing', (c) => c)).rejects.toThrow(/not found/);
  });
});

describe('FirestoreTripRepository stay and status queries', () => {
  it('test_listForStays_readsInChunks_andCountByStatuses_aggregates', async () => {
    const fake = new FakeFirestore();
    const trips = new FirestoreTripRepository(fake.asFirestore());
    const stayIds = Array.from({ length: 35 }, (_, i) => `s${i}`);
    await trips.create(tripFixture({ tripId: 't1', stayId: 's0' }));
    await trips.create(tripFixture({ tripId: 't2', stayId: 's34', status: 'COMPLETED' }));
    await trips.create(tripFixture({ tripId: 't3', stayId: 'other', status: 'CONFIRMED' }));

    const found = await trips.listForStays(stayIds);

    expect(found.map((t) => t.tripId).sort()).toEqual(['t1', 't2']);
    expect(await trips.countByStatuses(['REQUESTED', 'CONFIRMED'])).toBe(2);
    expect(await trips.listForStays([])).toEqual([]);
  });
});
