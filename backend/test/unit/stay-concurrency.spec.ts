import { CreateBookingDto } from '../../src/modules/guest/dto/guest.dto';
import { FirestoreStayRepository } from '../../src/infrastructure/repositories/firestore-stay.repository';
import { InMemorySeededCatalogRepository } from '../../src/infrastructure/repositories/in-memory-catalog.repository';
import { createSeededStayAggregate } from '../../src/infrastructure/seed/sanctuary-seed.data';
import { AdminFulfillmentService } from '../../src/modules/admin/admin-fulfillment.service';
import { GuestAlertFolioHelper } from '../../src/modules/guest/guest-alert-folio.helper';
import { GuestBookingService } from '../../src/modules/guest/guest-booking.service';
import { StaffMember, StayAggregate } from '../../src/domain/models/domain.models';
import { FakeFirestore } from '../support/fake-firestore';

const PARALLEL = 20;
const STAFF = { staffId: 'staff_eduardo', fullName: 'HOST ADMIN' } as StaffMember;

function paidBooking(index: number): CreateBookingDto {
  return {
    category: 'explore',
    catalogRefId: `unknown_${index}`,
    scheduledDate: '2026-11-10',
    scheduledTimeSlot: '10:00',
    partySize: 1,
  };
}

async function seedStay(fake: FakeFirestore) {
  const repo = new FirestoreStayRepository(fake.asFirestore());
  const stay = createSeededStayAggregate();
  await repo.createStay(stay);
  const catalog = new InMemorySeededCatalogRepository();
  const helper = new GuestAlertFolioHelper();
  return {
    repo,
    stay,
    booking: new GuestBookingService(repo, catalog, helper),
    admin: new AdminFulfillmentService(repo, catalog, {} as never),
  };
}

function bookingFolioLines(stay: StayAggregate): number {
  return stay.folioItems.filter((f) => f.folioItemId.startsWith('folio_bk_')).length;
}

describe('Stay mutations under concurrency (fake Firestore with transaction conflicts)', () => {
  it('test_repository_20ParallelConciergeAppends_keepsEveryRequest', async () => {
    const fake = new FakeFirestore();
    const { repo, stay } = await seedStay(fake);
    const template = stay.conciergeRequests[0];

    await Promise.all(
      Array.from({ length: PARALLEL }, (_, i) =>
        repo.createConciergeRequest(stay.stayId, { ...template, requestId: `req_par_${i}` }),
      ),
    );

    const stored = await repo.findByStayId(stay.stayId);
    expect(stored?.conciergeRequests).toHaveLength(stay.conciergeRequests.length + PARALLEL);
  });

  it('test_guestBooking_20ParallelPaidBookingsFromOneSnapshot_produce20FolioLines', async () => {
    const fake = new FakeFirestore();
    const { repo, stay, booking } = await seedStay(fake);
    const guardSnapshot = (await repo.findByStayId(stay.stayId)) as StayAggregate;

    await Promise.all(
      Array.from({ length: PARALLEL }, (_, i) => booking.createBooking(guardSnapshot, paidBooking(i))),
    );

    const stored = (await repo.findByStayId(stay.stayId)) as StayAggregate;
    const charged = stored.folioItems
      .filter((f) => !f.isComplimentary && f.category !== 'ECOLOGICAL_LEVY')
      .reduce((sum, f) => sum + f.chargedAmountUSD, 0);
    expect(bookingFolioLines(stored)).toBe(PARALLEL);
    expect(stored.folioSummary.incidentalsSubtotalUSD).toBe(charged);
  });

  it('test_guestLarder_afterBookingFromStaleSnapshot_keepsBookingFolioLine', async () => {
    const fake = new FakeFirestore();
    const { repo, stay, booking } = await seedStay(fake);
    const staleSnapshot = (await repo.findByStayId(stay.stayId)) as StayAggregate;
    const larderItemId = (await new InMemorySeededCatalogRepository().getLarderCatalog())[0].id;

    await booking.createBooking(staleSnapshot, paidBooking(1));
    await booking.updateLarderOrder(staleSnapshot, { items: [{ itemId: larderItemId, quantity: 3 }] });

    const stored = (await repo.findByStayId(stay.stayId)) as StayAggregate;
    expect(bookingFolioLines(stored)).toBe(1);
  });

  it('test_adminApproveCheckout_afterGuestBooking_settlesTheNewCharge', async () => {
    const fake = new FakeFirestore();
    const { repo, stay, booking, admin } = await seedStay(fake);
    const staleSnapshot = (await repo.findByStayId(stay.stayId)) as StayAggregate;
    jest.spyOn(repo, 'findByStayId').mockResolvedValueOnce(structuredClone(staleSnapshot));

    await booking.createBooking(staleSnapshot, paidBooking(7));
    await admin.approveCheckout(stay.stayId, {}, STAFF);

    jest.restoreAllMocks();
    const stored = (await repo.findByStayId(stay.stayId)) as StayAggregate;
    expect(stored.experienceBookings.some((b) => b.catalogRefId === 'unknown_7')).toBe(true);
    expect(bookingFolioLines(stored)).toBe(1);
  });
});

describe('Stay mutation and its operational alert are one atomic write (ADV-09)', () => {
  it('test_guestBooking_alertWriteFails_persistsNothingAndRetryCreatesOneBooking', async () => {
    const fake = new FakeFirestore();
    const { repo, stay, booking } = await seedStay(fake);
    fake.failWritesWith(new Error('14 UNAVAILABLE: alerts down'), 'operational_alerts');

    await expect(booking.createBooking(stay, paidBooking(9))).rejects.toThrow('UNAVAILABLE');
    fake.failWritesWith(null);
    await booking.createBooking(stay, paidBooking(9));

    const stored = (await repo.findByStayId(stay.stayId)) as StayAggregate;
    expect(stored.experienceBookings.filter((b) => b.catalogRefId === 'unknown_9')).toHaveLength(1);
    expect(bookingFolioLines(stored)).toBe(1);
    expect(fake.collections.get('operational_alerts')?.size).toBe(1);
  });
});

describe('FakeFirestore transaction retries are bounded like the Admin SDK', () => {
  it('test_fakeFirestore_contentionBeyondMaxAttempts_rejectsWithAbortedCode10', async () => {
    const fake = new FakeFirestore();
    fake.maxTransactionAttempts = 1;
    const { repo, stay } = await seedStay(fake);
    const template = stay.conciergeRequests[0];

    const results = await Promise.allSettled(
      Array.from({ length: 5 }, (_, i) =>
        repo.createConciergeRequest(stay.stayId, { ...template, requestId: `req_abort_${i}` }),
      ),
    );

    const rejected = results.filter((r): r is PromiseRejectedResult => r.status === 'rejected');
    expect(rejected.length).toBeGreaterThan(0);
    expect(rejected[0].reason).toMatchObject({ code: 10 });
  });
});
