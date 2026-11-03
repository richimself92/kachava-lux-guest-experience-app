import { NestExpressApplication } from '@nestjs/platform-express';
import { Test } from '@nestjs/testing';
import request from 'supertest';
import { AppModule } from '../../src/app.module';
import { configureApp } from '../../src/main';

const HOST_ADMIN_EMAIL = 'eduardo.rivera@kachavalux.com';
const COORDINATOR_EMAIL = 'mateo@kachavalux.com';
const CONCIERGE_EMAIL = 'sofia.wellness@kachavalux.com';

describe('Admin destructive and catalog writes are HOST_ADMIN only (ADV-02)', () => {
  let app: NestExpressApplication;
  const tokens: Record<string, string> = {};

  beforeAll(async () => {
    const moduleRef = await Test.createTestingModule({ imports: [AppModule] }).compile();
    app = moduleRef.createNestApplication<NestExpressApplication>();
    configureApp(app);
    await app.init();
    for (const email of [HOST_ADMIN_EMAIL, COORDINATOR_EMAIL, CONCIERGE_EMAIL]) {
      const login = await request(app.getHttpServer()).post('/api/v1/admin/auth/login').send({ email });
      tokens[email] = login.body.data.token;
    }
  });

  afterAll(() => app.close());

  const as = (email: string) => ({ Authorization: `Bearer ${tokens[email]}` });

  it.each([COORDINATOR_EMAIL, CONCIERGE_EMAIL])(
    'test_adminWrites_nonHostAdmin_%s_isForbidden',
    async (email) => {
      const server = app.getHttpServer();
      const statuses = [
        (await request(server).post('/api/v1/admin/reset').set(as(email))).status,
        (await request(server).post('/api/v1/admin/catalog/larder').set(as(email)).send({ name: 'X', price: 1 })).status,
        (await request(server).post('/api/v1/admin/catalog/experiences').set(as(email)).send({ title: 'X' })).status,
        (await request(server).delete('/api/v1/admin/catalog/larder/larder-1').set(as(email))).status,
        (await request(server).delete('/api/v1/admin/catalog/experiences/exp-1').set(as(email))).status,
      ];

      expect(statuses).toEqual([403, 403, 403, 403, 403]);
    },
  );

  it('test_catalogWrite_negativePrice_isRejectedWith400', async () => {
    const server = app.getHttpServer();

    const larder = await request(server).post('/api/v1/admin/catalog/larder').set(as(HOST_ADMIN_EMAIL)).send({ name: 'Pwn', price: -500 });
    const experience = await request(server).post('/api/v1/admin/catalog/experiences').set(as(HOST_ADMIN_EMAIL)).send({ title: 'Pwn', basePriceUSD: -1 });

    expect([larder.status, experience.status]).toEqual([400, 400]);
  });

  it('test_catalogRead_anyStaff_isAllowed', async () => {
    const res = await request(app.getHttpServer()).get('/api/v1/admin/catalog/larder').set(as(COORDINATOR_EMAIL));

    expect(res.status).toBe(200);
  });

  it('test_reset_inProduction_isForbiddenEvenForHostAdmin', async () => {
    const previous = process.env.NODE_ENV;
    process.env.NODE_ENV = 'production';
    try {
      const res = await request(app.getHttpServer()).post('/api/v1/admin/reset').set(as(HOST_ADMIN_EMAIL));

      expect(res.status).toBe(403);
    } finally {
      process.env.NODE_ENV = previous;
    }
    const stays = await request(app.getHttpServer()).get('/api/v1/admin/stays').set(as(HOST_ADMIN_EMAIL));
    expect(stays.body.data.length).toBeGreaterThan(0);
  });
});
