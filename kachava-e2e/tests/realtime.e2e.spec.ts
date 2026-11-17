import { expect, Locator, Page, test } from '@playwright/test';
import { attachErrorMonitor, readSemanticsSnapshot, waitForFlutterSemantics } from './e2e-helpers';
import { adminApi, GUEST_URL, guestApi, prepareGuestWorld, resortDay, tab } from './guest-world';

/**
 * ADR-012: a change on one side shows on the other without reload, polling or the Refresh
 * button. The writes go through the API so the test measures only the push path
 * (backend → `realtime_signals` → Firestore listener → re-fetch). Needs `firestore.rules`
 * to allow `get` on `realtime_signals/{id}` and both apps built with the Firebase emulator config.
 */
const ADMIN_URL = process.env.E2E_ADMIN_URL ?? 'http://localhost:3002';
const PUSH_TIMEOUT = 8000; // generous for CI; locally it lands in ~1 s

const button = (page: Page, name: string | RegExp): Locator =>
  page.getByRole('button', { name, exact: typeof name === 'string' });

async function typeInto(page: Page, target: Locator, text: string): Promise<void> {
  await expect(target).toBeVisible();
  await expect(async () => {
    await target.click();
    await page.waitForTimeout(250);
    await target.fill(text);
    await expect(target).toHaveValue(text, { timeout: 1000 });
  }).toPass({ timeout: 15000 });
}

const pushed = (page: Page, text: string) =>
  expect.poll(() => readSemanticsSnapshot(page), { timeout: PUSH_TIMEOUT, intervals: [250] }).toContain(text);

test.describe('ADR-012 real time (admin :3002 ↔ guest :3000)', () => {
  test('chat and request status reach the other side without reload', async ({ browser, request }) => {
    test.setTimeout(180_000);
    const world = await prepareGuestWorld(request, 'RT');
    const api = await adminApi(request);
    const guest = guestApi(request, world.guestId);

    // The guest opens a thread so the conversation exists.
    const thread = await guest.post('/concierge-requests', { type: 'ask', category: 'Resort Host chat', title: 'Message', details: `${world.tag} hello` });
    expect(thread.ok(), await thread.text()).toBe(true);
    const threadId = (await thread.json()).data.requestId as string;

    // Admin: Guests › Messages › this conversation.
    const adminPage = await (await browser.newContext({ viewport: { width: 1440, height: 900 } })).newPage();
    const adminErrors = attachErrorMonitor(adminPage);
    await adminPage.goto(ADMIN_URL);
    await button(adminPage, 'Guests').first().click();
    await adminPage.getByRole('tab', { name: 'Messages' }).click();
    await typeInto(adminPage, adminPage.getByRole('textbox', { name: 'Search' }).first(), world.tag);
    await button(adminPage, new RegExp(world.guestName)).first().click();
    await waitForFlutterSemantics(adminPage, `${world.tag} hello`);

    // Guest portal on the Resort Host tab.
    const guestPage = await (await browser.newContext({ viewport: { width: 390, height: 844 } })).newPage();
    const guestErrors = attachErrorMonitor(guestPage);
    await guestPage.goto(`${GUEST_URL}/?guestId=${world.guestId}`);
    await tab(guestPage, /Host/).click();
    await waitForFlutterSemantics(guestPage, `${world.tag} hello`);

    // guest → admin
    const sent = await guest.post(`/concierge-requests/${threadId}/messages`, { text: `${world.tag} guest-to-admin` });
    expect(sent.ok(), await sent.text()).toBe(true);
    await pushed(adminPage, `${world.tag} guest-to-admin`);

    // admin → guest
    const stays = (await api.get(`/stays?q=${encodeURIComponent(world.guestName)}`)).data;
    const stayId = stays[0].stayId ?? stays[0].id;
    await api.post(`/conversations/${stayId}/messages`, { text: `${world.tag} admin-to-guest` });
    await pushed(guestPage, `${world.tag} admin-to-guest`);

    // Status: the guest books, staff confirms → the guest's Requests tab updates by itself.
    const booking = await guest.post('/bookings', { serviceId: world.massageId, scheduledDate: resortDay(4), scheduledTimeSlot: '10:00', partySize: 1 });
    expect(booking.ok(), await booking.text()).toBe(true);
    await tab(guestPage, /Requests/).click();
    await waitForFlutterSemantics(guestPage, 'Received');
    const queue = (await api.get(`/requests?q=${encodeURIComponent(world.guestName)}&pageSize=10`)).data;
    const req = queue.find((r: any) => r.serviceId === world.massageId) ?? queue[0];
    await api.post(`/requests/${req.id ?? req.requestId}/transition`, { action: 'CONFIRM' });
    await pushed(guestPage, 'Confirmed');

    expect(adminErrors.pageErrors, 'admin page errors').toEqual([]);
    expect(guestErrors.pageErrors, 'guest page errors').toEqual([]);
  });
});
