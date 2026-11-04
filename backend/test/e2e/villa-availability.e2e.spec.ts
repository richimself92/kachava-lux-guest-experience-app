import request from 'supertest';
import { createTestApp, TestApp } from '../support/test-app';
import { FixedClock, patchSettings } from '../support/trip-setup';

const ADMIN = '/api/v1/admin';
/** 2026-11-20 07:00 at the resort (America/Cancun, UTC-5); 2026-11-20 12:00 UTC. */
const NOW = new Date('2026-11-20T12:00:00.000Z');
const VILLA = { category: 'Test', capacity: 4, operationalStatus: 'AVAILABLE', housekeepingStatus: 'CLEAN', maintenanceStatus: 'OK' };

/** No past check-in, no overlapping nights per villa, and the availability list behind the picker. */
describe('Villa availability for new reservations', () => {
  let t: TestApp;
  let admin: Record<string, string>;
  let villaA: string;
  let villaB: string;

  const post = (path: string, body: object) => request(t.server()).post(`${ADMIN}${path}`).set(admin).send(body);
  const reserve = (villaId: string, checkIn: string, checkOut: string) =>
    post('/stays', { guestName: 'Guest Test', villaId, checkIn, checkOut });
  const available = (query: string, headers = admin) =>
    request(t.server()).get(`${ADMIN}/villas/available${query}`).set(headers);
  const namesOf = (res: request.Response) => (res.body.data as { name: string }[]).map((v) => v.name);
  const createVilla = async (name: string, overrides: object = {}) =>
    (await post('/villas', { ...VILLA, name, ...overrides })).body.data.id as string;

  beforeEach(async () => {
    t = await createTestApp(undefined, { clock: new FixedClock(NOW) });
    admin = await t.adminHeaders();
    await patchSettings(t, { timeZone: 'America/Cancun' });
    villaA = await createVilla('Villa A');
    villaB = await createVilla('Villa B');
  });

  afterEach(() => t.close());

  describe('POST /admin/stays', () => {
    it('test_createReservation_checkInBeforeResortToday_is422', async () => {
      const res = await reserve(villaA, '2026-11-19', '2026-11-22');

      expect(res.status).toBe(422);
      expect(res.body.message).toBe('checkIn cannot be in the past');
    });

    it('test_createReservation_checkInResortToday_isCreated', async () => {
      expect((await reserve(villaA, '2026-11-20', '2026-11-22')).status).toBe(201);
    });

    it('test_createReservation_overlappingNightsOnTheSameVilla_is409NamingTheVilla', async () => {
      expect((await reserve(villaA, '2026-12-10', '2026-12-14')).status).toBe(201);

      const res = await reserve(villaA, '2026-12-12', '2026-12-16');

      expect(res.status).toBe(409);
      expect(res.body.message).toContain('Villa A');
    });

    it('test_createReservation_sameDayTurnoverAndOtherVilla_areCreated', async () => {
      expect((await reserve(villaA, '2026-12-10', '2026-12-14')).status).toBe(201);

      expect((await reserve(villaA, '2026-12-14', '2026-12-16')).status).toBe(201);
      expect((await reserve(villaA, '2026-12-07', '2026-12-10')).status).toBe(201);
      expect((await reserve(villaB, '2026-12-11', '2026-12-12')).status).toBe(201);
    });

    it('test_createReservation_overACancelledStay_isCreated', async () => {
      const first = await reserve(villaA, '2026-12-10', '2026-12-14');
      await request(t.server()).patch(`${ADMIN}/stays/${first.body.data.stay.stayId}`).set(admin)
        .send({ action: 'CANCEL', reason: 'Guest request' });

      expect((await reserve(villaA, '2026-12-11', '2026-12-13')).status).toBe(201);
    });
  });

  describe('GET /admin/villas/available', () => {
    it('test_available_excludesBookedAndOutOfServiceVillas', async () => {
      await createVilla('Villa C', { operationalStatus: 'MAINTENANCE' });
      await createVilla('Villa D', { isActive: false });
      await reserve(villaA, '2026-12-10', '2026-12-14');

      const overlapping = await available('?checkIn=2026-12-12&checkOut=2026-12-15');
      const turnover = await available('?checkIn=2026-12-14&checkOut=2026-12-15');

      expect(overlapping.status).toBe(200);
      expect(namesOf(overlapping)).toEqual(['Villa B']);
      expect(overlapping.body.data[0]).toMatchObject({ id: villaB, villaId: villaB, capacity: 4 });
      expect(namesOf(turnover)).toEqual(['Villa A', 'Villa B']);
    });

    it('test_available_pastOrInvertedRange_is422_andBadDates400', async () => {
      expect((await available('?checkIn=2026-11-19&checkOut=2026-11-22')).status).toBe(422);
      expect((await available('?checkIn=2026-12-05&checkOut=2026-12-05')).status).toBe(422);
      expect((await available('?checkIn=tomorrow&checkOut=2026-12-05')).status).toBe(400);
      expect((await available('?checkOut=2026-12-05')).status).toBe(400);
    });

    it('test_available_isOpenToEveryStaffRole_andClosedToAnonymous', async () => {
      const concierge = await t.staffHeaders('CONCIERGE_STAFF');

      expect((await available('?checkIn=2026-12-01&checkOut=2026-12-03', concierge)).status).toBe(200);
      expect((await request(t.server()).get(`${ADMIN}/villas/available?checkIn=2026-12-01&checkOut=2026-12-03`)).status)
        .toBe(401);
    });
  });
});
