import request from 'supertest';
import { createTestApp, createVillaAndStay, CreatedStay, TestApp } from '../support/test-app';
import { FixedClock, patchSettings } from '../support/trip-setup';

const ADMIN = '/api/v1/admin';
/** 2026-11-20 07:00 at the resort (America/Cancun, UTC-5). */
const NOW = new Date('2026-11-20T12:00:00.000Z');
const SETTINGS = { timeZone: 'America/Cancun', checkInTime: '15:00', transportAlertLeadHours: 12 };

/** Dashboard, Reservations, Guests, Tasks, Notifications and the Messages inbox on an empty store. */
describe('Command center operations (phases 6-8)', () => {
  let t: TestApp;
  let admin: Record<string, string>;

  const get = (path: string) => request(t.server()).get(`${ADMIN}${path}`).set(admin);
  const patch = (path: string, body: object) => request(t.server()).patch(`${ADMIN}${path}`).set(admin).send(body);
  const post = (path: string, body: object = {}) => request(t.server()).post(`${ADMIN}${path}`).set(admin).send(body);
  const checkIn = (stay: CreatedStay) => patch(`/stays/${stay.stayId}`, { action: 'CHECK_IN' });

  beforeEach(async () => {
    t = await createTestApp(undefined, { clock: new FixedClock(NOW) });
    admin = await t.adminHeaders();
  });

  afterEach(() => t.close());

  describe('GET /admin/dashboard', () => {
    it('test_dashboard_withoutTimeZone_is422SettingsRequired', async () => {
      const res = await get('/dashboard');

      expect(res.status).toBe(422);
      expect(res.body).toMatchObject({ code: 'SETTINGS_REQUIRED', details: ['timeZone'] });
    });

    it('test_dashboard_kpisAndTodaysActivity_fromRealStays', async () => {
      await patchSettings(t, SETTINGS);
      await createVillaAndStay(t, { villaName: 'Villa A', guestName: 'Ana Arrival', checkIn: '2026-11-20', checkOut: '2026-11-23' });
      const inHouse = await createVillaAndStay(t, { villaName: 'Villa B', guestName: 'Bea House', checkIn: '2026-11-18', checkOut: '2026-11-25' });
      const departing = await createVillaAndStay(t, { villaName: 'Villa C', guestName: 'Carl Leaving', checkIn: '2026-11-17', checkOut: '2026-11-20' });
      const overstay = await createVillaAndStay(t, { villaName: 'Villa D', guestName: 'Dan Over', checkIn: '2026-11-10', checkOut: '2026-11-19' });
      await createVillaAndStay(t, { villaName: 'Villa E', guestName: 'Eve Future', checkIn: '2026-12-01', checkOut: '2026-12-04' });
      for (const stay of [inHouse, departing, overstay]) expect((await checkIn(stay)).status).toBe(200);

      const res = await get('/dashboard');

      expect(res.status).toBe(200);
      expect(res.body.data.resortDate).toBe('2026-11-20');
      expect(res.body.data.kpis).toEqual({
        occupiedVillas: 3, availableVillas: 2, occupancyPct: 60, arrivals: 1, departures: 1, openRequests: 0,
      });
      expect(res.body.data.activity.total).toBe(4);
      expect(res.body.data.activity.rows.map((r: { guestName: string; status: string; overdue: boolean }) => [r.guestName, r.status, r.overdue]))
        .toEqual([
          ['Dan Over', 'IN_HOUSE', true],
          ['Carl Leaving', 'DEPARTURE', false],
          ['Ana Arrival', 'ARRIVAL', false],
          ['Bea House', 'IN_HOUSE', false],
        ]);
      expect(res.body.data.activity.rows[0]).toEqual(expect.objectContaining({ stayId: overstay.stayId, villaName: 'Villa D' }));
    });
  });

  describe('Reservations (/admin/stays)', () => {
    let ana: CreatedStay;

    beforeEach(async () => {
      await patchSettings(t, SETTINGS);
      ana = await createVillaAndStay(t, { villaName: 'Villa 1', guestName: 'Ana Peña', checkIn: '2026-12-01', checkOut: '2026-12-09' });
      await createVillaAndStay(t, { villaName: 'Villa 2', guestName: 'Bruno Test', checkIn: '2026-12-03', checkOut: '2026-12-05' });
    });

    it('test_list_rowsHaveTheTableFields_andSortByCheckOut', async () => {
      const byArrival = await get('/stays');
      const byDeparture = await get('/stays?sort=checkOut:desc');
      const range = await get('/stays?sort=checkOut:asc&from=2026-12-06');

      expect(byArrival.body.data[0]).toEqual({
        id: ana.stayId, guestName: 'Ana Peña', villaId: ana.villaId, villaName: 'Villa 1', checkIn: '2026-12-01',
        checkOut: '2026-12-09', status: 'PRE_ARRIVAL', resortHostName: null,
        magicLinkUrl: `http://localhost:3000/?guestId=${ana.guestTokenUuid}`,
      });
      expect(byDeparture.body.data.map((r: { guestName: string }) => r.guestName)).toEqual(['Ana Peña', 'Bruno Test']);
      expect(range.body.data.map((r: { guestName: string }) => r.guestName)).toEqual(['Ana Peña']);
      expect(byArrival.body.meta).toMatchObject({ page: 1, pageSize: 25, total: 2 });
    });

    it('test_list_filtersAndSearch', async () => {
      expect((await get('/stays?q=pena')).body.data.map((r: { id: string }) => r.id)).toEqual([ana.stayId]);
      expect((await get(`/stays?villaId=${ana.villaId}`)).body.meta.total).toBe(1);
      expect((await get('/stays?status=ACTIVE_STAY')).body.meta.total).toBe(0);
      expect((await get('/stays?from=2026-12-05&to=2026-12-01')).status).toBe(422);
      expect((await get('/stays?sort=guestName:asc')).status).toBe(400);
    });

    it('test_detailAndPatch_hostNotesWifiLanguage_thenCheckInAndCheckOut', async () => {
      const edited = await patch(`/stays/${ana.stayId}`, {
        resortHostName: 'Laura', resortHostStaffId: 'staff-3', internalNotes: 'Honeymoon', language: 'es',
        wifi: { ssid: 'Ana-Net', password: 'pw-1' },
      });
      const checkedIn = await checkIn(ana);
      const checkedOut = await patch(`/stays/${ana.stayId}`, { action: 'CHECK_OUT' });
      const detail = await get(`/stays/${ana.stayId}`);
      const row = (await get('/stays')).body.data[0];
      const guestView = await request(t.server()).get(`/api/v1/stays/${ana.guestTokenUuid}`);

      expect(edited.status).toBe(200);
      expect(edited.body.data).toMatchObject({
        resortHost: { staffId: 'staff-3', name: 'Laura' }, internalNotes: 'Honeymoon', language: 'es',
        wifi: { ssid: 'Ana-Net', password: 'pw-1' }, nights: 8,
      });
      expect(checkedIn.body.data.status).toBe('ACTIVE_STAY');
      expect(checkedOut.body.data.status).toBe('CHECKED_OUT');
      expect(detail.body.data.statusHistory.map((h: { to: string }) => h.to)).toEqual(['ACTIVE_STAY', 'CHECKED_OUT']);
      expect(row.resortHostName).toBe('Laura');
      expect(JSON.stringify(guestView.body)).not.toContain('Honeymoon');
    });

    it('test_cancel_needsAReason_andIllegalMovesAre422', async () => {
      const noReason = await patch(`/stays/${ana.stayId}`, { action: 'CANCEL' });
      const cancelled = await patch(`/stays/${ana.stayId}`, { action: 'CANCEL', reason: 'Guest request' });
      const afterCancel = await patch(`/stays/${ana.stayId}`, { action: 'CHECK_IN' });
      const unknownAction = await patch(`/stays/${ana.stayId}`, { action: 'TELEPORT' });

      expect(noReason.status).toBe(422);
      expect(cancelled.body.data).toMatchObject({ status: 'CANCELLED', cancellationReason: 'Guest request' });
      expect(afterCancel.status).toBe(422);
      expect(unknownAction.status).toBe(400);
      expect((await get('/stays/missing')).status).toBe(404);
      expect((await patch('/stays/missing', { internalNotes: 'x' })).status).toBe(404);
    });

    it('test_folio_listsAcquiredServicesWithSnapshots_andCharges', async () => {
      const serviceId = await activeBookingService(t, admin);
      await request(t.server()).post(`/api/v1/stays/${ana.guestTokenUuid}/bookings`)
        .send({ serviceId, scheduledDate: '2026-12-02', scheduledTimeSlot: '10:00', partySize: 2 });

      const folio = await get(`/stays/${ana.stayId}/folio`);

      expect(folio.status).toBe(200);
      expect(folio.body.data).toMatchObject({
        stay: { id: ana.stayId, guestName: 'Ana Peña', nights: 8 },
        services: [{ type: 'BOOKING', serviceId, totalUSD: 100, chargeToFolio: true, snapshot: { totalUSD: 100 } }],
        rating: null,
        charges: { totalUSD: 100 },
        pmsIntegrated: false,
      });
    });
  });

  describe('Guests (/admin/guests)', () => {
    it('test_list_oneRowPerStay_andStaffOnlyProfile', async () => {
      await patchSettings(t, SETTINGS);
      const ana = await createVillaAndStay(t, { villaName: 'Villa 1', guestName: 'Ana Peña' });
      await createVillaAndStay(t, { villaName: 'Villa 2', guestName: 'Bruno Test' });
      const guestPath = `/api/v1/stays/${ana.guestTokenUuid}`;
      await request(t.server()).patch(`${guestPath}/personalization`).send({ dietaryAllergies: ['Peanuts'], pillowType: 'Firm' });
      await request(t.server()).post(`${guestPath}/concierge-requests`).send({ title: 'Towels', details: 'Two more' });
      await patch(`/stays/${ana.stayId}`, { internalNotes: 'VIP', language: 'en' });

      const list = await get('/guests?q=ana');
      const profile = await get(`/guests/${ana.stayId}`);

      expect(list.body.data).toEqual([{
        stayId: ana.stayId, guestName: 'Ana Peña', villaId: ana.villaId, villaName: 'Villa 1', checkIn: '2026-12-01',
        checkOut: '2026-12-04', status: 'PRE_ARRIVAL', language: 'en', hasAllergies: true, openRequests: 1,
      }]);
      expect(profile.body.data).toMatchObject({
        stayId: ana.stayId, internalNotes: 'VIP', preferences: { pillow: 'Firm' },
        allergies: { hasAllergies: true, items: ['Peanuts'] },
        requestHistory: [{ type: 'REQUEST', title: 'Towels', open: true }],
      });
      expect((await get('/guests/missing')).status).toBe(404);
    });

    it('test_guestRoutes_areStaffOnly', async () => {
      const coordinator = await t.staffHeaders('DEPARTMENT_COORDINATOR');

      expect((await request(t.server()).get(`${ADMIN}/guests`)).status).toBe(401);
      expect((await request(t.server()).get(`${ADMIN}/guests`).set(coordinator)).status).toBe(403);
    });
  });

  describe('Tasks (/admin/tasks)', () => {
    beforeEach(() => patchSettings(t, SETTINGS));

    it('test_createListTransition_withOwnerAndCompletionNote', async () => {
      const stay = await createVillaAndStay(t, { villaName: 'Villa 1', guestName: 'Ana Test' });
      const late = await post('/tasks', { title: 'Fix AC', category: 'Maintenance', priority: 'URGENT', dueAt: '2026-11-20T06:00', stayId: stay.stayId });
      const later = await post('/tasks', { title: 'Flowers', category: 'Housekeeping', dueAt: '2026-11-21T09:00', ownerStaffId: 'staff-9', ownerName: 'Mia' });

      expect(late.status).toBe(201);
      expect(late.body.data).toMatchObject({
        status: 'PENDING', priority: 'URGENT', dueAt: '2026-11-20T11:00:00.000Z', overdue: true,
        villaName: 'Villa 1', guestName: 'Ana Test', source: { type: 'MANUAL', refId: null, stayId: stay.stayId },
      });
      expect(later.body.data).toMatchObject({ status: 'ASSIGNED', ownerStaffId: 'staff-9', overdue: false });

      const overdue = await get('/tasks?overdue=true');
      const byOwner = await get('/tasks?owner=staff-9');
      const desc = await get('/tasks?sort=dueAt:desc');
      expect(overdue.body.data.map((x: { title: string }) => x.title)).toEqual(['Fix AC']);
      expect(byOwner.body.meta.total).toBe(1);
      expect(desc.body.data[0].title).toBe('Flowers');

      const id = late.body.data.id;
      expect((await post(`/tasks/${id}/transition`, { to: 'ASSIGNED' })).status).toBe(422);
      expect((await post(`/tasks/${id}/transition`, { to: 'ASSIGNED', ownerStaffId: 'staff-1' })).body.data.status).toBe('ASSIGNED');
      expect((await post(`/tasks/${id}/transition`, { to: 'COMPLETED' })).status).toBe(422);
      const done = await post(`/tasks/${id}/transition`, { to: 'COMPLETED', note: 'Replaced filter' });
      expect(done.body.data).toMatchObject({ status: 'COMPLETED', overdue: false, completion: { note: 'Replaced filter', by: 'admin-service@test.local' } });
      expect((await patch(`/tasks/${id}`, { title: 'x' })).status).toBe(422);
    });

    it('test_patch_andValidation', async () => {
      const created = await post('/tasks', { title: 'Flowers', category: 'Housekeeping' });
      const edited = await patch(`/tasks/${created.body.data.id}`, { priority: 'HIGH', dueAt: '2026-11-22T10:00:00Z' });

      expect(edited.body.data).toMatchObject({ priority: 'HIGH', dueAt: '2026-11-22T10:00:00.000Z' });
      expect((await post('/tasks', { category: 'x' })).status).toBe(400);
      expect((await post('/tasks', { title: 'x', category: 'x', stayId: 'missing' })).status).toBe(404);
      expect((await get('/tasks?overdue=false')).status).toBe(400);
      expect((await get('/tasks?sort=title:asc')).status).toBe(400);
      expect((await get('/tasks/missing')).status).toBe(404);
    });

    it('test_guestActivity_createsTasksOncePerSource', async () => {
      const stay = await createVillaAndStay(t, { villaName: 'Villa 1', guestName: 'Ana Test' });
      const guestPath = `/api/v1/stays/${stay.guestTokenUuid}`;
      const bookingServiceId = await activeBookingService(t, admin, { operation: { requiresConfirmation: true } });
      const { serviceId: stockId, itemId } = await activeStockingService(t, admin);
      const prefId = await activePreferenceService(t, admin);

      await request(t.server()).post(`${guestPath}/bookings`).send({ serviceId: bookingServiceId, scheduledDate: '2026-12-02', scheduledTimeSlot: '10:00' });
      await request(t.server()).post(`${guestPath}/bookings`).send({ serviceId: prefId, scheduledDate: '2026-12-01' });
      for (const quantity of [1, 2]) {
        await request(t.server()).put(`${guestPath}/larder`).send({ serviceId: stockId, items: [{ itemId, quantity }] });
      }

      const tasks = await get('/tasks?pageSize=50');
      const bySource = tasks.body.data.map((x: { source: { type: string } }) => x.source.type).sort();
      expect(bySource).toEqual(['BOOKING', 'ORDER', 'PREFERENCE']);
      const order = tasks.body.data.find((x: { source: { type: string } }) => x.source.type === 'ORDER');
      expect(order).toMatchObject({ dueAt: '2026-12-01T20:00:00.000Z', villaName: 'Villa 1', status: 'PENDING' });
      expect((await get('/dashboard')).body.data.kpis.openRequests).toBe(3 + 3);
    });
  });

  describe('Notifications (/admin/notifications)', () => {
    it('test_storedAndComputedEvents_levelsTargetsAndReadState', async () => {
      await patchSettings(t, SETTINGS);
      const ana = await createVillaAndStay(t, { villaName: 'Villa 1', guestName: 'Ana Arrival', checkIn: '2026-11-20', checkOut: '2026-11-22' });
      const task = await post('/tasks', { title: 'Late task', category: 'Ops', priority: 'URGENT', dueAt: '2026-11-20T06:00' });

      const list = await get('/notifications');
      const events = list.body.data.map((n: { event: string }) => n.event).sort();
      expect(events).toEqual(['ARRIVAL_DAY', 'NEW_RESERVATION', 'TASK_OVERDUE']);
      const overdue = list.body.data.find((n: { event: string }) => n.event === 'TASK_OVERDUE');
      expect(overdue).toMatchObject({
        level: 'URGENT', playSound: true, read: false, category: 'TASK',
        targetRef: { type: 'TASK', id: task.body.data.id, stayId: null },
      });
      const arrival = list.body.data.find((n: { event: string }) => n.event === 'ARRIVAL_DAY');
      expect(arrival).toMatchObject({ level: 'INFO', playSound: false, targetRef: { type: 'STAY', id: ana.stayId, stayId: ana.stayId } });
      expect(list.body.meta.unreadCount).toBe(3);

      expect((await get('/notifications?level=INFO')).body.meta.total).toBe(2);
      expect((await get('/notifications?category=RESERVATION')).body.meta.total).toBe(1);
      expect((await get('/notifications?level=LOUD')).status).toBe(400);

      const read = await post(`/notifications/${arrival.id}/read`);
      expect(read.body.data).toMatchObject({ id: arrival.id, read: true });
      expect((await get('/notifications?read=true')).body.data.map((n: { id: string }) => n.id)).toEqual([arrival.id]);
      expect((await get('/notifications/unread-count')).body.data).toEqual({ unreadCount: 2, urgentUnreadCount: 1 });

      expect((await post('/notifications/read-all')).body.data).toEqual({ marked: 2 });
      expect((await get('/notifications/unread-count')).body.data).toEqual({ unreadCount: 0, urgentUnreadCount: 0 });
      expect((await post('/notifications/alt_missing/read')).status).toBe(404);
      expect((await post('/notifications/arrival_missing_2026-11-20/read')).status).toBe(404);
    });
  });

  describe('Messages inbox (/admin/conversations)', () => {
    beforeEach(async () => {
      // Guest messages are stamped with the system clock, so the inbox runs on it too.
      await t.close();
      t = await createTestApp();
      admin = await t.adminHeaders();
    });

    it('test_guestMessages_inbox_reply_visibleToGuest_andRead', async () => {
      const ana = await createVillaAndStay(t, { villaName: 'Villa 1', guestName: 'Ana Peña' });
      const bruno = await createVillaAndStay(t, { villaName: 'Villa 2', guestName: 'Bruno Test' });
      const guestPath = `/api/v1/stays/${ana.guestTokenUuid}`;
      const thread = await request(t.server()).post(`${guestPath}/concierge-requests`)
        .send({ title: 'Towels', details: 'Two more please', photoStoragePath: `private/stays/${ana.stayId}/concierge/r1/photo.jpg` });
      await request(t.server()).post(`${guestPath}/concierge-requests/${thread.body.data.requestId}/messages`).send({ text: 'Thanks!' });

      const inbox = await get('/conversations');
      expect(inbox.body.data).toHaveLength(1);
      expect(inbox.body.data[0]).toMatchObject({
        stayId: ana.stayId, guestName: 'Ana Peña', villaName: 'Villa 1', unreadCount: 2, awaitingReply: true,
        lastMessage: { text: 'Thanks!', from: 'GUEST', hasPhoto: false },
      });
      expect((await get('/conversations/unread-count')).body.data).toEqual({ unreadConversations: 1, unreadMessages: 2 });

      const notifications = await get('/notifications?category=CONCIERGE');
      const message = notifications.body.data.find((n: { event: string }) => n.event === 'GUEST_MESSAGE');
      expect(message).toMatchObject({ level: 'ACTION', targetRef: { type: 'CONVERSATION', id: ana.stayId } });

      const reply = await post(`/conversations/${ana.stayId}/messages`, { text: 'On the way' });
      expect(reply.status).toBe(201);
      expect(reply.body.data).toMatchObject({ from: 'STAFF', text: 'On the way', photoUrl: null });

      const guestThreads = await request(t.server()).get(`${guestPath}/concierge-requests`);
      expect(guestThreads.body.data[0].messages.map((m: { text: string }) => m.text)).toEqual(['Two more please', 'Thanks!', 'On the way']);

      const messages = await get(`/conversations/${ana.stayId}/messages?pageSize=2`);
      expect(messages.body.data.map((m: { text: string }) => m.text)).toEqual(['Thanks!', 'On the way']);
      expect(messages.body.meta.total).toBe(3);
      const older = await get(`/conversations/${ana.stayId}/messages?pageSize=2&page=2`);
      expect(older.body.data[0]).toMatchObject({ text: 'Two more please', from: 'GUEST' });
      expect(older.body.data[0].photoUrl).toContain(`stays/${ana.stayId}/concierge/r1/photo.jpg`);

      expect((await get('/conversations?awaitingReply=true')).body.meta.total).toBe(0);
      expect((await get('/conversations?unread=true')).body.meta.total).toBe(0);
      expect((await get('/conversations?q=ana')).body.meta.total).toBe(1);

      const opened = await post(`/conversations/${bruno.stayId}/messages`, { text: 'Welcome!' });
      expect(opened.status).toBe(201);
      const brunoThreads = await request(t.server()).get(`/api/v1/stays/${bruno.guestTokenUuid}/concierge-requests`);
      expect(brunoThreads.body.data[0].messages[0].text).toBe('Welcome!');
      expect((await get('/conversations')).body.data.map((r: { stayId: string }) => r.stayId)).toEqual([bruno.stayId, ana.stayId]);

      await request(t.server()).post(`${guestPath}/concierge-requests/${thread.body.data.requestId}/messages`).send({ text: 'One more' });
      expect((await get('/conversations?unread=true')).body.meta.total).toBe(1);
      expect((await post(`/conversations/${ana.stayId}/read`)).body.data).toMatchObject({ unreadCount: 0, awaitingReply: true });
      expect((await get('/conversations/unread-count')).body.data).toEqual({ unreadConversations: 0, unreadMessages: 0 });
      expect((await post('/conversations/missing/messages', { text: 'x' })).status).toBe(404);
      expect((await post(`/conversations/${ana.stayId}/messages`, { text: '' })).status).toBe(400);
    });
  });
});

async function createService(t: TestApp, admin: Record<string, string>, body: Record<string, unknown>): Promise<string> {
  const res = await request(t.server()).post(`${ADMIN}/services`).set(admin).send({
    shortDescription: { en: 'Short', es: 'Corta' },
    cover: { storagePath: 'catalog/services/cover.jpg' },
    status: 'ACTIVE',
    ...body,
  });
  if (res.status !== 201) throw new Error(`service: ${res.status} ${JSON.stringify(res.body)}`);
  return res.body.data.id;
}

function activeBookingService(t: TestApp, admin: Record<string, string>, extra: Record<string, unknown> = {}): Promise<string> {
  return createService(t, admin, {
    kind: 'EXPERIENCE', section: 'EXPERIENCES', usageType: 'BOOKING', name: { en: 'Cenote', es: 'Cenote' },
    pricing: { mode: 'PER_PERSON', amount: 50, chargeToFolio: true }, ...extra,
  });
}

function activePreferenceService(t: TestApp, admin: Record<string, string>): Promise<string> {
  return createService(t, admin, {
    kind: 'PREFERENCE', section: 'IN_VILLA', usageType: 'PREFERENCE', name: { en: 'Pillows', es: 'Almohadas' },
    pricing: { mode: 'INCLUDED', chargeToFolio: false },
  });
}

async function activeStockingService(t: TestApp, admin: Record<string, string>): Promise<{ serviceId: string; itemId: string }> {
  const serviceId = await createService(t, admin, {
    kind: 'VILLA_STOCKING', section: 'IN_VILLA', usageType: 'ORDER', name: { en: 'Stocking', es: 'Abastecimiento' },
    pricing: { mode: 'PER_UNIT', chargeToFolio: true },
  });
  const item = await request(t.server()).post(`${ADMIN}/services/${serviceId}/items`).set(admin)
    .send({ name: { en: 'Mango', es: 'Mango' }, priceUSD: 3, status: 'ACTIVE' });
  return { serviceId, itemId: item.body.data.id };
}
