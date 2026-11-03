import { expect, Page, test } from '@playwright/test';
import { attachErrorMonitor, readSemanticsSnapshot, waitForFlutterSemantics } from './e2e-helpers';
import {
  API,
  button,
  DEMO_MARKERS,
  GUEST_URL,
  guestApi,
  GuestWorld,
  Json,
  prepareGuestWorld,
  tab,
} from './guest-world';

/**
 * Guest self-service on the guided portal (`web/`) against the real backend: the guest-safe stay
 * view, per-service orders, cancel/change of requests while "Received", trip cancel and chat
 * photos inside the current thread. Data is created through the admin API (no seeds).
 */
const INTERNAL_KEYS = ['guestTokenUuid', 'adminNotes', 'assignedStaffId', 'photoStoragePath', 'notes', 'internalNotes'];

function keysOf(value: unknown, into = new Set<string>()): Set<string> {
  if (Array.isArray(value)) value.forEach((v) => keysOf(v, into));
  else if (value && typeof value === 'object') {
    for (const [key, child] of Object.entries(value)) {
      into.add(key);
      keysOf(child, into);
    }
  }
  return into;
}

/** A guest call made by the portal origin itself (exercises CORS preflight for PUT/PATCH). */
async function browserCall(page: Page, guestId: string, method: string, path: string, body?: Json) {
  return page.evaluate(
    async ({ url, method, body, guestId }) => {
      const res = await fetch(url, {
        method,
        headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${guestId}` },
        body: body === undefined ? undefined : JSON.stringify(body),
      });
      return { status: res.status, body: await res.json().catch(() => null) };
    },
    { url: `${API}/stays/${guestId}${path}`, method, body, guestId },
  );
}

async function openTab(page: Page, label: RegExp, expected: string): Promise<string> {
  await tab(page, label).click();
  return waitForFlutterSemantics(page, expected);
}

test.describe('Guest portal self-service', () => {
  test.describe.configure({ mode: 'serial' });
  let world: GuestWorld;

  test.beforeAll(async ({ request }) => {
    world = await prepareGuestWorld(request, 'GP');
  });

  test('E2E-G01: guest-safe stay view with ISO dates, journey marks and no internal fields', async ({ page, request }) => {
    await page.goto(`${GUEST_URL}/?guestId=${world.guestId}`);
    await waitForFlutterSemantics(page, world.villaName);

    const saved = await browserCall(page, world.guestId, 'PUT', '/journey', { skippedTaskIds: ['1:core:flight'] });
    const view = (await (await guestApi(request, world.guestId).get()).json()).data;

    expect(saved.status).toBe(200);
    expect(view).toMatchObject({
      checkInDate: world.checkIn, checkOutDate: world.checkOut,
      skippedTaskIds: ['1:core:flight'], completedTaskIds: [],
    });
    const keys = keysOf(view);
    expect(INTERNAL_KEYS.filter((k) => keys.has(k))).toEqual([]);

    // The skip lives on the stay: a fresh page shows it as Skipped.
    await page.reload();
    const home = await waitForFlutterSemantics(page, 'Skipped');
    expect(home).toContain('Next: 1.2 Preferences');
    expect(home).not.toMatch(DEMO_MARKERS);
  });

  test('E2E-G02: an order for one service never erases another service order', async ({ page, request }) => {
    await page.goto(`${GUEST_URL}/?guestId=${world.guestId}`);
    await waitForFlutterSemantics(page, world.villaName);

    const water = await browserCall(page, world.guestId, 'PUT', `/orders/${world.stockingId}`, { items: [{ itemId: world.waterId, quantity: 2 }] });
    const wine = await browserCall(page, world.guestId, 'PUT', `/orders/${world.barId}`, { items: [{ itemId: world.wineId, quantity: 1 }] });
    const view = (await (await guestApi(request, world.guestId).get()).json()).data;

    expect([water.status, wine.status]).toEqual([200, 200]);
    expect(view.larderOrders.map((o: Json) => o.serviceId).sort()).toEqual([world.barId, world.stockingId].sort());
    for (const line of view.larderOrders) expect(line.createdAt).toMatch(/^\d{4}-\d{2}-\d{2}T/);

    await page.reload(); // the portal refreshes on its 30 s poll; an external write shows after a reload
    await waitForFlutterSemantics(page, world.villaName);
    const requests = await openTab(page, /Requests/, 'My requests');
    expect(requests).toContain(`${world.tag} Villa stocking`);
    expect(requests).toContain(`${world.tag} Villa bar`);
  });

  test('E2E-G03: a Received booking can be changed and cancelled; a confirmed one cannot', async ({ page, request }) => {
    const guest = guestApi(request, world.guestId);
    const date = world.checkIn;
    const booked = (await (await guest.post('/bookings', {
      serviceId: world.massageId, scheduledDate: date, scheduledTimeSlot: '10:00', partySize: 1,
    })).json()).data;

    const changed = await guest.patch(`/bookings/${booked.bookingId}`, { partySize: 2 });
    expect(changed.status()).toBe(200);
    expect((await changed.json()).data).toMatchObject({ partySize: 2, status: 'REQUESTED', priceChargedUSD: 240 });
    expect((await guest.patch(`/bookings/${booked.bookingId}`, { partySize: 3 })).status()).toBe(422);

    // UI: the sheet offers Change and Cancel while Received; Cancel asks once and is confirmed by the server.
    await page.goto(`${GUEST_URL}/?guestId=${world.guestId}`);
    await waitForFlutterSemantics(page, world.villaName);
    await openTab(page, /Requests/, 'My requests');
    await button(page, new RegExp(`${world.tag} Massage`)).click();
    const sheet = await waitForFlutterSemantics(page, 'Change');
    expect(sheet).not.toContain('Ask Host');
    await button(page, 'Cancel').click();
    await waitForFlutterSemantics(page, `${world.tag} Massage?`);
    await button(page, 'Cancel').click();
    await waitForFlutterSemantics(page, 'Request cancelled');

    const stored = (await (await guest.get('/bookings')).json()).data.find((b: Json) => b.bookingId === booked.bookingId);
    expect(stored).toMatchObject({ status: 'CANCELLED', cancellationReason: 'Cancelled by guest' });
    expect((await guest.post(`/bookings/${booked.bookingId}/cancel`)).status()).toBe(422);
  });

  test('E2E-G04: a REQUESTED trip can be cancelled once', async ({ request }) => {
    const guest = guestApi(request, world.guestId);
    const trip = (await (await guest.post('/trips', {
      serviceId: world.transferId, type: 'ARRIVAL', airportCode: 'CUN',
      flight: { airline: 'AA', number: `AA ${world.tag.slice(-3)}`, scheduledAt: `${world.checkIn}T14:30` },
      passengers: 2, luggage: 2,
    })).json()).data;

    const cancelled = await guest.post(`/trips/${trip.id}/cancel`);
    const again = await guest.post(`/trips/${trip.id}/cancel`);

    expect(cancelled.status()).toBe(200);
    expect((await cancelled.json()).data).toMatchObject({ id: trip.id, status: 'CANCELLED' });
    expect(again.status()).toBe(422);
  });

  test('E2E-G05: a photo is uploaded as signed and shown inside the current thread', async ({ page, request }) => {
    const monitor = attachErrorMonitor(page);
    const guest = guestApi(request, world.guestId);
    const thread = (await (await guest.post('/concierge-requests', {
      type: 'ask', category: 'Resort Host chat', title: 'Message', details: `${world.tag} hello`,
    })).json()).data;
    const bytes = Buffer.from('ffd8ffe000104a46494600010100000100010000ffd9', 'hex');

    const ticket = (await (await guest.post('/concierge-requests/upload-url', {
      fileName: 'towel.jpg', contentType: 'image/jpeg', fileSizeBytes: bytes.length, requestId: thread.requestId,
    })).json()).data;
    expect(Object.keys(ticket).sort()).toEqual(['expiresAt', 'headers', 'maxBytes', 'method', 'storagePath', 'uploadUrl']);
    const upload = await request.fetch(ticket.uploadUrl, { method: ticket.method, headers: ticket.headers, data: bytes });
    expect(upload.ok()).toBe(true);
    const sent = await guest.post(`/concierge-requests/${thread.requestId}/messages`, { photoStoragePath: ticket.storagePath });

    expect(sent.status()).toBe(201);
    const photoUrl = (await sent.json()).data.messages.at(-1).photoUrl as string;
    expect(photoUrl).toMatch(/^https?:\/\//);
    expect((await request.get(photoUrl)).ok()).toBe(true);

    await page.goto(`${GUEST_URL}/?guestId=${world.guestId}`);
    await waitForFlutterSemantics(page, world.villaName);
    const host = await openTab(page, /Host/, 'Resort Host');
    expect(host).toContain(`${world.tag} hello`);
    expect(host).toContain('Photo');
    expect(await readSemanticsSnapshot(page)).not.toMatch(DEMO_MARKERS);
    expect(monitor.pageErrors).toEqual([]);
  });
});
