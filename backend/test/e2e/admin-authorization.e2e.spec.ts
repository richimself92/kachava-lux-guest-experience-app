import request from 'supertest';
import { createTestApp, TEST_ADMIN_EMAIL, TestApp } from '../support/test-app';

const API = '/api/v1/admin';

describe('Admin identity comes from the environment (plan rule 5)', () => {
  let t: TestApp;

  beforeEach(async () => {
    t = await createTestApp();
  });

  afterEach(() => t.close());

  const login = (email: string) => request(t.server()).post(`${API}/auth/login`).send({ email });

  it('test_login_configuredEmail_issuesHostAdminSessionWithoutStaffDocument', async () => {
    const res = await login(TEST_ADMIN_EMAIL.toUpperCase());

    expect(res.status).toBe(201);
    expect(res.body.data.staff).toMatchObject({ staffId: 'admin-service', rbacRole: 'HOST_ADMIN', email: TEST_ADMIN_EMAIL });
    expect(t.fake.collections.get('staff_members')?.size ?? 0).toBe(0);
    const settings = await request(t.server()).get(`${API}/settings`).set('Authorization', `Bearer ${res.body.data.token}`);
    expect(settings.status).toBe(200);
  });

  it('test_login_anyOtherEmail_isRejected', async () => {
    expect((await login('someone@else.test')).status).toBe(401);
  });

  it('test_login_withoutConfiguredEmail_failsClosed', async () => {
    delete process.env.ADMIN_SERVICE_EMAIL;

    expect((await login(TEST_ADMIN_EMAIL)).status).toBe(401);
  });

  it('test_login_invalidEmailShape_is400', async () => {
    expect((await login('not-an-email')).status).toBe(400);
  });
});

describe('Admin writes are HOST_ADMIN only (ADV-02)', () => {
  let t: TestApp;

  beforeAll(async () => {
    t = await createTestApp();
  });

  afterAll(() => t.close());

  it.each(['CONCIERGE_STAFF', 'DEPARTMENT_COORDINATOR'] as const)(
    'test_configurationWrites_%s_isForbidden',
    async (role) => {
      const as = await t.staffHeaders(role);
      const server = t.server();
      const statuses = [
        (await request(server).patch(`${API}/settings`).set(as).send({ checkInTime: '15:00' })).status,
        (await request(server).post(`${API}/villas`).set(as).send({})).status,
        (await request(server).post(`${API}/transport-providers`).set(as).send({ name: 'X' })).status,
        (await request(server).post(`${API}/services`).set(as).send({})).status,
        (await request(server).post(`${API}/uploads/sign`).set(as).send({})).status,
        (await request(server).post(`${API}/stays`).set(as).send({})).status,
      ];

      expect(statuses).toEqual([403, 403, 403, 403, 403, 403]);
    },
  );

  it.each([
    ['post', `${API}/reset`],
    ['get', `${API}/catalog/larder`],
    ['post', `${API}/catalog/experiences`],
    ['delete', `${API}/catalog/larder/x`],
  ] as const)('test_removedRoute_%s_%s_is404', async (method, path) => {
    const res = await request(t.server())[method](path).set(await t.adminHeaders());

    expect(res.status).toBe(404);
  });
});
