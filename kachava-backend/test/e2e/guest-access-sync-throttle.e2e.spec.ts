import { Controller, Get, Logger, Module } from '@nestjs/common';
import { APP_GUARD } from '@nestjs/core';
import { NestExpressApplication } from '@nestjs/platform-express';
import { Test } from '@nestjs/testing';
import { ThrottlerGuard, ThrottlerModule } from '@nestjs/throttler';
import request from 'supertest';
import {
  buildThrottlerOptions,
  resolveClientIpTracker,
  resolveThrottleTracker,
  THROTTLE_LIMIT_PER_IP,
  THROTTLE_LIMIT_PER_TRACKER,
} from '../../src/common/throttling/throttle-tracker';
import { configureApp } from '../../src/main';
import { createTestApp, seedGuestFixtures, TestApp } from '../support/test-app';

const UNKNOWN_UUID = '99999999-9999-4999-8999-999999999999';
const DEMO_UUID = '11111111-1111-4111-8111-111111111111';

describe('Guest magic link: invalid token vs storage failure', () => {
  let t: TestApp;

  beforeAll(async () => {
    t = await createTestApp();
  });

  afterAll(() => t.close());
  afterEach(() => t.fake.failReadsWith(null));

  it('test_getStay_unknownWellFormedToken_returns401', async () => {
    const res = await request(t.server()).get(`/api/v1/stays/${UNKNOWN_UUID}`);
    expect(res.status).toBe(401);
  });

  it('test_getStay_malformedToken_returns401', async () => {
    const res = await request(t.server()).get('/api/v1/stays/not-a-uuid');
    expect(res.status).toBe(401);
  });

  it('test_getStay_storageFailure_returns5xxNeverNotFound', async () => {
    t.fake.failReadsWith(new Error('UNAVAILABLE: firestore down'));
    const logSpy = jest.spyOn(Logger.prototype, 'error').mockImplementation(() => undefined);

    const res = await request(t.server()).get(`/api/v1/stays/${UNKNOWN_UUID}`);

    expect(res.status).toBeGreaterThanOrEqual(500);
    expect(res.body.success).toBe(false);
    expect(logSpy).toHaveBeenCalled();
    logSpy.mockRestore();
  });
});

describe('Admin read routes (guarded, open stays only)', () => {
  let t: TestApp;

  beforeAll(async () => {
    t = await createTestApp();
    seedGuestFixtures(t.fake);
  });

  afterAll(() => t.close());

  it('test_midStayFeedback_listsTheOpenStaysFeedback', async () => {
    const res = await request(t.server()).get('/api/v1/admin/midstay-feedback').set(await t.adminHeaders());

    expect(res.status).toBe(200);
    expect(res.body.data.map((f: { stayId: string }) => f.stayId)).toEqual(['stay-test-1']);
  });

  it('test_adminRoutes_withoutBearerToken_return401WithoutDefaultStaffIdentity', async () => {
    const server = t.server();

    const feedback = await request(server).get('/api/v1/admin/midstay-feedback');
    const stays = await request(server).get('/api/v1/admin/stays');

    expect([feedback.status, stays.status]).toEqual([401, 401]);
  });

  it('test_adminRoute_guestUuidAsBearer_isRejectedByAdminAuthGuard', async () => {
    const res = await request(t.server()).get('/api/v1/admin/midstay-feedback').set('Authorization', `Bearer ${DEMO_UUID}`);
    expect(res.status).toBe(401);
  });
});

@Controller()
class ProbeController {
  @Get('stays/:guestUuid')
  guest() {
    return 'ok';
  }

  @Get('public')
  open() {
    return 'ok';
  }
}

@Module({
  imports: [ThrottlerModule.forRoot(buildThrottlerOptions(2))],
  controllers: [ProbeController],
  providers: [{ provide: APP_GUARD, useClass: ThrottlerGuard }],
})
class ProbeModule {}

@Module({
  imports: [ThrottlerModule.forRoot(buildThrottlerOptions(100, 3))],
  controllers: [ProbeController],
  providers: [{ provide: APP_GUARD, useClass: ThrottlerGuard }],
})
class ProbeIpCapModule {}

describe('Throttling keyed per guest token / bearer token, falling back to client IP', () => {
  let app: NestExpressApplication;

  beforeEach(async () => {
    const moduleRef = await Test.createTestingModule({ imports: [ProbeModule] }).compile();
    app = moduleRef.createNestApplication<NestExpressApplication>();
    configureApp(app);
    await app.init();
  });

  afterEach(() => app.close());

  const hit = (path: string, headers: Record<string, string> = {}) =>
    request(app.getHttpServer()).get(`/api/v1/${path}`).set(headers);

  it('test_throttler_guestTokens_haveIndependentBudgetsBehindSameIp', async () => {
    const proxyIp = { 'X-Forwarded-For': '203.0.113.7' };
    await hit(`stays/${DEMO_UUID}`, proxyIp).expect(200);
    await hit(`stays/${DEMO_UUID}`, proxyIp).expect(200);

    await hit(`stays/${DEMO_UUID}`, proxyIp).expect(429);
    await hit(`stays/${UNKNOWN_UUID}`, proxyIp).expect(200);
  });

  it('test_throttler_adminBearerTokens_haveIndependentBudgets', async () => {
    await hit('public', { Authorization: 'Bearer staff-a' }).expect(200);
    await hit('public', { Authorization: 'Bearer staff-a' }).expect(200);

    await hit('public', { Authorization: 'Bearer staff-a' }).expect(429);
    await hit('public', { Authorization: 'Bearer staff-b' }).expect(200);
  });

  it('test_throttler_anonymousRequests_fallBackToForwardedClientIp', async () => {
    await hit('public', { 'X-Forwarded-For': '198.51.100.1' }).expect(200);
    await hit('public', { 'X-Forwarded-For': '198.51.100.1' }).expect(200);

    await hit('public', { 'X-Forwarded-For': '198.51.100.1' }).expect(429);
    await hit('public', { 'X-Forwarded-For': '198.51.100.2' }).expect(200);
  });
});

describe('Coarse per-IP cap on top of the per-token budget', () => {
  let app: NestExpressApplication;

  beforeEach(async () => {
    const moduleRef = await Test.createTestingModule({ imports: [ProbeIpCapModule] }).compile();
    app = moduleRef.createNestApplication<NestExpressApplication>();
    configureApp(app);
    await app.init();
  });

  afterEach(() => app.close());

  const randomGuestToken = (n: number) => `00000000-0000-4000-8000-${String(n).padStart(12, '0')}`;
  const hitAs = (path: string, ip: string, headers: Record<string, string> = {}) =>
    request(app.getHttpServer()).get(`/api/v1/${path}`).set({ 'X-Forwarded-For': ip, ...headers });

  it('test_throttler_rotatingGuestTokensFromOneIp_hitsPerIpCap', async () => {
    for (let n = 1; n <= 3; n += 1) await hitAs(`stays/${randomGuestToken(n)}`, '203.0.113.50').expect(200);

    await hitAs(`stays/${randomGuestToken(4)}`, '203.0.113.50').expect(429);
    await hitAs(`stays/${randomGuestToken(5)}`, '203.0.113.51').expect(200);
  });

  it('test_throttler_rotatingBearerTokensFromOneIp_hitsPerIpCap', async () => {
    for (let n = 1; n <= 3; n += 1) {
      await hitAs('public', '198.51.100.60', { Authorization: `Bearer forged-${n}` }).expect(200);
    }

    await hitAs('public', '198.51.100.60', { Authorization: 'Bearer forged-4' }).expect(429);
  });
});

describe('resolveThrottleTracker', () => {
  it('test_resolveThrottleTracker_prefersBearerThenGuestHeaderThenRouteTokenThenIp', () => {
    expect(resolveThrottleTracker({ params: { guestUuid: DEMO_UUID.toUpperCase() }, headers: {}, ip: '1.1.1.1' }))
      .toBe(`guest:${DEMO_UUID}`);
    expect(resolveThrottleTracker({ params: {}, headers: { authorization: 'Bearer staff-token' }, ip: '1.1.1.1' }))
      .toBe('bearer:staff-token');
    expect(resolveThrottleTracker({ headers: { 'x-guest-token': DEMO_UUID }, ip: '1.1.1.1' })).toBe(`guest:${DEMO_UUID}`);
    expect(resolveThrottleTracker({ headers: {}, ip: '1.1.1.1' })).toBe('ip:1.1.1.1');
  });

  it('test_buildThrottlerOptions_defaultBudget_coversGuestAndAdminPollingWithHeadroom', () => {
    const [throttler] = buildThrottlerOptions().throttlers;
    const guestPollsPerMinutePerDevice = 60 / 10;
    const adminSyncPerMinutePerTab = 60 / 5;

    expect(throttler.ttl).toBe(60_000);
    expect(throttler.limit).toBeGreaterThanOrEqual(4 * guestPollsPerMinutePerDevice + 60);
    expect(throttler.limit).toBeGreaterThanOrEqual(4 * adminSyncPerMinutePerTab + 120);
  });

  it('test_buildThrottlerOptions_default_appliesPerTokenAndCoarserPerIpThrottlers', () => {
    const { throttlers } = buildThrottlerOptions();

    expect(throttlers.map((t) => [t.name, t.ttl, t.limit])).toEqual([
      ['token', 60_000, THROTTLE_LIMIT_PER_TRACKER],
      ['ip', 60_000, THROTTLE_LIMIT_PER_IP],
    ]);
    expect(THROTTLE_LIMIT_PER_TRACKER).toBe(300);
    expect(THROTTLE_LIMIT_PER_IP).toBe(1500);
  });

  it('test_resolveClientIpTracker_ignoresTokensAndKeysByProxyResolvedIp', () => {
    expect(resolveClientIpTracker({ params: { guestUuid: DEMO_UUID }, headers: { authorization: 'Bearer x' }, ip: '1.1.1.1' }))
      .toBe('ip:1.1.1.1');
    expect(resolveClientIpTracker({ headers: {} })).toBe('ip:unknown');
  });
});
