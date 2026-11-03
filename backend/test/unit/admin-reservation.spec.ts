import { SecurityTokenService } from '../../src/common/services/security-token.service';
import { BusinessRuleError, EntityNotFoundError } from '../../src/domain/domain-errors';
import { OperationalAlert, StaffMember } from '../../src/domain/models/domain.models';
import { Villa } from '../../src/domain/models/resort-config.models';
import { FirestoreEntityRepository } from '../../src/infrastructure/repositories/firestore-entity.repository';
import { FirestoreStayRepository } from '../../src/infrastructure/repositories/firestore-stay.repository';
import { AdminService } from '../../src/modules/admin/admin.service';
import { FakeFirestore } from '../support/fake-firestore';
import { villaFixture } from '../support/stay-fixtures';

const STAFF = { staffId: 'staff-1', email: 'admin@test.local' } as StaffMember;
const RESERVATION = { guestName: 'Test Guest', villaId: 'villa-a', checkIn: '2026-12-01', checkOut: '2026-12-04' };

async function adminServiceOver(fake: FakeFirestore, villa: Villa | null = villaFixture()): Promise<AdminService> {
  const db = fake.asFirestore();
  const villas = new FirestoreEntityRepository<Villa>(db, 'villas', 'villaId', 'Villa');
  if (villa) await villas.create(villa);
  return new AdminService(
    new FirestoreStayRepository(db),
    villas,
    new SecurityTokenService(),
  );
}

describe('AdminService reservations & magic link URL', () => {
  const originalGuestPortalUrl = process.env.GUEST_PORTAL_URL;

  afterEach(() => {
    if (originalGuestPortalUrl === undefined) delete process.env.GUEST_PORTAL_URL;
    else process.env.GUEST_PORTAL_URL = originalGuestPortalUrl;
    jest.restoreAllMocks();
  });

  it('test_createReservation_whenGuestPortalUrlSet_usesConfiguredBaseUrlWithoutTrailingSlash', async () => {
    process.env.GUEST_PORTAL_URL = 'https://guest.example.app/';
    const adminService = await adminServiceOver(new FakeFirestore());

    const result = await adminService.createReservation(RESERVATION, STAFF);

    expect(result.magicLinkUrl).toMatch(/^https:\/\/guest\.example\.app\/\?guestId=[0-9a-f-]{36}$/i);
    expect(result.stay.magicLinkUrl).toBe(result.magicLinkUrl);
  });

  it('test_createReservation_copiesVillaNameAndWifiFromTheVilla', async () => {
    const adminService = await adminServiceOver(new FakeFirestore());

    const { stay } = await adminService.createReservation(RESERVATION, STAFF);

    expect(stay).toMatchObject({ villaId: 'villa-a', villaName: 'Test Villa', nights: 3, checkInDate: '2026-12-01' });
    expect(stay.villaAccess.wifiSsid).toBe('test-net');
  });

  it('test_createReservation_onOneInstance_magicLinkResolvesOnAnotherInstance', async () => {
    const fake = new FakeFirestore();
    const instanceA = await adminServiceOver(fake);
    const guestSideRepo = new FirestoreStayRepository(fake.asFirestore());

    const { stay } = await instanceA.createReservation(RESERVATION, STAFF);
    const resolved = await guestSideRepo.findByGuestTokenUuid(stay.guestTokenUuid);

    expect(resolved?.stayId).toBe(stay.stayId);
    expect(resolved?.flightTransfer.flightNumber).toBe('');
  });

  it('test_createReservation_commitsANewReservationNotificationWithTheStay', async () => {
    const fake = new FakeFirestore();
    const adminService = await adminServiceOver(fake);

    const { stay } = await adminService.createReservation(RESERVATION, STAFF);

    const alerts = Array.from(fake.store('operational_alerts').values()) as unknown as OperationalAlert[];
    expect(alerts).toHaveLength(1);
    expect(alerts[0]).toMatchObject({
      stayId: stay.stayId, category: 'RESERVATION', severity: 'NORMAL', event: 'NEW_RESERVATION',
      targetRef: { type: 'STAY', id: stay.stayId }, isAcknowledged: false,
    });
  });

  it('test_createReservation_unknownVilla_isNotFound', async () => {
    const adminService = await adminServiceOver(new FakeFirestore(), null);

    await expect(adminService.createReservation(RESERVATION, STAFF)).rejects.toBeInstanceOf(EntityNotFoundError);
  });

  it.each([
    ['inactive villa', villaFixture({ isActive: false }), RESERVATION],
    ['checkOut before checkIn', villaFixture(), { ...RESERVATION, checkOut: '2026-11-30' }],
    ['too many guests', villaFixture({ capacity: 2 }), { ...RESERVATION, guestsCount: 3 }],
  ])('test_createReservation_%s_isRejected', async (_label, villa, dto) => {
    const adminService = await adminServiceOver(new FakeFirestore(), villa);

    await expect(adminService.createReservation(dto, STAFF)).rejects.toBeInstanceOf(BusinessRuleError);
  });

  it('test_createReservation_storeWriteFails_rejectsInsteadOfReturningUnusableLink', async () => {
    const fake = new FakeFirestore();
    const adminService = await adminServiceOver(fake);
    fake.failWritesWith(new Error('UNAVAILABLE'));

    await expect(adminService.createReservation(RESERVATION, STAFF)).rejects.toThrow('UNAVAILABLE');
  });

  it('test_createReservation_concurrent_getsUniqueRandomStayIds', async () => {
    const adminService = await adminServiceOver(new FakeFirestore());

    const created = await Promise.all([adminService.createReservation(RESERVATION, STAFF), adminService.createReservation(RESERVATION, STAFF)]);

    const [first, second] = created.map((c) => c.stay.stayId);
    expect(first).not.toBe(second);
    expect(first).toMatch(/^stay_[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/);
  });
});
