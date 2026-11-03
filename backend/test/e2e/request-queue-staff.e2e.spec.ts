import request from 'supertest';
import { SERVICE_REQUESTS_COLLECTION } from '../../src/infrastructure/repositories/firestore-service-request.repository';
import { createTestApp, createVillaAndStay, TestApp } from '../support/test-app';

const ADMIN = '/api/v1/admin';

/** Section request queues (`/admin/requests`) and the staff roster (`/admin/staff`). */
describe('Request queue and staff roster', () => {
  let t: TestApp;
  let admin: Record<string, string>;

  beforeEach(async () => {
    t = await createTestApp();
    admin = await t.adminHeaders();
  });

  afterEach(() => t.close());

  describe('request queue', () => {
    let stayPath: string;
    let cenoteId: string;
    let bar: { serviceId: string; itemId: string };

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

    const list = (qs: string) => request(t.server()).get(`${ADMIN}/requests?${qs}`).set(admin);
    const move = (id: string, body: Record<string, unknown>) =>
      request(t.server()).post(`${ADMIN}/requests/${id}/transition`).set(admin).send(body);
    const book = (date: string) => request(t.server()).post(`${stayPath}/bookings`)
      .send({ serviceId: cenoteId, scheduledDate: date, scheduledTimeSlot: '10:00', partySize: 3 });

    beforeEach(async () => {
      await request(t.server()).patch(`${ADMIN}/settings`).set(admin).send({ timeZone: 'America/Cancun' });
      const created = await createVillaAndStay(t, { villaName: 'Villa Sol', guestName: 'Ana Ruiz' });
      stayPath = `/api/v1/stays/${created.guestTokenUuid}`;
      cenoteId = await activeService({
        kind: 'EXPERIENCE', section: 'EXPERIENCES', usageType: 'BOOKING', name: { en: 'Cenote swim', es: 'Nado en cenote' },
        pricing: { mode: 'PER_PERSON', amount: 50, chargeToFolio: true },
      });
      const barId = await activeService({
        kind: 'BAR', section: 'DINING', usageType: 'ORDER', name: { en: 'Lux bar', es: 'Bar Lux' },
        pricing: { mode: 'PER_UNIT', chargeToFolio: true },
      });
      const item = await request(t.server()).post(`${ADMIN}/services/${barId}/items`).set(admin)
        .send({ name: { en: 'Mojito', es: 'Mojito' }, priceUSD: 12, status: 'ACTIVE' });
      bar = { serviceId: barId, itemId: item.body.data.id };
    });

    it('test_list_returnsOnlyTheSectionsBookingsAndOrdersAsDataAndMeta', async () => {
      expect((await book('2026-12-02')).status).toBe(201);
      await request(t.server()).put(`${stayPath}/orders/${bar.serviceId}`).send({ items: [{ itemId: bar.itemId, quantity: 2 }] });

      const experiences = await list('section=EXPERIENCES');
      const dining = await list('section=DINING');

      expect(experiences.status).toBe(200);
      expect(experiences.body.meta).toMatchObject({ page: 1, total: 1 });
      expect(experiences.body.data[0]).toMatchObject({
        kind: 'BOOKING', guestName: 'Ana Ruiz', villaName: 'Villa Sol', at: '2026-12-02T10:00',
        quantity: 3, status: 'RECEIVED', serviceName: { en: 'Cenote swim', es: 'Nado en cenote' },
      });
      expect(experiences.body.data[0].id).toBe(experiences.body.data[0].requestId);
      expect(dining.body.data).toHaveLength(1);
      expect(dining.body.data[0]).toMatchObject({ kind: 'ORDER', quantity: 2, status: 'RECEIVED', totalUSD: 24 });
      expect(dining.body.data[0].searchKeywords).toBeUndefined();
    });

    it('test_list_filtersByStatusDateAndSearchAndSortsByDate', async () => {
      const first = (await book('2026-12-02')).body.data.bookingId;
      await book('2026-12-03');
      await move(first, { action: 'CONFIRM' });

      const confirmed = await list('section=EXPERIENCES&status=CONFIRMED');
      const open = await list('section=EXPERIENCES&status=OPEN');
      const dayTwo = await list('section=EXPERIENCES&from=2026-12-03&to=2026-12-03');
      const byGuest = await list('section=EXPERIENCES&q=ruiz');
      const byService = await list('section=EXPERIENCES&q=cenote');
      const none = await list('section=EXPERIENCES&q=zzz');
      const desc = await list('section=EXPERIENCES&sort=at:desc');

      expect(confirmed.body.data.map((r: { id: string }) => r.id)).toEqual([first]);
      expect(open.body.meta.total).toBe(2);
      expect(dayTwo.body.data.map((r: { at: string }) => r.at)).toEqual(['2026-12-03T10:00']);
      expect(byGuest.body.meta.total).toBe(2);
      expect(byService.body.meta.total).toBe(2);
      expect(none.body.meta.total).toBe(0);
      expect(desc.body.data.map((r: { at: string }) => r.at)).toEqual(['2026-12-03T10:00', '2026-12-02T10:00']);
    });

    it('test_transition_movesTheBookingTheGuestSeesAndRefusesInvalidMoves', async () => {
      const id = (await book('2026-12-02')).body.data.bookingId;

      const confirmed = await move(id, { action: 'CONFIRM' });
      const noReason = await move(id, { action: 'CANCEL' });
      const cancelled = await move(id, { action: 'CANCEL', reason: 'Weather' });
      const afterCancel = await move(id, { action: 'CONFIRM' });

      expect(confirmed.status).toBe(200);
      expect(confirmed.body.data).toMatchObject({ id, status: 'CONFIRMED' });
      expect(noReason.status).toBe(422);
      expect(cancelled.body.data).toMatchObject({ status: 'CANCELLED', open: false, cancellationReason: 'Weather' });
      expect(afterCancel.status).toBe(422);
      const guest = (await request(t.server()).get(stayPath)).body.data;
      expect(guest.experienceBookings[0].status).toBe('CANCELLED');
    });

    it('test_orderTransition_setsTheGuestOrderStatus', async () => {
      await request(t.server()).put(`${stayPath}/orders/${bar.serviceId}`).send({ items: [{ itemId: bar.itemId, quantity: 1 }] });
      const [order] = (await list('section=DINING')).body.data;

      const started = await move(order.id, { action: 'START' });

      expect(started.body.data.status).toBe('PREPARING');
      const guest = (await request(t.server()).get(stayPath)).body.data;
      expect(guest.larderOrders[0].provisioningStatus).toBe('Preparing');
    });

    it('test_emptiedOrder_leavesTheQueue', async () => {
      const put = (quantity: number) => request(t.server()).put(`${stayPath}/orders/${bar.serviceId}`)
        .send({ items: [{ itemId: bar.itemId, quantity }] });
      await put(1);
      expect((await list('section=DINING')).body.meta.total).toBe(1);

      await put(0);

      expect((await list('section=DINING')).body.meta.total).toBe(0);
      expect(t.fake.store(SERVICE_REQUESTS_COLLECTION).size).toBe(0);
    });

    it('test_badInput_isRejected', async () => {
      expect((await list('section=SPA')).status).toBe(400);
      expect((await list('status=LATE')).status).toBe(400);
      expect((await list('from=2026-12-05&to=2026-12-01')).status).toBe(422);
      expect((await move('missing', { action: 'CONFIRM' })).status).toBe(404);
      expect((await move('missing', { action: 'JUMP' })).status).toBe(400);
      expect((await request(t.server()).get(`${ADMIN}/requests`)).status).toBe(401);
    });
  });

  describe('staff roster', () => {
    const create = (body: Record<string, unknown>, headers = admin) =>
      request(t.server()).post(`${ADMIN}/staff`).set(headers).send({
        fullName: 'Lucia Perez', rbacRole: 'CONCIERGE_STAFF', department: 'CONCIERGE', email: 'Lucia@Resort.test', ...body,
      });

    it('test_roster_startsEmptyAndCreatesActiveStaffWithLowerCaseEmail', async () => {
      expect((await request(t.server()).get(`${ADMIN}/staff`).set(admin)).body.meta.total).toBe(0);

      const res = await create({ phone: ' +52 998 000 ' });

      expect(res.status).toBe(201);
      expect(res.body.data).toMatchObject({
        fullName: 'Lucia Perez', shortName: 'Lucia', email: 'lucia@resort.test', phone: '+52 998 000',
        rbacRole: 'CONCIERGE_STAFF', department: 'CONCIERGE', isActive: true,
      });
      expect(res.body.data.id).toBe(res.body.data.staffId);
    });

    it('test_duplicateEmail_isAConflict_andBadRole_isRejected', async () => {
      await create({});

      expect((await create({ fullName: 'Other', email: 'lucia@resort.test' })).status).toBe(409);
      expect((await create({ rbacRole: 'OWNER', email: 'x@resort.test' })).status).toBe(400);
      expect((await create({ email: 'not-an-email' })).status).toBe(400);
    });

    it('test_edit_andDeactivate_keepTheMemberButHideItFromActivePickers', async () => {
      const id = (await create({})).body.data.id;
      await create({ fullName: 'Marco Diaz', email: 'marco@resort.test', department: 'CULINARY' });

      const edited = await request(t.server()).patch(`${ADMIN}/staff/${id}`).set(admin)
        .send({ fullName: 'Lucia Perez Gomez', department: 'WELLNESS' });
      await request(t.server()).patch(`${ADMIN}/staff/${id}`).set(admin).send({ isActive: false });

      expect(edited.body.data).toMatchObject({ fullName: 'Lucia Perez Gomez', department: 'WELLNESS' });
      const all = await request(t.server()).get(`${ADMIN}/staff`).set(admin);
      const active = await request(t.server()).get(`${ADMIN}/staff?isActive=true`).set(admin);
      const search = await request(t.server()).get(`${ADMIN}/staff?q=marco`).set(admin);
      expect(all.body.data.map((s: { fullName: string }) => s.fullName)).toEqual(['Lucia Perez Gomez', 'Marco Diaz']);
      expect(active.body.data.map((s: { fullName: string }) => s.fullName)).toEqual(['Marco Diaz']);
      expect(search.body.meta.total).toBe(1);
    });

    it('test_onlyHostAdminWritesTheRoster_andUnknownStaffIsNotFound', async () => {
      const concierge = await t.staffHeaders('CONCIERGE_STAFF');

      expect((await create({}, concierge)).status).toBe(403);
      expect((await request(t.server()).get(`${ADMIN}/staff`).set(concierge)).status).toBe(200);
      expect((await request(t.server()).patch(`${ADMIN}/staff/nobody`).set(admin).send({ phone: '1' })).status).toBe(404);
    });
  });
});
