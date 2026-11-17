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

    const guests = (res: request.Response) => res.body.data.map((s: { guestName: string }) => s.guestName);

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

    it('test_regenerateToken_oldGuestLinkStopsWorking', async () => {
      const rotated = await request(t.server()).post(`${ADMIN}/stays/${created.stayId}/regenerate-token`).set(admin);

      expect(rotated.body.data.guestTokenUuid).not.toBe(created.guestTokenUuid);
      expect((await request(t.server()).get(stayPath)).status).toBe(401);
      expect((await request(t.server()).get(`/api/v1/stays/${rotated.body.data.guestTokenUuid}`)).status).toBe(200);
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
      const folio = await request(t.server()).get(stayPath);
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
      const res = await request(t.server()).put(`${stayPath}/orders/${orderServiceId}`)
        .send({ items: [{ itemId: orderItemId, quantity: 2 }] });

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
      [{ items: undefined }, 400],
    ])('test_order_invalid_%j_is%s', async (override, status) => {
      const body = { serviceId: orderServiceId, items: [{ itemId: orderItemId, quantity: 1 }], ...override } as Record<string, unknown>;
      const serviceId = body.serviceId === 'BOOKING' ? bookingServiceId : body.serviceId;
      const items = (body.items as Array<{ itemId: string }> | undefined)
        ?.map((l) => ({ ...l, itemId: l.itemId === 'ITEM' ? orderItemId : l.itemId }));

      expect((await request(t.server()).put(`${stayPath}/orders/${serviceId}`).send({ items })).status).toBe(status);
    });
  });

  describe('guest requests and admin operations lists', () => {
    beforeEach(async () => {
      await request(t.server()).patch(`${ADMIN}/stays/${created.stayId}`).set(admin).send({ action: 'CHECK_IN' }).expect(200);
      await request(t.server()).post(`${stayPath}/bookings`).send({ serviceId: bookingServiceId, scheduledDate: '2026-12-02', partySize: 1 });
      await request(t.server()).put(`${stayPath}/orders/${orderServiceId}`).send({ items: [{ itemId: orderItemId, quantity: 1 }] });
      await request(t.server()).post(`${stayPath}/concierge-requests`).send({ title: 'Towels', details: 'Two more', photoStoragePath: `/private/stays/${created.stayId}/concierge/r1/a.jpg` });
      await request(t.server()).post(`${stayPath}/midstay-checkin`).send({ rating: 2, note: 'Noise' });
    });

    const list = (path: string) => request(t.server()).get(`${ADMIN}/${path}`).set(admin);

    it('test_everyOperationsList_isPaginatedWithMeta', async () => {
      for (const path of ['requests', 'midstay-feedback', 'staff']) {
        const res = await list(`${path}?pageSize=10`);
        expect(res.status).toBe(200);
        expect(res.body.meta).toMatchObject({ page: 1, pageSize: 10, total: expect.any(Number) });
        expect(Array.isArray(res.body.data)).toBe(true);
      }
      expect((await list('midstay-feedback?q=noise')).body.meta.total).toBe(1);
      expect((await list('staff')).body.meta.total).toBe(0);
    });

    it('test_guestConciergeMessageUploadAndPersonalizationFlows', async () => {
      const [concierge] = (await request(t.server()).get(`${stayPath}/concierge-requests`)).body.data;
      const message = await request(t.server()).post(`${stayPath}/concierge-requests/${concierge.requestId}/messages`).send({ text: 'Thanks' });
      const upload = await request(t.server()).post(`${stayPath}/concierge-requests/upload-url`)
        .send({ fileName: 'a.jpg', contentType: 'image/jpeg', fileSizeBytes: 100 });
      const badUpload = await request(t.server()).post(`${stayPath}/concierge-requests/upload-url`)
        .send({ fileName: 'a.gif', contentType: 'image/gif', fileSizeBytes: 100 });
      const personalization = await request(t.server()).patch(`${stayPath}/personalization`).send({ pillowType: 'Soft', allergies: 'Nuts' });

      expect(message.body.data.messages.at(-1).text).toBe('Thanks');
      expect(upload.body.data.uploadUrl).toContain('https://signed.test/private/stays/');
      expect(badUpload.status).toBe(400);
      expect(personalization.body.data.pillowType).toBe('Soft');
    });
  });
});
