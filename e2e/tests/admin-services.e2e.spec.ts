import { APIRequestContext, expect, Page, test } from '@playwright/test';
import * as fs from 'fs';
import * as path from 'path';
import {
  ADMIN_DASHBOARD_URL,
  API_BASE_URL,
  assertNoHorizontalOverflow,
  attachErrorMonitor,
  captureDualScreenshot,
  readSemanticsSnapshot,
  waitForFlutterSemantics,
} from './e2e-helpers';

/**
 * Phase 4 — Services catalog (admin). Creates one service of every kind through the UI with an
 * uploaded cover (PNG fixture), adds and activates items, checks the 422 activation rule, filters,
 * paginates and reloads to prove persistence. Requires `run-local.sh` (Firestore + Storage emulators).
 * Names carry a unique run tag because the emulator data persists between runs.
 */
const ADMIN_EMAIL = process.env.E2E_ADMIN_EMAIL ?? 'admin@kachava.local';
const COVER = path.resolve(__dirname, '../fixtures/service-cover.png');
const RUN = `e2e${Date.now().toString(36)}`;

interface KindSpec {
  wire: string;
  label: string;
  section: string;
  /** `null`: the kind has no items list in the editor (experiences). */
  itemPrice: string | null;
  capacity?: boolean;
}

const KINDS: KindSpec[] = [
  { wire: 'EXPERIENCE', label: 'Experience', section: 'EXPERIENCES', itemPrice: null },
  { wire: 'BAR', label: 'Lux bar', section: 'DINING', itemPrice: '14.5' },
  { wire: 'BREAKFAST', label: 'Breakfast', section: 'DINING', itemPrice: '18' },
  { wire: 'SPECIAL_MENU', label: 'Special menu', section: 'DINING', itemPrice: '120' },
  { wire: 'VILLA_STOCKING', label: 'Villa stocking', section: 'IN_VILLA', itemPrice: '9.5' },
  { wire: 'WELLNESS', label: 'Wellness', section: 'WELLNESS', itemPrice: '150' },
  { wire: 'PREFERENCE', label: 'Preference', section: 'IN_VILLA', itemPrice: '0' },
  { wire: 'TRANSPORT', label: 'Transport', section: 'TRANSPORTATION', itemPrice: '95', capacity: true },
];
const EXTRA_SERVICES = 20; // 8 + 20 = 28 rows -> two pages of 25

// ---------- DOM helpers (Flutter web semantics) ----------

type Box = { x: number; y: number };

/** Center of the first visible semantics node matching [selector] and exact [label] (top-most first). */
async function centerOf(page: Page, selector: string, label?: string): Promise<Box | null> {
  return page.evaluate(
    ({ sel, text }) => {
      const hits: Array<{ x: number; y: number; top: number }> = [];
      const visit = (root: Document | ShadowRoot) => {
        root.querySelectorAll(sel).forEach((el) => {
          const name = (el.getAttribute('aria-label') || (el as HTMLElement).innerText || '').trim();
          const r = el.getBoundingClientRect();
          const visible = r.width > 2 && r.height > 2 && r.bottom > 0 && r.top < window.innerHeight;
          if (visible && (text === undefined || name === text)) {
            hits.push({ x: r.left + r.width / 2, y: r.top + r.height / 2, top: r.top });
          }
        });
        root.querySelectorAll('*').forEach((el) => el.shadowRoot && visit(el.shadowRoot));
      };
      visit(document);
      hits.sort((a, b) => a.top - b.top);
      return hits[0] ? { x: hits[0].x, y: hits[0].y } : null;
    },
    { sel: selector, text: label },
  );
}

async function clickWhenReady(page: Page, selector: string, label?: string, timeoutMs = 15000): Promise<void> {
  // Click only once the node stopped moving: closing a side panel re-flows the list, and a click
  // at the position of the previous frame lands on nothing.
  let previous: Box | null = null;
  let box: Box | null = null;
  await expect
    .poll(
      async () => {
        box = await centerOf(page, selector, label);
        const stable = box !== null && previous !== null && box.x === previous.x && box.y === previous.y;
        previous = box;
        return stable;
      },
      { timeout: timeoutMs, intervals: [50, 100, 100, 250] },
    )
    .toBe(true);
  await page.mouse.click(box!.x, box!.y);
}

const byId = (id: string) => `[flt-semantics-identifier="${id}"]`;

/**
 * Clicks the smallest visible node of [selector] whose name contains [text]. Table rows may expose
 * one merged label (every cell), so rows are matched by containment, never by exact text.
 */
async function clickContaining(page: Page, selector: string, text: string, timeoutMs = 15000): Promise<void> {
  let box: Box | null = null;
  const find = () =>
    page.evaluate(
      ({ sel, needle }) => {
        let best: { x: number; y: number; area: number } | null = null;
        const visit = (root: Document | ShadowRoot) => {
          root.querySelectorAll(sel).forEach((el) => {
            const name = `${el.getAttribute('aria-label') || ''} ${(el as HTMLElement).innerText || ''}`;
            const r = el.getBoundingClientRect();
            const visible = r.width > 2 && r.height > 2 && r.bottom > 0 && r.top < window.innerHeight;
            if (visible && name.includes(needle) && (!best || r.width * r.height < best.area)) {
              best = { x: r.left + r.width / 2, y: r.top + r.height / 2, area: r.width * r.height };
            }
          });
          root.querySelectorAll('*').forEach((el) => el.shadowRoot && visit(el.shadowRoot));
        };
        visit(document);
        return best as { x: number; y: number } | null;
      },
      { sel: selector, needle: text },
    );
  await expect.poll(async () => (box = await find()) !== null, { timeout: timeoutMs }).toBe(true);
  await page.mouse.click(box!.x, box!.y);
}
/** Material buttons have role=button; InkWell-based controls (filter chips) are only tappable. */
const TAPPABLE = '[role="button"], [flt-tappable]';
/** Table rows are InkWells: tappable semantics nodes. */
const ROW = '[flt-tappable], [role="button"]';
const clickButton = (page: Page, label: string) => clickWhenReady(page, TAPPABLE, label);

/** Wheel-scrolls the editor panel until a [selector] node labelled [label] is fully on screen:
 * the editor is one long scrolling form, and Flutter only hit-tests what is painted. */
async function scrollPanelTo(page: Page, selector: string, label: string): Promise<void> {
  const viewport = page.viewportSize()!;
  for (let i = 0; i < 30; i++) {
    const box = await centerOf(page, selector, label);
    if (box && box.y > 120 && box.y < viewport.height - 80) return;
    await page.mouse.move(viewport.width - 280, viewport.height / 2);
    await page.mouse.wheel(0, box && box.y <= 120 ? -300 : 300);
    await page.waitForTimeout(150);
  }
}

/** Polls until at least [min] visible buttons are labelled [label] (durable state, not a toast). */
async function waitForButtons(page: Page, label: string, min: number): Promise<void> {
  await expect
    .poll(
      () =>
        page.evaluate(
          ({ sel, text }) =>
            [...document.querySelectorAll(sel)].filter((el) => {
              const r = el.getBoundingClientRect();
              const name = (el.getAttribute('aria-label') || (el as HTMLElement).innerText || '').trim();
              return name === text && r.width > 2 && r.height > 2;
            }).length,
          { sel: TAPPABLE, text: label },
        ),
      { timeout: 20000 },
    )
    .toBeGreaterThanOrEqual(min);
}
const clickMenuItem = (page: Page, label: string) =>
  clickWhenReady(page, '[role="menuitem"], [role="menuitemcheckbox"]', label);

/** Replaces the text of the field whose semantics identifier is [id]. */
async function fillField(page: Page, id: string, value: string): Promise<void> {
  const selectAll = process.platform === 'darwin' ? 'Meta+A' : 'Control+A';
  // Flutter attaches the real <input> after the tap and can swallow the first key: type, then
  // verify the field holds exactly [value] and type again until it does.
  await expect(async () => {
    await clickWhenReady(page, byId(id));
    await page.keyboard.press(selectAll);
    await page.keyboard.type(value, { delay: 10 });
    const held = await page.evaluate(() => (document.activeElement as HTMLInputElement | null)?.value ?? '');
    expect(held).toBe(value);
  }).toPass({ timeout: 30000 });
}

async function selectDropdown(page: Page, id: string, option: string): Promise<void> {
  await clickWhenReady(page, byId(id));
  await clickMenuItem(page, option);
}

/** Menu items live in the left sidebar (x < 320); table cells may share their text. */
async function clickNav(page: Page, label: string): Promise<void> {
  const box = await page.evaluate((text) => {
    const el = [...document.querySelectorAll('flt-semantics')].find((n) => {
      const r = n.getBoundingClientRect();
      const name = (n.getAttribute('aria-label') || (n as HTMLElement).innerText || '').trim();
      return name === text && r.left < 320 && r.width > 4;
    });
    if (!el) return null;
    const r = el.getBoundingClientRect();
    return { x: r.left + r.width / 2, y: r.top + r.height / 2 };
  }, label);
  expect(box, `nav ${label}`).not.toBeNull();
  await page.mouse.click(box!.x, box!.y);
}

async function uploadWith(page: Page, buttonLabel: string): Promise<void> {
  const [chooser] = await Promise.all([page.waitForEvent('filechooser'), clickButton(page, buttonLabel)]);
  await chooser.setFiles(COVER);
}

async function confirmDialog(page: Page, verb: string): Promise<void> {
  await waitForFlutterSemantics(page, `${verb} this`);
  await clickButton(page, verb);
}

// ---------- API helpers (verification + bulk rows for pagination) ----------

async function adminToken(request: APIRequestContext): Promise<string> {
  const res = await request.post(`${API_BASE_URL}/admin/auth/login`, { data: { email: ADMIN_EMAIL } });
  expect(res.status()).toBe(201);
  return (await res.json()).data.token as string;
}

async function apiJson(request: APIRequestContext, token: string, method: string, url: string, data?: unknown) {
  const res = await request.fetch(`${API_BASE_URL}${url}`, {
    method,
    headers: { Authorization: `Bearer ${token}` },
    data,
  });
  return { status: res.status(), body: await res.json().catch(() => ({})) };
}

async function servicesByTag(request: APIRequestContext, token: string) {
  const res = await apiJson(request, token, 'GET', `/admin/services?q=${RUN}&pageSize=100`);
  expect(res.status).toBe(200);
  return res.body as { data: Array<Record<string, any>>; meta: { total: number } };
}

// ---------- UI flows ----------

async function openServices(page: Page): Promise<void> {
  await clickNav(page, 'Services');
  await waitForFlutterSemantics(page, 'New service');
}

async function searchFor(page: Page, text: string): Promise<void> {
  // Once opened, the search box is a real textbox; before that it is the "Search" button.
  // Tabs keep their neighbour's list in the tree: use the box that is on screen.
  const box = page.getByRole('textbox', { name: 'Search' });
  let onScreen = null;
  for (let i = 0; i < (await box.count()); i++) {
    const r = await box.nth(i).boundingBox();
    if (r && r.x >= 0 && r.x + r.width <= page.viewportSize()!.width) onScreen = box.nth(i);
  }
  if (onScreen) await onScreen.click();
  else await clickContaining(page, 'input, textarea, [role="textbox"], flt-semantics', 'Search');
  await page.keyboard.press(process.platform === 'darwin' ? 'Meta+A' : 'Control+A');
  await page.keyboard.type(text, { delay: 10 });
}

const searchTag = (page: Page) => searchFor(page, RUN);

async function createServiceViaUi(page: Page, spec: KindSpec, index: number): Promise<void> {
  const name = `${RUN} ${spec.label}`;
  // One tap: every "New" opens a fresh editor (admin_list_screen_open_test.dart).
  await clickButton(page, 'New service');
  await waitForFlutterSemantics(page, 'More options'); // one scrolling form per kind, no tabs
  await selectDropdown(page, 'svc-kind', spec.label);
  await fillField(page, 'svc-name.en', name);
  await fillField(page, 'svc-name.es', `${name} ES`);
  await fillField(page, 'svc-shortDescription.en', 'Short text');
  await fillField(page, 'svc-shortDescription.es', 'Texto corto');
  await clickButton(page, 'Save');
  await waitForFlutterSemantics(page, name); // the panel title is the saved name
  if (index === 0) {
    // Activation without a cover is refused (422) and the missing item shows inline.
    await clickButton(page, 'Activate');
    await confirmDialog(page, 'Activate');
    await waitForFlutterSemantics(page, 'Cover required');
  }
  await uploadWith(page, 'Upload'); // the cover sits at the top of the same form
  await waitForFlutterSemantics(page, 'Usage rights');
  await fillField(page, 'svc-cover-alt-en', `${spec.label} cover`);
  await fillField(page, 'svc-cover-alt-es', `Portada ${spec.label}`);
  await clickWhenReady(page, `${byId('svc-cover-rights')}[role="checkbox"]`);
  await clickButton(page, 'Activate');
  await confirmDialog(page, 'Activate');
  await waitForButtons(page, 'Deactivate', 1); // service footer flips once the server confirms
  if (spec.itemPrice !== null) await addItemViaUi(page, spec, index === 1);
  await clickButton(page, 'Close');
}

async function addItemViaUi(page: Page, spec: KindSpec, withPhoto: boolean): Promise<void> {
  const item = `${RUN} ${spec.label} item`;
  await scrollPanelTo(page, TAPPABLE, 'New item'); // the items list sits below the kind's fields
  await clickButton(page, 'New item'); // the items list is inline; the item form replaces the panel
  await fillField(page, 'svc-name.en', item);
  await fillField(page, 'svc-name.es', `${item} ES`);
  if (withPhoto) {
    await uploadWith(page, 'Upload');
    await clickWhenReady(page, `${byId('svc-item-image-rights')}[role="checkbox"]`);
  }
  await fillField(page, 'svc-priceUSD', spec.itemPrice!);
  if (spec.capacity) {
    await fillField(page, 'svc-capacity.passengers', '6');
    await fillField(page, 'svc-capacity.luggage', '4');
  }
  await clickButton(page, 'Save'); // the item form; it closes back to the service form
  await scrollPanelTo(page, TAPPABLE, 'New item'); // back on the service form, scrolled to the top
  await clickContaining(page, ROW, item); // the row exists once the server confirmed
  await clickButton(page, 'Activate');
  await confirmDialog(page, 'Activate');
  await waitForButtons(page, 'Deactivate', 1); // item footer (the service form is hidden meanwhile)
  await clickButton(page, 'Cancel'); // back to the service form with its inline items
}

async function expectRange(page: Page, range: string, timeoutMs = 25000): Promise<void> {
  await waitForFlutterSemantics(page, range, timeoutMs);
}

test.describe.serial('Admin Services catalog (Phase 4)', () => {
  test('E2E-S01: one service per kind with cover upload, items and activation', async ({ page, request }) => {
    test.setTimeout(10 * 60 * 1000);
    await page.setViewportSize({ width: 1440, height: 900 });
    const monitor = attachErrorMonitor(page);
    await page.goto(ADMIN_DASHBOARD_URL);
    await waitForFlutterSemantics(page, 'COMMAND CENTER');
    await openServices(page);
    for (const [index, spec] of KINDS.entries()) {
      await createServiceViaUi(page, spec, index);
    }
    await captureDualScreenshot(page, 'e2e-admin-services-desktop.png');

    // Assert — the server holds every kind, active, with a signed catalog cover and an active item.
    const token = await adminToken(request);
    const { data } = await servicesByTag(request, token);
    expect(data.map((s) => s.kind).sort()).toEqual(KINDS.map((k) => k.wire).sort());
    for (const service of data) {
      const spec = KINDS.find((k) => k.wire === service.kind)!;
      expect(service.status).toBe('ACTIVE');
      expect(service.section).toBe(spec.section);
      expect(service.cover.storagePath).toMatch(/^catalog\/services\//);
      expect(service.cover.usageRightsConfirmed).toBe(true);
      const cover = await request.get(service.cover.url);
      expect(cover.status()).toBe(200);
      const items = await apiJson(request, token, 'GET', `/admin/services/${service.id}/items`);
      if (spec.itemPrice === null) {
        expect(items.body.data).toHaveLength(0);
        continue;
      }
      expect(items.body.data).toHaveLength(1);
      expect(items.body.data[0].status).toBe('ACTIVE');
      expect(items.body.data[0].priceUSD).toBe(Number(spec.itemPrice));
      if (spec.capacity) expect(items.body.data[0].capacity).toEqual({ passengers: 6, luggage: 4 });
    }
    expect(monitor.pageErrors).toEqual([]);
    expect(monitor.overflowErrors).toEqual([]);
  });

  test('E2E-S02: search, filters, pagination and persistence after reload', async ({ page, request }) => {
    test.setTimeout(4 * 60 * 1000);
    await page.setViewportSize({ width: 1440, height: 900 });
    const monitor = attachErrorMonitor(page);
    const token = await adminToken(request);
    for (let i = 1; i <= EXTRA_SERVICES; i += 1) {
      const created = await apiJson(request, token, 'POST', '/admin/services', {
        kind: 'EXPERIENCE',
        section: 'EXPERIENCES',
        usageType: 'BOOKING',
        name: { en: `${RUN} Extra ${String(i).padStart(2, '0')}`, es: '' },
        pricing: { mode: 'ON_REQUEST' },
      });
      expect(created.status).toBe(201);
    }
    expect((await servicesByTag(request, token)).meta.total).toBe(KINDS.length + EXTRA_SERVICES);

    await page.goto(ADMIN_DASHBOARD_URL);
    await waitForFlutterSemantics(page, 'COMMAND CENTER');
    await openServices(page);
    await searchTag(page);
    await expectRange(page, '1–25 of 28');
    await expect(async () => {
      await clickButton(page, 'Next page'); // disabled until the first page settled: tap again if it did nothing
      await expectRange(page, '26–28 of 28', 5000);
    }).toPass({ timeout: 40000 });

    // Filters: Section = Dining (3 kinds), then Use = Booking (breakfast and special menu; the bar
    // is ordered), then clear.
    await clickButton(page, 'Section');
    await clickMenuItem(page, 'Dining');
    await expectRange(page, '1–3 of 3');
    await clickButton(page, 'Use');
    await clickMenuItem(page, 'Booking');
    await expectRange(page, '1–2 of 2');
    const dining = await readSemanticsSnapshot(page);
    expect(dining).toContain(`${RUN} Special menu`);
    expect(dining).toContain(`${RUN} Breakfast`);
    expect(dining).not.toContain(`${RUN} Lux bar`);
    await clickButton(page, 'Clear all'); // clears the search text too
    await searchTag(page);
    await expectRange(page, '1–25 of 28');
    await clickButton(page, 'Status');
    await clickMenuItem(page, 'Disabled');
    await expectRange(page, '1–20 of 20'); // the 20 extra rows were never activated
    await assertNoHorizontalOverflow(page);

    // Persistence: a full reload reads everything back from the server.
    await page.reload();
    await waitForFlutterSemantics(page, 'COMMAND CENTER');
    await openServices(page);
    await searchTag(page);
    await expectRange(page, '1–25 of 28');
    await searchFor(page, `${RUN} Transport`);
    await expectRange(page, '1–1 of 1');
    await clickContaining(page, ROW, `${RUN} Transport`);
    await waitForFlutterSemantics(page, 'Deactivate');
    await waitForFlutterSemantics(page, `${RUN} Transport item`); // inline "Vehicles" list
    await waitForFlutterSemantics(page, '$95.00 USD');
    await clickButton(page, 'Close');

    // Section views open on the live request queue (daily work); the catalog is the second tab.
    await clickNav(page, 'Experiences');
    await waitForFlutterSemantics(page, 'Guest bookings and orders of this section.');
    expect(await readSemanticsSnapshot(page)).not.toContain('coming soon');
    await page.getByRole('tab', { name: 'Catalog' }).click(); // section-level tab bar, not the scrolling editor bar
    await waitForFlutterSemantics(page, 'New service'); // the catalog list is showing, not the queue
    await searchTag(page);
    await waitForFlutterSemantics(page, `${RUN} Experience`);
    expect(await readSemanticsSnapshot(page)).not.toContain(`${RUN} Lux bar`);
    await captureDualScreenshot(page, 'e2e-admin-experiences-section.png');
    expect(monitor.pageErrors).toEqual([]);
    expect(monitor.overflowErrors).toEqual([]);
  });

  test('E2E-S03: mobile 375 renders the catalog without overflow', async ({ page }) => {
    await page.setViewportSize({ width: 375, height: 812 });
    await page.goto(ADMIN_DASHBOARD_URL);
    await waitForFlutterSemantics(page, 'Menu');
    await clickButton(page, 'Menu');
    // The drawer slides in: Playwright waits for the item to be stable before tapping.
    await page.getByRole('button', { name: 'Services', exact: true }).click();
    await waitForFlutterSemantics(page, 'New service');
    await assertNoHorizontalOverflow(page);
    expect(fs.existsSync(COVER)).toBe(true);
    await captureDualScreenshot(page, 'e2e-admin-services-mobile.png');
  });
});
