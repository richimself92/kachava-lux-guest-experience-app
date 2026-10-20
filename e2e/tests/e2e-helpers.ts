import { expect, Page } from '@playwright/test';
import * as fs from 'fs';
import * as path from 'path';

export const GUEST_PORTAL_URL = 'http://localhost:3000';
export const ADMIN_DASHBOARD_URL = 'http://localhost:3002';
export const API_BASE_URL = 'http://localhost:3001/api/v1';
export const VILLA_102_UUID = '550e8400-e29b-41d4-a716-446655440000';
export const ADMIN_STAFF_EMAIL = 'eduardo.rivera@kachavalux.com';
export const ARTIFACT_SCREENSHOT_DIR =
  '/Users/jggomez/.gemini/antigravity-cli/brain/931c042f-a480-488d-845b-685ff41b66dc';
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

export async function installAdminLoginNormalizer(page: Page): Promise<void> {
  await page.route('**/api/v1/admin/auth/login', async (route) => {
    const req = route.request();
    const raw = req.postData() || '{}';
    const fixed = raw.replace('eduardo@kachavalux.com', ADMIN_STAFF_EMAIL);
    await route.continue({ postData: fixed });
  });
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
        if (text.includes(needle) && r.width > 4 && r.height > 4 && r.width < 600 && r.height < 220) {
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

export async function clickSemanticsByText(
  page: Page,
  labelSubstring: string,
): Promise<boolean> {
  const coords = await findSemanticsCenter(page, labelSubstring);
  if (!coords) return false;
  await page.mouse.click(coords.x, coords.y);
  return true;
}

export async function fillSemanticsTextField(
  page: Page,
  labelSubstring: string,
  value: string,
): Promise<boolean> {
  const coords = await findSemanticsCenter(page, labelSubstring);
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
