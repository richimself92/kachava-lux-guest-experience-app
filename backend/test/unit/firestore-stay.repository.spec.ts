import { StayAggregate } from '../../src/domain/models/domain.models';
import { FirestoreStayRepository } from '../../src/infrastructure/repositories/firestore-stay.repository';
import { createSeededStayAggregate } from '../../src/infrastructure/seed/sanctuary-seed.data';
import { FakeFirestore } from '../support/fake-firestore';

const TOKEN_A = '11111111-1111-4111-8111-111111111111';
const TOKEN_B = '22222222-2222-4222-8222-222222222222';

function stayFixture(stayId: string, guestTokenUuid: string): StayAggregate {
  return { ...createSeededStayAggregate(), stayId, guestTokenUuid };
}

describe('FirestoreStayRepository (Firestore as single source of truth)', () => {
  let fake: FakeFirestore;
  let instanceA: FirestoreStayRepository;
  let instanceB: FirestoreStayRepository;

  beforeEach(() => {
    fake = new FakeFirestore();
    instanceA = new FirestoreStayRepository(fake.asFirestore());
    instanceB = new FirestoreStayRepository(fake.asFirestore());
  });

  it('test_firestoreStayRepository_newInstance_doesNotSeedDemoData', async () => {
    expect(await instanceA.listStays()).toEqual([]);
    expect(fake.collections.get('stays')?.size ?? 0).toBe(0);
  });

  it('test_firestoreStayRepository_stayCreatedOnOneInstance_isReadByAnother', async () => {
    await instanceA.createStay(stayFixture('stay_a', TOKEN_A));

    const byToken = await instanceB.findByGuestTokenUuid(TOKEN_A.toUpperCase());
    const byId = await instanceB.findByStayId('stay_a');

    expect(byToken?.stayId).toBe('stay_a');
    expect(byId?.guestTokenUuid).toBe(TOKEN_A);
    expect((await instanceB.listStays()).map((s) => s.stayId)).toEqual(['stay_a']);
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
    await instanceA.listStays();

    await instanceB.updateStayWifi('stay_b', { wifiSsid: 'Fresh_SSID' });
    await instanceA.updateStayStatus('stay_a', 'ACTIVE_STAY');

    expect((await instanceB.findByStayId('stay_b'))?.villaAccess.wifiSsid).toBe('Fresh_SSID');
  });

  it('test_firestoreStayRepository_writeFailure_surfacesAsRejectedPromise', async () => {
    await instanceA.createStay(stayFixture('stay_a', TOKEN_A));
    fake.failWritesWith(new Error('UNAVAILABLE: firestore down'));

    await expect(instanceA.createStay(stayFixture('stay_b', TOKEN_B))).rejects.toThrow(
      'UNAVAILABLE',
    );
    await expect(instanceA.updateStayStatus('stay_a', 'CHECKED_OUT')).rejects.toThrow(
      'UNAVAILABLE',
    );
    fake.failWritesWith(null);
    expect((await instanceB.findByStayId('stay_a'))?.status).toBe('ACTIVE_STAY');
  });

  it('test_firestoreStayRepository_readFailure_surfacesAsErrorNotNull', async () => {
    fake.failReadsWith(new Error('DEADLINE_EXCEEDED'));

    await expect(instanceA.findByGuestTokenUuid(TOKEN_A)).rejects.toThrow('DEADLINE_EXCEEDED');
    await expect(instanceA.listStays()).rejects.toThrow('DEADLINE_EXCEEDED');
  });

  it('test_firestoreStayRepository_mutationOfUnknownStay_rejectsWithNotFound', async () => {
    await expect(instanceA.updateStayStatus('missing', 'ACTIVE_STAY')).rejects.toThrow(
      'Stay with ID missing not found',
    );
  });

  it('test_firestoreStayRepository_resetAllStays_deletesFromStoreForEveryInstance', async () => {
    await instanceA.createStay(stayFixture('stay_a', TOKEN_A));

    await instanceB.resetAllStays();

    expect(await instanceA.listStays()).toEqual([]);
    expect(await instanceA.findByGuestTokenUuid(TOKEN_A)).toBeNull();
  });

  it('test_firestoreStayRepository_crossStayAdminUpdates_persistToStore', async () => {
    const seeded = stayFixture('stay_a', TOKEN_A);
    await instanceA.createStay(seeded);
    const requestId = seeded.conciergeRequests[0].requestId;
    const bookingId = seeded.experienceBookings[0].bookingId;

    await instanceA.updateConciergeRequestAdmin(requestId, { notes: 'Ice ready' });
    await instanceA.appendConciergeMessage('stay_a', requestId, {
      sender: 'GUEST', senderName: 'Guest', text: 'Thanks', sentAt: '2026-11-13T10:00:00.000Z',
    });
    await instanceA.updateBookingAssignment(bookingId, {
      status: 'CONFIRMED', cancellationReason: undefined,
    });
    await instanceA.updateLarderOrderStatus('stay_a', { provisioningStatus: 'Stocked in Villa' });

    const reread = await instanceB.findConciergeRequestById(requestId);
    expect(reread?.notes).toBe('Ice ready');
    expect(reread?.messages.at(-1)?.text).toBe('Thanks');
    expect((await instanceB.listBookingsForStay('stay_a'))[0].status).toBe('CONFIRMED');
    const larder = await instanceB.listLarderOrdersAcrossStays();
    expect(larder.every((o) => o.provisioningStatus === 'Stocked in Villa')).toBe(true);
  });

  it('test_firestoreStayRepository_crossStayUpdateOfUnknownItem_returnsNull', async () => {
    await instanceA.createStay(stayFixture('stay_a', TOKEN_A));

    expect(await instanceA.updateBookingAssignment('nope', { status: 'CONFIRMED' })).toBeNull();
    expect(await instanceA.updateConciergeRequestAdmin('nope', { notes: 'x' })).toBeNull();
    expect(await instanceA.updateLarderOrderStatus('nope', { provisioningStatus: 'x' })).toBeNull();
  });

  it('test_firestoreStayRepository_legacyDocumentWithoutEmbeddedLists_isNormalizedToEmptyLists', async () => {
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
