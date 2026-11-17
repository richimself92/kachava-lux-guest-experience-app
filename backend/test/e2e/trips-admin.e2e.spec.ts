import request from 'supertest';
import { storedAlerts } from '../support/stored-alerts';
import { FakeFirestore } from '../support/fake-firestore';
import { createTestApp, createVillaAndStay, TestApp } from '../support/test-app';
import {
  arrivalBody,
  createProvider,
  FixedClock,
  patchSettings,
  setUpTripWorld,
  TripWorld,
} from '../support/trip-setup';

const TRIPS = '/api/v1/admin/trips';
const DRIVER = { name: 'Test Driver', phone: '+52 200' };

describe('Admin trips (/admin/trips)', () => {
  let t: TestApp;
  let w: TripWorld;
  let admin: Record<string, string>;

  beforeEach(async () => {
    t = await createTestApp(new FakeFirestore(), { clock: new FixedClock() });
    w = await setUpTripWorld(t);
    admin = await t.adminHeaders();
  });

  afterEach(() => t.close());

  const staffCreate = (body: Record<string, unknown>) =>
    request(t.server()).post(TRIPS).set(admin).send({ stayId: w.stay.stayId, ...body });
  const transition = (id: string, body: Record<string, unknown>) =>
    request(t.server()).post(`${TRIPS}/${id}/transition`).set(admin).send(body);
  const transferAlerts = async () => storedAlerts(t.fake, 'TRANSFER');

  describe('POST /admin/trips (staff on behalf of a guest)', () => {
    it('test_staffCreate_isStaffOwned_skipsLeadTime_andRaisesNoAlert', async () => {
      const res = await staffCreate(arrivalBody(w.serviceId, {
        flight: { airline: 'Test Air', number: 'TA 7', scheduledAt: '2026-11-20T09:00' }, notes: 'meet at door 3',
      }));

      expect(res.status).toBe(201);
      expect(res.body.data).toMatchObject({
        createdBy: 'STAFF', status: 'REQUESTED', guestName: 'Ana Test', villaId: w.stay.villaId, villaName: 'Villa 3',
        stayId: w.stay.stayId, notes: 'meet at door 3', createdByActor: 'admin-service@test.local', unconfirmedDue: true,
      });
      expect(res.body.data.statusHistory).toEqual([
        { from: null, to: 'REQUESTED', at: '2026-11-20T12:00:00.000Z', by: 'admin-service@test.local', reason: null },
      ]);
      expect(await transferAlerts()).toEqual([]);
    });

    it('test_staffDeparture_canOverrideSuggestedPickup', async () => {
      const res = await staffCreate(arrivalBody(w.serviceId, {
        type: 'DEPARTURE', flight: { airline: 'A', number: 'TA 8', scheduledAt: '2026-12-04T12:00' }, pickupAt: '2026-12-04T08:15',
      }));

      expect(res.body.data.pickupAt).toBe('2026-12-04T13:15:00.000Z');
    });

    it('test_unknownStay_is404_unknownProvider_is422', async () => {
      const unknownStay = await request(t.server()).post(TRIPS).set(admin).send({ stayId: 'nope', ...arrivalBody(w.serviceId) });
      const unknownProvider = await staffCreate(arrivalBody(w.serviceId, { providerId: 'no-such-provider' }));

      expect([unknownStay.status, unknownProvider.status]).toEqual([404, 422]);
    });

    it('test_withoutToken_is401', async () => {
      expect((await request(t.server()).post(TRIPS).send(arrivalBody(w.serviceId))).status).toBe(401);
    });
  });

  describe('PATCH /admin/trips/:id', () => {
    let id: string;

    beforeEach(async () => {
      id = (await staffCreate(arrivalBody(w.serviceId, {
        type: 'DEPARTURE', itemId: w.vanId, flight: { airline: 'Test Air', number: 'TA 8', scheduledAt: '2026-12-04T12:00' },
      }))).body.data.id;
    });

    it('test_flightTimeChange_recomputesDeparturePickup_andRaisesHighAlert', async () => {
      const res = await request(t.server()).patch(`${TRIPS}/${id}`).set(admin)
        .send({ flight: { airline: 'Test Air', number: 'TA 8', scheduledAt: '2026-12-04T15:00' } });

      expect(res.status).toBe(200);
      expect(res.body.data.pickupAt).toBe('2026-12-04T17:00:00.000Z');
      const alerts = await transferAlerts();
      expect(alerts).toHaveLength(1);
      expect(alerts[0]).toMatchObject({ severity: 'HIGH', targetRef: { type: 'TRIP', id } });
      expect(alerts[0].summary).toContain('TA 8');
    });

    it('test_detailsWithoutFlightChange_raiseNoAlert', async () => {
      const res = await request(t.server()).patch(`${TRIPS}/${id}`).set(admin)
        .send({ notes: 'quiet edit', passengers: 3, luggage: 1, driver: DRIVER });

      expect(res.status).toBe(200);
      expect(res.body.data).toMatchObject({ notes: 'quiet edit', passengers: 3, driver: DRIVER, updatedBy: 'admin-service@test.local' });
      expect(await transferAlerts()).toEqual([]);
    });

    it('test_overCapacity_is422', async () => {
      const res = await request(t.server()).patch(`${TRIPS}/${id}`).set(admin).send({ passengers: 9 });

      expect(res.status).toBe(422);
    });

    it('test_removingDriverFromConfirmedTrip_is422', async () => {
      await transition(id, { to: 'SENT_TO_PROVIDER', providerId: w.providerId });
      await transition(id, { to: 'CONFIRMED', driver: DRIVER });

      const res = await request(t.server()).patch(`${TRIPS}/${id}`).set(admin).send({ driver: null });

      expect(res.status).toBe(422);
      expect(res.body.message).toContain('driver.name is required');
    });

    it('test_unknownTrip_is404', async () => {
      expect((await request(t.server()).patch(`${TRIPS}/nope`).set(admin).send({ notes: 'x' })).status).toBe(404);
    });
  });

  describe('POST /admin/trips/:id/transition', () => {
    let id: string;

    beforeEach(async () => {
      id = (await staffCreate(arrivalBody(w.serviceId))).body.data.id;
    });

    it('test_fullLifecycle_withRequirementsEnforced', async () => {
      const noProvider = await transition(id, { to: 'SENT_TO_PROVIDER' });
      const sent = await transition(id, { to: 'SENT_TO_PROVIDER', providerId: w.providerId });
      const noDriver = await transition(id, { to: 'CONFIRMED' });
      const confirmed = await transition(id, { to: 'CONFIRMED', driver: DRIVER, vehicle: { description: 'Van', plate: 'TST-1' } });
      const enRoute = await transition(id, { to: 'EN_ROUTE' });
      const completed = await transition(id, { to: 'COMPLETED' });
      const afterFinal = await transition(id, { to: 'CANCELLED', reason: 'too late' });

      expect([noProvider.status, sent.status, noDriver.status, confirmed.status, enRoute.status, completed.status, afterFinal.status])
        .toEqual([422, 200, 422, 200, 200, 200, 422]);
      expect(completed.body.data.statusHistory.map((h: { to: string }) => h.to))
        .toEqual(['REQUESTED', 'SENT_TO_PROVIDER', 'CONFIRMED', 'EN_ROUTE', 'COMPLETED']);
      expect(confirmed.body.data).toMatchObject({ providerId: w.providerId, driver: DRIVER, unconfirmedDue: false });
    });

    it('test_skippingAStep_is422', async () => {
      const res = await transition(id, { to: 'EN_ROUTE' });

      expect(res.status).toBe(422);
      expect(res.body.message).toContain('Cannot move a trip from REQUESTED to EN_ROUTE');
    });

    it('test_cancel_needsReason', async () => {
      const without = await transition(id, { to: 'CANCELLED' });
      const withReason = await transition(id, { to: 'CANCELLED', reason: 'Guest changed plans' });

      expect([without.status, withReason.status]).toEqual([422, 200]);
      expect(withReason.body.data).toMatchObject({ status: 'CANCELLED', cancellationReason: 'Guest changed plans' });
    });

    it('test_inactiveProvider_isRejected', async () => {
      const inactive = await createProvider(t, { name: 'Retired Co', isActive: false });

      expect((await transition(id, { to: 'SENT_TO_PROVIDER', providerId: inactive })).status).toBe(422);
    });

    it.each([{ to: 'FLYING' }, {}, { to: 'CONFIRMED', driver: 'Bob' }])('test_malformed_%j_is400', async (body) => {
      expect((await transition(id, body)).status).toBe(400);
    });
  });

  describe('GET /admin/trips (list, filters, search, unconfirmed flag)', () => {
    const ids: Record<string, string> = {};

    beforeEach(async () => {
      const second = await createVillaAndStay(t, { villaName: 'Villa 5', guestName: 'Bruno Peña' });
      // Dec 1 22:00 resort time = Dec 2 03:00 UTC: a "Dec 1" trip in the resort calendar.
      ids.late = (await staffCreate(arrivalBody(w.serviceId, { flight: { airline: 'Sky', number: 'SK 77', scheduledAt: '2026-12-01T22:00' } }))).body.data.id;
      ids.soon = (await staffCreate({
        serviceId: w.serviceId, type: 'LOCAL', pickupAt: '2026-11-20T15:00', origin: 'Villa', destination: 'Town', passengers: 1,
      })).body.data.id;
      ids.bruno = (await request(t.server()).post(TRIPS).set(admin).send({
        stayId: second.stayId, ...arrivalBody(w.serviceId, { type: 'DEPARTURE', flight: { airline: 'Test Air', number: 'TA 123', scheduledAt: '2026-12-03T10:00' } }),
      })).body.data.id;
      await transition(ids.bruno, { to: 'SENT_TO_PROVIDER', providerId: w.providerId });
    });

    const list = (qs = '') => request(t.server()).get(`${TRIPS}${qs}`).set(admin);
    const idsOf = (res: request.Response) => res.body.data.map((trip: { id: string }) => trip.id);

    it('test_list_ordersByPickupAndPaginates', async () => {
      const page1 = await list('?pageSize=2');
      const page2 = await list('?pageSize=2&page=2');
      const desc = await list('?sort=pickupAt:desc');

      expect(idsOf(page1)).toEqual([ids.soon, ids.late]);
      expect(page1.body.meta).toMatchObject({ page: 1, pageSize: 2, total: 3 });
      expect(idsOf(page2)).toEqual([ids.bruno]);
      expect(idsOf(desc)).toEqual([ids.bruno, ids.late, ids.soon]);
    });

    it('test_list_filtersByStatusTypeProviderAndVilla', async () => {
      expect(idsOf(await list('?status=SENT_TO_PROVIDER'))).toEqual([ids.bruno]);
      expect(idsOf(await list('?type=LOCAL'))).toEqual([ids.soon]);
      expect(idsOf(await list(`?providerId=${w.providerId}`))).toEqual([ids.bruno]);
      expect(idsOf(await list(`?villaId=${w.stay.villaId}`))).toEqual([ids.soon, ids.late]);
    });

    it('test_list_dateRangeUsesResortTimeZone_byPickupOrFlight', async () => {
      expect(idsOf(await list('?from=2026-12-01&to=2026-12-01'))).toEqual([ids.late]);
      expect(idsOf(await list('?from=2026-12-02'))).toEqual([ids.bruno]);
      expect(idsOf(await list('?from=2026-12-03&to=2026-12-03&dateField=flightAt'))).toEqual([ids.bruno]);
      expect(idsOf(await list('?to=2026-11-30&dateField=flightAt'))).toEqual([]);
    });

    it('test_list_searchesGuestNameAndFlightNumber', async () => {
      expect(idsOf(await list('?q=pena'))).toEqual([ids.bruno]);
      expect(idsOf(await list('?q=ta123'))).toEqual([ids.bruno]);
      expect(idsOf(await list('?q=SK%2077'))).toEqual([ids.late]);
    });

    it('test_list_flagsUnconfirmedTripsWithinLeadHours', async () => {
      const res = await list();
      const flags = Object.fromEntries(res.body.data.map((trip: { id: string; unconfirmedDue: boolean }) => [trip.id, trip.unconfirmedDue]));

      expect(flags).toEqual({ [ids.soon]: true, [ids.late]: false, [ids.bruno]: false });
    });

    it('test_unconfirmedDueEndpoint_returnsOnlyDueTrips', async () => {
      const clock = new FixedClock(new Date('2026-12-03T06:00:00.000Z'));
      await t.close();
      t = await createTestApp(t.fake, { clock });
      admin = await t.adminHeaders();

      const res = await request(t.server()).get(`${TRIPS}/unconfirmed-due`).set(admin);

      expect(res.status).toBe(200);
      expect(idsOf(res)).toEqual([ids.soon, ids.late, ids.bruno]);
      expect(res.body.meta).toMatchObject({ page: 1, total: 3 });
      expect(res.body.data.every((trip: { unconfirmedDue: boolean }) => trip.unconfirmedDue)).toBe(true);
    });

    it('test_getOne_returnsAdminView', async () => {
      const res = await request(t.server()).get(`${TRIPS}/${ids.late}`).set(admin);

      expect(res.status).toBe(200);
      expect(res.body.data).toMatchObject({ id: ids.late, unconfirmedDue: false, notes: '' });
    });

    it.each(['status=LOST', 'type=BUS', 'from=12/01/2026', 'dateField=createdAt', 'sort=guestName:asc', 'pageSize=500'])(
      'test_list_invalid_%s_is400',
      async (qs) => {
        expect((await list(`?${qs}`)).status).toBe(400);
      },
    );
  });

  describe('missing Settings', () => {
    it('test_withoutLeadHours_dueEndpointIs422_andListFlagIsNull', async () => {
      await staffCreate(arrivalBody(w.serviceId));
      await patchSettings(t, { transportAlertLeadHours: null });

      const due = await request(t.server()).get(`${TRIPS}/unconfirmed-due`).set(admin);
      const listed = await request(t.server()).get(TRIPS).set(admin);

      expect(due.status).toBe(422);
      expect(due.body).toMatchObject({ code: 'SETTINGS_REQUIRED', details: ['transportAlertLeadHours'] });
      expect(listed.status).toBe(200);
      expect(listed.body.data[0].unconfirmedDue).toBeNull();
    });

    it('test_dateFilterWithoutTimeZone_is422SettingsRequired', async () => {
      await patchSettings(t, { timeZone: null });

      const res = await request(t.server()).get(`${TRIPS}?from=2026-12-01`).set(admin);

      expect(res.status).toBe(422);
      expect(res.body).toMatchObject({ code: 'SETTINGS_REQUIRED', details: ['timeZone'] });
    });
  });
});
