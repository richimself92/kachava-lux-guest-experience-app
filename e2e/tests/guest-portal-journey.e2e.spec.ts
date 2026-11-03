import { APIRequestContext, expect, Locator, Page, test } from '@playwright/test';
import * as fs from 'fs';
import * as path from 'path';
import { attachErrorMonitor, readSemanticsSnapshot, waitForFlutterSemantics } from './e2e-helpers';
import { uploadCoverObject } from './guest-world';

/**
 * Phase 9 (plan v2): guest portal guided journey against the real backend (Firestore + Storage
 * emulators, `run-local.sh`). Settings, a villa, a stay and ACTIVE catalog services (ORDER, BOOKING,
 * TRIP) are created through the admin API with a per-run tag; the guest then follows the numbered
 * journey (skips stored on the stay), orders from the catalog (per-service `PUT /orders/:serviceId`),
 * sees the request in My requests and writes to the Resort Host. Nothing is seeded: everything the
 * portal shows comes from these API calls. Cancel/change and chat photos: `guest-portal.e2e.spec.ts`.
 */
const GUEST_URL = process.env.E2E_GUEST_URL ?? 'http://localhost:3000';
const API = process.env.E2E_API_BASE_URL ?? 'http://localhost:3011/api/v1';
const ADMIN_EMAIL = process.env.E2E_ADMIN_EMAIL ?? 'admin@kachava.local';
const EVIDENCE = path.resolve(__dirname, '../../doc/kachava-command-center/evidence');
const RUN = `P9${Date.now().toString(36).slice(-5).toUpperCase()}`;
const ZONE = 'America/Cancun';
const GUEST = `${RUN} Ana Ruiz`;
const COVER = (name: string) => ({
  storagePath: `catalog/services/e2e-${name}.jpg`,
  alt: { en: 'Cover photo', es: 'Foto de portada' },
  usageRightsConfirmed: true,
});

type Json = Record<string, any>;

function resortDay(offset = 0): string {
  return new Intl.DateTimeFormat('sv-SE', { timeZone: ZONE }).format(new Date(Date.now() + offset * 86_400_000));
}

async function shot(page: Page, name: string): Promise<void> {
  fs.mkdirSync(EVIDENCE, { recursive: true });
  await page.screenshot({ path: path.join(EVIDENCE, `phase-9-${name}.png`), fullPage: true });
}

async function adminApi(request: APIRequestContext) {
  const login = await request.post(`${API}/admin/auth/login`, { data: { email: ADMIN_EMAIL } });
  expect(login.ok()).toBe(true);
  const headers = { Authorization: `Bearer ${(await login.json()).data.token}` };
  const call = async (method: 'get' | 'post' | 'patch', p: string, data?: Json) => {
    const res = await request[method](`${API}/admin${p}`, { headers, data });
    expect([200, 201], `${method.toUpperCase()} ${p}: ${await res.text()}`).toContain(res.status());
    return (await res.json()) as Json;
  };
  return {
    get: (p: string) => call('get', p),
    post: (p: string, data: Json) => call('post', p, data),
    patch: (p: string, data: Json) => call('patch', p, data),
  };
}
type Api = Awaited<ReturnType<typeof adminApi>>;

async function createService(api: Api, body: Json, items: Json[]): Promise<string> {
  await uploadCoverObject(COVER(body.kind).storagePath);
  const created = await api.post('/services', { ...body, cover: COVER(body.kind), status: 'DISABLED' });
  const id = created.data.id ?? created.data.serviceId;
  for (const item of items) await api.post(`/services/${id}/items`, { ...item, status: 'ACTIVE' });
  await api.patch(`/services/${id}`, { status: 'ACTIVE' });
  return id;
}

/** Settings airport, three ACTIVE services and an upcoming stay (check-in in 3 days); returns the guest link id. */
async function prepare(api: Api): Promise<string> {
  const settings = (await api.get('/settings')).data;
  const airports = (settings.airports ?? []).filter((a: Json) => a.code !== 'CUN');
  await api.patch('/settings', {
    timeZone: settings.timeZone ?? ZONE,
    transportAlertLeadHours: settings.transportAlertLeadHours ?? 24,
    airports: [...airports, { code: 'CUN', name: 'Cancun International', departureBufferHours: 3, isActive: true }],
  });
  const text = (en: string, es: string) => ({ en: `${RUN} ${en}`, es: `${RUN} ${es}` });
  await createService(api, {
    kind: 'VILLA_STOCKING', section: 'IN_VILLA', usageType: 'ORDER',
    name: text('Villa stocking', 'Surtido de villa'), shortDescription: text('Before you land', 'Antes de llegar'),
    pricing: { mode: 'PER_UNIT', amount: null, chargeToFolio: true },
    availability: { offeredWhen: 'BEFORE_ARRIVAL' },
  }, [{ name: { en: 'Water', es: 'Agua' }, priceUSD: 4, category: 'Drinks' }]);
  await createService(api, {
    kind: 'WELLNESS', section: 'WELLNESS', usageType: 'BOOKING',
    name: text('Massage', 'Masaje'), shortDescription: text('In your villa', 'En tu villa'),
    pricing: { mode: 'PER_PERSON', amount: 120, chargeToFolio: true },
    availability: { offeredWhen: 'BOTH', timeSlots: [{ start: '10:00', end: '11:00' }], minGuests: 1, maxGuests: 2 },
    guestForm: { date: true, time: true, guests: true, notes: false, dietary: false, health: false },
  }, []);
  await createService(api, {
    kind: 'TRANSPORT', section: 'TRANSPORTATION', usageType: 'TRIP',
    name: text('Airport transfer', 'Traslado'), shortDescription: text('Private van', 'Camioneta privada'),
    pricing: { mode: 'FIXED', amount: 90, chargeToFolio: true },
    availability: { offeredWhen: 'BOTH', minLeadHours: 24 },
    transport: { airportCodes: ['CUN'], priceBasis: 'PER_VEHICLE' },
  }, [{ name: { en: 'Van', es: 'Camioneta' }, priceUSD: 90, capacity: { passengers: 6, luggage: 6 } }]);
  const villa = await api.post('/villas', { name: `${RUN} Casa Ceiba`, category: 'Ocean view', capacity: 4, operationalStatus: 'AVAILABLE', housekeepingStatus: 'CLEAN', maintenanceStatus: 'OK' });
  const created = await api.post('/stays', {
    guestName: GUEST, villaId: villa.data.id, guestsCount: 2, checkIn: resortDay(3), checkOut: resortDay(8),
  });
  const stay = created.data.stay ?? created.data;
  return stay.guestTokenUuid as string;
}

const button = (page: Page, name: string | RegExp): Locator =>
  page.getByRole('button', { name, exact: typeof name === 'string' }).last();

const tab = (page: Page, name: RegExp): Locator => page.getByRole('tab', { name }).last();

async function typeInto(page: Page, label: string, value: string): Promise<void> {
  const field = page.locator(`input[aria-label*="${label}"], textarea[aria-label*="${label}"]`).last();
  await expect(field).toBeVisible();
  // Flutter re-creates the <input> on focus and can drop the first event: verify the value held.
  await expect(async () => {
    await field.click();
    await field.fill(value);
    await expect(field).toHaveValue(value, { timeout: 1000 });
  }).toPass({ timeout: 15000 });
}

test.describe('Phase 9 — guest portal guided journey', () => {
  test.describe.configure({ mode: 'serial' });
  let guestId = '';

  test.beforeAll(async ({ request }) => {
    guestId = await prepare(await adminApi(request));
  });

  test('numbered journey, order, My requests and Resort Host at 375px', async ({ page, request }) => {
    const errors = attachErrorMonitor(page);
    await page.setViewportSize({ width: 375, height: 812 });
    await page.goto(`${GUEST_URL}/?guestId=${guestId}`);

    // Home: step 1 open by resort date, numbered core tasks first, sticky Next.
    await waitForFlutterSemantics(page, 'Before arrival');
    let snapshot = await readSemanticsSnapshot(page);
    expect(snapshot).toContain('1.1 Flight & transfer');
    expect(snapshot).toContain('1.2 Preferences');
    expect(snapshot).toMatch(/Next: 1\.1 Flight & transfer/);
    expect(snapshot).not.toMatch(/yacht|Cenote|Tulum|Philosophy|Concierge/i);
    await shot(page, 'home-375');

    // Not now: stored on the stay (PUT /journey), 1.1 leaves the count and Next moves to 1.2.
    const skipSaved = page.waitForResponse((res) => res.url().endsWith(`/stays/${guestId}/journey`) && res.request().method() === 'PUT');
    await button(page, 'Not now').click();
    expect((await skipSaved).status()).toBe(200);
    await waitForFlutterSemantics(page, 'Next: 1.2 Preferences');
    await page.reload();
    snapshot = await waitForFlutterSemantics(page, 'Skipped');
    expect(snapshot).toMatch(/Next: 1\.2 Preferences/);

    // 1.2 Preferences: explicit "None", saved only after the server answers.
    await button(page, /Next: 1\.2 Preferences/).click();
    await waitForFlutterSemantics(page, 'Step 1 of');
    await page.getByRole('switch').first().click();
    await button(page, /^(Next|Save)$/).click();
    await shot(page, 'preferences-375');

    // Services: search the run's stocking service, order 2 waters.
    await page.goto(`${GUEST_URL}/?guestId=${guestId}`);
    await waitForFlutterSemantics(page, 'Before arrival');
    await tab(page, /Services/).click();
    // The filter applying is the outcome that matters: type again if the first input was dropped.
    await expect(async () => {
      await typeInto(page, 'Search', `${RUN} Villa`);
      await waitForFlutterSemantics(page, '1 services', 4000);
    }).toPass({ timeout: 30000 });
    await button(page, `${RUN} Villa stocking`).click();
    await waitForFlutterSemantics(page, 'Order');
    await shot(page, 'detail-375');
    await button(page, 'Order').click();
    await button(page, /^\+ Water/).click(); // a focused tooltip button repeats its label
    await button(page, /^\+ Water/).click(); // a focused tooltip button repeats its label
    await waitForFlutterSemantics(page, '2 items · $8 USD');
    await button(page, 'Review').click();
    const orderSaved = page.waitForResponse((res) => res.url().includes(`/stays/${guestId}/orders/`) && res.request().method() === 'PUT');
    await button(page, 'Order').click();
    expect((await orderSaved).status()).toBe(200);
    await waitForFlutterSemantics(page, 'Order sent');

    // My requests: plain status word, never a raw enum.
    await tab(page, /Requests/).click();
    await waitForFlutterSemantics(page, 'My requests');
    snapshot = await readSemanticsSnapshot(page);
    expect(snapshot).toContain(`${RUN} Villa stocking`);
    expect(snapshot).toContain('Received');
    expect(snapshot).not.toContain('REQUESTED');
    await shot(page, 'requests-375');

    // Resort Host chat: success toast only after the server confirms.
    await tab(page, /Host/).click();
    await waitForFlutterSemantics(page, 'Resort Host');
    await typeInto(page, 'Message', `${RUN} extra towels please`);
    await button(page, 'Send').click();
    await waitForFlutterSemantics(page, 'Message sent');
    await shot(page, 'host-375');

    // The backend holds what the guest sent.
    const stay = await request.get(`${API}/stays/${guestId}`, { headers: { Authorization: `Bearer ${guestId}` } });
    const body = (await stay.json()).data;
    expect(body).toMatchObject({ checkInDate: resortDay(3), checkOutDate: resortDay(8) });
    expect(body.skippedTaskIds).toContain('1:core:flight');
    expect(body.larderOrders.some((o: Json) => o.quantity === 2 && typeof o.createdAt === 'string')).toBe(true);
    expect(body.personalization.dietary).toBe('None');
    expect(body.conciergeRequests.some((r: Json) => r.details?.includes(RUN))).toBe(true);
    expect(errors.pageErrors).toEqual([]);
    expect(errors.overflowErrors).toEqual([]);
  });

  test('desktop 1440px: services grid and language toggle', async ({ page }) => {
    await page.setViewportSize({ width: 1440, height: 900 });
    await page.goto(`${GUEST_URL}/?guestId=${guestId}`);
    await waitForFlutterSemantics(page, 'Before arrival');
    await button(page, 'ES').click();
    await waitForFlutterSemantics(page, 'Antes de llegar');
    await tab(page, /Servicios/).click();
    await waitForFlutterSemantics(page, 'servicios');
    await shot(page, 'services-1440-es');
    await button(page, 'EN').click();
    await waitForFlutterSemantics(page, 'Services');
  });

  test('expired link says to ask the Resort Host', async ({ page }) => {
    await page.goto(`${GUEST_URL}/?guestId=00000000-0000-4000-8000-000000000000`);
    await waitForFlutterSemantics(page, 'Ask your Resort Host for a new one');
  });
});
