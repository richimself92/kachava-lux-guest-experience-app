import { CreateBookingDto } from '../../src/modules/guest/dto/guest.dto';
import { CatalogItem, CatalogService } from '../../src/domain/catalog/catalog.models';
import { FirestoreEntityRepository } from '../../src/infrastructure/repositories/firestore-entity.repository';
import { FirestoreServiceRequestRepository } from '../../src/infrastructure/repositories/firestore-service-request.repository';
import { FirestoreStayRepository } from '../../src/infrastructure/repositories/firestore-stay.repository';
import { GuestAlertFolioHelper } from '../../src/modules/guest/guest-alert-folio.helper';
import { GuestBookingService } from '../../src/modules/guest/guest-booking.service';
import { TaskAutomation } from '../../src/modules/tasks/task-automation.service';
import { FirestoreTaskRepository } from '../../src/infrastructure/repositories/firestore-task.repository';
import { FirestoreSettingsRepository } from '../../src/infrastructure/repositories/firestore-settings.repository';
import { SystemClock } from '../../src/infrastructure/time/system-clock';
import { StayAggregate } from '../../src/domain/models/domain.models';
import { itemFixture, serviceFixture } from '../support/catalog-fixtures';
import { FakeFirestore } from '../support/fake-firestore';
import { populatedStayFixture } from '../support/stay-fixtures';

const PARALLEL = 20;
const STOCKING_SERVICE = serviceFixture({
  serviceId: 'svc-stock', kind: 'VILLA_STOCKING', section: 'IN_VILLA', usageType: 'ORDER', experience: null,
  stocking: { maxPerItem: null, orderDeadlineHoursBeforeCheckIn: null },
  pricing: { mode: 'PER_UNIT', amount: null, currency: 'USD', chargeToFolio: true, note: { en: '', es: '' } },
});

function paidBooking(index: number): CreateBookingDto {
  return {
    serviceId: 'svc-1',
    scheduledDate: '2026-11-10',
    scheduledTimeSlot: '10:00',
    partySize: 1,
    metadata: { ref: `ref_${index}` },
  };
}

async function seedStay(fake: FakeFirestore) {
  const db = fake.asFirestore();
  const repo = new FirestoreStayRepository(db);
  const services = new FirestoreEntityRepository<CatalogService>(db, 'catalog_services', 'serviceId', 'Service');
  const items = new FirestoreEntityRepository<CatalogItem>(db, 'catalog_items', 'itemId', 'Item');
  const stay = populatedStayFixture();
  await repo.createStay(stay);
  await services.create(serviceFixture());
  await services.create(STOCKING_SERVICE);
  await items.create(itemFixture({ serviceId: 'svc-stock' }));
  const helper = new GuestAlertFolioHelper();
  return {
    repo,
    stay,
    booking: new GuestBookingService(repo, services, items, helper, new TaskAutomation(
      new FirestoreTaskRepository(db), new FirestoreSettingsRepository(db), new SystemClock(),
      new FirestoreServiceRequestRepository(db), repo,
    )),
  };
}

const hasRef = (ref: string) => (b: { metadata: Record<string, unknown> }) => b.metadata.ref === ref;

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
    await booking.createBooking(staleSnapshot, paidBooking(1));
    await booking.updateServiceOrder(staleSnapshot, 'svc-stock', [{ itemId: 'item-1', quantity: 3 }]);

    const stored = (await repo.findByStayId(stay.stayId)) as StayAggregate;
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
    expect(stored.experienceBookings.filter(hasRef('ref_9'))).toHaveLength(1);
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
