import { APIRequestContext, expect, Locator, Page } from '@playwright/test';

/**
 * Shared set-up of the guest portal specs. Nothing is seeded: every villa, stay, setting and
 * catalog service the portal shows is created here through the admin API with a per-run tag,
 * against the real local stack (`run-local.sh`: backend, guest portal, emulators).
 */
export const GUEST_URL = process.env.E2E_GUEST_URL ?? 'http://localhost:3000';
export const API = process.env.E2E_API_BASE_URL ?? 'http://localhost:3011/api/v1';
export const ADMIN_EMAIL = process.env.E2E_ADMIN_EMAIL ?? 'admin@kachava.local';
export const ZONE = 'America/Cancun';
/** A well-formed guest id that no stay holds (the backend answers 401/404). */
export const UNKNOWN_GUEST_ID = '00000000-0000-4000-8000-000000000000';

export type Json = Record<string, any>;

export function runTag(prefix: string): string {
  return `${prefix}${Date.now().toString(36).slice(-5).toUpperCase()}`;
}

/** Resort calendar day `offset` days from today (YYYY-MM-DD). */
export function resortDay(offset = 0): string {
  return new Intl.DateTimeFormat('sv-SE', { timeZone: ZONE }).format(new Date(Date.now() + offset * 86_400_000));
}

export async function adminApi(request: APIRequestContext) {
  const login = await request.post(`${API}/admin/auth/login`, { data: { email: ADMIN_EMAIL } });
  expect(login.ok()).toBe(true);
  const headers = { Authorization: `Bearer ${(await login.json()).data.token}` };
  const call = async (method: 'get' | 'post' | 'patch', path: string, data?: Json) => {
    const res = await request[method](`${API}/admin${path}`, { headers, data });
    expect([200, 201], `${method.toUpperCase()} ${path}: ${await res.text()}`).toContain(res.status());
    return (await res.json()) as Json;
  };
  return {
    get: (path: string) => call('get', path),
    post: (path: string, data: Json) => call('post', path, data),
    patch: (path: string, data: Json) => call('patch', path, data),
  };
}
export type AdminApi = Awaited<ReturnType<typeof adminApi>>;

/** Guest routes authenticated by the link id itself (`Authorization: Bearer <guestId>`). */
export function guestApi(request: APIRequestContext, guestId: string) {
  const headers = { Authorization: `Bearer ${guestId}` };
  const base = `${API}/stays/${guestId}`;
  return {
    get: (path = '') => request.get(`${base}${path}`, { headers }),
    post: (path: string, data?: Json) => request.post(`${base}${path}`, { headers, data }),
    put: (path: string, data: Json) => request.put(`${base}${path}`, { headers, data }),
    patch: (path: string, data: Json) => request.patch(`${base}${path}`, { headers, data }),
  };
}

function cover(tag: string) {
  return {
    storagePath: `catalog/services/e2e-${tag}.jpg`,
    alt: { en: `${tag} photo`, es: `Foto ${tag}` },
    usageRightsConfirmed: true,
  };
}

/** Creates the service DISABLED, adds its ACTIVE items, then activates it. */
export async function createActiveService(api: AdminApi, body: Json, items: Json[] = []): Promise<{ id: string; itemIds: string[] }> {
  const created = await api.post('/services', { ...body, cover: cover(body.kind), status: 'DISABLED' });
  const id = created.data.id ?? created.data.serviceId;
  const itemIds: string[] = [];
  for (const item of items) {
    const res = await api.post(`/services/${id}/items`, { ...item, status: 'ACTIVE' });
    itemIds.push(res.data.id ?? res.data.itemId);
  }
  await api.patch(`/services/${id}`, { status: 'ACTIVE' });
  return { id, itemIds };
}

export interface GuestWorld {
  tag: string;
  guestId: string;
  guestName: string;
  villaName: string;
  checkIn: string;
  checkOut: string;
  stockingId: string;
  waterId: string;
  barId: string;
  wineId: string;
  massageId: string;
  transferId: string;
}

/** CUN airport in Settings plus the time zone (kept when already configured). */
async function ensureAirport(api: AdminApi): Promise<void> {
  const settings = (await api.get('/settings')).data;
  const airports = (settings.airports ?? []).filter((a: Json) => a.code !== 'CUN');
  await api.patch('/settings', {
    timeZone: settings.timeZone ?? ZONE,
    transportAlertLeadHours: settings.transportAlertLeadHours ?? 24,
    airports: [...airports, { code: 'CUN', name: 'Cancun International', departureBufferHours: 3, isActive: true }],
  });
}

/** Two ORDER services, one BOOKING service and an airport TRIP service, tagged with `tag`. */
async function createCatalog(api: AdminApi, tag: string) {
  const text = (en: string, es: string) => ({ en: `${tag} ${en}`, es: `${tag} ${es}` });
  const order = (en: string, es: string, item: Json) => createActiveService(api, {
    kind: 'VILLA_STOCKING', section: 'IN_VILLA', usageType: 'ORDER',
    name: text(en, es), shortDescription: text('Before you land', 'Antes de llegar'),
    pricing: { mode: 'PER_UNIT', amount: null, chargeToFolio: true },
    availability: { offeredWhen: 'BEFORE_ARRIVAL' },
  }, [item]);
  const stocking = await order('Villa stocking', 'Surtido de villa', { name: { en: 'Water', es: 'Agua' }, priceUSD: 4, category: 'Drinks' });
  const bar = await order('Villa bar', 'Bar de villa', { name: { en: 'Red wine', es: 'Vino tinto' }, priceUSD: 30, category: 'Wine' });
  const massage = await createActiveService(api, {
    kind: 'WELLNESS', section: 'WELLNESS', usageType: 'BOOKING',
    name: text('Massage', 'Masaje'), shortDescription: text('In your villa', 'En tu villa'),
    pricing: { mode: 'PER_PERSON', amount: 120, chargeToFolio: true },
    availability: { offeredWhen: 'BOTH', timeSlots: [{ start: '10:00', end: '11:00' }], minGuests: 1, maxGuests: 2 },
    guestForm: { date: true, time: true, guests: true, notes: false, dietary: false, health: false },
  });
  const transfer = await createActiveService(api, {
    kind: 'TRANSPORT', section: 'TRANSPORTATION', usageType: 'TRIP',
    name: text('Airport transfer', 'Traslado'), shortDescription: text('Private van', 'Camioneta privada'),
    pricing: { mode: 'FIXED', amount: 90, chargeToFolio: true },
    availability: { offeredWhen: 'BOTH', minLeadHours: 24 },
    transport: { airportCodes: ['CUN'], priceBasis: 'PER_VEHICLE' },
  }, [{ name: { en: 'Van', es: 'Camioneta' }, priceUSD: 90, capacity: { passengers: 6, luggage: 6 } }]);
  return { stocking, bar, massage, transfer };
}

/** Settings, the tagged catalog, a villa and an upcoming stay (check-in in 3 days). */
export async function prepareGuestWorld(request: APIRequestContext, prefix: string): Promise<GuestWorld> {
  const api = await adminApi(request);
  const tag = runTag(prefix);
  await ensureAirport(api);
  const catalog = await createCatalog(api, tag);
  const villaName = `${tag} Casa Ceiba`;
  const guestName = `${tag} Ana Ruiz`;
  const villa = await api.post('/villas', { name: villaName, category: 'Ocean view', capacity: 4 });
  const checkIn = resortDay(3);
  const checkOut = resortDay(8);
  const created = await api.post('/stays', { guestName, villaId: villa.data.id, guestsCount: 2, checkIn, checkOut });
  const stay = created.data.stay ?? created.data;
  return {
    tag, guestName, villaName, checkIn, checkOut,
    guestId: stay.guestTokenUuid as string,
    stockingId: catalog.stocking.id, waterId: catalog.stocking.itemIds[0],
    barId: catalog.bar.id, wineId: catalog.bar.itemIds[0],
    massageId: catalog.massage.id,
    transferId: catalog.transfer.id,
  };
}

/** Last visible Flutter button with this accessible name. */
export const button = (page: Page, name: string | RegExp): Locator =>
  page.getByRole('button', { name, exact: typeof name === 'string' }).last();

export async function typeInto(page: Page, label: string, value: string): Promise<void> {
  const field = page.locator(`input[aria-label*="${label}"], textarea[aria-label*="${label}"]`).last();
  await expect(field).toBeVisible();
  await field.click();
  await field.fill(value);
}

/** Demo/prototype content that must never appear in the portal (no seeds, no fake data). */
export const DEMO_MARKERS = /Miller|Alex & Sarah|Villa 102|Julian Vance|yacht|Cenote|Tulum|Philosophy|Soundscape|432Hz/i;
