import { NestExpressApplication } from '@nestjs/platform-express';
import { Test } from '@nestjs/testing';
import request from 'supertest';
import { AppModule } from '../../src/app.module';
import { StepUpAttemptLimiter } from '../../src/common/services/step-up-attempt-limiter';
import { configureApp } from '../../src/main';

describe('POST /api/v1/stays/:guestUuid/verify-step-up only accepts the stay own villa', () => {
  let app: NestExpressApplication;
  let villa108GuestUuid = '';
  let villa108StayId = '';

  beforeAll(async () => {
    const moduleRef = await Test.createTestingModule({ imports: [AppModule] }).compile();
    app = moduleRef.createNestApplication<NestExpressApplication>();
    configureApp(app);
    await app.init();
    const login = await request(app.getHttpServer())
      .post('/api/v1/admin/auth/login')
      .send({ email: 'eduardo.rivera@kachavalux.com' });
    const created = await request(app.getHttpServer())
      .post('/api/v1/admin/stays')
      .set('Authorization', `Bearer ${login.body.data.token}`)
      .send({ guestName: 'Julian Vance', villaId: 'villa-108', villaName: 'Villa 108', nights: 3, guestsCount: 2 });
    villa108GuestUuid = created.body.data.stay.guestTokenUuid;
    villa108StayId = created.body.data.stay.stayId;
  });

  afterAll(() => app.close());
  /** These cases test answer matching; the brute-force lockout has its own suite below. */
  afterEach(() => app.get(StepUpAttemptLimiter).recordSuccess(villa108StayId));

  const challenge = (paths: string, body: Record<string, string>) =>
    request(app.getHttpServer()).post(`/api/v1/stays/${villa108GuestUuid}/${paths}`).send(body);

  it.each(['verify-step-up', 'verify-stepup'])(
    'test_%s_otherStayVilla102_isForbidden',
    async (path) => {
      const res = await challenge(path, { villaNumber: '102', lastName: 'nobody' });

      expect(res.status).toBe(403);
      expect(res.body.data?.stepUpToken).toBeUndefined();
    },
  );

  it('test_verifyStepUp_ownVillaNumberOrVillaId_issuesStepUpToken', async () => {
    const byNumber = await challenge('verify-step-up', { villaNumber: '108' });
    const byVillaId = await challenge('verify-step-up', { villaNumber: 'villa-108' });

    expect([byNumber.status, byVillaId.status]).toEqual([201, 201]);
    expect(typeof byNumber.body.data.stepUpToken).toBe('string');
  });

  it.each(['a', 'v', 'van', 'Julian', 'ance'])(
    'test_verifyStepUp_partialOrGivenNameLastName_%p_isForbidden',
    async (lastName) => {
      const res = await challenge('verify-step-up', { lastName });

      expect(res.status).toBe(403);
      expect(res.body.data?.stepUpToken).toBeUndefined();
    },
  );

  it('test_verifyStepUp_fullLastNameAnyCase_issuesStepUpToken', async () => {
    const res = await challenge('verify-step-up', { lastName: ' VANCE ' });

    expect(res.status).toBe(201);
    expect(typeof res.body.data.stepUpToken).toBe('string');
  });
});

describe('POST /verify-step-up brute force is locked out per stay (ADV-04)', () => {
  let app: NestExpressApplication;
  let guestUuid = '';

  beforeAll(async () => {
    const moduleRef = await Test.createTestingModule({ imports: [AppModule] }).compile();
    app = moduleRef.createNestApplication<NestExpressApplication>();
    configureApp(app);
    await app.init();
    const login = await request(app.getHttpServer()).post('/api/v1/admin/auth/login').send({ email: 'eduardo.rivera@kachavalux.com' });
    const created = await request(app.getHttpServer())
      .post('/api/v1/admin/stays')
      .set('Authorization', `Bearer ${login.body.data.token}`)
      .send({ guestName: 'Nora Quill', villaId: 'villa-107', villaName: 'Villa 107' });
    guestUuid = created.body.data.stay.guestTokenUuid;
  });

  afterAll(() => app.close());

  it('test_verifyStepUp_enumeratingVillaNumbers_isLockedOutAfterFiveFailuresWith429', async () => {
    const statuses: number[] = [];
    for (let guess = 100; guess < 110; guess += 1) {
      const res = await request(app.getHttpServer())
        .post(`/api/v1/stays/${guestUuid}/verify-step-up`)
        .set('X-Forwarded-For', `192.0.2.${guess}`)
        .send({ villaNumber: String(guess) });
      statuses.push(res.status);
      if (res.status === 429) expect(Number(res.headers['retry-after'])).toBeGreaterThan(0);
    }

    expect(statuses.slice(0, 5)).toEqual([403, 403, 403, 403, 403]);
    expect(statuses.slice(5)).toEqual([429, 429, 429, 429, 429]);
  });
});
