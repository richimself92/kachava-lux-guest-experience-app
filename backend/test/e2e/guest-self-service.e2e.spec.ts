import request from 'supertest';
import { sourceTaskId } from '../../src/domain/tasks/task.models';
import { FakeFirestore } from '../support/fake-firestore';
import { storedAlerts } from '../support/stored-alerts';
import { forbiddenKeysIn } from '../support/guest-view-assertions';
import { createTestApp, createVillaAndStay, CreatedStay, TestApp } from '../support/test-app';
import { arrivalBody, FixedClock, setUpTripWorld } from '../support/trip-setup';

const ADMIN = '/api/v1/admin';

/** Guest self-service gaps of the guided portal: dates, journey marks, cancel/change, photos, orders. */
describe('Guest self-service endpoints', () => {
  let t: TestApp;
  let admin: Record<string, string>;
  let created: CreatedStay;
  let stayPath: string;
  let bookingServiceId: string;

  async function activeService(body: Record<string, unknown>): Promise<string> {
    const res = await request(t.server()).post(`${ADMIN}/services`).set(admin).send({
      shortDescription: { en: 'Short', es: 'Corta' },
      cover: { storagePath: 'catalog/services/cover.jpg' },
      status: 'ACTIVE',
      ...body,
    });
    expect(res.status).toBe(201);
    return res.body.data.id;
  }

  async function orderService(name: string, price: number): Promise<{ serviceId: string; itemId: string }> {
    const serviceId = await activeService({
      kind: 'VILLA_STOCKING', section: 'IN_VILLA', usageType: 'ORDER', name: { en: name, es: name },
      pricing: { mode: 'PER_UNIT', chargeToFolio: true }, stocking: { maxPerItem: 4 },
    });
    const item = await request(t.server()).post(`${ADMIN}/services/${serviceId}/items`).set(admin)
      .send({ name: { en: `${name} item`, es: `${name} item` }, priceUSD: price, status: 'ACTIVE' });
    return { serviceId, itemId: item.body.data.id };
  }

  const book = (body: Record<string, unknown> = {}) => request(t.server()).post(`${stayPath}/bookings`)
    .send({ serviceId: bookingServiceId, scheduledDate: '2026-12-02', scheduledTimeSlot: '10:00', partySize: 2, ...body });

  beforeEach(async () => {
    t = await createTestApp();
    admin = await t.adminHeaders();
    created = await createVillaAndStay(t, { villaName: 'Villa 7', guestName: 'Ana Test' });
    stayPath = `/api/v1/stays/${created.guestTokenUuid}`;
    bookingServiceId = await activeService({
      kind: 'EXPERIENCE', section: 'EXPERIENCES', usageType: 'BOOKING', name: { en: 'Cenote', es: 'Cenote' },
      pricing: { mode: 'PER_PERSON', amount: 50, chargeToFolio: true },
      availability: { maxGuests: 6, blockedDates: ['2026-12-25'] },
      operation: { responsibleDepartment: 'CONCIERGE', requiresConfirmation: true },
    });
  });

  afterEach(() => t.close());

  describe('stay view', () => {
    it('test_stayView_publishesIsoStayDatesAndEmptyJourneyMarks', async () => {
      const res = await request(t.server()).get(stayPath);

      expect(res.status).toBe(200);
      expect(res.body.data).toMatchObject({
        checkInDate: '2026-12-01', checkOutDate: '2026-12-04', skippedTaskIds: [], completedTaskIds: [],
      });
    });

    it('test_bookingAndOrderViews_carryCreatedAtAndUpdatedAt', async () => {
      const stock = await orderService('Bar', 4);
      await book();
      await request(t.server()).put(`${stayPath}/orders/${stock.serviceId}`).send({ items: [{ itemId: stock.itemId, quantity: 1 }] });

      const view = (await request(t.server()).get(stayPath)).body.data;

      for (const entry of [view.experienceBookings[0], view.larderOrders[0]]) {
        expect(entry.createdAt).toEqual(expect.stringMatching(/^\d{4}-\d{2}-\d{2}T/));
        expect(entry.updatedAt).toEqual(expect.stringMatching(/^\d{4}-\d{2}-\d{2}T/));
      }
    });
  });

  describe('PUT /stays/:guestUuid/journey', () => {
    it('test_journeyMarks_arePersistedOnTheStay', async () => {
      const res = await request(t.server()).put(`${stayPath}/journey`)
        .send({ skippedTaskIds: ['1:core:flight'], completedTaskIds: ['core:departure'] });
      const view = await request(t.server()).get(stayPath);

      expect(res.status).toBe(200);
      expect(res.body.data).toEqual({ skippedTaskIds: ['1:core:flight'], completedTaskIds: ['core:departure'] });
      expect(view.body.data).toMatchObject({ skippedTaskIds: ['1:core:flight'], completedTaskIds: ['core:departure'] });
    });

    it.each([
      { skippedTaskIds: 'core:flight' },
      { skippedTaskIds: ['bad id with spaces'] },
      { completedTaskIds: Array.from({ length: 61 }, (_, i) => `t${i}`) },
    ])('test_journeyMarks_invalid_%j_is400', async (body) => {
      expect((await request(t.server()).put(`${stayPath}/journey`).send(body)).status).toBe(400);
    });
  });

  describe('booking cancel and change', () => {
    it('test_cancel_requestedBooking_cancelsItsFolioLineTaskAndAlertsStaff', async () => {
      const booking = (await book()).body.data;

      const res = await request(t.server()).post(`${stayPath}/bookings/${booking.bookingId}/cancel`);
      const folio = await request(t.server()).get(stayPath);
      const task = await request(t.server()).get(`${ADMIN}/tasks/${sourceTaskId('BOOKING', booking.bookingId)}`).set(admin);
      const alerts = storedAlerts(t.fake, 'BOOKING');

      expect(res.status).toBe(200);
      expect(res.body.data).toMatchObject({ bookingId: booking.bookingId, status: 'CANCELLED', cancellationReason: 'Cancelled by guest' });
      expect(forbiddenKeysIn(res.body.data)).toEqual([]);
      expect(folio.body.data.folioSummary.incidentalsSubtotalUSD).toBe(0);
      expect(task.body.data.status).toBe('CANCELLED');
      expect(alerts.some((a) => a.title.includes('cancelled by guest'))).toBe(true);
    });

    it('test_cancel_confirmedBooking_is422', async () => {
      const booking = (await book()).body.data;
      await request(t.server()).post(`${ADMIN}/requests/${booking.bookingId}/transition`).set(admin).send({ action: 'CONFIRM' }).expect(200);

      const res = await request(t.server()).post(`${stayPath}/bookings/${booking.bookingId}/cancel`);

      expect(res.status).toBe(422);
    });

    it('test_cancel_unknownOrOtherStaysBooking_is404', async () => {
      const other = await createVillaAndStay(t, { villaName: 'Villa 8', guestName: 'Other Guest' });
      const foreign = (await request(t.server()).post(`/api/v1/stays/${other.guestTokenUuid}/bookings`)
        .send({ serviceId: bookingServiceId, scheduledDate: '2026-12-02' })).body.data;

      const statuses = [
        (await request(t.server()).post(`${stayPath}/bookings/bk_missing/cancel`)).status,
        (await request(t.server()).post(`${stayPath}/bookings/${foreign.bookingId}/cancel`)).status,
      ];

      expect(statuses).toEqual([404, 404]);
    });

    it('test_change_requestedBooking_movesDateTimeAndParty_andReprices', async () => {
      const booking = (await book()).body.data;

      const res = await request(t.server()).patch(`${stayPath}/bookings/${booking.bookingId}`)
        .send({ scheduledDate: '2026-12-03', scheduledTimeSlot: '15:30', partySize: 3 });
      const folio = await request(t.server()).get(stayPath);

      expect(res.status).toBe(200);
      expect(res.body.data).toMatchObject({
        scheduledDate: '2026-12-03', scheduledTimeSlot: '15:30', partySize: 3, status: 'REQUESTED', priceChargedUSD: 150,
      });
      expect(res.body.data.updatedAt >= res.body.data.createdAt).toBe(true);
      expect(folio.body.data.folioSummary.incidentalsSubtotalUSD).toBe(150);
    });

    it.each([
      [{ partySize: 7 }, 422],
      [{ scheduledDate: '2026-12-25' }, 422],
      [{ scheduledDate: '12/03/2026' }, 400],
      [{ scheduledTimeSlot: '3pm' }, 400],
      [{ status: 'CONFIRMED' }, 400],
    ])('test_change_invalid_%j_is%s', async (body, status) => {
      const booking = (await book()).body.data;

      expect((await request(t.server()).patch(`${stayPath}/bookings/${booking.bookingId}`).send(body)).status).toBe(status);
    });

    it('test_change_afterConfirmation_is422', async () => {
      const booking = (await book()).body.data;
      await request(t.server()).post(`${ADMIN}/requests/${booking.bookingId}/transition`).set(admin).send({ action: 'CONFIRM' }).expect(200);

      const res = await request(t.server()).patch(`${stayPath}/bookings/${booking.bookingId}`).send({ partySize: 1 });

      expect(res.status).toBe(422);
    });
  });

  describe('PUT /stays/:guestUuid/orders/:serviceId', () => {
    it('test_orderForOneService_neverErasesAnotherServicesOrder', async () => {
      const bar = await orderService('Bar', 4);
      const wine = await orderService('Wine', 10);
      await request(t.server()).put(`${stayPath}/orders/${bar.serviceId}`).send({ items: [{ itemId: bar.itemId, quantity: 2 }] });

      const res = await request(t.server()).put(`${stayPath}/orders/${wine.serviceId}`).send({ items: [{ itemId: wine.itemId, quantity: 1 }] });

      expect(res.status).toBe(200);
      expect(res.body.data.orders.map((o: { serviceId: string }) => o.serviceId).sort()).toEqual([bar.serviceId, wine.serviceId].sort());
      expect(res.body.data.folioSummary.incidentalsSubtotalUSD).toBe(18);
    });

    it('test_emptyItems_clearsOnlyThatService', async () => {
      const bar = await orderService('Bar', 4);
      const wine = await orderService('Wine', 10);
      await request(t.server()).put(`${stayPath}/orders/${bar.serviceId}`).send({ items: [{ itemId: bar.itemId, quantity: 1 }] });
      await request(t.server()).put(`${stayPath}/orders/${wine.serviceId}`).send({ items: [{ itemId: wine.itemId, quantity: 1 }] });

      const res = await request(t.server()).put(`${stayPath}/orders/${bar.serviceId}`).send({ items: [] });

      expect(res.body.data.orders.map((o: { serviceId: string }) => o.serviceId)).toEqual([wine.serviceId]);
      expect(res.body.data.folioSummary.incidentalsSubtotalUSD).toBe(10);
    });

    it.each([
      ['missing-service', { items: [] }, 404],
      ['BOOKING', { items: [] }, 422],
      ['BAR', { items: 'x' }, 400],
    ])('test_order_%s_%j_is%s', async (target, body, status) => {
      const bar = await orderService('Bar', 4);
      const serviceId = target === 'BOOKING' ? bookingServiceId : target === 'BAR' ? bar.serviceId : target;

      expect((await request(t.server()).put(`${stayPath}/orders/${serviceId}`).send(body)).status).toBe(status);
    });
  });

  describe('chat photos and uploads', () => {
    async function thread(): Promise<string> {
      const res = await request(t.server()).post(`${stayPath}/concierge-requests`)
        .send({ type: 'ask', category: 'Resort Host chat', title: 'Message', details: 'Hello' });
      return res.body.data.requestId;
    }

    it('test_uploadUrl_returnsMethodHeadersAndLimits', async () => {
      const res = await request(t.server()).post(`${stayPath}/concierge-requests/upload-url`)
        .send({ fileName: 'leak photo.jpg', contentType: 'image/jpeg', fileSizeBytes: 1000, requestId: 'req_1' });

      expect(res.status).toBe(201);
      expect(res.body.data).toEqual({
        uploadUrl: expect.stringContaining(`https://signed.test/private/stays/${created.stayId}/concierge/req_1/`),
        method: 'PUT',
        headers: expect.objectContaining({ 'Content-Type': 'image/jpeg' }),
        storagePath: `/private/stays/${created.stayId}/concierge/req_1/leak_photo.jpg`,
        expiresAt: expect.any(String),
        maxBytes: 10 * 1024 * 1024,
      });
      expect(t.signer.signedWrites.at(-1)).toMatchObject({ maxBytes: 10 * 1024 * 1024 });
    });

    it('test_uploadUrl_requestIdWithPathCharacters_is400', async () => {
      const res = await request(t.server()).post(`${stayPath}/concierge-requests/upload-url`)
        .send({ fileName: 'a.jpg', contentType: 'image/jpeg', fileSizeBytes: 10, requestId: '../other' });

      expect(res.status).toBe(400);
    });

    it('test_messageWithPhoto_isStoredInTheThread_andBothViewsGetASignedUrl', async () => {
      const requestId = await thread();
      const path = `/private/stays/${created.stayId}/concierge/${requestId}/p.jpg`;

      const res = await request(t.server()).post(`${stayPath}/concierge-requests/${requestId}/messages`)
        .send({ photoStoragePath: path });
      const guestView = await request(t.server()).get(stayPath);
      const adminView = await request(t.server()).get(`${ADMIN}/conversations/${created.stayId}/messages`).set(admin);

      expect(res.status).toBe(201);
      expect(res.body.data.messages.at(-1)).toMatchObject({ sender: 'GUEST', text: '', photoUrl: `https://signed.test/read${path}` });
      expect(res.body.data.messages[0].photoUrl).toBeNull();
      expect(forbiddenKeysIn(res.body.data)).toEqual([]);
      const guestMessages = guestView.body.data.conciergeRequests[0].messages;
      expect(guestMessages.at(-1).photoUrl).toBe(`https://signed.test/read${path}`);
      expect(forbiddenKeysIn(guestView.body.data)).toEqual([]);
      expect(adminView.body.data.at(-1)).toMatchObject({ from: 'GUEST', photoUrl: `https://signed.test/read${path}` });
    });

    it('test_threadOpenedWithPhoto_showsItOnTheFirstMessage', async () => {
      const path = `/private/stays/${created.stayId}/concierge/req_x/p.jpg`;
      await request(t.server()).post(`${stayPath}/concierge-requests`)
        .send({ type: 'ask', title: 'Photo', details: 'Look', photoStoragePath: path });

      const view = await request(t.server()).get(`${stayPath}/concierge-requests`);

      expect(view.body.data[0].messages[0].photoUrl).toBe(`https://signed.test/read${path}`);
    });

    it.each([
      [{ text: '' }, 400],
      [{ text: 'Hi', photoStoragePath: '/private/stays/another-stay/concierge/r/p.jpg' }, 422],
      [{ text: 'Hi', photoStoragePath: '/catalog/services/cover.jpg' }, 422],
    ])('test_message_invalid_%j_is%s', async (body, status) => {
      const requestId = await thread();

      expect((await request(t.server()).post(`${stayPath}/concierge-requests/${requestId}/messages`).send(body)).status).toBe(status);
    });

    it('test_newThread_withForeignPhoto_is422', async () => {
      const res = await request(t.server()).post(`${stayPath}/concierge-requests`)
        .send({ title: 'Photo', photoStoragePath: '/private/stays/another-stay/concierge/r/p.jpg' });

      expect(res.status).toBe(422);
    });
  });
});

describe('Guest trip cancel (POST /stays/:guestUuid/trips/:tripId/cancel)', () => {
  let t: TestApp;

  beforeEach(async () => {
    t = await createTestApp(new FakeFirestore(), { clock: new FixedClock() });
  });

  afterEach(() => t.close());

  it('test_cancel_requestedTrip_isCancelledWithItsTaskAndAlert', async () => {
    const w = await setUpTripWorld(t);
    const trip = (await request(t.server()).post(w.guestPath).send(arrivalBody(w.serviceId))).body.data;
    const admin = await t.adminHeaders();

    const res = await request(t.server()).post(`${w.guestPath}/${trip.id}/cancel`);
    const task = await request(t.server()).get(`${ADMIN}/tasks/${sourceTaskId('TRIP', trip.id)}`).set(admin);
    const alerts = storedAlerts(t.fake, 'TRANSFER');

    expect(res.status).toBe(200);
    expect(res.body.data).toMatchObject({ id: trip.id, status: 'CANCELLED' });
    expect(res.body.data).not.toHaveProperty('statusHistory');
    expect(task.body.data.status).toBe('CANCELLED');
    expect(alerts.some((a) => a.title.includes('cancelled by guest'))).toBe(true);
  });

  it('test_cancel_tripSentToProvider_is422', async () => {
    const w = await setUpTripWorld(t);
    const trip = (await request(t.server()).post(w.guestPath).send(arrivalBody(w.serviceId))).body.data;
    await request(t.server()).post(`${ADMIN}/trips/${trip.id}/transition`).set(await t.adminHeaders())
      .send({ to: 'SENT_TO_PROVIDER', providerId: w.providerId });

    expect((await request(t.server()).post(`${w.guestPath}/${trip.id}/cancel`)).status).toBe(422);
  });

  it('test_cancel_otherStaysOrUnknownTrip_is404', async () => {
    const w = await setUpTripWorld(t);
    const other = await createVillaAndStay(t, { villaName: 'Villa 4', guestName: 'Other Guest' });
    const foreign = (await request(t.server()).post(`/api/v1/stays/${other.guestTokenUuid}/trips`)
      .send(arrivalBody(w.serviceId))).body.data;

    const statuses = [
      (await request(t.server()).post(`${w.guestPath}/${foreign.id}/cancel`)).status,
      (await request(t.server()).post(`${w.guestPath}/trip_missing/cancel`)).status,
    ];

    expect(statuses).toEqual([404, 404]);
  });
});
