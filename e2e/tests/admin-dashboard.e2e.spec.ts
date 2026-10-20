import { expect, Page, test } from '@playwright/test';
import {
  ADMIN_DASHBOARD_URL,
  API_BASE_URL,
  assertNoHorizontalOverflow,
  attachErrorMonitor,
  browserFetchJson,
  captureDualScreenshot,
  clickSemanticsByText,
  ensureActiveVilla102Stay,
  fetchAdminAuthToken,
  fillSemanticsTextField,
  GUEST_PORTAL_URL,
  installAdminLoginNormalizer,
  readSemanticsSnapshot,
  waitForFlutterSemantics,
} from './e2e-helpers';

async function selectAdminTabAndVerify(
  page: Page,
  tabLabel: string,
  expectedText: string,
): Promise<void> {
  const clicked = await clickSemanticsByText(page, tabLabel);
  expect(clicked).toBe(true);
  await waitForFlutterSemantics(page, expectedText);
  await assertNoHorizontalOverflow(page);
}

test.describe('Kachava Lux Admin Operations Dashboard E2E (http://localhost:3002)', () => {
  test('E2E-A01: Desktop 1440x900 Command Center & Zero-401 Live Backend Handshake', async ({
    page,
  }) => {
    // Arrange
    await page.setViewportSize({ width: 1440, height: 900 });
    await installAdminLoginNormalizer(page);
    const monitor = attachErrorMonitor(page);
    const adminStatuses: Record<string, number> = {};
    page.on('response', (res) => {
      if (res.url().includes('/api/v1/admin/')) {
        const endpoint = res.url().split('/api/v1/admin/')[1].split('?')[0];
        adminStatuses[endpoint] = res.status();
      }
    });
    // Act
    await page.goto(ADMIN_DASHBOARD_URL);
    const initialSemantics = await waitForFlutterSemantics(page, 'KACHAVA LUX');
    await expect.poll(() => Object.keys(adminStatuses).length, { timeout: 15000 }).toBeGreaterThanOrEqual(7);
    // Assert
    expect(initialSemantics).toContain('HOST ADMIN');
    expect(initialSemantics).toContain('EN | ES');
    expect(initialSemantics).toContain('🔔 Test 10s');
    expect(adminStatuses['auth/login']).toBe(201);
    for (const key of ['staff', 'alerts', 'stays', 'bookings', 'larder-orders', 'concierge-requests']) {
      expect(adminStatuses[key]).toBe(200);
    }
    expect(Object.values(adminStatuses).filter((s) => s === 401)).toEqual([]);
    await assertNoHorizontalOverflow(page);
    await captureDualScreenshot(page, 'e2e-admin-overview-desktop.png');
    // Verify EN | ES bilingual toggle & 10s Alert button in Top Command Bar
    expect(await clickSemanticsByText(page, 'EN | ES')).toBe(true);
    await waitForFlutterSemantics(page, 'Villas Ocupadas');
    expect(await clickSemanticsByText(page, 'ES | EN')).toBe(true);
    await waitForFlutterSemantics(page, 'Active Residencies');
    expect(await clickSemanticsByText(page, '🔔 Test 10s')).toBe(true);
    await waitForFlutterSemantics(page, 'INCOMING GUEST UPDATE · LIVE ALERT (10S CHIME ACTIVE)');
    expect(await clickSemanticsByText(page, 'Mute / Dismiss')).toBe(true);
    expect([...monitor.pageErrors, ...monitor.consoleErrors, ...monitor.overflowErrors]).toEqual([]);
  });

  test('E2E-A02: Zero-State Reset, Empty Dialogs, 2s Poll Persistence & All 6 Admin Workspaces', async ({
    page,
  }) => {
    // Arrange — Reset backend to clean zero-state (0 stays, 0 alerts, 8 FREE villas)
    await page.setViewportSize({ width: 1440, height: 900 });
    await installAdminLoginNormalizer(page);
    const monitor = attachErrorMonitor(page);
    await page.goto(ADMIN_DASHBOARD_URL);
    await waitForFlutterSemantics(page, 'KACHAVA LUX');
    const token = await fetchAdminAuthToken(page);
    const authHeader = { Authorization: `Bearer ${token}` };
    const resetRes = await browserFetchJson(page, `${API_BASE_URL}/admin/reset`, 'POST', {}, authHeader);
    expect(resetRes.status).toBe(201);
    const staysAfterReset = await browserFetchJson(page, `${API_BASE_URL}/admin/stays`, 'GET', undefined, authHeader);
    const alertsAfterReset = await browserFetchJson(page, `${API_BASE_URL}/admin/alerts`, 'GET', undefined, authHeader);
    expect((staysAfterReset.body.data as unknown[]).length).toBe(0);
    expect(((alertsAfterReset.body.data as Record<string, unknown>).alerts as unknown[]).length).toBe(0);
    // Act & Assert — Navigate to Tab 2 (2. Villas, Guests & Magic Links) & verify 8 FREE villas
    await selectAdminTabAndVerify(page, '2. Villas, Guests & Magic Links', 'All 8 Villas are FREE');
    expect(await clickSemanticsByText(page, '+ New Villa')).toBe(true);
    await waitForFlutterSemantics(page, 'Register New Sanctuary Villa');
    expect(await fillSemanticsTextField(page, 'Villa Name / Number', 'Villa 110')).toBe(true);
    expect(await fillSemanticsTextField(page, 'Suite / Category', 'Mayan Sanctuary')).toBe(true);
    expect(await clickSemanticsByText(page, 'Save Villa')).toBe(true);
    await waitForFlutterSemantics(page, 'Villa 110 — Mayan Sanctuary');
    expect(await clickSemanticsByText(page, '+ New Guest Stay')).toBe(true);
    await waitForFlutterSemantics(page, 'New Guest Stay & Magic Link');
    expect(await fillSemanticsTextField(page, 'Guest Name(s)', 'Marcus & Elena Sterling')).toBe(true);
    expect(await clickSemanticsByText(page, 'Create & Generate Link')).toBe(true);
    const staySemantics = await waitForFlutterSemantics(page, 'Marcus & Elena Sterling');
    expect(staySemantics).toContain('OPERATIONS NOTIFICATION · HOST ADMIN');
    expect(staySemantics).not.toContain('INCOMING GUEST UPDATE · LIVE ALERT (10S CHIME ACTIVE)');
    expect(staySemantics).toContain('GUEST COMFORT, SCENT, DIET, ALLERGIES & NOTES');
    expect(staySemantics).toContain('Edit Wi-Fi');
    expect(staySemantics).toContain('Airport Transfer: Guest has not registered flight details yet');
    expect(await clickSemanticsByText(page, 'Mute / Dismiss')).toBe(true);
    // Verify stay persists across 2-second background poll with 0 self-alerts
    await page.waitForTimeout(2500);
    expect(await readSemanticsSnapshot(page)).toContain('Marcus & Elena Sterling');
    const postCreateAlerts = await browserFetchJson(page, `${API_BASE_URL}/admin/alerts`, 'GET', undefined, authHeader);
    expect(((postCreateAlerts.body.data as Record<string, unknown>).alerts as unknown[]).length).toBe(0);
    await captureDualScreenshot(page, 'e2e-admin-stays.png');
    // Navigate across all remaining Admin tabs with 0 overflow
    await selectAdminTabAndVerify(page, '3. Pre-Arrival: Minibar & Pantry', 'LIVE MINIBAR & LARDER CATALOG');
    await selectAdminTabAndVerify(page, '4. Stay: Yacht, Dining & Tours', 'LIVE EXPERIENCES CATALOG');
    await selectAdminTabAndVerify(page, '5. Stay: 24/7 Chat & Requests', 'Concierge');
    await captureDualScreenshot(page, 'e2e-admin-concierge.png');
    await selectAdminTabAndVerify(page, '6. Stay Summary & Feedback', 'Stay Summary, Acquired Services & Guest Feedback');
    await captureDualScreenshot(page, 'e2e-admin-folio.png');
    await selectAdminTabAndVerify(page, '1. Live Summary & Alerts', 'SANCTUARY COMMAND CENTER');
    expect([...monitor.pageErrors, ...monitor.consoleErrors, ...monitor.overflowErrors]).toEqual([]);
  });

  test('E2E-A03..A06: Bilateral Hospitality Lifecycle, Chauffeur Sync & Live Configurable Catalogs', async ({
    browser,
  }) => {
    // Arrange — Create fresh stay & open both Admin and Guest contexts
    const adminPage = await browser.newPage({ viewport: { width: 1440, height: 900 } });
    const guestPage = await browser.newPage({ viewport: { width: 430, height: 932 } });
    await installAdminLoginNormalizer(adminPage);
    const adminMon = attachErrorMonitor(adminPage);
    const guestMon = attachErrorMonitor(guestPage);
    await adminPage.goto(ADMIN_DASHBOARD_URL);
    await waitForFlutterSemantics(adminPage, 'KACHAVA LUX');
    const token = await fetchAdminAuthToken(adminPage);
    const authHeader = { Authorization: `Bearer ${token}` };
    const createRes = await browserFetchJson(
      adminPage,
      `${API_BASE_URL}/admin/stays`,
      'POST',
      { guestName: 'Elena Rostova', villaId: 'villa-104', villaName: 'Villa 104 — Jaguar Sanctuary', nights: 4, guestsCount: 2 },
      authHeader,
    );
    expect(createRes.status).toBe(201);
    const createdStay = (createRes.body.data as Record<string, unknown>).stay as Record<string, unknown>;
    const stayId = createdStay.stayId as string;
    const guestUuid = createdStay.guestTokenUuid as string;
    // Act & Assert 1 — Open Guest Portal (:3000/?guestId=<guestUuid>) & verify zero-mock initial state
    await guestPage.goto(`${GUEST_PORTAL_URL}/?guestId=${guestUuid}`);
    const guestHome = await waitForFlutterSemantics(guestPage, 'Elena Rostova');
    expect(guestHome).toContain('Not registered yet — Tap to enter your arrival flight');
    expect(guestHome).toContain('Tap to configure pillows, diet & allergies');
    expect(guestHome).toContain('0 items selected');
    expect(guestHome).not.toContain('23°C');
    // Act & Assert 2 — Guest submits flight details & diet/allergy preferences -> Admin receives Guest-only alerts
    const trfGuest = await browserFetchJson(guestPage, `${API_BASE_URL}/stays/${guestUuid}/transfer`, 'PATCH', {
      arrivalDate: '2026-12-10',
      arrivalAirport: 'Cancun International (CUN)',
      airline: 'Aeroméxico',
      flightNumber: 'AM 420',
      terminal: 'Terminal 3',
      estimatedLanding: '14:30',
      partySize: 2,
    });
    expect(trfGuest.status).toBe(200);
    const prefGuest = await browserFetchJson(guestPage, `${API_BASE_URL}/stays/${guestUuid}/personalization`, 'PATCH', {
      pillowType: 'Goose Down',
      scentProfile: 'Copal & Amber',
      dietary: 'Pescatarian',
      dietaryAllergies: ['Shellfish'],
      allergies: 'Shellfish',
    });
    expect(prefGuest.status).toBe(200);
    const alertsRes = await browserFetchJson(adminPage, `${API_BASE_URL}/admin/alerts`, 'GET', undefined, authHeader);
    const alerts = (alertsRes.body.data as { alerts: Array<Record<string, unknown>> }).alerts;
    expect(alerts.length).toBeGreaterThanOrEqual(2);
    const ackRes = await browserFetchJson(adminPage, `${API_BASE_URL}/admin/alerts/${alerts[0].alertId}/acknowledge`, 'PATCH', {}, authHeader);
    expect(ackRes.status).toBe(200);
    // Act & Assert 3 — HOST ADMIN assigns Chauffeur & Meeting Point -> syncs back to Guest transport screen
    const assignTrf = await browserFetchJson(adminPage, `${API_BASE_URL}/admin/stays/${stayId}/transfer`, 'PATCH', {
      assignedDriver: 'Carlos · Escalade ESV #04',
      vehicleModel: 'Escalade ESV #04',
      meetingPoint: 'Terminal 3 FBO · Gate 4',
      status: 'Confirmed',
    }, authHeader);
    expect(assignTrf.status).toBe(200);
    expect(await clickSemanticsByText(guestPage, '1. Flight & Airport Transfer')).toBe(true);
    const transportSemantics = await waitForFlutterSemantics(guestPage, 'Carlos · Escalade ESV #04');
    expect(transportSemantics).toContain('AM 420');
    expect(transportSemantics).toContain('Terminal 3 FBO · Gate 4');
    expect(transportSemantics).toContain('Confirmed');
    // Act & Assert 4 — Configurable Experience & Category-Free Larder Catalogs sync live to Guest Portal
    const expCatRes = await browserFetchJson(adminPage, `${API_BASE_URL}/admin/catalog/experiences`, 'POST', {
      title: 'Mayan Stargazing Ritual',
      category: 'Adventure',
      duration: '3 Hours',
      priceText: '$320 USD',
      basePriceUSD: 320,
      isIncluded: false,
      description: 'Private rooftop telescope & ancestral astronomy.',
    }, authHeader);
    expect(expCatRes.status).toBe(201);
    const expId = (expCatRes.body.data as Record<string, unknown>).id as string;
    const larderCatRes = await browserFetchJson(adminPage, `${API_BASE_URL}/admin/catalog/larder`, 'POST', {
      name: 'Kombucha Hibiscus Elixir',
      price: 24,
    }, authHeader);
    expect(larderCatRes.status).toBe(201);
    const larderId = (larderCatRes.body.data as Record<string, unknown>).id as string;
    const guestExpCat = await browserFetchJson(guestPage, `${API_BASE_URL}/catalog/experiences`, 'GET');
    const guestLarderCat = await browserFetchJson(guestPage, `${API_BASE_URL}/catalog/larder`, 'GET');
    expect(JSON.stringify(guestExpCat.body.data)).toContain('Mayan Stargazing Ritual');
    expect(JSON.stringify(guestLarderCat.body.data)).toContain('Kombucha Hibiscus Elixir');
    expect((await browserFetchJson(adminPage, `${API_BASE_URL}/admin/catalog/experiences/${expId}`, 'DELETE', undefined, authHeader)).status).toBe(200);
    expect((await browserFetchJson(adminPage, `${API_BASE_URL}/admin/catalog/larder/${larderId}`, 'DELETE', undefined, authHeader)).status).toBe(200);
    // Act & Assert 5 — Admin Checkout Approval & Token Rotation
    expect((await browserFetchJson(adminPage, `${API_BASE_URL}/admin/stays/${stayId}/folio/approve-checkout`, 'PATCH', { approveLateCheckout: true }, authHeader)).status).toBe(200);
    expect((await browserFetchJson(adminPage, `${API_BASE_URL}/admin/stays/${stayId}/regenerate-token`, 'POST', {}, authHeader)).status).toBe(201);
    expect([...adminMon.pageErrors, ...guestMon.pageErrors, ...adminMon.overflowErrors, ...guestMon.overflowErrors]).toEqual([]);
    await guestPage.close();
    await adminPage.close();
  });

  test('E2E-R01 & E2E-R02: Responsive Breakpoints (768x1024, 320x780) & Cross-App Live Sync', async ({
    browser,
  }) => {
    // Arrange — Open Guest & Admin Browser Contexts at 768x1024 Tablet Breakpoint
    const guestPage = await browser.newPage({ viewport: { width: 768, height: 1024 } });
    const adminPage = await browser.newPage({ viewport: { width: 768, height: 1024 } });
    await installAdminLoginNormalizer(adminPage);
    const guestMon = attachErrorMonitor(guestPage);
    const adminMon = attachErrorMonitor(adminPage);
    await adminPage.goto(ADMIN_DASHBOARD_URL);
    await waitForFlutterSemantics(adminPage, 'SANCTUARY COMMAND CENTER');
    const active102 = await ensureActiveVilla102Stay(adminPage);
    await guestPage.goto(`${GUEST_PORTAL_URL}/?guestId=${active102.guestUuid}`);
    await waitForFlutterSemantics(guestPage, 'VILLA 102');
    await assertNoHorizontalOverflow(guestPage);
    await assertNoHorizontalOverflow(adminPage);
    // Act — Resize to 320x780 Mobile & Capture Screenshot
    await guestPage.setViewportSize({ width: 320, height: 780 });
    await adminPage.setViewportSize({ width: 320, height: 780 });
    await waitForFlutterSemantics(adminPage, '1. Summary');
    await assertNoHorizontalOverflow(guestPage);
    await assertNoHorizontalOverflow(adminPage);
    await captureDualScreenshot(adminPage, 'e2e-admin-mobile-320.png');
    // Act & Assert — E2E-R02 Cross-App Guest -> Admin Concierge Sync
    const syncTitle = `Cross-App Sync Orchid Refresh ${Date.now()}`;
    const postRes = await browserFetchJson(guestPage, `${API_BASE_URL}/stays/${active102.guestUuid}/concierge-requests`, 'POST', {
      type: 'request',
      category: 'HOUSEKEEPING',
      title: syncTitle,
    });
    expect(postRes.status).toBe(201);
    const token = await fetchAdminAuthToken(adminPage);
    const adminList = await browserFetchJson(adminPage, `${API_BASE_URL}/admin/concierge-requests`, 'GET', undefined, {
      Authorization: `Bearer ${token}`,
    });
    expect(JSON.stringify(adminList.body.data)).toContain(syncTitle);
    expect([...guestMon.pageErrors, ...adminMon.pageErrors, ...guestMon.overflowErrors, ...adminMon.overflowErrors]).toEqual([]);
    await guestPage.close();
    await adminPage.close();
  });
});
