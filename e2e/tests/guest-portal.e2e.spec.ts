import { expect, Page, test } from '@playwright/test';
import {
  ADMIN_STAFF_EMAIL,
  API_BASE_URL,
  assertNoHorizontalOverflow,
  attachErrorMonitor,
  browserFetchJson,
  captureDualScreenshot,
  clickSemanticsByText,
  ensureActiveVilla102Stay,
  GUEST_PORTAL_URL,
  readSemanticsSnapshot,
  waitForFlutterSemantics,
} from './e2e-helpers';

async function openDrawerAndSelectScreen(
  page: Page,
  drawerScreenLabel: string,
  expectedTextAfter: string,
): Promise<string> {
  const clickedOpen = await clickSemanticsByText(page, 'all screens');
  expect(clickedOpen).toBe(true);
  await waitForFlutterSemantics(page, 'Sanctuary Screen Switcher');
  if (/^(10|11|12|13)\./.test(drawerScreenLabel)) {
    const vp = page.viewportSize() || { width: 1280, height: 860 };
    await page.mouse.move(vp.width / 2, vp.height / 2);
    await page.mouse.wheel(0, 360);
    await page.waitForTimeout(250);
  }
  const clickedTile = await clickSemanticsByText(page, drawerScreenLabel);
  expect(clickedTile).toBe(true);
  const semantics = await waitForFlutterSemantics(page, expectedTextAfter);
  await assertNoHorizontalOverflow(page);
  return semantics;
}

async function createEphemeralTestStay(page: Page): Promise<{
  stayId: string;
  guestUuid: string;
  lastName: string;
}> {
  const loginRes = await browserFetchJson(page, `${API_BASE_URL}/admin/auth/login`, 'POST', {
    email: ADMIN_STAFF_EMAIL,
  });
  expect(loginRes.status).toBe(201);
  const token = (loginRes.body.data as Record<string, unknown>).token as string;
  const stayRes = await browserFetchJson(
    page,
    `${API_BASE_URL}/admin/stays`,
    'POST',
    { guestName: 'Julian Vance', villaId: 'villa-108', nights: 3, guestsCount: 2 },
    { Authorization: `Bearer ${token}` },
  );
  const stay = (stayRes.body.data as Record<string, unknown>).stay as Record<string, unknown>;
  return {
    stayId: stay.stayId as string,
    guestUuid: stay.guestTokenUuid as string,
    lastName: 'vance',
  };
}

test.describe('Kachava Lux Guest Experience Portal E2E (http://localhost:3000)', () => {
  test('E2E-G01: Magic-Link Auth, Veridical Home (Zero Fake Climate) & Invalid Token Gate', async ({
    page,
  }) => {
    // Arrange
    const monitor = attachErrorMonitor(page);
    await page.goto(`${GUEST_PORTAL_URL}/?guestId=invalid-token-999`);
    const active102 = await ensureActiveVilla102Stay(page);
    const stayGetPromise = page.waitForResponse(
      (res) =>
        res.url().includes(`/api/v1/stays/${active102.guestUuid}`) &&
        res.request().method() === 'GET',
    );
    // Act — Valid Magic Link
    await page.goto(`${GUEST_PORTAL_URL}/?guestId=${active102.guestUuid}`);
    const stayResponse = await stayGetPromise;
    const semantics = await waitForFlutterSemantics(page, 'VILLA 102');
    // Assert — Valid Stay Hydrated, Zero Fake 23°C Climate on Home, HOST ADMIN & Invalid Token Gate
    expect(stayResponse.status()).toBe(200);
    expect(semantics).toContain('432Hz');
    expect(semantics).toContain('EN | ES');
    expect(semantics).toContain('HOST ADMIN');
    expect(semantics).toContain('STAY STATUS');
    expect(semantics).not.toContain('23°C');
    await assertNoHorizontalOverflow(page);
    await captureDualScreenshot(page, 'e2e-guest-home.png');
    await page.goto(`${GUEST_PORTAL_URL}/?guestId=invalid-token-999`);
    const restricted = await waitForFlutterSemantics(page, 'Access Restricted');
    expect(restricted).toContain('Invalid Magic Link');
    expect(restricted).toContain('HOST ADMIN');
    await assertNoHorizontalOverflow(page);
    await captureDualScreenshot(page, 'e2e-guest-restricted.png');
    expect([...monitor.pageErrors, ...monitor.overflowErrors]).toEqual([]);
  });

  test('E2E-G02: 432Hz Soundscape, Bilingual Toggle & All 13 Sanctuary Screens Veridical Audit', async ({
    page,
  }) => {
    // Arrange
    const monitor = attachErrorMonitor(page);
    await page.goto(`${GUEST_PORTAL_URL}/?guestId=invalid-token-999`);
    const active102 = await ensureActiveVilla102Stay(page);
    await page.goto(`${GUEST_PORTAL_URL}/?guestId=${active102.guestUuid}`);
    await waitForFlutterSemantics(page, 'VILLA 102');
    // Act & Assert — Toggle Bilingual EN | ES -> ES | EN -> EN | ES & 432Hz Soundscape
    expect(await clickSemanticsByText(page, 'EN | ES')).toBe(true);
    await waitForFlutterSemantics(page, 'TU RESIDENCIA');
    expect(await clickSemanticsByText(page, 'ES | EN')).toBe(true);
    await waitForFlutterSemantics(page, 'YOUR RESIDENCE');
    expect(await clickSemanticsByText(page, 'Play 432Hz Sanctuary Soundscape')).toBe(true);
    await waitForFlutterSemantics(page, 'Pause 432Hz Sanctuary Soundscape');
    // Act & Assert — Navigate across all active Sanctuary Screens & verify Included Privileges & Philosophy 432Hz bar removed
    const transportSem = await openDrawerAndSelectScreen(page, '2. Private Aviation & Transfer', 'Private Airport Transportation');
    expect(transportSem).toContain('CHAUFFEUR & MEETING POINT (HOST ADMIN)');
    const personalizeSem = await openDrawerAndSelectScreen(page, '3. Stay Personalization', 'STAY PREFERENCES & ALLERGIES');
    expect(personalizeSem).toContain('Goose Down');
    expect(personalizeSem).toContain('Copal & Amber');
    expect(personalizeSem).toContain('Pescatarian');
    expect(personalizeSem).not.toContain('Step 1');
    expect(await clickSemanticsByText(page, 'all screens')).toBe(true);
    const drawerSem = await waitForFlutterSemantics(page, 'Sanctuary Screen Switcher');
    expect(drawerSem).not.toContain('4. Included Privileges');
    expect(drawerSem).not.toContain('Beneficios Incluidos');
    expect(await clickSemanticsByText(page, '5. Curated Excursions')).toBe(true);
    await waitForFlutterSemantics(page, 'CURATED SANCTUARY EXCURSIONS');
    // Verify Yacht package selection persists across 2-second polling cycle without deselecting
    await openDrawerAndSelectScreen(page, '6. Private Yacht Charter', 'Galeon 470 Sky');
    expect(await clickSemanticsByText(page, 'Extended Caribbean Experience')).toBe(true);
    await waitForFlutterSemantics(page, 'RESERVE YACHT CHARTER ($1000.00 USD DUE) →');
    await page.waitForTimeout(2300);
    expect(await readSemanticsSnapshot(page)).toContain('RESERVE YACHT CHARTER ($1000.00 USD DUE) →');
    // Verify Dining menu & evening selection persists across 2-second polling cycle without deselecting
    await openDrawerAndSelectScreen(page, '7. In-Villa Private Dining', 'In-Villa Chef Experience');
    expect(await clickSemanticsByText(page, 'Tierra Sagrada Heritage Menu')).toBe(true);
    await page.waitForTimeout(2300);
    expect(await readSemanticsSnapshot(page)).toContain('Tierra Sagrada Heritage Menu');
    // Verify Minibar (+) increment persists across 2-second polling cycle & category strip removed
    const larderSem = await openDrawerAndSelectScreen(page, '8. Villa Stocking & Larder', 'Stock My Villa');
    expect(larderSem).not.toContain('CHILLED IN LARDER');
    expect(await clickSemanticsByText(page, 'Increase')).toBe(true);
    await waitForFlutterSemantics(page, '1 items');
    await page.waitForTimeout(2300);
    expect(await readSemanticsSnapshot(page)).toContain('1 items');
    await captureDualScreenshot(page, 'e2e-guest-larder.png');
    await openDrawerAndSelectScreen(page, '9. 24/7 Dedicated Concierge', 'HOST ADMIN');
    await captureDualScreenshot(page, 'e2e-guest-concierge.png');
    await openDrawerAndSelectScreen(page, '10. Mid-Stay Check-In', 'MID-STAY CHECK-IN');
    const departureSem = await openDrawerAndSelectScreen(page, '11. Departure & Folio Ledger', 'Stay & Departure Summary');
    expect(departureSem).toContain('STAY DATES & TRANSFER SUMMARY');
    await captureDualScreenshot(page, 'e2e-guest-folio.png');
    const philosophySem = await openDrawerAndSelectScreen(page, '12. Biophilic Architecture', 'The Architecture of Stillness');
    expect(philosophySem).not.toContain('432Hz SANCTUARY SOUNDSCAPE');
    const profileSem = await openDrawerAndSelectScreen(page, '13. Guest Profile & Keycard', 'VILLA WI-FI NETWORK & PASSCODE');
    expect(profileSem).toContain('REGISTERED DIETARY & ALLERGY SUMMARY');
    expect(profileSem).not.toContain('NFC Digital Keycard');
    const homeSem = await openDrawerAndSelectScreen(page, '1. Residency Home', 'WELCOME TO KACHAVA LUX');
    expect(homeSem).not.toContain('23°C');
    expect(homeSem).not.toContain('Included Privileges');
    expect([...monitor.pageErrors, ...monitor.consoleErrors, ...monitor.overflowErrors]).toEqual([]);
  });

  test('E2E-G03..G05: Browser-Origin CORS Mutations, Unconditional Personalization Alert, Live Wi-Fi & Category-Free Larder', async ({
    page,
  }) => {
    // Arrange
    await page.goto(`${GUEST_PORTAL_URL}/?guestId=invalid-token-999`);
    const active102 = await ensureActiveVilla102Stay(page);
    await page.goto(`${GUEST_PORTAL_URL}/?guestId=${active102.guestUuid}`);
    await waitForFlutterSemantics(page, 'VILLA 102');
    const stayUrl = `${API_BASE_URL}/stays/${active102.guestUuid}`;
    const loginRes = await browserFetchJson(page, `${API_BASE_URL}/admin/auth/login`, 'POST', {
      email: ADMIN_STAFF_EMAIL,
    });
    const adminToken = (loginRes.body.data as Record<string, unknown>).token as string;
    const authHeader = { Authorization: `Bearer ${adminToken}` };
    // Act & Assert — E2E-G03 Transfer & Personalization (without allergies) emits DIETARY alert
    const transferRes = await browserFetchJson(page, `${stayUrl}/transfer`, 'PATCH', {
      airline: 'American Airlines',
      flightNumber: 'AA 1492',
      arrivalTime: '14:25',
      partySize: 2,
    });
    expect(transferRes.status).toBe(200);
    const prefRes = await browserFetchJson(page, `${stayUrl}/personalization`, 'PATCH', {
      pillowSelection: 'Organic Buckwheat & Lavender',
      scentProfile: 'Copal & Wild Fig',
      dietary: 'Pescatarian',
      allergies: '',
      dietaryAllergies: [],
    });
    expect(prefRes.status).toBe(200);
    const alertsRes = await browserFetchJson(page, `${API_BASE_URL}/admin/alerts`, 'GET', undefined, authHeader);
    const alerts = (alertsRes.body.data as { alerts: Array<Record<string, unknown>> }).alerts;
    expect(alerts.some((a) => a.category === 'DIETARY' && String(a.summary).includes('Organic Buckwheat & Lavender'))).toBe(true);
    // Act & Assert — Configure Wi-Fi via PATCH /api/v1/admin/stays/:stayId/wifi & verify live sync in :3000
    const wifiRes = await browserFetchJson(
      page,
      `${API_BASE_URL}/admin/stays/${active102.stayId}/wifi`,
      'PATCH',
      { wifiSsid: 'Kachava_Ceiba_5G', wifiPasscode: 'CeibaSanctuary2026' },
      authHeader,
    );
    expect(wifiRes.status).toBe(200);
    const stayCheck = await browserFetchJson(page, stayUrl, 'GET');
    const villaAccess = (stayCheck.body.data as Record<string, unknown>).villaAccess as Record<string, unknown>;
    expect(villaAccess.wifiSsid).toBe('Kachava_Ceiba_5G');
    expect(villaAccess.wifiPasscode).toBe('CeibaSanctuary2026');
    await waitForFlutterSemantics(page, 'Wi-Fi: Kachava_Ceiba_5G');
    // Act & Assert — Add Minibar catalog item without category & verify live sync to :3000
    const addLarderRes = await browserFetchJson(
      page,
      `${API_BASE_URL}/admin/catalog/larder`,
      'POST',
      { name: 'Cenote Botanical Tonic', price: 28 },
      authHeader,
    );
    expect(addLarderRes.status).toBe(201);
    const newLarderId = (addLarderRes.body.data as Record<string, unknown>).id as string;
    const larderCatRes = await browserFetchJson(page, `${API_BASE_URL}/catalog/larder`, 'GET');
    expect(JSON.stringify(larderCatRes.body.data)).toContain('Cenote Botanical Tonic');
    await browserFetchJson(page, `${API_BASE_URL}/admin/catalog/larder/${newLarderId}`, 'DELETE', undefined, authHeader);
    // Act & Assert — E2E-G04 Larder Order & E2E-G05 Booking
    const larderRes = await browserFetchJson(page, `${stayUrl}/larder`, 'PUT', {
      items: [{ itemId: 'pantry-mangoes', quantity: 2 }],
    });
    expect(larderRes.status).toBe(200);
    const bookingRes = await browserFetchJson(page, `${stayUrl}/bookings`, 'POST', {
      category: 'yacht',
      catalogRefId: 'yacht-galeon-500',
      scheduledDate: '2026-11-14',
      scheduledTimeSlot: '15:30',
    });
    expect(bookingRes.status).toBe(201);
  });

  test('E2E-G06..G07: Browser-Origin Concierge Request, Chat Message & Mid-Stay Check-In', async ({
    page,
  }) => {
    // Arrange
    await page.goto(`${GUEST_PORTAL_URL}/?guestId=invalid-token-999`);
    const active102 = await ensureActiveVilla102Stay(page);
    await page.goto(`${GUEST_PORTAL_URL}/?guestId=${active102.guestUuid}`);
    await waitForFlutterSemantics(page, 'VILLA 102');
    const stayUrl = `${API_BASE_URL}/stays/${active102.guestUuid}`;
    // Act & Assert — E2E-G06 Concierge Request + Message & E2E-G07 Mid-Stay Check-In
    const reqRes = await browserFetchJson(page, `${stayUrl}/concierge-requests`, 'POST', {
      type: 'request',
      category: 'CULINARY',
      title: 'E2E Artisanal Mezcal Tasting Setup',
    });
    expect(reqRes.status).toBe(201);
    const reqId = (reqRes.body.data as Record<string, unknown>).requestId as string;
    const msgRes = await browserFetchJson(
      page,
      `${stayUrl}/concierge-requests/${reqId}/messages`,
      'POST',
      { text: 'Include smoked sea salt and orange slices please.', senderName: 'Alex Miller' },
    );
    expect(msgRes.status).toBe(201);
    const midStayRes = await browserFetchJson(page, `${stayUrl}/midstay-checkin`, 'POST', {
      rating: 5,
      selectedSentiment: 'transcendent',
      note: 'Sanctuary acoustic harmony is extraordinary.',
    });
    expect(midStayRes.status).toBe(201);
  });

  test('E2E-G08: Step-Up Verification & Express Checkout on Ephemeral Stay', async ({ page }) => {
    // Arrange
    await page.goto(`${GUEST_PORTAL_URL}/?guestId=invalid-token-999`);
    const active102 = await ensureActiveVilla102Stay(page);
    await page.goto(`${GUEST_PORTAL_URL}/?guestId=${active102.guestUuid}`);
    await waitForFlutterSemantics(page, 'VILLA 102');
    const tempStay = await createEphemeralTestStay(page);
    // Act — Verify Step-Up & Submit Express Checkout
    const stepUpRes = await browserFetchJson(
      page,
      `${API_BASE_URL}/stays/${tempStay.guestUuid}/verify-step-up`,
      'POST',
      { villaNumber: '108', lastName: tempStay.lastName },
    );
    expect(stepUpRes.status).toBe(201);
    const stepUpToken = (stepUpRes.body.data as Record<string, unknown>).stepUpToken as string;
    const checkoutRes = await browserFetchJson(
      page,
      `${API_BASE_URL}/stays/${tempStay.guestUuid}/folio/checkout`,
      'POST',
      { lateCheckoutRequested: true, requestedCheckoutTime: '14:00' },
      { 'X-StepUp-Token': stepUpToken },
    );
    // Assert — Checkout Succeeded & Villa 102 Remains ACTIVE_STAY
    expect(checkoutRes.status).toBe(201);
    const villa102Res = await browserFetchJson(page, `${API_BASE_URL}/stays/${active102.guestUuid}`, 'GET');
    expect((villa102Res.body.data as Record<string, unknown>).status).toBe('ACTIVE_STAY');
  });
});
