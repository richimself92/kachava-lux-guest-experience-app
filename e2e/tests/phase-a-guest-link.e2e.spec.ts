import { expect, Page, test } from '@playwright/test';
import { attachErrorMonitor, readSemanticsSnapshot, waitForFlutterSemantics } from './e2e-helpers';
import {
  adminApi,
  API,
  DEMO_MARKERS,
  GUEST_URL,
  guestApi,
  GuestWorld,
  prepareGuestWorld,
  UNKNOWN_GUEST_ID,
} from './guest-world';

/**
 * Phase A guarantees of the guest magic link on the guided portal (`web/`): the link opens the
 * right stay with real data only, a bad or expired link shows the "ask your Resort Host" screen,
 * transient failures keep the last data ("Reconnecting…") and the link is remembered on the
 * device. Everything is created through the admin API (no seeds); the stay is upcoming.
 */
const STAY_PATH = (guestId: string) => `/api/v1/stays/${guestId}`;
/** No polling (ADR-012): a quiet window long enough to catch the old 30 s poll. */
const QUIET_MS = 40_000;
const PUSH_MS = 10_000;

/** The app-bar Refresh button: the only manual way to re-read the stay. */
const tapRefresh = (page: Page) => page.getByRole('button', { name: 'Refresh' }).last().click();

test.describe('Phase A: guest magic link reliability', () => {
  test.describe.configure({ mode: 'serial' });
  let world: GuestWorld;

  test.beforeAll(async ({ request }) => {
    world = await prepareGuestWorld(request, 'PA');
  });

  test('E2E-PA01: the link opens the right stay with server data only; no polling, server changes push a refresh', async ({ page, request }) => {
    test.setTimeout(QUIET_MS + 120_000);
    const monitor = attachErrorMonitor(page);
    const statuses: number[] = [];
    page.on('response', (res) => {
      if (res.request().method() === 'GET' && res.url().endsWith(STAY_PATH(world.guestId))) statuses.push(res.status());
    });
    await page.setViewportSize({ width: 390, height: 844 });

    await page.goto(`${GUEST_URL}/?guestId=${world.guestId}`);
    const home = await waitForFlutterSemantics(page, world.villaName);

    // Same stay as the server holds: villa, dates and the numbered journey of its catalog.
    const stay = (await (await guestApi(request, world.guestId).get()).json()).data;
    expect(stay.guestProfile.name).toBe(world.guestName);
    expect(stay).toMatchObject({ checkInDate: world.checkIn, checkOutDate: world.checkOut });
    expect(home).toContain(stay.stayDatesLabel);
    expect(home).toContain('Before arrival');
    expect(home).toContain('1.3 In villa'); // the catalog's in-villa services group, never a hardcoded list
    expect(home).not.toMatch(DEMO_MARKERS);
    expect(home).not.toContain('Ask your Resort Host');

    // Quiet: nothing changes on the server, so the portal makes no request at all.
    await page.waitForTimeout(2_000);
    const settled = statuses.length;
    await page.waitForTimeout(QUIET_MS);
    expect(statuses.length, 'no polling while nothing changes').toBe(settled);

    // A server-side change for this stay pushes a re-read (Firestore signal → REST).
    const api = await adminApi(request);
    const found = (await api.get(`/stays?q=${encodeURIComponent(world.guestName)}`)).data[0];
    await api.patch(`/stays/${found.stayId ?? found.id}`, { internalNotes: `${world.tag} pushed` });
    await expect.poll(() => statuses.length, { timeout: PUSH_MS }).toBeGreaterThan(settled);
    const snap = await readSemanticsSnapshot(page);
    expect(snap).toContain(world.villaName);
    expect(snap).not.toMatch(DEMO_MARKERS);
    expect(snap).not.toContain(`${world.tag} pushed`); // internal notes never reach the guest
    expect(statuses.every((status) => status === 200)).toBe(true);
    expect([...monitor.pageErrors, ...monitor.overflowErrors]).toEqual([]);
  });

  test('E2E-PA02: an unknown link shows the expired-link screen, never data', async ({ page }) => {
    const statuses: number[] = [];
    page.on('response', (res) => {
      if (res.url().endsWith(STAY_PATH(UNKNOWN_GUEST_ID))) statuses.push(res.status());
    });

    await page.goto(`${GUEST_URL}/?guestId=${UNKNOWN_GUEST_ID}`);
    const snap = await waitForFlutterSemantics(page, 'Ask your Resort Host for a new one');

    expect([401, 404]).toContain(statuses[0]);
    expect(snap).not.toContain('Reconnecting');
    expect(snap).not.toMatch(DEMO_MARKERS);
  });

  test('E2E-PA02b: a malformed link is reported without calling the API', async ({ page }) => {
    const calls: string[] = [];
    page.on('request', (req) => {
      if (req.url().startsWith(`${API}/stays/`)) calls.push(req.url());
    });

    await page.goto(`${GUEST_URL}/?guestId=not-a-guest-id`);
    await waitForFlutterSemantics(page, 'This link is not valid');

    expect(calls).toEqual([]);
  });

  test('E2E-PA03: the first frame is a loading skeleton, never demo data', async ({ page }) => {
    let release: () => void = () => undefined;
    const gate = new Promise<void>((resolve) => { release = resolve; });
    await page.route(`**${STAY_PATH(world.guestId)}`, async (route) => {
      if (route.request().method() === 'GET') await gate;
      await route.continue();
    });

    await page.goto(`${GUEST_URL}/?guestId=${world.guestId}`);
    const loading = await waitForFlutterSemantics(page, 'Loading');

    expect(loading).not.toMatch(DEMO_MARKERS);
    expect(loading).not.toContain(world.villaName);
    release();
    await waitForFlutterSemantics(page, world.villaName);
  });

  test('E2E-PA04: HTTP 503 keeps the last data and shows Reconnecting', async ({ page }) => {
    await page.goto(`${GUEST_URL}/?guestId=${world.guestId}`);
    await waitForFlutterSemantics(page, world.villaName);
    let blocked = true;
    await page.route(`**${STAY_PATH(world.guestId)}`, async (route) => {
      if (route.request().method() === 'GET' && blocked) {
        await route.fulfill({ status: 503, contentType: 'application/json', body: '{"success":false}' });
      } else {
        await route.continue();
      }
    });

    // The next read fails: same villa on screen, no expired-link screen.
    await tapRefresh(page);
    const degraded = await waitForFlutterSemantics(page, 'Reconnecting', PUSH_MS);
    expect(degraded).toContain(world.villaName);
    expect(degraded).not.toContain('Ask your Resort Host');

    blocked = false;
    await tapRefresh(page);
    await expect
      .poll(() => readSemanticsSnapshot(page), { timeout: PUSH_MS, intervals: [500] })
      .not.toContain('Reconnecting');
  });

  test('E2E-PA05: the link is remembered: reopening the bare portal shows the same stay', async ({ page }) => {
    await page.goto(`${GUEST_URL}/?guestId=${world.guestId}`);
    await waitForFlutterSemantics(page, world.villaName);

    await page.goto(`${GUEST_URL}/`);
    const reopened = await waitForFlutterSemantics(page, world.villaName);

    expect(reopened).not.toContain('Open the link from your Resort Host');
    expect(await page.evaluate(() => JSON.stringify(window.localStorage))).toContain(world.guestId);
  });

  test('E2E-PA06: a link the server rejects (401) ends the session on its next read', async ({ page }) => {
    await page.goto(`${GUEST_URL}/?guestId=${world.guestId}`);
    await waitForFlutterSemantics(page, world.villaName);

    await page.route(`**${STAY_PATH(world.guestId)}`, (route) =>
      route.fulfill({ status: 401, contentType: 'application/json', body: '{"success":false,"statusCode":401}' }));

    await tapRefresh(page);
    await waitForFlutterSemantics(page, 'Ask your Resort Host for a new one', PUSH_MS);
    expect(await readSemanticsSnapshot(page)).not.toContain(world.villaName);
  });
});
