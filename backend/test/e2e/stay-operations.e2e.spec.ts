import request from 'supertest';
import { createTestApp, createVillaAndStay, CreatedStay, TestApp } from '../support/test-app';

const ADMIN = '/api/v1/admin';

/** End-to-end guest and admin stay flows on an empty store: everything is created via the API. */
describe('Stays, guest orders/bookings and admin operations', () => {
  let t: TestApp;
  let admin: Record<string, string>;
  let created: CreatedStay;
  let stayPath: string;
  let bookingServiceId: string;
  let orderServiceId: string;
  let orderItemId: string;

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

  beforeEach(async () => {
    t = await createTestApp();
    admin = await t.adminHeaders();
    created = await createVillaAndStay(t, { villaName: 'Villa 7', guestName: 'Ana Test' });
    stayPath = `/api/v1/stays/${created.guestTokenUuid}`;
    bookingServiceId = await activeService({
      kind: 'EXPERIENCE', section: 'EXPERIENCES', usageType: 'BOOKING', name: { en: 'Cenote', es: 'Cenote' },
      pricing: { mode: 'PER_PERSON', amount: 50, chargeToFolio: true },
      availability: { maxGuests: 6, blockedDates: ['2026-12-25'] },
      operation: { responsibleDepartment: 'CONCIERGE' },
    });
    orderServiceId = await activeService({
      kind: 'VILLA_STOCKING', section: 'IN_VILLA', usageType: 'ORDER', name: { en: 'Stocking', es: 'Abastecimiento' },
      pricing: { mode: 'PER_UNIT', chargeToFolio: true }, stocking: { maxPerItem: 4 },
    });
    const item = await request(t.server()).post(`${ADMIN}/services/${orderServiceId}/items`).set(admin)
      .send({ name: { en: 'Mango', es: 'Mango' }, priceUSD: 3.5, status: 'ACTIVE', category: 'Fruit' });
    orderItemId = item.body.data.id;
  });

  afterEach(() => t.close());

  describe('admin stays list (GET /admin/stays)', () => {
    beforeEach(async () => {
      await createVillaAndStay(t, { villaName: 'Villa 8', guestName: 'Bruno Peña', checkIn: '2026-12-10', checkOut: '2026-12-12' });
      await createVillaAndStay(t, { villaName: 'Villa 9', guestName: 'Carla Peña', checkIn: '2026-11-20', checkOut: '2026-11-22' });
    });

    const guests = (res: request.Response) => res.body.data.map((s: { guestProfile: { name: string } }) => s.guestProfile.name);

    it('test_listStays_paginatesByArrivalWithMeta', async () => {
      const page1 = await request(t.server()).get(`${ADMIN}/stays?pageSize=2`).set(admin);
      const page2 = await request(t.server()).get(`${ADMIN}/stays?pageSize=2&page=2`).set(admin);
      const desc = await request(t.server()).get(`${ADMIN}/stays?sort=checkInDate:desc`).set(admin);

      expect(guests(page1)).toEqual(['Carla Peña', 'Ana Test']);
      expect(page1.body.meta).toMatchObject({ page: 1, pageSize: 2, total: 3 });
      expect(guests(page2)).toEqual(['Bruno Peña']);
      expect(guests(desc)[0]).toBe('Bruno Peña');
    });

    it('test_listStays_filtersAndSearch', async () => {
      const byVilla = await request(t.server()).get(`${ADMIN}/stays?villaId=${created.villaId}`).set(admin);
      const byStatus = await request(t.server()).get(`${ADMIN}/stays?status=ACTIVE_STAY`).set(admin);
      const byRange = await request(t.server()).get(`${ADMIN}/stays?from=2026-11-25&to=2026-12-05`).set(admin);
      const search = await request(t.server()).get(`${ADMIN}/stays?q=pena`).set(admin);

      expect(guests(byVilla)).toEqual(['Ana Test']);
      expect(byStatus.body.meta.total).toBe(0);
      expect(guests(byRange)).toEqual(['Ana Test']);
      expect(guests(search)).toEqual(['Carla Peña', 'Bruno Peña']);
    });

    it.each(['from=12/01/2026', 'status=PARTY', 'sort=guestName:asc', 'pageSize=0'])('test_listStays_invalid_%s_is400', async (qs) => {
      expect((await request(t.server()).get(`${ADMIN}/stays?${qs}`).set(admin)).status).toBe(400);
    });
  });

  describe('reservations', () => {
    it.each([
      [{ villaId: 'missing-villa' }, 404],
      [{ checkIn: 'Oct 19' }, 400],
      [{ checkOut: '2026-11-30' }, 422],
      [{ guestsCount: 5 }, 422],
    ])('test_createReservation_invalid_%j_is%s', async (override, status) => {
      const res = await request(t.server()).post(`${ADMIN}/stays`).set(admin)
        .send({ guestName: 'X Y', villaId: created.villaId, checkIn: '2026-12-01', checkOut: '2026-12-03', ...override });

      expect(res.status).toBe(status);
    });

    it('test_stayAdminMutations_tokenStatusWifiTransfer', async () => {
      const id = created.stayId;
      const rotated = await request(t.server()).post(`${ADMIN}/stays/${id}/regenerate-token`).set(admin);
      const status = await request(t.server()).patch(`${ADMIN}/stays/${id}/status`).set(admin).send({ status: 'ACTIVE_STAY' });
      const wifi = await request(t.server()).patch(`${ADMIN}/stays/${id}/wifi`).set(admin).send({ wifiSsid: 'Net7' });
      const transfer = await request(t.server()).patch(`${ADMIN}/stays/${id}/transfer`).set(admin).send({ vehicleModel: 'Van', status: 'Confirmed' });
      const badStatus = await request(t.server()).patch(`${ADMIN}/stays/${id}/status`).set(admin).send({ status: 'GONE' });

      expect(rotated.body.data.guestTokenUuid).not.toBe(created.guestTokenUuid);
      expect((await request(t.server()).get(stayPath)).status).toBe(401);
      expect(status.body.data.status).toBe('ACTIVE_STAY');
      expect(wifi.body.data.villaAccess.wifiSsid).toBe('Net7');
      expect(transfer.body.data).toMatchObject({ vehicleModel: 'Van', status: 'Confirmed' });
      expect(badStatus.status).toBe(400);
    });
  });

  describe('guest bookings and orders store a catalog snapshot', () => {
    it('test_booking_snapshotsNameAndPrice_andLaterPriceChangeDoesNotAlterIt', async () => {
      const res = await request(t.server()).post(`${stayPath}/bookings`)
        .send({ serviceId: bookingServiceId, scheduledDate: '2026-12-02', scheduledTimeSlot: '09:30', partySize: 3 });
      await request(t.server()).patch(`${ADMIN}/services/${bookingServiceId}`).set(admin).send({ pricing: { amount: 999 } });
      const stored = await request(t.server()).get(`${stayPath}/bookings`);

      expect(res.status).toBe(201);
      expect(res.body.data).toMatchObject({
        serviceId: bookingServiceId, section: 'EXPERIENCES', usageType: 'BOOKING', priceChargedUSD: 150,
        snapshot: { serviceName: { en: 'Cenote', es: 'Cenote' }, pricingMode: 'PER_PERSON', totalUSD: 150,
          lines: [{ itemId: null, unitPriceUSD: 50, quantity: 1, lineTotalUSD: 150 }] },
      });
      expect(stored.body.data[0].snapshot.totalUSD).toBe(150);
      const folio = await request(t.server()).get(`${stayPath}/folio`);
      expect(folio.body.data.folioSummary.incidentalsSubtotalUSD).toBe(150);
    });

    it.each([
      [{ serviceId: 'missing' }, 404],
      [{ partySize: 7 }, 422],
      [{ scheduledDate: '2026-12-25' }, 422],
      [{ scheduledDate: 'tomorrow' }, 400],
      [{ itemId: 'missing-item' }, 404],
    ])('test_booking_invalid_%j_is%s', async (override, status) => {
      const res = await request(t.server()).post(`${stayPath}/bookings`)
        .send({ serviceId: bookingServiceId, scheduledDate: '2026-12-02', ...override });

      expect(res.status).toBe(status);
    });

    it('test_booking_disabledServiceOrOrderService_is422', async () => {
      const orderAsBooking = await request(t.server()).post(`${stayPath}/bookings`).send({ serviceId: orderServiceId, scheduledDate: '2026-12-02' });
      await request(t.server()).patch(`${ADMIN}/services/${bookingServiceId}`).set(admin).send({ status: 'DISABLED' });
      const disabled = await request(t.server()).post(`${stayPath}/bookings`).send({ serviceId: bookingServiceId, scheduledDate: '2026-12-02' });

      expect([orderAsBooking.status, disabled.status]).toEqual([422, 422]);
    });

    it('test_order_snapshotsItemNameAndPrice_andChargesFolio', async () => {
      const res = await request(t.server()).put(`${stayPath}/larder`)
        .send({ serviceId: orderServiceId, items: [{ itemId: orderItemId, quantity: 2 }] });

      expect(res.status).toBe(200);
      expect(res.body.data.orders[0]).toMatchObject({
        serviceId: orderServiceId, catalogItemId: orderItemId, itemName: { en: 'Mango', es: 'Mango' },
        unitPriceUSD: 3.5, quantity: 2, lineTotalUSD: 7, category: 'Fruit',
      });
      expect(res.body.data.folioSummary.incidentalsSubtotalUSD).toBe(7);
    });

    it.each([
      [{ items: [{ itemId: 'missing', quantity: 1 }] }, 404],
      [{ items: [{ itemId: 'ITEM', quantity: 5 }] }, 422],
      [{ serviceId: 'BOOKING' }, 422],
      [{ serviceId: undefined }, 400],
    ])('test_order_invalid_%j_is%s', async (override, status) => {
      const body = { serviceId: orderServiceId, items: [{ itemId: orderItemId, quantity: 1 }], ...override } as Record<string, unknown>;
      if (body.serviceId === 'BOOKING') body.serviceId = bookingServiceId;
      body.items = (body.items as Array<{ itemId: string }>).map((l) => ({ ...l, itemId: l.itemId === 'ITEM' ? orderItemId : l.itemId }));

      expect((await request(t.server()).put(`${stayPath}/larder`).send(body)).status).toBe(status);
    });
  });

  describe('guest requests and admin operations lists', () => {
    beforeEach(async () => {
      await request(t.server()).patch(`${ADMIN}/stays/${created.stayId}/status`).set(admin).send({ status: 'ACTIVE_STAY' });
      await request(t.server()).post(`${stayPath}/bookings`).send({ serviceId: bookingServiceId, scheduledDate: '2026-12-02', partySize: 1 });
      await request(t.server()).put(`${stayPath}/larder`).send({ serviceId: orderServiceId, items: [{ itemId: orderItemId, quantity: 1 }] });
      await request(t.server()).post(`${stayPath}/concierge-requests`).send({ title: 'Towels', details: 'Two more', photoStoragePath: '/private/stays/x/a.jpg' });
      await request(t.server()).post(`${stayPath}/midstay-checkin`).send({ rating: 2, note: 'Noise' });
    });

    const list = (path: string) => request(t.server()).get(`${ADMIN}/${path}`).set(admin);

    it('test_everyOperationsList_isPaginatedWithMeta', async () => {
      for (const path of ['alerts', 'bookings', 'larder-orders', 'concierge-requests', 'midstay-feedback', 'staff']) {
        const res = await list(`${path}?pageSize=10`);
        expect(res.status).toBe(200);
        expect(res.body.meta).toMatchObject({ page: 1, pageSize: 10, total: expect.any(Number) });
        expect(Array.isArray(res.body.data)).toBe(true);
      }
      const alerts = await list('alerts?isAcknowledged=false&sort=createdAt:desc');
      expect(alerts.body.meta.unreadCount).toBe(alerts.body.meta.total);
      expect((await list('bookings?section=EXPERIENCES')).body.meta.total).toBe(1);
      expect((await list('bookings?q=cenote')).body.meta.total).toBe(1);
      expect((await list('staff')).body.meta.total).toBe(0);
    });

    it('test_adminActions_assignBookingLarderStatusConciergeReplyPhotoAndAck', async () => {
      const booking = (await list('bookings')).body.data[0];
      const request_ = (await list('concierge-requests')).body.data[0];
      const alert = (await list('alerts')).body.data[0];

      const assigned = await request(t.server()).patch(`${ADMIN}/bookings/${booking.bookingId}/assign`).set(admin).send({ status: 'CONFIRMED' });
      const larder = await request(t.server()).patch(`${ADMIN}/larder-orders/${created.stayId}/status`).set(admin).send({ provisioningStatus: 'Stocked' });
      const larderMissing = await request(t.server()).patch(`${ADMIN}/larder-orders/${created.stayId}/status`).set(admin).send({});
      const reply = await request(t.server()).patch(`${ADMIN}/concierge-requests/${request_.requestId}`).set(admin).send({ status: 'Completed', replyMessage: 'Done' });
      const photo = await request(t.server()).get(`${ADMIN}/concierge-requests/${request_.requestId}/photo-url`).set(admin);
      const ack = await request(t.server()).patch(`${ADMIN}/alerts/${alert.alertId}/acknowledge`).set(admin);

      expect(assigned.body.data.status).toBe('CONFIRMED');
      expect(larder.body.data.provisioningStatus).toBe('Stocked');
      expect(larderMissing.status).toBe(400);
      expect(reply.body.data).toMatchObject({ status: 'Completed', isCompleted: true });
      expect(photo.body.data.downloadUrl).toBe('https://signed.test/read/private/stays/x/a.jpg');
      expect(ack.body.data).toMatchObject({ isAcknowledged: true, acknowledgedByStaffId: 'admin-service' });
    });

    it('test_guestConciergeMessageUploadAndCheckoutFlows', async () => {
      const [concierge] = (await request(t.server()).get(`${stayPath}/concierge-requests`)).body.data;
      const message = await request(t.server()).post(`${stayPath}/concierge-requests/${concierge.requestId}/messages`).send({ text: 'Thanks' });
      const upload = await request(t.server()).post(`${stayPath}/concierge-requests/upload-url`)
        .send({ fileName: 'a.jpg', contentType: 'image/jpeg', fileSizeBytes: 100 });
      const badUpload = await request(t.server()).post(`${stayPath}/concierge-requests/upload-url`)
        .send({ fileName: 'a.gif', contentType: 'image/gif', fileSizeBytes: 100 });
      const personalization = await request(t.server()).patch(`${stayPath}/personalization`).send({ pillowType: 'Soft', allergies: 'Nuts' });
      const noStepUp = await request(t.server()).post(`${stayPath}/folio/checkout`).send({});
      const stepUp = await request(t.server()).post(`${stayPath}/verify-step-up`).send({ lastName: 'Test' });
      const checkout = await request(t.server()).post(`${stayPath}/folio/checkout`)
        .set('X-StepUp-Session', stepUp.body.data.stepUpToken).send({});
      const approved = await request(t.server()).patch(`${ADMIN}/stays/${created.stayId}/folio/approve-checkout`).set(admin).send({});

      expect(message.body.data.messages.at(-1).text).toBe('Thanks');
      expect(upload.body.data.uploadUrl).toContain('https://signed.test/private/stays/');
      expect(badUpload.status).toBe(400);
      expect(personalization.body.data.pillowType).toBe('Soft');
      expect(noStepUp.status).toBe(403);
      expect(checkout.body.data.folioSummary.paymentStatus).toBe('SETTLED');
      expect(approved.body.data).toMatchObject({ status: 'CHECKED_OUT', approvedByStaffId: 'admin-service' });
    });
  });
});
