import { APIRequestContext, expect, Locator, Page, test } from '@playwright/test';
import * as fs from 'fs';
import * as path from 'path';
import { assertNoHorizontalOverflow, attachErrorMonitor, readSemanticsSnapshot, waitForFlutterSemantics } from './e2e-helpers';

/**
 * Phase 3 (plan v2): Settings and Villas end to end against the real backend
 * (Firestore + Storage emulators). Data created here stays in the emulator;
 * every name carries a per-run tag so runs never collide.
 */
const ADMIN_URL = process.env.E2E_ADMIN_URL ?? 'http://localhost:3002';
const API = process.env.E2E_API_BASE_URL ?? 'http://localhost:3011/api/v1';
const ADMIN_EMAIL = process.env.E2E_ADMIN_EMAIL ?? 'admin@kachava.local';
const EVIDENCE = path.resolve(__dirname, '../../doc/kachava-command-center/evidence');
const RUN = `P3${Date.now().toString(36).slice(-5).toUpperCase()}`;
const UI_VILLAS = [
  { name: `${RUN} Casa Ceiba`, category: 'Ocean view', capacity: '4' },
  { name: `${RUN} Casa Luna`, category: 'Garden', capacity: '2' },
  { name: `${RUN} Casa Sol`, category: 'Ocean view', capacity: '6' },
];
const BULK = 27; // 3 created in the UI + 27 via the API = 30 rows for this run

type Json = Record<string, any>;

async function shot(page: Page, name: string): Promise<void> {
  fs.mkdirSync(EVIDENCE, { recursive: true });
  await page.screenshot({ path: path.join(EVIDENCE, `phase-3-${name}.png`) });
}

async function adminApi(request: APIRequestContext) {
  const login = await request.post(`${API}/admin/auth/login`, { data: { email: ADMIN_EMAIL } });
  expect(login.ok()).toBe(true);
  const token = (await login.json()).data.token as string;
  const headers = { Authorization: `Bearer ${token}` };
  return {
    get: async (p: string): Promise<Json> => {
      const res = await request.get(`${API}/admin${p}`, { headers });
      expect(res.status(), p).toBe(200);
      return res.json();
    },
    post: async (p: string, data: Json): Promise<Json> => {
      const res = await request.post(`${API}/admin${p}`, { headers, data });
      expect(res.status(), p).toBe(201);
      return res.json();
    },
  };
}

/** Records every admin API response; removed endpoints must never be hit. */
function trackAdminApi(page: Page): Array<{ method: string; path: string; status: number }> {
  const hits: Array<{ method: string; path: string; status: number }> = [];
  page.on('response', (res) => {
    const url = res.url();
    if (!url.includes('/api/v1/admin/')) return;
    hits.push({
      method: res.request().method(),
      path: url.split('/api/v1/admin')[1].split('?')[0],
      status: res.status(),
    });
  });
  return hits;
}

async function openAdmin(page: Page): Promise<void> {
  await page.goto(ADMIN_URL);
  await waitForFlutterSemantics(page, 'Unread operational alerts');
}

const button = (page: Page, name: string | RegExp): Locator =>
  page.getByRole('button', { name, exact: typeof name === 'string' });

const field = (page: Page, label: string): Locator =>
  page.locator(`input[aria-label*="${label}"], textarea[aria-label*="${label}"]`).last();

/** Focus, wait for Flutter to attach the editor, then replace the text. */
async function typeInto(page: Page, target: Locator, text: string): Promise<void> {
  await expect(target).toBeVisible();
  await expect(async () => {
    await target.click();
    await page.waitForTimeout(250);
    await target.fill(text);
    await expect(target).toHaveValue(text, { timeout: 1000 });
  }).toPass({ timeout: 15000 });
}

/** Flutter web mirrors a field's text into the DOM only while focused. */
async function expectFieldValue(page: Page, target: Locator, value: string): Promise<void> {
  await target.click();
  await page.waitForTimeout(250);
  await expect(target).toHaveValue(value);
}

/** The list search box (its hint is its accessible name). */
const searchBox = (page: Page): Locator => page.getByRole('textbox', { name: 'Search' });

/** Top-bar gear (its tooltip can shadow the accessible name after a tap). */
const gear = (page: Page): Locator =>
  page.locator('flt-semantics[role="button"]').filter({ hasText: /^Settings/ }).first();

async function choose(page: Page, dropdown: RegExp, option: string): Promise<void> {
  await button(page, dropdown).last().click();
  await page.getByRole('menuitem', { name: option, exact: true }).click();
}

async function filterBy(page: Page, filter: string, option: string): Promise<void> {
  await page.getByRole('button', { name: new RegExp(`^${filter}`) }).first().click();
  await page.getByRole('menuitemcheckbox', { name: option, exact: true }).click();
}

/**
 * Taps at the element's center like a user does. Flutter hit-tests the tap;
 * a neighbouring chip's 48px semantics box can shadow the DOM hit check.
 */
async function tapCenter(page: Page, target: Locator): Promise<void> {
  const box = await target.boundingBox();
  expect(box).not.toBeNull();
  await page.mouse.click(box!.x + box!.width / 2, box!.y + box!.height / 2);
}

/** Right after a popup menu closes, Flutter web may spend the first tap on
 * restoring focus, so the tap is retried until the filters are gone. */
async function clearAllFilters(page: Page): Promise<void> {
  const clearAll = page.getByRole('button', { name: 'Clear all' });
  await expect(async () => {
    if ((await clearAll.count()) > 0) await tapCenter(page, clearAll);
    await expect(clearAll).toHaveCount(0, { timeout: 1500 });
  }).toPass({ timeout: 15000 });
}

/** Taps [target] until [expected] shows. The first tap after typing can be
 * spent on moving focus out of the text field, and a hover tooltip can then
 * shadow the button's name, so the position is read once. */
async function tapUntilText(page: Page, target: Locator, expected: string): Promise<void> {
  const box = await target.boundingBox();
  expect(box).not.toBeNull();
  await expect(async () => {
    const snapshot = await readSemanticsSnapshot(page);
    if (!snapshot.includes(expected)) {
      await page.mouse.click(box!.x + box!.width / 2, box!.y + box!.height / 2);
    }
    await waitForFlutterSemantics(page, expected, 1500);
  }).toPass({ timeout: 15000 });
}

async function expectText(page: Page, text: string): Promise<void> {
  await waitForFlutterSemantics(page, text, 15000);
}

async function searchVillas(page: Page, text: string): Promise<void> {
  await typeInto(page, searchBox(page), text);
}

async function openRow(page: Page, name: string): Promise<void> {
  await page.getByRole('button', { name: new RegExp(name) }).first().click();
  await expect(page.getByRole('group', { name, exact: true })).toBeVisible();
}

/** The searchable time zone field (its hint is its only label). */
const zoneField = (page: Page): Locator =>
  page
    .locator('input:not([aria-label*="Check-"]):not([aria-label*="Trip alert"]):not([aria-label="Search"])')
    .first();

async function configureSettings(page: Page): Promise<void> {
  await typeInto(page, field(page, 'Check-in'), '15:00');
  await typeInto(page, field(page, 'Check-out'), '11:00');
  const zone = zoneField(page);
  await zone.click();
  await page.waitForTimeout(250);
  await zone.fill('Cancun');
  await button(page, 'America/Cancun').click();
  await typeInto(page, field(page, 'Trip alert'), '24');
  const snapshot = await readSemanticsSnapshot(page);
  if (!snapshot.includes('CUN')) {
    await button(page, 'Add airport').first().click();
    await expectText(page, 'Code');
    await typeInto(page, field(page, 'Code'), 'CUN');
    await typeInto(page, field(page, 'Name'), 'Cancun International');
    await typeInto(page, field(page, 'Buffer'), '3');
    await button(page, 'Save').last().click();
    await expectText(page, 'Cancun International');
  }
}

async function createVillaInUi(page: Page, v: (typeof UI_VILLAS)[number], withWifi: boolean): Promise<void> {
  await button(page, 'New villa').first().click();
  await expect(page.getByRole('group', { name: 'New villa', exact: true })).toBeVisible();
  await typeInto(page, field(page, 'Name'), v.name);
  await typeInto(page, field(page, 'Category'), v.category);
  await typeInto(page, field(page, 'Capacity'), v.capacity);
  if (withWifi) {
    await button(page, 'More').click();
    await page.waitForTimeout(400); // expansion animation
    await typeInto(page, field(page, 'Wi-Fi network'), `${RUN}-guest`);
    const password = field(page, 'Wi-Fi password');
    await typeInto(page, password, 'sunrise-2026');
    await expect(password).toHaveAttribute('type', 'password');
    await button(page, 'Show password').click();
    await expect(password).not.toHaveAttribute('type', 'password');
  }
  await button(page, 'Save').last().click();
  await expectText(page, 'Villa saved');
  await expect(page.getByRole('group', { name: 'New villa', exact: true })).toHaveCount(0);
}

test.describe('Phase 3 — Settings and Villas (admin http://localhost:3002)', () => {
  test('E2E-P3-01: configure Settings, create/edit/deactivate villas, search/filter/page, reload persists (1440)', async ({
    page,
    request,
  }) => {
    test.setTimeout(240000);
    await page.setViewportSize({ width: 1440, height: 900 });
    const monitor = attachErrorMonitor(page);
    const hits = trackAdminApi(page);
    const api = await adminApi(request);

    // Load with no errors against the backend.
    await openAdmin(page);
    const settingsBefore = (await api.get('/settings')).data;
    if (settingsBefore.timeZone === null) {
      await expectText(page, 'Time zone not set');
      await shot(page, 'dashboard-setup-link-1440');
      await button(page, 'Set up in Settings').click();
    } else {
      await gear(page).click();
    }

    // Settings: one form, "Not set" for empty values, Save + one-line toast.
    await expectText(page, 'Airports');
    if (settingsBefore.checkInTime === null) await shot(page, 'settings-empty-1440');
    await configureSettings(page);
    await button(page, 'Save').click();
    await expectText(page, 'Settings saved');
    await shot(page, 'settings-1440');
    const settings = (await api.get('/settings')).data;
    expect(settings).toMatchObject({
      checkInTime: '15:00',
      checkOutTime: '11:00',
      timeZone: 'America/Cancun',
      transportAlertLeadHours: 24,
    });
    expect(settings.airports).toEqual(
      expect.arrayContaining([expect.objectContaining({ code: 'CUN', departureBufferHours: 3 })]),
    );

    // Villas: empty state on a fresh database, then 3 villas through the UI.
    await button(page, 'Villas').click();
    await expectText(page, 'Inventory, status and housekeeping per villa.');
    const villasBefore = await api.get('/villas?pageSize=1');
    if (villasBefore.meta.total === 0) {
      await expectText(page, 'No villas yet');
      await shot(page, 'villas-empty-1440');
    }
    for (const [i, v] of UI_VILLAS.entries()) await createVillaInUi(page, v, i === 0);

    // Edit one villa.
    await searchVillas(page, RUN);
    await openRow(page, UI_VILLAS[1].name);
    await typeInto(page, field(page, 'Capacity'), '3');
    await choose(page, /^Housekeeping/, 'Needs cleaning');
    await button(page, 'Save').last().click();
    await expectText(page, 'Villa saved');

    // Deactivate one villa (⋮ > Deactivate, one-line confirm).
    await openRow(page, UI_VILLAS[2].name);
    await button(page, 'Actions').click();
    await page.getByRole('menuitem', { name: 'Deactivate' }).click();
    await expectText(page, `Deactivate ${UI_VILLAS[2].name}?`);
    await button(page, 'Deactivate').last().click();
    await expectText(page, 'Villa deactivated');

    // Bulk villas so this run alone needs pagination (30 rows).
    for (let i = 1; i <= BULK; i += 1) {
      await api.post('/villas', {
        name: `${RUN} Bulk ${String(i).padStart(2, '0')}`,
        category: i % 3 === 0 ? 'Garden' : 'Ocean view',
        capacity: 2 + (i % 5),
        operationalStatus: i % 9 === 0 ? 'BLOCKED' : 'AVAILABLE',
        housekeepingStatus: i % 2 === 0 ? 'DIRTY' : 'CLEAN',
        maintenanceStatus: 'OK',
      });
    }

    // Search + pagination (25 per page).
    await page.reload();
    await waitForFlutterSemantics(page, 'Unread operational alerts');
    await button(page, 'Villas').click();
    await searchVillas(page, RUN);
    await expectText(page, '1–25 of 30');
    await shot(page, 'villas-1440');
    await tapUntilText(page, button(page, 'Next page'), '26–30 of 30');
    await tapUntilText(page, button(page, 'Previous page'), '1–25 of 30');

    // Filters: status, category, active.
    await filterBy(page, 'Status', 'Blocked');
    await expectText(page, '1–3 of 3');
    await clearAllFilters(page);
    await searchVillas(page, RUN);
    await filterBy(page, 'Category', 'Garden');
    await expectText(page, '1–10 of 10');
    await filterBy(page, 'Category', 'Ocean view');
    await expectText(page, '1–20 of 20');
    await filterBy(page, 'Active', 'No');
    await expectText(page, '1–1 of 1');
    await expectText(page, UI_VILLAS[2].name);
    await shot(page, 'villas-filtered-1440');
    await clearAllFilters(page);

    // Sort by name: descending puts "Casa Sol" before the bulk rows.
    await searchVillas(page, RUN);
    await page.getByRole('button', { name: 'Name, sorted ascending' }).click();
    await expect(page.getByRole('button', { name: 'Name, sorted descending' })).toBeVisible();
    await expect(page.getByRole('button', { name: new RegExp(`^${RUN} `) }).first()).toContainText(
      `${RUN} Casa Sol`,
    );

    // Reload: everything came from the server and persisted.
    await page.reload();
    await waitForFlutterSemantics(page, 'Unread operational alerts');
    await button(page, 'Villas').click();
    await searchVillas(page, RUN);
    await expectText(page, '1–25 of 30');
    await searchVillas(page, UI_VILLAS[1].name);
    await expectText(page, '1–1 of 1');
    await openRow(page, UI_VILLAS[1].name);
    await expectFieldValue(page, field(page, 'Capacity'), '3');
    await expect(button(page, /^Housekeeping/).last()).toContainText('Needs cleaning');
    await shot(page, 'villa-detail-1440');
    await button(page, 'Close').click();
    await searchVillas(page, UI_VILLAS[0].name);
    await expectText(page, '1–1 of 1');
    await openRow(page, UI_VILLAS[0].name);
    await button(page, 'More').click();
    await page.waitForTimeout(400); // expansion animation
    await expectFieldValue(page, field(page, 'Wi-Fi network'), `${RUN}-guest`);
    await expect(field(page, 'Wi-Fi password')).toHaveAttribute('type', 'password');
    await button(page, 'Close').click();
    const persisted = (await api.get(`/villas?q=${RUN}&pageSize=50`)).data as Json[];
    expect(persisted).toHaveLength(30);
    const byName = Object.fromEntries(persisted.map((v) => [v.name, v]));
    expect(byName[UI_VILLAS[0].name]).toMatchObject({ category: 'Ocean view', capacity: 4, wifi: { ssid: `${RUN}-guest`, password: 'sunrise-2026' } });
    expect(byName[UI_VILLAS[1].name]).toMatchObject({ capacity: 3, housekeepingStatus: 'DIRTY', isActive: true });
    expect(byName[UI_VILLAS[2].name]).toMatchObject({ isActive: false });

    await gear(page).click();
    await expectFieldValue(page, field(page, 'Check-in'), '15:00');
    await expectFieldValue(page, field(page, 'Check-out'), '11:00');
    await expectFieldValue(page, field(page, 'Trip alert'), '24');
    await expectFieldValue(page, zoneField(page), 'America/Cancun');
    await page.keyboard.press('Escape');
    await button(page, 'Dashboard').click();
    await expect(button(page, 'Set up in Settings')).toHaveCount(0);

    // Nothing hit a removed endpoint and nothing failed.
    expect(hits.filter((h) => h.path.startsWith('/catalog/') || h.path === '/reset')).toEqual([]);
    expect(hits.filter((h) => h.status >= 400)).toEqual([]);
    expect(hits.filter((h) => h.path === '/sync').every((h) => h.status === 200)).toBe(true);
    await assertNoHorizontalOverflow(page);
    expect([...monitor.pageErrors, ...monitor.consoleErrors, ...monitor.overflowErrors]).toEqual([]);
  });

  test('E2E-P3-02: mobile 375 — villas list, full-screen detail and settings', async ({ page }) => {
    await page.setViewportSize({ width: 375, height: 812 });
    const monitor = attachErrorMonitor(page);
    const hits = trackAdminApi(page);
    await openAdmin(page);

    await button(page, 'Menu').click();
    await button(page, 'Villas').click();
    await expectText(page, 'Villas');
    await button(page, 'Search').click();
    await typeInto(page, searchBox(page), 'Casa');
    await expectText(page, 'Casa');
    await assertNoHorizontalOverflow(page);
    await shot(page, 'villas-375');

    await page.getByRole('button', { name: /Casa Luna/ }).first().click();
    await expect(field(page, 'Capacity')).toBeVisible();
    // Full-screen sheet: wait until it finished sliding up over the list.
    await expect
      .poll(async () => (await button(page, 'Close').boundingBox())?.y ?? 999)
      .toBeLessThan(24);
    await page.waitForTimeout(300);
    await assertNoHorizontalOverflow(page);
    await shot(page, 'villa-detail-375');
    await button(page, 'Close').click();

    await gear(page).click();
    await expectText(page, 'Airports');
    await assertNoHorizontalOverflow(page);
    await shot(page, 'settings-375');

    expect(hits.filter((h) => h.status >= 400)).toEqual([]);
    expect([...monitor.pageErrors, ...monitor.consoleErrors, ...monitor.overflowErrors]).toEqual([]);
  });
});
