import { expect, test } from '@playwright/test';
import { attachErrorMonitor, readSemanticsSnapshot, waitForFlutterSemantics } from './e2e-helpers';
import {
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
const SOAK_MS = 2 * 60 * 1000;
const POLL_MS = 30_000;

test.describe('Phase A: guest magic link reliability', () => {
  test.describe.configure({ mode: 'serial' });
  let world: GuestWorld;

  test.beforeAll(async ({ request }) => {
    world = await prepareGuestWorld(request, 'PA');
  });

  test('E2E-PA01: the link opens the right stay with server data only, and keeps it while polling', async ({ page, request }) => {
    test.setTimeout(SOAK_MS + 120_000);
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
    expect(home).toContain(`${world.tag} Villa stocking`);
    expect(home).not.toMatch(DEMO_MARKERS);
    expect(home).not.toContain('Ask your Resort Host');

    // Soak: every poll (30 s) answers 200 and keeps the same stay on screen.
    const started = Date.now();
    while (Date.now() - started < SOAK_MS) {
      await page.waitForResponse(
        (res) => res.request().method() === 'GET' && res.url().endsWith(STAY_PATH(world.guestId)),
        { timeout: POLL_MS + 15_000 },
      );
      const snap = await readSemanticsSnapshot(page);
      expect(snap).toContain(world.villaName);
      expect(snap).not.toMatch(DEMO_MARKERS);
    }
    expect(statuses.length).toBeGreaterThanOrEqual(Math.floor(SOAK_MS / POLL_MS));
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

    // The next poll fails: same villa on screen, no expired-link screen.
    const degraded = await waitForFlutterSemantics(page, 'Reconnecting', POLL_MS + 15_000);
    expect(degraded).toContain(world.villaName);
    expect(degraded).not.toContain('Ask your Resort Host');

    blocked = false;
    await expect
      .poll(() => readSemanticsSnapshot(page), { timeout: POLL_MS + 15_000, intervals: [1000] })
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

  test('E2E-PA06: a link the server rejects (401) ends the session on its next poll', async ({ page }) => {
    await page.goto(`${GUEST_URL}/?guestId=${world.guestId}`);
    await waitForFlutterSemantics(page, world.villaName);

    await page.route(`**${STAY_PATH(world.guestId)}`, (route) =>
      route.fulfill({ status: 401, contentType: 'application/json', body: '{"success":false,"statusCode":401}' }));

    await waitForFlutterSemantics(page, 'Ask your Resort Host for a new one', POLL_MS + 15_000);
    expect(await readSemanticsSnapshot(page)).not.toContain(world.villaName);
  });
});
