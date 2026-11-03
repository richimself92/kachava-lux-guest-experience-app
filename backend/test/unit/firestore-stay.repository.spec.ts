import { StayAggregate } from '../../src/domain/models/domain.models';
import { StayPageQuery } from '../../src/domain/ports/repository.ports';
import {
  FirestoreStayRepository,
  guestSearchKeywords,
} from '../../src/infrastructure/repositories/firestore-stay.repository';
import { FakeFirestore } from '../support/fake-firestore';
import { populatedStayFixture } from '../support/stay-fixtures';

const TOKEN_A = '11111111-1111-4111-8111-111111111111';
const TOKEN_B = '22222222-2222-4222-8222-222222222222';

function stayFixture(stayId: string, guestTokenUuid: string, overrides: Partial<StayAggregate> = {}): StayAggregate {
  return { ...populatedStayFixture(), stayId, guestTokenUuid, ...overrides };
}

const PAGE: StayPageQuery = { page: 1, pageSize: 25, direction: 'asc' };

describe('FirestoreStayRepository (Firestore as single source of truth)', () => {
  let fake: FakeFirestore;
  let instanceA: FirestoreStayRepository;
  let instanceB: FirestoreStayRepository;

  beforeEach(() => {
    fake = new FakeFirestore();
    instanceA = new FirestoreStayRepository(fake.asFirestore());
    instanceB = new FirestoreStayRepository(fake.asFirestore());
  });

  it('test_firestoreStayRepository_newInstance_doesNotSeedData', async () => {
    expect((await instanceA.pageStays(PAGE)).meta.total).toBe(0);
    expect(fake.collections.get('stays')?.size ?? 0).toBe(0);
  });

  it('test_firestoreStayRepository_stayCreatedOnOneInstance_isReadByAnother', async () => {
    await instanceA.createStay(stayFixture('stay_a', TOKEN_A));

    const byToken = await instanceB.findByGuestTokenUuid(TOKEN_A.toUpperCase());
    const byId = await instanceB.findByStayId('stay_a');

    expect(byToken?.stayId).toBe('stay_a');
    expect(byId?.guestTokenUuid).toBe(TOKEN_A);
    expect((await instanceB.pageStays(PAGE)).data.map((s) => s.stayId)).toEqual(['stay_a']);
  });

  it('test_firestoreStayRepository_updateOnOneInstance_isVisibleOnAnotherWithoutRestart', async () => {
    await instanceA.createStay(stayFixture('stay_a', TOKEN_A));
    await instanceB.findByGuestTokenUuid(TOKEN_A);

    await instanceA.updateStayStatus('stay_a', 'CHECKED_OUT');
    const rotated = await instanceA.updateStayToken('stay_a', TOKEN_B);

    expect(rotated.guestTokenUuid).toBe(TOKEN_B);
    expect((await instanceB.findByGuestTokenUuid(TOKEN_B))?.status).toBe('CHECKED_OUT');
    expect(await instanceB.findByGuestTokenUuid(TOKEN_A)).toBeNull();
  });

  it('test_firestoreStayRepository_writeOnOneStay_doesNotOverwriteConcurrentChangesToOtherStays', async () => {
    await instanceA.createStay(stayFixture('stay_a', TOKEN_A));
    await instanceA.createStay(stayFixture('stay_b', TOKEN_B));

    await instanceB.updateStayWifi('stay_b', { wifiSsid: 'Fresh_SSID' });
    await instanceA.updateStayStatus('stay_a', 'ACTIVE_STAY');

    expect((await instanceB.findByStayId('stay_b'))?.villaAccess.wifiSsid).toBe('Fresh_SSID');
  });

  it('test_firestoreStayRepository_writeFailure_surfacesAsRejectedPromise', async () => {
    await instanceA.createStay(stayFixture('stay_a', TOKEN_A));
    fake.failWritesWith(new Error('UNAVAILABLE: firestore down'));

    await expect(instanceA.createStay(stayFixture('stay_b', TOKEN_B))).rejects.toThrow('UNAVAILABLE');
    await expect(instanceA.updateStayStatus('stay_a', 'CHECKED_OUT')).rejects.toThrow('UNAVAILABLE');
    fake.failWritesWith(null);
    expect((await instanceB.findByStayId('stay_a'))?.status).toBe('ACTIVE_STAY');
  });

  it('test_firestoreStayRepository_readFailure_surfacesAsErrorNotNull', async () => {
    fake.failReadsWith(new Error('DEADLINE_EXCEEDED'));

    await expect(instanceA.findByGuestTokenUuid(TOKEN_A)).rejects.toThrow('DEADLINE_EXCEEDED');
    await expect(instanceA.pageStays(PAGE)).rejects.toThrow('DEADLINE_EXCEEDED');
  });

  it('test_firestoreStayRepository_mutationOfUnknownStay_rejectsWithNotFound', async () => {
    await expect(instanceA.updateStayStatus('missing', 'ACTIVE_STAY')).rejects.toThrow(
      'Stay with ID missing not found',
    );
  });

  it('test_firestoreStayRepository_crossStayAdminUpdates_persistToStore', async () => {
    const stay = stayFixture('stay_a', TOKEN_A);
    await instanceA.createStay(stay);
    const requestId = stay.conciergeRequests[0].requestId;
    const bookingId = stay.experienceBookings[0].bookingId;

    await instanceA.updateConciergeRequestAdmin(requestId, { notes: 'Ice ready' });
    await instanceA.appendConciergeMessage('stay_a', requestId, {
      sender: 'GUEST', senderName: 'Guest', text: 'Thanks', sentAt: '2026-11-13T10:00:00.000Z',
    });
    await instanceA.updateBookingAssignment(bookingId, { status: 'CONFIRMED', cancellationReason: undefined });
    await instanceA.updateLarderOrderStatus('stay_a', { provisioningStatus: 'Stocked' });

    const reread = await instanceB.findConciergeRequestById(requestId);
    expect(reread?.notes).toBe('Ice ready');
    expect(reread?.messages.at(-1)?.text).toBe('Thanks');
    expect((await instanceB.listBookingsForStay('stay_a'))[0].status).toBe('CONFIRMED');
    const larder = await instanceB.listLarderOrdersAcrossStays();
    expect(larder.every((o) => o.provisioningStatus === 'Stocked')).toBe(true);
  });

  it('test_firestoreStayRepository_crossStayUpdateOfUnknownItem_returnsNull', async () => {
    await instanceA.createStay(stayFixture('stay_a', TOKEN_A));

    expect(await instanceA.updateBookingAssignment('nope', { status: 'CONFIRMED' })).toBeNull();
    expect(await instanceA.updateConciergeRequestAdmin('nope', { notes: 'x' })).toBeNull();
    expect(await instanceA.updateLarderOrderStatus('nope', { provisioningStatus: 'x' })).toBeNull();
  });

  it('test_firestoreStayRepository_documentWithoutEmbeddedLists_isNormalizedToEmptyLists', async () => {
    const { larderOrders, experienceBookings, conciergeRequests, midstayFeedback, folioItems, ...root } =
      stayFixture('stay_legacy', TOKEN_A);
    fake.store('stays').set('stay_legacy', JSON.parse(JSON.stringify(root)));

    const stay = await instanceA.findByGuestTokenUuid(TOKEN_A);

    expect(stay?.larderOrders).toEqual([]);
    expect(stay?.folioItems).toEqual([]);
    expect(await instanceA.listBookingsAcrossStays()).toEqual([]);
    expect([larderOrders, experienceBookings, conciergeRequests, midstayFeedback, folioItems]).toHaveLength(5);
  });
});

describe('FirestoreStayRepository paging (filters, arrival range, guest search)', () => {
  let fake: FakeFirestore;
  let repo: FirestoreStayRepository;

  beforeEach(async () => {
    fake = new FakeFirestore();
    repo = new FirestoreStayRepository(fake.asFirestore());
    const guest = (name: string) => ({ ...populatedStayFixture().guestProfile, name });
    await repo.createStay(stayFixture('s1', TOKEN_A, { checkInDate: '2026-12-10', status: 'PRE_ARRIVAL', villaId: 'v1', guestProfile: guest('Ana Peña') }));
    await repo.createStay(stayFixture('s2', TOKEN_B, { checkInDate: '2026-12-01', status: 'ACTIVE_STAY', villaId: 'v2', guestProfile: guest('Bruno Díaz') }));
    await repo.createStay(stayFixture('s3', '33333333-3333-4333-8333-333333333333', { checkInDate: '2026-11-20', status: 'CHECKED_OUT', villaId: 'v1', guestProfile: guest('Carla Peña') }));
  });

  const ids = (page: { data: StayAggregate[] }) => page.data.map((s) => s.stayId);

  it('test_pageStays_ordersByArrivalAndCountsTotal', async () => {
    const asc = await repo.pageStays(PAGE);
    const desc = await repo.pageStays({ ...PAGE, direction: 'desc', pageSize: 2 });

    expect(ids(asc)).toEqual(['s3', 's2', 's1']);
    expect(ids(desc)).toEqual(['s1', 's2']);
    expect(desc.meta).toEqual({ page: 1, pageSize: 2, total: 3 });
  });

  it('test_pageStays_secondPage_usesOffset', async () => {
    expect(ids(await repo.pageStays({ ...PAGE, pageSize: 2, page: 2 }))).toEqual(['s1']);
  });

  it('test_pageStays_filtersByStatusVillaAndArrivalRange', async () => {
    expect(ids(await repo.pageStays({ ...PAGE, status: 'ACTIVE_STAY' }))).toEqual(['s2']);
    expect(ids(await repo.pageStays({ ...PAGE, villaId: 'v1' }))).toEqual(['s3', 's1']);
    expect(ids(await repo.pageStays({ ...PAGE, from: '2026-11-25', to: '2026-12-05' }))).toEqual(['s2']);
  });

  it('test_pageStays_searchesGuestNamePrefixesIgnoringCaseAndAccents', async () => {
    expect(ids(await repo.pageStays({ ...PAGE, q: 'PENA' }))).toEqual(['s3', 's1']);
    expect(ids(await repo.pageStays({ ...PAGE, q: 'bruno d' }))).toEqual(['s2']);
    expect((await repo.pageStays({ ...PAGE, q: 'zzz' })).meta.total).toBe(0);
  });

  it('test_pageStays_neverReturnsTheDerivedSearchField', async () => {
    const [stay] = (await repo.pageStays(PAGE)).data;

    expect(stay).not.toHaveProperty('guestSearchKeywords');
    expect(fake.store('stays').get('s1')).toHaveProperty('guestSearchKeywords');
  });

  it('test_listOpenStays_onlyPreArrivalAndInHouse_bounded', async () => {
    expect((await repo.listOpenStays(10)).map((s) => s.stayId)).toEqual(['s2', 's1']);
    expect(await repo.listOpenStays(1)).toHaveLength(1);
  });

  it('test_hasStaysForVilla', async () => {
    expect(await repo.hasStaysForVilla('v1')).toBe(true);
    expect(await repo.hasStaysForVilla('v9')).toBe(false);
  });

  it('test_guestSearchKeywords_prefixesOfNameAndWords', () => {
    expect(guestSearchKeywords('Ana Peña')).toEqual(
      expect.arrayContaining(['a', 'an', 'ana', 'ana p', 'ana pena', 'p', 'pe', 'pena']),
    );
  });
});
