import { expect, Locator, Page, test } from '@playwright/test';
import * as fs from 'fs';
import * as path from 'path';
import { attachErrorMonitor, waitForFlutterSemantics } from './e2e-helpers';
import { adminApi, createActiveService, guestApi, Json, resortDay, runTag, ZONE } from './guest-world';

/**
 * Section request queues (Experiences / Dining › Requests) and the staff roster
 * (Settings › Staff) against the real backend on the emulators. Guest requests
 * are placed through the guest API; every staff action runs in the admin UI.
 * Names carry a per-run tag (leading "0" so they sort first).
 */
const ADMIN_URL = process.env.E2E_ADMIN_URL ?? 'http://localhost:3002';
const EVIDENCE = path.resolve(__dirname, '../../doc/kachava-command-center/evidence');

async function shot(page: Page, name: string): Promise<void> {
  fs.mkdirSync(EVIDENCE, { recursive: true });
  await page.screenshot({ path: path.join(EVIDENCE, `e2e-${name}.png`) });
}

const button = (page: Page, name: string | RegExp): Locator =>
  page.getByRole('button', { name, exact: typeof name === 'string' });

const field = (page: Page, label: string): Locator =>
  page.locator(`input[aria-label*="${label}"], textarea[aria-label*="${label}"]`).last();

const expectText = (page: Page, text: string) => waitForFlutterSemantics(page, text, 20000);

/** Top-bar gear (its tooltip can shadow the accessible name after a tap). */
const gear = (page: Page): Locator =>
  page.locator('flt-semantics[role="button"]').filter({ hasText: /^Settings/ }).first();

async function typeInto(page: Page, target: Locator, text: string): Promise<void> {
  await expect(target).toBeVisible();
  // Flutter web can drop the first keys typed into a just-focused field: verify the value held.
  await expect(async () => {
    await target.click();
    await page.waitForTimeout(250);
    await target.fill(text);
    await expect(target).toHaveValue(text, { timeout: 1000 });
  }).toPass({ timeout: 15000 });
}

async function choose(page: Page, dropdown: RegExp, option: string): Promise<void> {
  await button(page, dropdown).last().click();
  await page.getByRole('menuitem', { name: option, exact: true }).last().click();
}

async function search(page: Page, text: string): Promise<void> {
  await typeInto(page, page.getByRole('textbox', { name: 'Search' }).first(), text);
}

async function openAdmin(page: Page): Promise<void> {
  await page.goto(ADMIN_URL);
  await waitForFlutterSemantics(page, 'Unread operational alerts');
}

test.describe('Request queues and staff roster (admin http://localhost:3002)', () => {
  test('E2E-RQ-01: Experiences and Dining queues — filter, search, confirm, start, complete, cancel with reason', async ({
    page,
    request,
  }) => {
    test.setTimeout(300000);
    await page.setViewportSize({ width: 1440, height: 900 });
    const monitor = attachErrorMonitor(page);
    const api = await adminApi(request);
    const tag = runTag('0RQ');
    const guestName = `${tag} Ana Ruiz`;

    // Arrange (API): time zone, a villa, a stay, one Experiences booking service, one Dining order service.
    const settings = (await api.get('/settings')).data;
    await api.patch('/settings', { timeZone: settings.timeZone ?? ZONE });
    const villa = (await api.post('/villas', { name: `${tag} Casa Ceiba`, category: 'Garden', capacity: 4, operationalStatus: 'AVAILABLE', housekeepingStatus: 'CLEAN', maintenanceStatus: 'OK' })).data;
    const created = (await api.post('/stays', { guestName, villaId: villa.id, guestsCount: 2, checkIn: resortDay(0), checkOut: resortDay(4) })).data;
    const guestId = (created.stay ?? created).guestTokenUuid as string;
    const kayak = await createActiveService(api, {
      kind: 'EXPERIENCE', section: 'EXPERIENCES', usageType: 'BOOKING',
      name: { en: `${tag} Kayak tour`, es: `${tag} Tour en kayak` }, shortDescription: { en: 'Lagoon', es: 'Laguna' },
      pricing: { mode: 'PER_PERSON', amount: 60, chargeToFolio: true },
    });
    const bar = await createActiveService(api, {
      kind: 'BAR', section: 'DINING', usageType: 'ORDER',
      name: { en: `${tag} Lux bar`, es: `${tag} Bar Lux` }, shortDescription: { en: 'Drinks', es: 'Bebidas' },
      pricing: { mode: 'PER_UNIT', chargeToFolio: true },
    }, [{ name: { en: 'Mojito', es: 'Mojito' }, priceUSD: 12 }]);

    // The guest books the tour and orders drinks.
    const guest = guestApi(request, guestId);
    const booked = await guest.post('/bookings', { serviceId: kayak.id, scheduledDate: resortDay(1), scheduledTimeSlot: '10:00', partySize: 2 });
    expect(booked.ok(), await booked.text()).toBe(true);
    const bookingId = (await booked.json()).data.bookingId as string;
    const ordered = await guest.put(`/orders/${bar.id}`, { items: [{ itemId: bar.itemIds[0], quantity: 3 }] });
    expect(ordered.ok(), await ordered.text()).toBe(true);

    // API contract: section-scoped pages with { data, meta }.
    const queue = await api.get(`/requests?section=EXPERIENCES&q=${encodeURIComponent(tag)}`);
    expect(queue.meta.total).toBe(1);
    expect(queue.data[0]).toMatchObject({ id: bookingId, status: 'RECEIVED', quantity: 2, guestName });
    const drinks = (await api.get(`/requests?section=DINING&q=${encodeURIComponent(tag)}`)).data;
    expect(drinks).toHaveLength(1);
    expect(drinks[0]).toMatchObject({ kind: 'ORDER', status: 'RECEIVED', quantity: 3 });

    // Experiences › Requests: search the run, open the booking, move it through every step.
    await openAdmin(page);
    await button(page, 'Experiences').first().click();
    await page.getByRole('tab', { name: 'Requests' }).click();
    await expectText(page, 'Guest · Villa');
    await search(page, tag);
    await expectText(page, `${tag} Kayak tour`);
    await page.getByRole('button', { name: new RegExp(guestName) }).first().click();
    await expectText(page, 'Cancel request');
    await shot(page, 'requests-experiences-detail-1440');
    for (const [action, status] of [['Confirm', 'CONFIRMED'], ['Start', 'PREPARING'], ['Complete', 'DONE']] as const) {
      await button(page, action).last().click();
      await expect.poll(async () => (await api.get(`/requests?section=EXPERIENCES&q=${encodeURIComponent(tag)}&status=${status}`)).meta.total, {
        timeout: 15000,
      }).toBe(1);
    }
    await expectText(page, 'Done');
    const guestView = (await (await guest.get()).json()).data as Json;
    expect(guestView.experienceBookings.find((b: Json) => b.bookingId === bookingId).status).toBe('COMPLETED');

    // Dining › Requests: cancel the drinks order with a reason.
    await button(page, 'Dining').first().click();
    await page.getByRole('tab', { name: 'Requests' }).click();
    await search(page, tag);
    await expectText(page, `${tag} Lux bar`);
    await page.getByRole('button', { name: new RegExp(guestName) }).first().click();
    await button(page, 'Cancel request').last().click();
    await typeInto(page, field(page, 'Reason'), 'Bar closed tonight');
    await button(page, 'Cancel request').last().click();
    await expectText(page, 'Request cancelled');
    const cancelled = (await api.get(`/requests?section=DINING&q=${encodeURIComponent(tag)}&status=CANCELLED`)).data;
    expect(cancelled[0]).toMatchObject({ status: 'CANCELLED', cancellationReason: 'Bar closed tonight' });
    // The default "Open" filter no longer lists it.
    expect((await api.get(`/requests?section=DINING&q=${encodeURIComponent(tag)}&status=OPEN`)).meta.total).toBe(0);
    await shot(page, 'requests-dining-cancelled-1440');

    // Mobile at 375: with the default "Open" filter the cancelled order is gone (one line + Clear filters).
    await page.setViewportSize({ width: 375, height: 812 });
    await expectText(page, 'No results');
    await shot(page, 'requests-dining-375');
    const dims = await page.evaluate(() => ({ sw: document.documentElement.scrollWidth, iw: window.innerWidth }));
    expect(dims.sw).toBeLessThanOrEqual(dims.iw);

    expect(monitor.pageErrors).toEqual([]);
    expect(monitor.overflowErrors).toEqual([]);
  });

  test('E2E-ST-01: Settings › Staff — create, owner picker reads the roster, edit, deactivate', async ({ page, request }) => {
    test.setTimeout(300000);
    await page.setViewportSize({ width: 1440, height: 900 });
    const monitor = attachErrorMonitor(page);
    const api = await adminApi(request);
    const tag = runTag('0ST');
    const name = `${tag} Lucia Perez`;
    const email = `${tag.toLowerCase()}@staff.test`;

    await openAdmin(page);
    await gear(page).click();
    await page.getByRole('tab', { name: 'Staff' }).click();
    await expectText(page, 'Department');
    await button(page, 'New staff').first().click();
    await typeInto(page, field(page, 'Name'), name);
    await choose(page, /^Role/, 'Coordinator');
    await choose(page, /^Department/, 'Culinary');
    await typeInto(page, field(page, 'Email'), email);
    await typeInto(page, field(page, 'Phone'), '+52 998 555 0101');
    await button(page, 'Save').last().click();
    await expectText(page, 'Staff saved');

    const roster = (await api.get(`/staff?q=${encodeURIComponent(tag)}`)).data as Json[];
    expect(roster).toHaveLength(1);
    expect(roster[0]).toMatchObject({ fullName: name, rbacRole: 'DEPARTMENT_COORDINATOR', department: 'CULINARY', email, isActive: true });
    await search(page, tag);
    await expectText(page, email);
    await shot(page, 'settings-staff-1440');

    // The Tasks owner picker offers the new member without reloading the app.
    await button(page, 'Tasks').first().click();
    await button(page, 'New task').first().click();
    await button(page, /^Owner/).last().click();
    await expect(page.getByRole('menuitem', { name, exact: true }).last()).toBeVisible();
    await page.keyboard.press('Escape');

    // Edit, then deactivate from the ⋮ menu.
    await gear(page).click();
    await page.getByRole('tab', { name: 'Staff' }).click();
    await search(page, tag);
    await page.getByRole('button', { name: new RegExp(name) }).first().click();
    await typeInto(page, field(page, 'Phone'), '+52 998 555 0202');
    await button(page, 'Save').last().click();
    await expectText(page, 'Staff saved');
    await expect.poll(async () => (await api.get(`/staff?q=${encodeURIComponent(tag)}`)).data[0].phone, { timeout: 15000 })
      .toBe('+52 998 555 0202');
    await page.getByRole('button', { name: new RegExp(name) }).first().click();
    await button(page, 'Actions').last().click();
    await page.getByRole('menuitem', { name: 'Deactivate' }).click();
    await button(page, 'Deactivate').last().click();
    await expectText(page, 'Staff deactivated');
    const after = (await api.get(`/staff?q=${encodeURIComponent(tag)}`)).data[0];
    expect(after.isActive).toBe(false);
    expect((await api.get(`/staff?isActive=true&q=${encodeURIComponent(tag)}`)).meta.total).toBe(0);
    await shot(page, 'settings-staff-deactivated-1440');

    expect(monitor.pageErrors).toEqual([]);
    expect(monitor.overflowErrors).toEqual([]);
  });
});
