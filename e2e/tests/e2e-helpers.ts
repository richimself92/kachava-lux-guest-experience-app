import { expect, Page } from '@playwright/test';
import * as fs from 'fs';
import * as path from 'path';

export const ADMIN_DASHBOARD_URL = 'http://localhost:3002';
export const API_BASE_URL = process.env.E2E_API_BASE_URL ?? 'http://localhost:3011/api/v1';
const ARTIFACT_SCREENSHOT_DIR = path.resolve(
  __dirname,
  '../../doc/kachava-command-center/evidence',
);
const LOCAL_SCREENSHOT_DIR = path.resolve(__dirname, '../screenshots');

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
