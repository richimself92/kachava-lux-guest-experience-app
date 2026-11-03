import { APIRequestContext, expect, Locator, Page, test } from '@playwright/test';
import * as fs from 'fs';
import * as path from 'path';
import { attachErrorMonitor, waitForFlutterSemantics } from './e2e-helpers';

/**
 * Phases 6-8 (plan v2): Dashboard, Reservations, Guests › Messages, Tasks and
 * Notifications against the real backend (Firestore + Storage emulators).
 * Settings and a villa are prepared through the API; the reservation, the
 * reply, the task flow and the notification "Open" run in the UI. Every name
 * carries a per-run tag so runs never collide on a persistent emulator.
 */
const ADMIN_URL = process.env.E2E_ADMIN_URL ?? 'http://localhost:3002';
const API = process.env.E2E_API_BASE_URL ?? 'http://localhost:3011/api/v1';
const ADMIN_EMAIL = process.env.E2E_ADMIN_EMAIL ?? 'admin@kachava.local';
const EVIDENCE = path.resolve(__dirname, '../../doc/kachava-command-center/evidence');
const RUN = `P8${Date.now().toString(36).slice(-5).toUpperCase()}`;
const ZONE = 'America/Cancun';
const GUEST = `${RUN} Ana Ruiz`;
const VILLA = `${RUN} Casa Ceiba`;
const TASK = `${RUN} Turn-down`;

type Json = Record<string, any>;

/** Resort calendar day `YYYY-MM-DD`, [offset] days from today. */
function resortDay(offset = 0): string {
  const at = new Date(Date.now() + offset * 86_400_000);
  return new Intl.DateTimeFormat('sv-SE', { timeZone: ZONE }).format(at);
}

async function shot(page: Page, name: string): Promise<void> {
  fs.mkdirSync(EVIDENCE, { recursive: true });
  await page.screenshot({ path: path.join(EVIDENCE, `phase-8-${name}.png`) });
}

async function adminApi(request: APIRequestContext) {
  const login = await request.post(`${API}/admin/auth/login`, { data: { email: ADMIN_EMAIL } });
  expect(login.ok()).toBe(true);
  const token = (await login.json()).data.token as string;
  const headers = { Authorization: `Bearer ${token}` };
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

/** The guest side: write to the Resort Host from the magic link. */
async function guestWrites(request: APIRequestContext, magicLinkUrl: string, text: string): Promise<void> {
  const uuid = new URL(magicLinkUrl).searchParams.get('guestId');
  expect(uuid, 'guestId in the magic link').toBeTruthy();
  const created = await request.post(`${API}/stays/${uuid}/concierge-requests`, {
    data: { type: 'ask', title: 'Resort Host', details: text },
  });
  expect(created.ok(), await created.text()).toBe(true);
  const requestId = (await created.json()).data.requestId as string;
  const message = await request.post(`${API}/stays/${uuid}/concierge-requests/${requestId}/messages`, {
    data: { text },
  });
  expect(message.ok(), await message.text()).toBe(true);
}

async function ensureSettings(api: Api): Promise<void> {
  const current = (await api.get('/settings')).data;
  await api.patch('/settings', {
    timeZone: current.timeZone ?? ZONE,
    transportAlertLeadHours: current.transportAlertLeadHours ?? 24,
  });
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

const expectText = (page: Page, text: string) => waitForFlutterSemantics(page, text, 20000);

async function choose(page: Page, dropdown: RegExp, option: string): Promise<void> {
  await button(page, dropdown).last().click();
  await page.getByRole('menuitem', { name: option, exact: true }).last().click();
}

async function openMenu(page: Page, item: string): Promise<void> {
  await button(page, item).first().click();
}

async function search(page: Page, text: string): Promise<void> {
  await typeInto(page, page.getByRole('textbox', { name: 'Search' }).first(), text);
}

test.describe('Phases 6-8 — operations (admin http://localhost:3002)', () => {
  test('E2E-P8-01: reservation → dashboard → message reply → task flow → notification open', async ({
    page,
    request,
  }) => {
    test.setTimeout(420000);
    await page.setViewportSize({ width: 1440, height: 900 });
    const monitor = attachErrorMonitor(page);
    const api = await adminApi(request);

    // Arrange (API): Settings and one villa.
    await ensureSettings(api);
    const villa = (await api.post('/villas', { name: VILLA, category: 'Ocean view', capacity: 4 })).data;
    const before = (await api.get('/dashboard')).data;

    // Reservations: "+ New reservation" in the UI, arriving today.
    await page.goto(ADMIN_URL);
    await waitForFlutterSemantics(page, 'Unread operational alerts');
    await openMenu(page, 'Reservations');
    await button(page, 'New reservation').first().click();
    await typeInto(page, field(page, 'Guest'), GUEST);
    await choose(page, /^Villa/, VILLA);
    await typeInto(page, field(page, 'Arrival'), resortDay(0));
    await typeInto(page, field(page, 'Departure'), resortDay(3));
    await button(page, 'Save').last().click();
    await expectText(page, 'Reservation created');

    const rows = (await api.get(`/stays?q=${encodeURIComponent(RUN)}`)).data;
    expect(rows).toHaveLength(1);
    const stay = rows[0];
    expect(stay).toMatchObject({ guestName: GUEST, villaId: villa.id, status: 'PRE_ARRIVAL', checkIn: resortDay(0) });

    // Detail: Summary (copy link), Folio says "No PMS integration"; check in.
    await search(page, RUN);
    await page.getByRole('button', { name: new RegExp(GUEST) }).first().click();
    await expectText(page, 'Guest link');
    await button(page, 'Copy').click();
    await expectText(page, 'Link copied');
    await page.getByRole('tab', { name: 'Folio' }).click();
    await expectText(page, 'No PMS integration');
    await page.getByRole('tab', { name: 'Summary' }).click();
    await button(page, 'Check in').last().click();
    await button(page, 'Check in').last().click(); // confirm dialog
    await expectText(page, 'In house');
    expect((await api.get(`/stays/${stay.id}`)).data.status).toBe('ACTIVE_STAY');
    await shot(page, 'reservation-detail-1440');

    // Dashboard: KPIs moved and the guest is in today's activity.
    const after = (await api.get('/dashboard')).data;
    expect(after.resortDate).toBe(resortDay(0));
    expect(after.kpis.occupiedVillas).toBe(before.kpis.occupiedVillas + 1);
    expect(after.kpis.arrivals).toBe(before.kpis.arrivals + 1);
    await openMenu(page, 'Dashboard');
    await expectText(page, 'Overview');
    await expectText(page, 'Occupied villas');
    await expectText(page, "Today's activity");
    await expectText(page, GUEST);
    await expectText(page, 'Arrival');
    await shot(page, 'dashboard-1440');
    await page.getByRole('button', { name: new RegExp(GUEST) }).first().click();
    await expectText(page, 'Guest link'); // the row opens the stay detail

    // Guest writes → Guests › Messages (unread) → reply.
    await guestWrites(request, stay.magicLinkUrl, `${RUN} Can we get extra towels?`);
    const inbox = (await api.get(`/conversations?q=${encodeURIComponent(RUN)}`)).data;
    expect(inbox[0]).toMatchObject({ stayId: stay.id, awaitingReply: true });
    expect(inbox[0].unreadCount).toBeGreaterThan(0);
    await openMenu(page, 'Guests');
    await page.getByRole('tab', { name: 'Messages' }).click();
    await search(page, RUN);
    await page.getByRole('button', { name: new RegExp(GUEST) }).first().click();
    await expectText(page, 'Can we get extra towels?');
    await typeInto(page, field(page, 'Reply'), `${RUN} On their way`);
    await button(page, 'Send').click();
    await expectText(page, `${RUN} On their way`);
    const answered = (await api.get(`/conversations?q=${encodeURIComponent(RUN)}`)).data[0];
    expect(answered).toMatchObject({ awaitingReply: false, unreadCount: 0 });
    await shot(page, 'messages-1440');

    // Tasks: create, Assign (owner), Start, Complete (note).
    const staff = (await api.get('/staff?pageSize=100')).data as Json[];
    expect(staff.length, 'at least the admin identity').toBeGreaterThan(0);
    await openMenu(page, 'Tasks');
    await button(page, 'New task').first().click();
    await typeInto(page, field(page, 'Title'), TASK);
    await typeInto(page, field(page, 'Category'), 'Housekeeping');
    await typeInto(page, field(page, 'Due'), `${resortDay(0)} 23:00`);
    await button(page, 'Save').last().click();
    await expectText(page, 'Task created');
    await search(page, RUN);
    await page.getByRole('button', { name: new RegExp(TASK) }).first().click();
    await button(page, 'Assign').last().click();
    await choose(page, /^Owner/, staff[0].fullName);
    await button(page, 'Assign').last().click();
    await expectText(page, 'Assigned');
    await button(page, 'Start').last().click();
    await expectText(page, 'In progress');
    await button(page, 'Complete').last().click();
    await typeInto(page, field(page, 'Completion note'), 'Done by housekeeping');
    await button(page, 'Complete').last().click();
    await expectText(page, 'Completed');
    const task = (await api.get(`/tasks?q=${encodeURIComponent(RUN)}`)).data[0];
    expect(task).toMatchObject({ status: 'COMPLETED', ownerStaffId: staff[0].staffId });
    expect(task.completion.note).toBe('Done by housekeeping');
    await shot(page, 'task-completed-1440');

    // Notifications: the guest message (Action) opens Guests › Messages.
    await guestWrites(request, stay.magicLinkUrl, `${RUN} One more pillow please`);
    const feed = (await api.get(`/notifications?q=${encodeURIComponent(RUN)}&read=false`)).data as Json[];
    const message = feed.find((n) => n.targetRef?.type === 'CONVERSATION');
    expect(message, 'guest message notification').toBeTruthy();
    expect(message!.level).toBe('ACTION');
    expect(message!.playSound).toBe(false);
    await page.getByRole('button', { name: /Unread operational alerts/ }).click();
    await expectText(page, 'Notifications');
    await search(page, RUN);
    await expectText(page, 'Action');
    await shot(page, 'notifications-1440');
    await button(page, 'Open').first().click();
    await expectText(page, 'One more pillow please');
    const opened = (await api.get(`/notifications?q=${encodeURIComponent(RUN)}`)).data as Json[];
    expect(opened.find((n) => n.id === message!.id)?.read).toBe(true);

    expect(monitor.pageErrors).toEqual([]);
    expect(monitor.overflowErrors).toEqual([]);
  });

  test('E2E-P8-02: mobile 375 — menu shows every plan item, dashboard fits', async ({ page }) => {
    await page.setViewportSize({ width: 375, height: 812 });
    const monitor = attachErrorMonitor(page);
    await page.goto(ADMIN_URL);
    await waitForFlutterSemantics(page, 'Unread operational alerts');
    await expectText(page, 'Overview');
    await button(page, 'Menu').click();
    for (const item of [
      'Dashboard', 'Reservations', 'Guests', 'Villas', 'Services', 'Experiences',
      'Dining', 'Transportation', 'Wellness', 'Tasks', 'Notifications',
    ]) {
      await expectText(page, item);
    }
    await shot(page, 'menu-375');
    expect(monitor.overflowErrors).toEqual([]);
  });
});
