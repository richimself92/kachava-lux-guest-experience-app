import request from 'supertest';
import { forbiddenKeysIn } from '../support/guest-view-assertions';
import { createTestApp, GUEST_STAY_PATH as STAY, seedGuestFixtures, TestApp } from '../support/test-app';

describe('Guest routes return only the ADR-007 guest-safe view', () => {
  let t: TestApp;

  beforeAll(async () => {
    t = await createTestApp();
    seedGuestFixtures(t.fake);
  });

  afterAll(() => t.close());

  it.each(['', '/bookings', '/concierge-requests', '/folio'])(
    'test_guestGet%s_containsNoStaffOrInternalFields',
    async (suffix) => {
      const res = await request(t.server()).get(`${STAY}${suffix}`);

      expect(res.status).toBe(200);
      expect(forbiddenKeysIn(res.body.data)).toEqual([]);
    },
  );

  it('test_guestMutations_responsesContainNoStaffOrInternalFields', async () => {
    const server = t.server();
    const responses = [
      await request(server).patch(`${STAY}/transfer`).send({ flightNumber: 'AA 1' }),
      await request(server).post(`${STAY}/bookings`).send({ serviceId: 'svc-1', scheduledDate: '2026-12-03', scheduledTimeSlot: '10:00' }),
      await request(server).post(`${STAY}/concierge-requests`).send({ title: 'Ice', details: 'More ice' }),
      await request(server).post(`${STAY}/midstay-checkin`).send({ rating: 5 }),
      await request(server).put(`${STAY}/larder`).send({ serviceId: 'svc-stock', items: [] }),
    ];

    expect(responses.map((r) => r.status)).toEqual([200, 201, 201, 201, 200]);
    expect(forbiddenKeysIn(responses.map((r) => r.body.data))).toEqual([]);
  });
});
