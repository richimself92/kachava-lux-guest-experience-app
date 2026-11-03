import { SecurityTokenService } from '../../src/common/services/security-token.service';
import { StayRepositoryPort } from '../../src/domain/ports/repository.ports';
import { FirestoreStayRepository } from '../../src/infrastructure/repositories/firestore-stay.repository';
import { InMemorySeededAlertRepository } from '../../src/infrastructure/repositories/in-memory-alert.repository';
import { InMemorySeededCatalogRepository } from '../../src/infrastructure/repositories/in-memory-catalog.repository';
import { InMemorySeededStaffRepository } from '../../src/infrastructure/repositories/in-memory-staff.repository';
import { InMemorySeededStayRepository } from '../../src/infrastructure/repositories/in-memory-stay.repository';
import { FirebaseStorageSignerAdapter } from '../../src/infrastructure/storage/storage-signer.adapter';
import { AdminFulfillmentService } from '../../src/modules/admin/admin-fulfillment.service';
import { AdminService } from '../../src/modules/admin/admin.service';
import { FakeFirestore } from '../support/fake-firestore';

describe('AdminService reservations & production magic link URL', () => {
  const originalGuestPortalUrl = process.env.GUEST_PORTAL_URL;

  afterEach(() => {
    if (originalGuestPortalUrl === undefined) {
      delete process.env.GUEST_PORTAL_URL;
    } else {
      process.env.GUEST_PORTAL_URL = originalGuestPortalUrl;
    }
  });

  function createAdminService(stayRepo: StayRepositoryPort = new InMemorySeededStayRepository()): AdminService {
    const fulfillmentService = new AdminFulfillmentService(
      stayRepo,
      new InMemorySeededCatalogRepository(),
      new FirebaseStorageSignerAdapter(),
    );
    return new AdminService(
      stayRepo,
      new InMemorySeededAlertRepository(),
      new InMemorySeededStaffRepository(),
      new SecurityTokenService(),
      fulfillmentService,
    );
  }

  it('test_createReservation_whenGuestPortalUrlSet_usesConfiguredBaseUrlWithoutTrailingSlash', async () => {
    process.env.GUEST_PORTAL_URL = 'https://kavacha-app-guest-portal.web.app/';
    const adminService = createAdminService();

    const result = await adminService.createReservation({
      guestName: 'Elena Vance',
      villaId: 'villa-104',
      villaName: 'Villa 104 — Cliff Sanctuary',
    });

    expect(result.magicLinkUrl).toMatch(
      /^https:\/\/kavacha-app-guest-portal\.web\.app\/\?guestId=[0-9a-f-]{36}$/i,
    );
    expect(result.stay.magicLinkUrl).toBe(result.magicLinkUrl);
  });

  it('test_createReservation_whenGuestPortalUrlUnset_defaultsToLocalhost3000', async () => {
    delete process.env.GUEST_PORTAL_URL;
    const adminService = createAdminService();

    const result = await adminService.createReservation({
      guestName: 'Marcus Sterling',
      villaId: 'villa-105',
    });

    expect(result.magicLinkUrl).toMatch(/^http:\/\/localhost:3000\/\?guestId=[0-9a-f-]{36}$/i);
    expect(result.stay.magicLinkUrl).toBe(result.magicLinkUrl);
  });

  it('test_createReservation_onOneInstance_magicLinkResolvesOnAnotherInstance', async () => {
    const fake = new FakeFirestore();
    const instanceA = createAdminService(new FirestoreStayRepository(fake.asFirestore()));
    const guestSideRepo = new FirestoreStayRepository(fake.asFirestore());

    const { stay } = await instanceA.createReservation({ guestName: 'Ana Ruiz', villaId: 'villa-107' });
    const resolved = await guestSideRepo.findByGuestTokenUuid(stay.guestTokenUuid);

    expect(resolved?.stayId).toBe(stay.stayId);
    expect(resolved?.guestProfile.name).toBe('Ana Ruiz');
    expect(resolved?.flightTransfer.flightNumber).toBe('');
  });

  it('test_createReservation_storeWriteFails_rejectsInsteadOfReturningUnusableLink', async () => {
    const fake = new FakeFirestore();
    fake.failWritesWith(new Error('UNAVAILABLE'));
    const adminService = createAdminService(new FirestoreStayRepository(fake.asFirestore()));

    await expect(
      adminService.createReservation({ guestName: 'Ana Ruiz', villaId: 'villa-107' }),
    ).rejects.toThrow('UNAVAILABLE');
  });

  it('test_alertRepository_executesCrudInMemoryWhenFirestoreDisabled', async () => {
    const alertRepo = new InMemorySeededAlertRepository();
    const initial = await alertRepo.listAlerts();
    expect(initial.alerts.length).toBeGreaterThan(0);

    const firstId = initial.alerts[0].alertId;
    const acked = await alertRepo.acknowledgeAlert(firstId, 'staff-01');
    expect(acked?.isAcknowledged).toBe(true);
  });

  it('test_catalogRepository_executesCrudInMemoryWhenFirestoreDisabled', async () => {
    const catalogRepo = new InMemorySeededCatalogRepository();
    expect((await catalogRepo.getLarderCatalog()).length).toBeGreaterThan(0);

    const createdLarder = await catalogRepo.createLarderCatalogItem({
      id: 'larder_test_hydration',
      name: 'Cold-Pressed Elixir',
      price: 25,
    });
    expect(createdLarder.id).toBe('larder_test_hydration');

    const deletedLarder = await catalogRepo.deleteLarderCatalogItem('larder_test_hydration');
    expect(deletedLarder.deleted).toBe(true);
    expect((await catalogRepo.getExperiencesCatalog()).length).toBeGreaterThan(0);
  });

  it('test_createReservation_sameVillaSameMillisecond_getsUniqueRandomStayIds', async () => {
    jest.spyOn(Date, 'now').mockReturnValue(Date.parse('2026-12-01T00:00:00.000Z'));
    const adminService = createAdminService();
    const dto = { guestName: 'Guest N', villaId: 'villa-7', villaName: 'Villa 7' };

    const created = await Promise.all([
      adminService.createReservation(dto),
      adminService.createReservation(dto),
    ]);

    jest.restoreAllMocks();
    const [first, second] = created.map((c) => c.stay.stayId);
    expect(first).not.toBe(second);
    expect(first).toMatch(/^stay_[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/);
  });
});
