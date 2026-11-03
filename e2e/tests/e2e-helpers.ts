import { expect, Page } from '@playwright/test';
import * as fs from 'fs';
import * as path from 'path';

export const GUEST_PORTAL_URL = 'http://localhost:3000';
export const ADMIN_DASHBOARD_URL = 'http://localhost:3002';
// Override with E2E_API_BASE_URL when the backend runs on a non-default port.
export const API_BASE_URL = process.env.E2E_API_BASE_URL ?? 'http://localhost:3001/api/v1';
export const VILLA_102_UUID = '550e8400-e29b-41d4-a716-446655440000';
export const ADMIN_STAFF_EMAIL = 'eduardo.rivera@kachavalux.com';
export const ARTIFACT_SCREENSHOT_DIR = path.resolve(
  __dirname,
  '../../doc/kachava-command-center/evidence',
);
export const LOCAL_SCREENSHOT_DIR = path.resolve(__dirname, '../screenshots');

export interface ErrorMonitor {
  pageErrors: string[];
  consoleErrors: string[];
  overflowErrors: string[];
}

export async function captureDualScreenshot(page: Page, fileName: string): Promise<void> {
  fs.mkdirSync(ARTIFACT_SCREENSHOT_DIR, { recursive: true });
  fs.mkdirSync(LOCAL_SCREENSHOT_DIR, { recursive: true });
  const artifactFile = path.join(ARTIFACT_SCREENSHOT_DIR, fileName);
  const localFile = path.join(LOCAL_SCREENSHOT_DIR, fileName);
  await page.screenshot({ path: artifactFile, fullPage: true });
  fs.copyFileSync(artifactFile, localFile);
}

export function attachErrorMonitor(page: Page): ErrorMonitor {
  const monitor: ErrorMonitor = { pageErrors: [], consoleErrors: [], overflowErrors: [] };
  page.on('pageerror', (err) => monitor.pageErrors.push(err.message));
  page.on('console', (msg) => {
    const text = msg.text();
    if (text.includes('RenderFlex overflowed') || text.includes('A RenderFlex overflowed')) {
      monitor.overflowErrors.push(text);
    }
    if (msg.type() === 'error' && !text.includes('favicon.ico')) {
      monitor.consoleErrors.push(text);
    }
  });
  return monitor;
}

export async function assertNoHorizontalOverflow(page: Page): Promise<void> {
  const dims = await page.evaluate(() => ({
    scrollWidth: document.documentElement.scrollWidth,
    innerWidth: window.innerWidth,
  }));
  expect(dims.scrollWidth).toBeLessThanOrEqual(dims.innerWidth);
}

/**
 * Opens the admin app and signs in through the Staff Sign-In screen
 * (keys `staff-sign-in-email` / `staff-sign-in-submit`), exactly as staff would.
 */
export async function signInAsStaff(page: Page, email = ADMIN_STAFF_EMAIL): Promise<void> {
  await page.goto(ADMIN_DASHBOARD_URL);
  await waitForFlutterSemantics(page, 'Staff Sign-In');
  expect(await fillSemanticsTextField(page, 'Staff email', email)).toBe(true);
  expect(await clickSemanticsExact(page, 'Sign in')).toBe(true);
  await waitForFlutterSemantics(page, 'HOST ADMIN');
}

export async function readSemanticsSnapshot(page: Page): Promise<string> {
  return page.evaluate(() => {
    const tokens: string[] = [];
    const visitRoot = (root: Document | ShadowRoot | Element) => {
      root.querySelectorAll('*').forEach((el) => {
        const aria = el.getAttribute('aria-label');
        if (aria) tokens.push(aria);
        const placeholder = el.getAttribute('placeholder');
        if (placeholder) tokens.push(placeholder);
        const text = (el as HTMLElement).innerText;
        if (text && text.trim().length > 0 && el.children.length === 0) {
          tokens.push(text.trim());
        }
        if (el.shadowRoot) visitRoot(el.shadowRoot);
      });
    };
    visitRoot(document);
    return tokens.join(' | ');
  });
}

export async function waitForFlutterSemantics(
  page: Page,
  expectedText: string,
  timeoutMs = 25000,
): Promise<string> {
  await page
    .locator('flt-semantics, [role="button"], flt-glass-pane, flutter-view')
    .first()
    .waitFor({ state: 'attached', timeout: timeoutMs });
  await expect
    .poll(async () => await readSemanticsSnapshot(page), {
      timeout: timeoutMs,
      intervals: [250, 500, 1000],
    })
    .toContain(expectedText);
  return readSemanticsSnapshot(page);
}

export async function findSemanticsCenter(
  page: Page,
  labelSubstring: string,
): Promise<{ x: number; y: number } | null> {
  return page.evaluate((target) => {
    const needle = target.toLowerCase();
    const matches: Array<{ x: number; y: number; score: number }> = [];
    const collect = (root: Document | ShadowRoot | Element) => {
      root.querySelectorAll('flt-semantics, [role="button"], [aria-label], input, textarea').forEach((el) => {
        const text = `${el.getAttribute('aria-label') || ''} ${el.getAttribute('placeholder') || ''} ${(el as HTMLElement).innerText || ''}`.toLowerCase();
        const r = el.getBoundingClientRect();
        if (text.includes(needle) && r.width > 4 && r.height > 4 && r.width < 600 && r.height < 300) {
          const rolePenalty = el.getAttribute('role') === 'button' ? 0 : 100000;
          matches.push({ x: r.left + r.width / 2, y: r.top + r.height / 2, score: rolePenalty + r.width * r.height });
        }
      });
      root.querySelectorAll('*').forEach((el) => el.shadowRoot && collect(el.shadowRoot));
    };
    collect(document);
    matches.sort((a, b) => a.score - b.score);
    return matches[0] ? { x: matches[0].x, y: matches[0].y } : null;
  }, labelSubstring);
}

/** Polls (no fixed sleep) until a node matching [labelSubstring] has a clickable box. */
export async function waitForSemanticsCenter(
  page: Page,
  labelSubstring: string,
  timeoutMs = 10000,
): Promise<{ x: number; y: number } | null> {
  const deadline = Date.now() + timeoutMs;
  for (;;) {
    const coords = await findSemanticsCenter(page, labelSubstring);
    if (coords || Date.now() >= deadline) return coords;
    await page.waitForTimeout(250);
  }
}

export async function clickSemanticsByText(
  page: Page,
  labelSubstring: string,
): Promise<boolean> {
  const coords = await waitForSemanticsCenter(page, labelSubstring);
  if (!coords) return false;
  await page.mouse.click(coords.x, coords.y);
  return true;
}

/** Clicks the semantics node whose whole label equals [label] (case-insensitive). */
export async function clickSemanticsExact(page: Page, label: string): Promise<boolean> {
  const coords = await page.evaluate((target) => {
    const needle = target.toLowerCase();
    let best: { x: number; y: number; area: number } | null = null;
    document.querySelectorAll('flt-semantics').forEach((el) => {
      const text = `${el.getAttribute('aria-label') || ''}`.trim().toLowerCase() ||
        ((el as HTMLElement).innerText || '').trim().toLowerCase();
      const r = el.getBoundingClientRect();
      if (text === needle && r.width > 4 && r.height > 4) {
        const area = r.width * r.height;
        if (!best || area < best.area) best = { x: r.left + r.width / 2, y: r.top + r.height / 2, area };
      }
    });
    return best;
  }, label);
  if (!coords) return false;
  await page.mouse.click(coords.x, coords.y);
  return true;
}

export async function fillSemanticsTextField(
  page: Page,
  labelSubstring: string,
  value: string,
): Promise<boolean> {
  const coords = await waitForSemanticsCenter(page, labelSubstring);
  if (!coords) return false;
  await page.mouse.click(coords.x, coords.y);
  await page.waitForTimeout(150);
  await page.keyboard.type(value, { delay: 15 });
  await page.waitForTimeout(100);
  return true;
}

export interface BrowserFetchResult {
  status: number;
  ok: boolean;
  body: Record<string, unknown>;
}

export async function browserFetchJson(
  page: Page,
  url: string,
  method: string,
  payload?: Record<string, unknown>,
  headers?: Record<string, string>,
): Promise<BrowserFetchResult> {
  return page.evaluate(
    async ({ reqUrl, reqMethod, reqPayload, reqHeaders }) => {
      const response = await fetch(reqUrl, {
        method: reqMethod,
        headers: {
          'Content-Type': 'application/json',
          Accept: 'application/json',
          ...(reqHeaders || {}),
        },
        body: reqPayload ? JSON.stringify(reqPayload) : undefined,
      });
      const json = await response.json().catch(() => ({}));
      return { status: response.status, ok: response.ok, body: json };
    },
    { reqUrl: url, reqMethod: method, reqPayload: payload, reqHeaders: headers },
  );
}

export async function fetchAdminAuthToken(page: Page): Promise<string> {
  const loginRes = await browserFetchJson(page, `${API_BASE_URL}/admin/auth/login`, 'POST', {
    email: ADMIN_STAFF_EMAIL,
  });
  expect(loginRes.status).toBe(201);
  return (loginRes.body.data as Record<string, unknown>).token as string;
}

export async function ensureActiveVilla102Stay(
  page: Page,
): Promise<{ stayId: string; guestUuid: string }> {
  const token = await fetchAdminAuthToken(page);
  const authHeader = { Authorization: `Bearer ${token}` };
  const staysRes = await browserFetchJson(page, `${API_BASE_URL}/admin/stays`, 'GET', undefined, authHeader);
  const stays = (staysRes.body.data as Array<Record<string, unknown>>) || [];
  const existing102 = stays.find((s) => String(s.villaId).includes('102') && s.status !== 'CHECKED_OUT');
  if (existing102) {
    return { stayId: existing102.stayId as string, guestUuid: existing102.guestTokenUuid as string };
  }
  const created = await browserFetchJson(
    page,
    `${API_BASE_URL}/admin/stays`,
    'POST',
    {
      guestName: 'Alex & Sarah Miller',
      villaId: 'villa-102',
      villaName: 'Villa 102 — Ceiba Suite',
      suiteName: 'Ceiba Suite',
      nights: 5,
      guestsCount: 2,
    },
    authHeader,
  );
  expect(created.status).toBe(201);
  const stay = (created.body.data as Record<string, unknown>).stay as Record<string, unknown>;
  const stayId = stay.stayId as string;
  await browserFetchJson(page, `${API_BASE_URL}/admin/stays/${stayId}/status`, 'PATCH', { status: 'ACTIVE_STAY' }, authHeader);
  return { stayId, guestUuid: stay.guestTokenUuid as string };
}

export interface CreatedStay {
  stayId: string;
  guestUuid: string;
  magicLinkUrl: string;
  villaName: string;
  guestName: string;
}

/**
 * The live console lists only villas that already appear on a server stay, so a
 * free villa is prepared by creating and releasing one throw-away stay via the API.
 */
export async function prepareFreeVilla(page: Page, villaId: string, villaName: string): Promise<void> {
  const token = await fetchAdminAuthToken(page);
  const authHeader = { Authorization: `Bearer ${token}` };
  const created = await browserFetchJson(
    page,
    `${API_BASE_URL}/admin/stays`,
    'POST',
    { guestName: 'Villa Seed', villaId, villaName, nights: 1, guestsCount: 1 },
    authHeader,
  );
  expect(created.status).toBe(201);
  const stay = (created.body.data as Record<string, unknown>).stay as Record<string, unknown>;
  const out = await browserFetchJson(
    page,
    `${API_BASE_URL}/admin/stays/${stay.stayId}/status`,
    'PATCH',
    { status: 'CHECKED_OUT' },
    authHeader,
  );
  expect(out.status).toBe(200);
  // The console learns about the villa on its next /admin/sync tick (second one = a request started after the change).
  await waitForAdminSyncCycles(page, 2);
}

export async function waitForAdminSyncCycles(page: Page, cycles: number): Promise<void> {
  for (let i = 0; i < cycles; i += 1) {
    await page.waitForResponse((r) => r.url().includes('/api/v1/admin/sync'), { timeout: 30000 });
  }
}

/** Picks a day in the NEXT month so the date is always in the future. */
async function pickFutureDate(page: Page, fieldLabel: string, day: number): Promise<void> {
  expect(await clickSemanticsByText(page, fieldLabel)).toBe(true);
  await waitForFlutterSemantics(page, 'Next month');
  expect(await clickSemanticsExact(page, 'Next month')).toBe(true);
  const next = new Date();
  next.setDate(1);
  next.setMonth(next.getMonth() + 1);
  const month = next.toLocaleString('en-US', { month: 'long' });
  const dayLabel = `${month} ${day}, ${next.getFullYear()}`;
  await waitForFlutterSemantics(page, dayLabel);
  expect(await clickSemanticsByText(page, dayLabel)).toBe(true);
  expect(await clickSemanticsExact(page, 'OK')).toBe(true);
}

/** Drives Tab 2 "+ New Guest Stay" dialog for an AVAILABLE villa. */
export async function submitNewStayDialog(page: Page, villaLabel: string, guestName: string): Promise<void> {
  expect(await clickSemanticsByText(page, '2. Villas, Guests & Magic Links')).toBe(true);
  expect(await clickSemanticsByText(page, '+ New Guest Stay')).toBe(true);
  await waitForFlutterSemantics(page, 'New Guest Stay & Magic Link');
  expect(await clickSemanticsByText(page, 'Select Villa')).toBe(true);
  expect(await clickSemanticsByText(page, `${villaLabel} — AVAILABLE`)).toBe(true);
  expect(await fillSemanticsTextField(page, 'Guest Name(s)', guestName)).toBe(true);
  await pickFutureDate(page, 'Check-In Date', 10);
  await pickFutureDate(page, 'Check-Out Date', 15);
  expect(await clickSemanticsByText(page, 'Create & Generate Link')).toBe(true);
}

export async function findAdminStayByGuest(page: Page, guestName: string): Promise<CreatedStay | null> {
  const token = await fetchAdminAuthToken(page);
  const res = await browserFetchJson(page, `${API_BASE_URL}/admin/stays`, 'GET', undefined, {
    Authorization: `Bearer ${token}`,
  });
  const stays = (res.body.data as Array<Record<string, any>>) || [];
  const hit = stays.find((s) => s.guestProfile?.name === guestName);
  if (!hit) return null;
  return {
    stayId: hit.stayId,
    guestUuid: hit.guestTokenUuid,
    magicLinkUrl: hit.magicLinkUrl,
    villaName: hit.villaName,
    guestName,
  };
}
