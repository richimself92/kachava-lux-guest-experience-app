import { NestExpressApplication } from '@nestjs/platform-express';
import { Test } from '@nestjs/testing';
import request from 'supertest';
import { AppModule } from '../../src/app.module';
import { SecurityTokenService } from '../../src/common/services/security-token.service';
import { RbacRole, StaffMember } from '../../src/domain/models/domain.models';
import { CLOCK_PORT, ClockPort } from '../../src/domain/ports/clock.port';
import {
  CATALOG_ITEMS_COLLECTION,
  CATALOG_SERVICES_COLLECTION,
  FIRESTORE_DB,
  OBJECT_URL_SIGNER,
} from '../../src/infrastructure/firebase/firebase-admin.module';
import { STAFF_COLLECTION } from '../../src/infrastructure/repositories/firestore-staff.repository';
import {
  guestSearchKeywords,
  STAYS_COLLECTION,
} from '../../src/infrastructure/repositories/firestore-stay.repository';
import { configureApp, enableRealtimeEmission } from '../../src/main';
import { itemFixture, serviceFixture } from './catalog-fixtures';
import { FakeFirestore } from './fake-firestore';
import { FakeObjectUrlSigner } from './fake-object-url-signer';
import { populatedStayFixture, TEST_GUEST_TOKEN } from './stay-fixtures';

export const TEST_ADMIN_EMAIL = 'admin-service@test.local';
export const GUEST_STAY_PATH = `/api/v1/stays/${TEST_GUEST_TOKEN}`;

/**
 * Writes a populated in-house stay plus two ACTIVE catalog services straight into the fake
 * store: `svc-1` (BOOKING, PER_PERSON $10) and `svc-stock` (ORDER, item `item-1` at $5).
 */
export function seedGuestFixtures(fake: FakeFirestore): void {
  const stay = populatedStayFixture();
  fake.store(STAYS_COLLECTION).set(stay.stayId, {
    ...JSON.parse(JSON.stringify(stay)),
    guestSearchKeywords: guestSearchKeywords(stay.guestProfile.name),
  });
  const stocking = serviceFixture({
    serviceId: 'svc-stock', kind: 'VILLA_STOCKING', section: 'IN_VILLA', usageType: 'ORDER', experience: null,
    stocking: { maxPerItem: 5, orderDeadlineHoursBeforeCheckIn: null },
    pricing: { mode: 'PER_UNIT', amount: null, currency: 'USD', chargeToFolio: true, note: { en: '', es: '' } },
  });
  for (const service of [serviceFixture(), stocking]) {
    fake.store(CATALOG_SERVICES_COLLECTION).set(service.serviceId, JSON.parse(JSON.stringify(service)));
  }
  const item = itemFixture({ serviceId: 'svc-stock' });
  fake.store(CATALOG_ITEMS_COLLECTION).set(item.itemId, JSON.parse(JSON.stringify(item)));
}

export interface TestApp {
  app: NestExpressApplication;
  fake: FakeFirestore;
  signer: FakeObjectUrlSigner;
  server: () => ReturnType<NestExpressApplication['getHttpServer']>;
  /** Bearer header of the env-configured admin identity (silent login). */
  adminHeaders: () => Promise<Record<string, string>>;
  /** Bearer header of a rostered staff member with `role` (written to the fake Firestore). */
  staffHeaders: (role: RbacRole) => Promise<Record<string, string>>;
  close: () => Promise<void>;
}

export interface TestAppOptions {
  /** Pins "now" for time-dependent rules; the system clock is used when omitted. */
  clock?: ClockPort;
}

/**
 * Boots the real AppModule with exactly two external handles replaced by test-only fakes:
 * Firestore (FakeFirestore) and the object URL signer (plus, optionally, the clock). Every
 * repository is the production Firestore adapter running over the fake.
 */
export async function createTestApp(fake = new FakeFirestore(), options: TestAppOptions = {}): Promise<TestApp> {
  process.env.ADMIN_SERVICE_EMAIL = TEST_ADMIN_EMAIL;
  const signer = new FakeObjectUrlSigner();
  let builder = Test.createTestingModule({ imports: [AppModule] })
    .overrideProvider(FIRESTORE_DB)
    .useValue(fake.asFirestore())
    .overrideProvider(OBJECT_URL_SIGNER)
    .useValue(signer);
  if (options.clock) builder = builder.overrideProvider(CLOCK_PORT).useValue(options.clock);
  const moduleRef = await builder.compile();
  const app = moduleRef.createNestApplication<NestExpressApplication>();
  configureApp(app);
  enableRealtimeEmission(app);
  // Listen explicitly: supertest then reuses one bound server for every request in the test.
  await app.listen(0, '127.0.0.1');
  const server = () => app.getHttpServer();

  let adminToken: string | null = null;
  const adminHeaders = async () => {
    if (!adminToken) {
      const res = await request(server()).post('/api/v1/admin/auth/login').send({ email: TEST_ADMIN_EMAIL });
      adminToken = res.body.data.token as string;
    }
    return { Authorization: `Bearer ${adminToken}` };
  };

  const staffHeaders = async (role: RbacRole) => {
    const staff: StaffMember = {
      staffId: `staff-${role.toLowerCase()}`,
      firebaseUid: '',
      fullName: `Test ${role}`,
      shortName: role,
      role,
      department: 'CONCIERGE',
      rbacRole: role,
      email: `${role.toLowerCase()}@test.local`,
      phone: '',
      avatarUrl: '',
      isActive: true,
    };
    fake.store(STAFF_COLLECTION).set(staff.staffId, { ...staff });
    const token = app.get(SecurityTokenService).issueStaffToken(staff);
    return { Authorization: `Bearer ${token}` };
  };

  return { app, fake, signer, server, adminHeaders, staffHeaders, close: () => app.close() };
}

export interface CreatedStay {
  villaId: string;
  stayId: string;
  guestTokenUuid: string;
}

/** Reservations need the resort day: configures `America/Cancun` when no time zone is set yet. */
export async function ensureResortTimeZone(t: TestApp): Promise<void> {
  const headers = await t.adminHeaders();
  const settings = await request(t.server()).get('/api/v1/admin/settings').set(headers);
  if (settings.body.data?.timeZone) return;
  const res = await request(t.server()).patch('/api/v1/admin/settings').set(headers).send({ timeZone: 'America/Cancun' });
  if (res.status !== 200) throw new Error(`ensureResortTimeZone failed: ${res.status} ${JSON.stringify(res.body)}`);
}

/** Creates a villa and a reservation through the admin API (as the env admin identity). */
export async function createVillaAndStay(
  t: TestApp,
  options: { villaName: string; guestName: string; checkIn?: string; checkOut?: string },
): Promise<CreatedStay> {
  await ensureResortTimeZone(t);
  const headers = await t.adminHeaders();
  const villa = await request(t.server()).post('/api/v1/admin/villas').set(headers).send({
    name: options.villaName, category: 'Test', capacity: 4,
    operationalStatus: 'AVAILABLE', housekeepingStatus: 'CLEAN', maintenanceStatus: 'OK',
  });
  const stay = await request(t.server()).post('/api/v1/admin/stays').set(headers).send({
    guestName: options.guestName, villaId: villa.body.data.id, guestsCount: 2,
    checkIn: options.checkIn ?? '2026-12-01', checkOut: options.checkOut ?? '2026-12-04',
  });
  if (stay.status !== 201) throw new Error(`createVillaAndStay failed: ${stay.status} ${JSON.stringify(stay.body)}`);
  return {
    villaId: villa.body.data.id,
    stayId: stay.body.data.stay.stayId,
    guestTokenUuid: stay.body.data.stay.guestTokenUuid,
  };
}
