import { NestExpressApplication } from '@nestjs/platform-express';
import { Test } from '@nestjs/testing';
import request from 'supertest';
import { AppModule } from '../../src/app.module';
import { DEFAULT_DEMO_GUEST_UUID } from '../../src/infrastructure/seed/sanctuary-seed.data';
import { configureApp } from '../../src/main';
import { forbiddenKeysIn } from '../support/guest-view-assertions';

const STAY = `/api/v1/stays/${DEFAULT_DEMO_GUEST_UUID}`;

describe('Guest routes return only the ADR-007 guest-safe view', () => {
  let app: NestExpressApplication;

  beforeAll(async () => {
    const moduleRef = await Test.createTestingModule({ imports: [AppModule] }).compile();
    app = moduleRef.createNestApplication<NestExpressApplication>();
    configureApp(app);
    await app.init();
  });

  afterAll(() => app.close());

  it.each(['', '/bookings', '/concierge-requests', '/folio'])(
    'test_guestGet%s_containsNoStaffOrInternalFields',
    async (suffix) => {
      const res = await request(app.getHttpServer()).get(`${STAY}${suffix}`);

      expect(res.status).toBe(200);
      expect(forbiddenKeysIn(res.body.data)).toEqual([]);
    },
  );

  it('test_guestMutations_responsesContainNoStaffOrInternalFields', async () => {
    const server = app.getHttpServer();
    const responses = [
      await request(server).patch(`${STAY}/transfer`).send({ flightNumber: 'AA 1' }),
      await request(server).post(`${STAY}/bookings`).send({
        category: 'explore', catalogRefId: 'exp-x', scheduledDate: '2026-11-14', scheduledTimeSlot: '10:00',
      }),
      await request(server).post(`${STAY}/concierge-requests`).send({ title: 'Ice', details: 'More ice' }),
      await request(server).post(`${STAY}/midstay-checkin`).send({ rating: 5 }),
      await request(server).put(`${STAY}/larder`).send({ items: [] }),
    ];

    expect(responses.map((r) => r.status)).toEqual([200, 201, 201, 201, 200]);
    expect(forbiddenKeysIn(responses.map((r) => r.body.data))).toEqual([]);
  });
});
