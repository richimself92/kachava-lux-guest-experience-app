import { expect, Page, test } from '@playwright/test';
import * as path from 'path';
import { attachErrorMonitor, waitForFlutterSemantics } from './e2e-helpers';
import { button, DEMO_MARKERS, GUEST_URL, GuestWorld, prepareGuestWorld, tab, typeInto } from './guest-world';

/**
 * Phase 10 exploratory pass on the guest portal at 1440 and 375 px: Home journey, Services, one form
 * of each type (order, booking, transfer wizard), My requests and the Resort Host chat with a photo.
 * Every step must leave 0 console errors, 0 failed or 4xx/5xx requests, no horizontal overflow, no raw
 * enum on screen and no demo data. Screenshots: doc/kachava-command-center/evidence/final-guest-*.png.
 */
const EVIDENCE = path.resolve(__dirname, '../../doc/kachava-command-center/evidence');
const RAW_ENUM = /\b[A-Z]{2,}(?:_[A-Z]+)+\b/;
const PHOTO = path.resolve(__dirname, '../fixtures/service-cover.png');

async function openServices(page: Page): Promise<void> {
  await tab(page, /Services/).click();
  await waitForFlutterSemantics(page, ' services'); // the catalog finished loading
}

/** Types in the Services search and waits for the filter to apply (the outcome, not the DOM value). */
async function search(page: Page, text: string, count: number): Promise<void> {
  await expect(async () => {
    const field = page.locator('input[aria-label*="Search"], textarea[aria-label*="Search"]').last();
    await field.click();
    await page.keyboard.press(process.platform === 'darwin' ? 'Meta+A' : 'Control+A');
    await page.keyboard.type(text, { delay: 10 });
    await waitForFlutterSemantics(page, `${count} services`, 4000);
  }).toPass({ timeout: 30000 });
}

async function check(page: Page, errors: string[]): Promise<void> {
  // Only what Flutter exposes as the screen (no <head> scripts or CSS).
  const screen = await page.evaluate(() =>
    [...document.querySelectorAll('flt-semantics')]
      .map((el) => `${el.getAttribute('aria-label') ?? ''} ${(el as HTMLElement).innerText ?? ''}`)
      .join(' | '),
  );
  expect(screen).not.toMatch(RAW_ENUM);
  expect(screen).not.toMatch(DEMO_MARKERS);
  const dims = await page.evaluate(() => ({ sw: document.documentElement.scrollWidth, iw: window.innerWidth }));
  expect(dims.sw).toBeLessThanOrEqual(dims.iw);
  expect(errors).toEqual([]);
}

for (const width of [1440, 375]) {
  test.describe(`Guest portal exploratory at ${width}px`, () => {
    let world: GuestWorld;
    test.beforeAll(async ({ request }) => {
      world = await prepareGuestWorld(request, 'FX');
    });

    test(`every screen and form is clean at ${width}`, async ({ page }) => {
      test.setTimeout(240_000);
      await page.setViewportSize({ width, height: width === 1440 ? 900 : 812 });
      const monitor = attachErrorMonitor(page);
      const problems: string[] = [];
      page.on('response', (res) => {
        if (res.status() >= 400) problems.push(`${res.status()} ${res.url()}`);
      });
      page.on('requestfailed', (req) => problems.push(`failed ${req.url()}`));
      const shot = (area: string) => page.screenshot({ path: path.join(EVIDENCE, `final-guest-${area}-${width}.png`) });
      const all = () => [...monitor.pageErrors, ...monitor.consoleErrors, ...monitor.overflowErrors, ...problems];

      // Home journey.
      await page.goto(`${GUEST_URL}/?guestId=${world.guestId}`);
      await waitForFlutterSemantics(page, world.villaName);
      await waitForFlutterSemantics(page, '1.1 Flight & transfer');
      await check(page, all());
      await shot('home');

      // Services: search the run's catalog.
      await openServices(page);
      await search(page, world.tag, 4);
      await check(page, all());
      await shot('services');

      // Order form (stocking): add two waters, review, send.
      await button(page, `${world.tag} Villa stocking`).click();
      await button(page, 'Order').click();
      // A focused Flutter tooltip button repeats its label in its name: match the start.
      await button(page, /^\+ Water/).click();
      // A focused Flutter tooltip button repeats its label in its name: match the start.
      await button(page, /^\+ Water/).click();
      await waitForFlutterSemantics(page, '2 items · $8 USD');
      await check(page, all());
      await shot('form-order');
      await button(page, 'Review').click();
      const sent = page.waitForResponse((res) => res.url().includes(`/stays/${world.guestId}/orders/`) && res.request().method() === 'PUT');
      await button(page, 'Order').click();
      expect((await sent).status()).toBe(200);
      await waitForFlutterSemantics(page, 'Order sent');

      // Booking form (massage): opened, validation shown for the empty required fields.
      await page.goto(`${GUEST_URL}/?guestId=${world.guestId}`);
      await waitForFlutterSemantics(page, world.villaName);
      await openServices(page);
      await search(page, `${world.tag} Massage`, 1);
      await button(page, new RegExp(`${world.tag} Massage`)).click();
      await button(page, 'Book').click();
      await waitForFlutterSemantics(page, 'Pick date');
      await check(page, all());
      await shot('form-booking');

      // Transfer wizard (trip): first step.
      await page.goto(`${GUEST_URL}/?guestId=${world.guestId}`);
      await waitForFlutterSemantics(page, world.villaName);
      await openServices(page);
      await search(page, `${world.tag} Airport`, 1);
      await button(page, new RegExp(`${world.tag} Airport transfer`)).click();
      await button(page, 'Plan trip').click();
      await waitForFlutterSemantics(page, 'Step 1 of');
      await check(page, all());
      await shot('wizard-transfer');

      // My requests: the order is listed with a plain status word.
      await page.goto(`${GUEST_URL}/?guestId=${world.guestId}`);
      await waitForFlutterSemantics(page, world.villaName);
      await tab(page, /Requests/).click();
      await waitForFlutterSemantics(page, `${world.tag} Villa stocking`);
      await waitForFlutterSemantics(page, 'Received');
      await check(page, all());
      await shot('requests');

      // Resort Host: a message with a real photo, stored and shown in the thread.
      await tab(page, /Host/).click();
      await waitForFlutterSemantics(page, 'Resort Host');
      await typeInto(page, 'Message', `${world.tag} extra towels please`);
      const [chooser] = await Promise.all([page.waitForEvent('filechooser'), button(page, 'Attach photo').click()]);
      await chooser.setFiles(PHOTO);
      await waitForFlutterSemantics(page, 'Remove photo'); // the photo is read before it can be sent
      await button(page, 'Send').click();
      await waitForFlutterSemantics(page, 'Message sent');
      const host = await waitForFlutterSemantics(page, `${world.tag} extra towels please`);
      expect(host).toContain('Photo');
      await check(page, all());
      await shot('host');
    });
  });
}
