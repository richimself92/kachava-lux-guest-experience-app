import { expect, test } from '@playwright/test';
import {
  ADMIN_STAFF_EMAIL,
  API_BASE_URL,
  attachErrorMonitor,
  captureDualScreenshot,
  clickSemanticsByText,
  fillSemanticsTextField,
  findAdminStayByGuest,
  GUEST_PORTAL_URL,
  prepareFreeVilla,
  readSemanticsSnapshot,
  openAdminDashboard,
  waitForAdminSyncCycles,
  submitNewStayDialog,
  waitForFlutterSemantics,
} from './e2e-helpers';

const SOAK_MS = 5 * 60 * 1000;
const FICTIONAL_GUEST = 'Alex & Sarah';

// Hyphenated on purpose: the admin app sends the villa display name as `villaId`, and the
// backend rejects names with spaces (see E2E-PA06 for the defect itself).
function uniqueVilla(): { id: string; name: string } {
  const n = String(Date.now()).slice(-4);
  return { id: `Villa-${n}`, name: `Villa-${n}` };
}

test.describe('Phase A: guest magic link reliability', () => {
  test('E2E-PA01: admin creates a stay, copies the link, guest sees the right data for 5 minutes of polling', async ({
    browser,
  }) => {
    test.setTimeout(SOAK_MS + 180000);
    // Arrange
    const context = await browser.newContext({
      viewport: { width: 1440, height: 900 },
      permissions: ['clipboard-read', 'clipboard-write'],
    });
    const adminPage = await context.newPage();
    const guestPage = await context.newPage();
    await guestPage.setViewportSize({ width: 430, height: 932 });
    const guestMon = attachErrorMonitor(guestPage);
    const villa = uniqueVilla();
    const guestName = `Marisol Quintana ${villa.name.slice(-4)}`;
    await openAdminDashboard(adminPage);
    await prepareFreeVilla(adminPage, villa.id, villa.name);
    // Act 1 — create through the admin UI, filter the list to the new card and copy its link
    await submitNewStayDialog(adminPage, villa.name, guestName);
    await waitForFlutterSemantics(adminPage, guestName);
    const stay = await findAdminStayByGuest(adminPage, guestName);
    expect(stay).not.toBeNull();
    expect(await fillSemanticsTextField(adminPage, 'Search guest', guestName)).toBe(true);
    const cardSemantics = await waitForFlutterSemantics(adminPage, 'Copy Magic Link');
    expect(cardSemantics).toContain(stay!.magicLinkUrl);
    expect(await clickSemanticsByText(adminPage, 'Copy Magic Link')).toBe(true);
    await expect.poll(() => adminPage.evaluate(() => navigator.clipboard.readText())).toBe(stay!.magicLinkUrl);
    const copiedLink = await adminPage.evaluate(() => navigator.clipboard.readText());
    await captureDualScreenshot(adminPage, 'e2e-pa01-admin-created-stay.png');
    // Act 2 — open the copied link in the guest portal; first paint is the loading screen, not the Miller data
    const stayGets: number[] = [];
    guestPage.on('response', (res) => {
      if (res.request().method() === 'GET' && res.url().includes(`/api/v1/stays/${stay!.guestUuid}`)) {
        stayGets.push(res.status());
      }
    });
    await guestPage.goto(copiedLink);
    const home = await waitForFlutterSemantics(guestPage, guestName);
    // Assert — correct guest/villa, nothing from the fictional Miller stay
    expect(home.toUpperCase()).toContain(villa.name.toUpperCase());
    expect(home).not.toContain(FICTIONAL_GUEST);
    expect(home).not.toContain('Miller');
    expect(home).not.toContain('Access Restricted');
    await captureDualScreenshot(guestPage, 'e2e-pa01-guest-home.png');
    // Soak — keep the page open; every poll cycle (10s) must stay 200 and keep the same guest
    const started = Date.now();
    let cycles = 0;
    while (Date.now() - started < SOAK_MS) {
      await guestPage.waitForResponse(
        (res) => res.request().method() === 'GET' && res.url().includes(`/api/v1/stays/${stay!.guestUuid}`),
        { timeout: 30000 },
      );
      cycles += 1;
      const snap = await readSemanticsSnapshot(guestPage);
      expect(snap).toContain(guestName);
      expect(snap).not.toContain('Access Restricted');
      expect(snap).not.toContain(FICTIONAL_GUEST);
    }
    expect(cycles).toBeGreaterThanOrEqual(25);
    expect(stayGets.length).toBeGreaterThanOrEqual(25);
    expect(stayGets.every((status) => status === 200)).toBe(true);
    expect([...guestMon.pageErrors, ...guestMon.consoleErrors, ...guestMon.overflowErrors]).toEqual([]);
    await captureDualScreenshot(guestPage, 'e2e-pa01-guest-after-5min.png');
    await context.close();
  });

  test('E2E-PA02: unknown guestId shows Access Restricted (404)', async ({ page }) => {
    // Arrange
    const unknown = '00000000-0000-4000-8000-00000000dead';
    const statuses: number[] = [];
    page.on('response', (res) => {
      if (res.url().includes(`/api/v1/stays/${unknown}`)) statuses.push(res.status());
    });
    // Act
    await page.goto(`${GUEST_PORTAL_URL}/?guestId=${unknown}`);
    const snap = await waitForFlutterSemantics(page, 'Access Restricted');
    // Assert
    expect(statuses[0]).toBe(404);
    expect(snap).not.toContain(FICTIONAL_GUEST);
    expect(snap).not.toContain('Reconnecting');
    await captureDualScreenshot(page, 'e2e-pa02-access-restricted.png');
  });

  test('E2E-PA03: guest shows a loading screen first, never the fictional Miller data', async ({ page }) => {
    // Arrange — hold the first stay GET so the pre-response frame can be observed
    let release: () => void = () => undefined;
    const gate = new Promise<void>((resolve) => { release = resolve; });
    await page.route('**/api/v1/stays/*', async (route) => {
      if (route.request().method() === 'GET') await gate;
      await route.continue();
    });
    const created = await createApiStay(page);
    // Act
    await page.goto(`${GUEST_PORTAL_URL}/?guestId=${created.guestUuid}`);
    const loading = await waitForFlutterSemantics(page, 'Preparing your sanctuary');
    // Assert
    expect(loading).not.toContain(FICTIONAL_GUEST);
    expect(loading).not.toContain('Villa 102');
    expect(loading).not.toContain('Access Restricted');
    release();
    const loaded = await waitForFlutterSemantics(page, created.guestName);
    expect(loaded).not.toContain(FICTIONAL_GUEST);
  });

  test('E2E-PA04: HTTP 503 on the stay GET keeps last data and shows Reconnecting', async ({ page }) => {
    // Arrange — load a real stay first
    const created = await createApiStay(page);
    await page.goto(`${GUEST_PORTAL_URL}/?guestId=${created.guestUuid}`);
    await waitForFlutterSemantics(page, created.guestName);
    // Act — the backend starts answering 503
    let blocked = true;
    await page.route(`**/api/v1/stays/${created.guestUuid}`, async (route) => {
      if (route.request().method() === 'GET' && blocked) {
        await route.fulfill({ status: 503, contentType: 'application/json', body: '{"success":false}' });
      } else {
        await route.continue();
      }
    });
    // Assert — last data kept, not Access Restricted
    const degraded = await waitForFlutterSemantics(page, 'Reconnecting', 30000);
    expect(degraded).toContain(created.guestName);
    expect(degraded).not.toContain('Access Restricted');
    await captureDualScreenshot(page, 'e2e-pa04-reconnecting.png');
    // Recovery — once the backend answers again the indicator disappears
    blocked = false;
    await expect
      .poll(async () => await readSemanticsSnapshot(page), { timeout: 30000, intervals: [1000] })
      .not.toContain('Reconnecting');
    expect(await readSemanticsSnapshot(page)).toContain(created.guestName);
  });

  test('E2E-PA05: admin create-stay failure (HTTP 500) shows an error and generates no link', async ({ page }) => {
    // Arrange
    await page.setViewportSize({ width: 1440, height: 900 });
    const villa = uniqueVilla();
    const guestName = `Failing Create ${villa.name.slice(-4)}`;
    await openAdminDashboard(page);
    await prepareFreeVilla(page, villa.id, villa.name);
    await page.route('**/api/v1/admin/stays', async (route) => {
      if (route.request().method() === 'POST') {
        await route.fulfill({ status: 500, contentType: 'application/json', body: '{"success":false}' });
      } else {
        await route.continue();
      }
    });
    // Act
    await submitNewStayDialog(page, villa.name, guestName);
    // Assert — error toast, no card, no link, nothing stored on the server
    const snap = await waitForFlutterSemantics(page, 'Stay not created');
    expect(snap).toContain('No link was generated');
    expect(snap).not.toContain('Stay created');
    expect(snap).not.toContain(guestName);
    await page.unroute('**/api/v1/admin/stays');
    expect(await findAdminStayByGuest(page, guestName)).toBeNull();
    await captureDualScreenshot(page, 'e2e-pa05-create-failure.png');
  });
});

test('E2E-PA06: admin UI creates a stay for a standard "Villa NNN" villa name (regression: villaId with space)', async ({ page }) => {
  // Arrange — a known villa whose display name has a space, as every real villa does
  await page.setViewportSize({ width: 1440, height: 900 });
  const n = String(Date.now()).slice(-4);
  const guestName = `Space Villa ${n}`;
  await openAdminDashboard(page);
  await prepareFreeVilla(page, `villa-${n}`, `Villa ${n}`);
  const creates: number[] = [];
  page.on('response', (res) => {
    if (res.request().method() === 'POST' && res.url().endsWith('/api/v1/admin/stays')) creates.push(res.status());
  });
  // Act
  await submitNewStayDialog(page, `Villa ${n}`, guestName);
  await waitForAdminSyncCycles(page, 2);
  // Assert — the server must accept the create and the stay must exist
  expect(creates).toEqual([201]);
  expect(await findAdminStayByGuest(page, guestName)).not.toBeNull();
});

async function createApiStay(page: import('@playwright/test').Page): Promise<{ guestUuid: string; guestName: string }> {
  const villa = uniqueVilla();
  const guestName = `Ines Valdivia ${villa.name.slice(-4)}`;
  const login = await page.request.post(`${API_BASE_URL}/admin/auth/login`, { data: { email: ADMIN_STAFF_EMAIL } });
  const token = (await login.json()).data.token as string;
  const res = await page.request.post(`${API_BASE_URL}/admin/stays`, {
    data: { guestName, villaId: villa.id, villaName: villa.name, nights: 3, guestsCount: 2 },
    headers: { Authorization: `Bearer ${token}` },
  });
  expect(res.status()).toBe(201);
  const stay = (await res.json()).data.stay as Record<string, unknown>;
  return { guestUuid: stay.guestTokenUuid as string, guestName };
}
