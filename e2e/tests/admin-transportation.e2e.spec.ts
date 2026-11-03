import { APIRequestContext, expect, Locator, Page, test } from '@playwright/test';
import * as fs from 'fs';
import * as path from 'path';
import { attachErrorMonitor, readSemanticsSnapshot, waitForFlutterSemantics } from './e2e-helpers';

/**
 * Phase 5 (plan v2): HOSPITALITY › Transportation against the real backend
 * (Firestore + Storage emulators). Settings, a villa, a stay and (when
 * missing) an ACTIVE transport service with a van are prepared through the
 * API; the provider and the trip are created in the UI, then the trip goes
 * through the whole status flow. Every name carries a per-run tag.
 */
const ADMIN_URL = process.env.E2E_ADMIN_URL ?? 'http://localhost:3002';
const API = process.env.E2E_API_BASE_URL ?? 'http://localhost:3011/api/v1';
const ADMIN_EMAIL = process.env.E2E_ADMIN_EMAIL ?? 'admin@kachava.local';
const EVIDENCE = path.resolve(__dirname, '../../doc/kachava-command-center/evidence');
const RUN = `P5${Date.now().toString(36).slice(-5).toUpperCase()}`;
const ZONE = 'America/Cancun';
const GUEST = `${RUN} Ana Ruiz`;
const PROVIDER = `${RUN} Shuttles`;
const FLIGHT = `${RUN.slice(-4)} 512`;

type Json = Record<string, any>;

/** Resort calendar day `YYYY-MM-DD`, [offset] days from today. */
function resortDay(offset = 0): string {
  const at = new Date(Date.now() + offset * 86_400_000);
  return new Intl.DateTimeFormat('sv-SE', { timeZone: ZONE }).format(at);
}

async function shot(page: Page, name: string): Promise<void> {
  fs.mkdirSync(EVIDENCE, { recursive: true });
  await page.screenshot({ path: path.join(EVIDENCE, `phase-5-${name}.png`) });
}

async function adminApi(request: APIRequestContext) {
  const login = await request.post(`${API}/admin/auth/login`, { data: { email: ADMIN_EMAIL } });
  expect(login.ok()).toBe(true);
  const token = (await login.json()).data.token as string;
  const headers = { Authorization: `Bearer ${token}` };
  const call = async (method: 'get' | 'post' | 'patch', p: string, data?: Json, ok = [200, 201]) => {
    const res = await request[method](`${API}/admin${p}`, { headers, data });
    expect(ok, `${method.toUpperCase()} ${p}: ${await res.text()}`).toContain(res.status());
    return (await res.json()) as Json;
  };
  return {
    get: (p: string) => call('get', p),
    post: (p: string, data: Json) => call('post', p, data),
    patch: (p: string, data: Json) => call('patch', p, data),
  };
}
type Api = Awaited<ReturnType<typeof adminApi>>;

/** Time zone, CUN airport (3 h buffer) and the trip alert lead time. */
async function ensureSettings(api: Api): Promise<void> {
  const current = (await api.get('/settings')).data;
  const airports = (current.airports ?? []).filter((a: Json) => a.code !== 'CUN');
  await api.patch('/settings', {
    timeZone: current.timeZone ?? ZONE,
    transportAlertLeadHours: current.transportAlertLeadHours ?? 24,
    airports: [...airports, { code: 'CUN', name: 'Cancun International', departureBufferHours: 3, isActive: true }],
  });
}

/** An ACTIVE transport service serving CUN with a 6-seat van (created once). */
async function ensureTransportService(api: Api): Promise<{ id: string; name: string }> {
  const list = await api.get('/services?kind=TRANSPORT&status=ACTIVE&pageSize=100');
  const existing = list.data.find((s: Json) => (s.transport?.airportCodes ?? []).length === 0
    || s.transport.airportCodes.includes('CUN'));
  if (existing) return { id: existing.id, name: existing.name.en };
  const name = `${RUN} Airport transfer`;
  const service = await api.post('/services', {
    kind: 'TRANSPORT',
    section: 'TRANSPORTATION',
    usageType: 'TRIP',
    name: { en: name, es: `${RUN} Traslado aeropuerto` },
    shortDescription: { en: 'Private transfer', es: 'Traslado privado' },
    cover: { storagePath: 'catalog/services/e2e-transport-cover.jpg', alt: { en: 'Van', es: 'Camioneta' }, usageRightsConfirmed: true },
    pricing: { mode: 'FIXED', amount: 90, chargeToFolio: true },
    transport: { airportCodes: ['CUN'], priceBasis: 'PER_VEHICLE' },
    status: 'ACTIVE',
  });
  await api.post(`/services/${service.data.id}/items`, {
    name: { en: 'Van', es: 'Camioneta' },
    priceUSD: 90,
    capacity: { passengers: 6, luggage: 6 },
    status: 'ACTIVE',
  });
  return { id: service.data.id, name };
}

/** A villa and an upcoming stay for [GUEST] (check-in today, resort time). */
async function createStay(api: Api): Promise<string> {
  const villa = await api.post('/villas', { name: `${RUN} Casa Ceiba`, category: 'Ocean view', capacity: 4 });
  const stay = await api.post('/stays', {
    guestName: GUEST,
    villaId: villa.data.id,
    guestsCount: 2,
    checkIn: resortDay(0),
    checkOut: resortDay(4),
  });
  return stay.data.stayId ?? stay.data.id;
}

const button = (page: Page, name: string | RegExp): Locator =>
  page.getByRole('button', { name, exact: typeof name === 'string' });

const field = (page: Page, label: string): Locator =>
  page.locator(`input[aria-label*="${label}"], textarea[aria-label*="${label}"]`).last();

async function typeInto(page: Page, target: Locator, text: string): Promise<void> {
  await expect(target).toBeVisible();
  await expect(async () => {
    await target.click();
    await page.waitForTimeout(250);
    await target.fill(text);
    await expect(target).toHaveValue(text, { timeout: 1000 });
  }).toPass({ timeout: 15000 });
}

async function expectText(page: Page, text: string): Promise<void> {
  await waitForFlutterSemantics(page, text, 15000);
}

async function choose(page: Page, dropdown: RegExp, option: string): Promise<void> {
  await button(page, dropdown).last().click();
  await page.getByRole('menuitem', { name: option, exact: true }).last().click();
}

async function filterBy(page: Page, filter: string, option: string): Promise<void> {
  await page.getByRole('button', { name: new RegExp(`^${filter}`) }).first().click();
  await page.getByRole('menuitemcheckbox', { name: option, exact: true }).click();
}

async function clearAllFilters(page: Page): Promise<void> {
  const clearAll = page.getByRole('button', { name: 'Clear all' });
  await expect(async () => {
    if ((await clearAll.count()) > 0) await clearAll.first().click();
    await expect(clearAll).toHaveCount(0, { timeout: 1500 });
  }).toPass({ timeout: 15000 });
}

async function openTransportation(page: Page): Promise<void> {
  await button(page, 'Transportation').click();
  await expectText(page, 'Trips');
}

/** Clicks the trip's next action, then waits for the toast of [status]. */
async function advance(page: Page, action: string, status: string): Promise<void> {
  await button(page, action).last().click();
  await expectText(page, `Trip · ${status}`);
}

test.describe('Phase 5 — Transportation (admin http://localhost:3002)', () => {
  test('E2E-P5-01: provider, staff trip, full status flow, filters, reload persists (1440)', async ({
    page,
    request,
  }) => {
    test.setTimeout(300000);
    await page.setViewportSize({ width: 1440, height: 900 });
    const monitor = attachErrorMonitor(page);
    const api = await adminApi(request);

    // Arrange (API): Settings, transport service + van, villa + stay.
    await ensureSettings(api);
    const service = await ensureTransportService(api);
    const stayId = await createStay(api);

    // Menu: HOSPITALITY › Transportation, default window "Today + tomorrow".
    await page.goto(ADMIN_URL);
    await waitForFlutterSemantics(page, 'Unread operational alerts');
    await openTransportation(page);
    await expectText(page, 'Dates: Today + tomorrow');
    await shot(page, 'trips-default-1440');

    // Providers: create one in the UI.
    await button(page, 'Providers').click();
    await button(page, 'New provider').first().click();
    await typeInto(page, field(page, 'Name'), PROVIDER);
    await typeInto(page, field(page, 'Phone'), '+52 998 000 0000');
    await typeInto(page, field(page, 'Email'), `dispatch-${RUN.toLowerCase()}@provider.test`);
    await button(page, 'Save').last().click();
    await expectText(page, 'Provider saved');
    await shot(page, 'providers-1440');
    const providers = await api.get(`/transport-providers?q=${encodeURIComponent(RUN)}`);
    expect(providers.data).toEqual([expect.objectContaining({ name: PROVIDER, isActive: true })]);

    // New trip on behalf of the guest: departure tomorrow 18:00, no pickup.
    await button(page, 'Trips').click();
    await button(page, 'New trip').first().click();
    await typeInto(page, field(page, 'Guest stay'), GUEST);
    await page.getByRole('option', { name: new RegExp(GUEST) }).first().click();
    await choose(page, /^Service/, service.name);
    await choose(page, /^Type/, 'Departure');
    await typeInto(page, field(page, 'Airline'), 'Aeromexico');
    await typeInto(page, field(page, 'Flight number'), FLIGHT);
    await typeInto(page, field(page, 'Flight time'), `${resortDay(1)} 18:00`);
    await typeInto(page, field(page, 'Passengers'), '2');
    await button(page, 'Save').last().click();
    // The backend suggests flight − 3 h airport buffer.
    await expectText(page, 'Trip created · Pickup');
    await expectText(page, '15:00');

    const created = (await api.get(`/trips?q=${encodeURIComponent(GUEST)}`)).data;
    expect(created).toHaveLength(1);
    const trip = created[0];
    expect(trip).toMatchObject({
      stayId,
      type: 'DEPARTURE',
      airportCode: 'CUN',
      status: 'REQUESTED',
      createdBy: 'STAFF',
      passengers: 2,
    });
    expect(trip.flight.number).toBe(FLIGHT);

    // Full status flow from the detail panel: one next action at a time.
    await typeInto(page, page.getByRole('textbox', { name: 'Search' }), FLIGHT.replace(' ', ''));
    await page.getByRole('button', { name: new RegExp(GUEST) }).first().click();
    await expectText(page, 'Send to provider');
    await shot(page, 'trip-detail-requested-1440');
    await button(page, 'Send to provider').last().click();
    await choose(page, /^Provider/, PROVIDER);
    await advance(page, 'Send to provider', 'Sent to provider');
    await button(page, 'Confirm').last().click();
    await typeInto(page, field(page, 'Driver name'), 'Luis Pech');
    await typeInto(page, field(page, 'Driver phone'), '+52 984 111 2233');
    await typeInto(page, field(page, 'Plate'), 'YUC-1234');
    await advance(page, 'Confirm', 'Confirmed');
    await advance(page, 'En route', 'En route');
    await advance(page, 'Complete', 'Completed');
    await shot(page, 'trip-detail-completed-1440');

    const done = (await api.get(`/trips/${trip.id}`)).data;
    expect(done.status).toBe('COMPLETED');
    expect(done.driver).toEqual({ name: 'Luis Pech', phone: '+52 984 111 2233' });
    expect(done.statusHistory.map((h: Json) => h.to)).toEqual([
      'REQUESTED', 'SENT_TO_PROVIDER', 'CONFIRMED', 'EN_ROUTE', 'COMPLETED',
    ]);
    await button(page, 'Close').click();

    // A second trip (API) to cancel with a reason from the ⋮ menu.
    const local = (await api.post('/trips', {
      stayId,
      serviceId: service.id,
      type: 'LOCAL',
      origin: `${RUN} Villa`,
      destination: 'Tulum',
      pickupAt: `${resortDay(0)}T23:30`,
      passengers: 2,
    })).data;
    await clearAllFilters(page);
    await typeInto(page, page.getByRole('textbox', { name: 'Search' }), GUEST);
    await expectText(page, 'Unconfirmed');
    await page.getByRole('button', { name: /Local/ }).first().click();
    await button(page, 'Actions').click();
    await page.getByRole('menuitem', { name: 'Cancel trip' }).click();
    await typeInto(page, field(page, 'Reason'), 'Guest changed plans');
    await button(page, 'Cancel trip').last().click();
    await expectText(page, 'Trip cancelled');
    expect((await api.get(`/trips/${local.id}`)).data).toMatchObject({
      status: 'CANCELLED',
      cancellationReason: 'Guest changed plans',
    });
    await button(page, 'Close').click();

    // Filters: status, type and dates reach the server.
    await filterBy(page, 'Status', 'Completed');
    await expectText(page, '1–1 of 1');
    await clearAllFilters(page);
    await typeInto(page, page.getByRole('textbox', { name: 'Search' }), GUEST);
    await filterBy(page, 'Type', 'Local');
    await expectText(page, '1–1 of 1');
    await filterBy(page, 'Dates', 'Last 7 days');
    await expectText(page, 'No results');
    await shot(page, 'trips-filtered-1440');

    // Reload: everything came from the server.
    await page.reload();
    await waitForFlutterSemantics(page, 'Unread operational alerts');
    await openTransportation(page);
    await typeInto(page, page.getByRole('textbox', { name: 'Search' }), GUEST);
    await expectText(page, '1–2 of 2');
    const snapshot = await readSemanticsSnapshot(page);
    expect(snapshot).toContain('Completed');
    expect(snapshot).toContain('Cancelled');
    expect(snapshot).toContain(`${PROVIDER} · Luis Pech`);
    await shot(page, 'trips-after-reload-1440');

    expect([...monitor.pageErrors, ...monitor.consoleErrors, ...monitor.overflowErrors]).toEqual([]);
  });
});
