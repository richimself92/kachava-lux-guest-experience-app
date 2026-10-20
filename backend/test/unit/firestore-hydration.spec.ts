import * as firebaseAdminModule from '../../src/infrastructure/firebase/firebase-admin.module';
import { SecurityTokenService } from '../../src/common/services/security-token.service';
import { FirestoreStayRepositoryAdapter } from '../../src/infrastructure/repositories/firestore-stay.repository';
import { InMemorySeededAlertRepository } from '../../src/infrastructure/repositories/in-memory-alert.repository';
import { InMemorySeededCatalogRepository } from '../../src/infrastructure/repositories/in-memory-catalog.repository';
import { InMemorySeededStaffRepository } from '../../src/infrastructure/repositories/in-memory-staff.repository';
import { createSeededStayAggregate } from '../../src/infrastructure/seed/sanctuary-seed.data';
import { FirebaseStorageSignerAdapter } from '../../src/infrastructure/storage/storage-signer.adapter';
import { AdminFulfillmentService } from '../../src/modules/admin/admin-fulfillment.service';
import { AdminService } from '../../src/modules/admin/admin.service';

describe('Cloud Run Cold-Start Firestore Hydration & Production Magic Link URL', () => {
  const originalGuestPortalUrl = process.env.GUEST_PORTAL_URL;

  afterEach(() => {
    jest.restoreAllMocks();
    if (originalGuestPortalUrl === undefined) {
      delete process.env.GUEST_PORTAL_URL;
    } else {
      process.env.GUEST_PORTAL_URL = originalGuestPortalUrl;
    }
  });

  function createAdminService(): AdminService {
    const stayRepo = new FirestoreStayRepositoryAdapter();
    const alertRepo = new InMemorySeededAlertRepository();
    const staffRepo = new InMemorySeededStaffRepository();
    const catalogRepo = new InMemorySeededCatalogRepository();
    const storageSigner = new FirebaseStorageSignerAdapter();
    const securityTokenService = new SecurityTokenService();
    const fulfillmentService = new AdminFulfillmentService(
      stayRepo,
      catalogRepo,
      storageSigner,
    );
    return new AdminService(
      stayRepo,
      alertRepo,
      staffRepo,
      securityTokenService,
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

    expect(result.magicLinkUrl).toMatch(
      /^http:\/\/localhost:3000\/\?guestId=[0-9a-f-]{36}$/i,
    );
    expect(result.stay.magicLinkUrl).toBe(result.magicLinkUrl);
  });

  it('test_firestoreStayRepositoryAdapter_hydratesAndExecutesReadWriteMethods', async () => {
    const repo = new FirestoreStayRepositoryAdapter();
    await repo.ensureHydrated();

    const stays = await repo.listStays();
    expect(stays.length).toBeGreaterThanOrEqual(1);

    const stay = stays[0];
    const byId = await repo.findByStayId(stay.stayId);
    expect(byId?.stayId).toBe(stay.stayId);

    const byToken = await repo.findByGuestTokenUuid(stay.guestTokenUuid);
    expect(byToken?.stayId).toBe(stay.stayId);

    const updatedPriv = await repo.updateSignaturePrivilege(stay.stayId, 'massage');
    expect(updatedPriv.selectedSignaturePrivilege).toBe('massage');

    const larderOrders = await repo.listAllLarderOrders();
    expect(Array.isArray(larderOrders)).toBe(true);

    const bookings = await repo.listAllBookings();
    expect(Array.isArray(bookings)).toBe(true);

    const requests = await repo.listAllConciergeRequests();
    expect(Array.isArray(requests)).toBe(true);
  });

  it('test_firestoreStayRepositoryAdapter_hydratesFromFirestoreWhenEnabled', async () => {
    const remoteStay = createSeededStayAggregate();
    remoteStay.stayId = 'stay_cloud_hydrated_108';
    remoteStay.villaName = 'Villa 108 — Cloud Sanctuary';

    const setMock = jest.fn().mockResolvedValue(undefined);
    const mockDb = {
      collection: jest.fn().mockReturnValue({
        get: jest.fn().mockResolvedValue({
          empty: false,
          docs: [{ data: () => remoteStay }],
        }),
        doc: jest.fn().mockReturnValue({
          set: setMock,
          collection: jest.fn().mockReturnValue({
            doc: jest.fn().mockReturnValue({ set: setMock }),
          }),
        }),
      }),
    };

    jest
      .spyOn(firebaseAdminModule, 'getNamedFirestoreDb')
      .mockReturnValue(mockDb as unknown as FirebaseFirestore.Firestore);

    const repo = new FirestoreStayRepositoryAdapter();
    const stays = await repo.listStays();

    expect(stays).toHaveLength(1);
    expect(stays[0].stayId).toBe('stay_cloud_hydrated_108');

    await repo.updateStayStatus('stay_cloud_hydrated_108', 'ACTIVE_STAY');
    expect(setMock).toHaveBeenCalled();
  });

  it('test_alertRepository_hydratesAndExecutesCrudInMemoryWhenFirestoreDisabled', async () => {
    const alertRepo = new InMemorySeededAlertRepository();
    const initial = await alertRepo.listAlerts();
    expect(initial.alerts.length).toBeGreaterThan(0);

    const firstId = initial.alerts[0].alertId;
    const acked = await alertRepo.acknowledgeAlert(firstId, 'staff-01');
    expect(acked?.isAcknowledged).toBe(true);
  });

  it('test_catalogRepository_hydratesAndExecutesCrudInMemoryWhenFirestoreDisabled', async () => {
    const catalogRepo = new InMemorySeededCatalogRepository();
    const larder = await catalogRepo.getLarderCatalog();
    expect(larder.length).toBeGreaterThan(0);

    const createdLarder = await catalogRepo.createLarderCatalogItem({
      id: 'larder_test_hydration',
      name: 'Cold-Pressed Elixir',
      price: 25,
    });
    expect(createdLarder.id).toBe('larder_test_hydration');

    const deletedLarder = await catalogRepo.deleteLarderCatalogItem('larder_test_hydration');
    expect(deletedLarder.deleted).toBe(true);

    const experiences = await catalogRepo.getExperiencesCatalog();
    expect(experiences.length).toBeGreaterThan(0);
  });
});
