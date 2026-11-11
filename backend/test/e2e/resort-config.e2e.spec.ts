import request from 'supertest';
import { createTestApp, TestApp } from '../support/test-app';

const API = '/api/v1/admin';

const villaBody = (name: string, overrides: Record<string, unknown> = {}) => ({
  name,
  category: 'Ocean',
  capacity: 4,
  wifi: { ssid: `${name}-net`, password: 'secret-pass' },
  operationalStatus: 'AVAILABLE',
  housekeepingStatus: 'CLEAN',
  maintenanceStatus: 'OK',
  ...overrides,
});

describe('Settings (GET/PATCH /admin/settings)', () => {
  let t: TestApp;

  beforeEach(async () => {
    t = await createTestApp();
  });

  afterEach(() => t.close());

  it('test_getSettings_emptyDatabase_returnsNullsWithoutDefaults', async () => {
    const res = await request(t.server()).get(`${API}/settings`).set(await t.adminHeaders());

    expect(res.status).toBe(200);
    expect(res.body.data).toEqual({
      checkInTime: null,
      checkOutTime: null,
      timeZone: null,
      airports: [],
      transportAlertLeadHours: null,
      updatedAt: null,
      updatedBy: null,
    });
  });

  it('test_patchSettings_validValues_persistAndAudit', async () => {
    const headers = await t.adminHeaders();
    const patch = {
      checkInTime: '15:00',
      timeZone: 'America/Cancun',
      airports: [{ code: 'CUN', name: 'Cancun International', departureBufferHours: 3 }],
      transportAlertLeadHours: 12,
    };

    const res = await request(t.server()).patch(`${API}/settings`).set(headers).send(patch);
    const again = await request(t.server()).get(`${API}/settings`).set(headers);

    expect(res.status).toBe(200);
    expect(again.body.data).toMatchObject({ ...patch, checkOutTime: null, updatedBy: 'admin-service@test.local' });
    expect(again.body.data.airports[0].isActive).toBe(true);
    expect(again.body.data.updatedAt).toEqual(expect.any(String));
  });

  it.each([
    [{ checkInTime: '25:00' }],
    [{ timeZone: 'Mars/Olympus' }],
    [{ airports: [{ code: 'cun', name: 'x', departureBufferHours: 1 }] }],
    [{ airports: [{ code: 'CUN', name: 'x', departureBufferHours: -1 }] }],
    [{ transportAlertLeadHours: 0 }],
  ])('test_patchSettings_invalid_%j_is400', async (patch) => {
    const res = await request(t.server()).patch(`${API}/settings`).set(await t.adminHeaders()).send(patch);

    expect(res.status).toBe(400);
  });

  it('test_patchSettings_duplicateAirportCodes_is422', async () => {
    const airport = { code: 'CUN', name: 'Cancun', departureBufferHours: 3 };

    const res = await request(t.server())
      .patch(`${API}/settings`)
      .set(await t.adminHeaders())
      .send({ airports: [airport, airport] });

    expect(res.status).toBe(422);
  });

  it('test_patchSettings_nonAdminRole_is403_butCanRead', async () => {
    const concierge = await t.staffHeaders('CONCIERGE_STAFF');

    const write = await request(t.server()).patch(`${API}/settings`).set(concierge).send({ checkInTime: '15:00' });
    const read = await request(t.server()).get(`${API}/settings`).set(concierge);

    expect([write.status, read.status]).toEqual([403, 200]);
  });

  it('test_settings_withoutToken_is401', async () => {
    expect((await request(t.server()).get(`${API}/settings`)).status).toBe(401);
  });
});

describe('Villas (GET/POST/PATCH/DELETE /admin/villas)', () => {
  let t: TestApp;

  beforeEach(async () => {
    t = await createTestApp();
  });

  afterEach(() => t.close());

  async function createVilla(name: string, overrides: Record<string, unknown> = {}) {
    const res = await request(t.server()).post(`${API}/villas`).set(await t.adminHeaders()).send(villaBody(name, overrides));
    expect(res.status).toBe(201);
    return res.body.data;
  }

  it('test_listVillas_emptyDatabase_returnsEmptyPage', async () => {
    const res = await request(t.server()).get(`${API}/villas`).set(await t.adminHeaders());

    expect(res.status).toBe(200);
    expect(res.body.data).toEqual([]);
    expect(res.body.meta).toMatchObject({ page: 1, pageSize: 25, total: 0 });
  });

  it('test_createVilla_persistsWithAuditAndActiveByDefault', async () => {
    const villa = await createVilla('Ceiba');

    expect(villa).toMatchObject({
      id: expect.any(String),
      villaId: villa.id,
      name: 'Ceiba',
      isActive: true,
      maintenanceNote: '',
      currentGuestName: null,
      createdBy: 'admin-service@test.local',
      updatedBy: 'admin-service@test.local',
    });
    const stored = await request(t.server()).get(`${API}/villas/${villa.villaId}`).set(await t.adminHeaders());
    expect(stored.body.data).toEqual(villa);
  });

  it('test_listVillas_paginatesSortsSearchesAndFilters', async () => {
    await createVilla('Ceiba');
    await createVilla('Alux', { category: 'Jungle' });
    await createVilla('Balam', { operationalStatus: 'BLOCKED' });
    const headers = await t.adminHeaders();

    const page1 = await request(t.server()).get(`${API}/villas?pageSize=2&sort=name:asc`).set(headers);
    const page2 = await request(t.server()).get(`${API}/villas?pageSize=2&page=2&sort=name:asc`).set(headers);
    const desc = await request(t.server()).get(`${API}/villas?sort=name:desc`).set(headers);
    const search = await request(t.server()).get(`${API}/villas?q=bal`).set(headers);
    const byStatus = await request(t.server()).get(`${API}/villas?operationalStatus=BLOCKED`).set(headers);
    const byCategory = await request(t.server()).get(`${API}/villas?category=Jungle`).set(headers);

    expect(page1.body.data.map((v: { name: string }) => v.name)).toEqual(['Alux', 'Balam']);
    expect(page1.body.meta).toMatchObject({ page: 1, pageSize: 2, total: 3 });
    expect(page2.body.data.map((v: { name: string }) => v.name)).toEqual(['Ceiba']);
    expect(desc.body.data[0].name).toBe('Ceiba');
    expect(search.body.data.map((v: { name: string }) => v.name)).toEqual(['Balam']);
    expect(byStatus.body.meta.total).toBe(1);
    expect(byCategory.body.data[0].name).toBe('Alux');
  });

  it('test_listVillas_activeFilter_parsesBoolean', async () => {
    const villa = await createVilla('Ceiba');
    await createVilla('Alux');
    await request(t.server()).patch(`${API}/villas/${villa.villaId}`).set(await t.adminHeaders()).send({ isActive: false });

    const res = await request(t.server()).get(`${API}/villas?isActive=false`).set(await t.adminHeaders());

    expect(res.body.data.map((v: { name: string }) => v.name)).toEqual(['Ceiba']);
  });

  it.each([
    ['pageSize=101'],
    ['page=0'],
    ['sort=wifi:asc'],
    ['sort=name'],
    ['operationalStatus=PARTY'],
  ])('test_listVillas_invalidQuery_%s_is400', async (qs) => {
    const res = await request(t.server()).get(`${API}/villas?${qs}`).set(await t.adminHeaders());

    expect(res.status).toBe(400);
  });

  it.each([
    [{ name: '' }],
    [{ capacity: 0 }],
    [{ operationalStatus: 'OPEN' }],
    [{ wifi: { ssid: 1 } }],
  ])('test_createVilla_invalid_%j_is400', async (overrides) => {
    const res = await request(t.server()).post(`${API}/villas`).set(await t.adminHeaders()).send(villaBody('X', overrides));

    expect(res.status).toBe(400);
  });

  it('test_patchVilla_updatesFieldsAndAudit', async () => {
    const villa = await createVilla('Ceiba');

    const res = await request(t.server())
      .patch(`${API}/villas/${villa.villaId}`)
      .set(await t.adminHeaders())
      .send({ housekeepingStatus: 'DIRTY', operationalStatus: 'MAINTENANCE', maintenanceNote: 'AC check', wifi: { ssid: 'new', password: 'p' } });

    expect(res.status).toBe(200);
    expect(res.body.data).toMatchObject({
      id: villa.id,
      housekeepingStatus: 'DIRTY',
      operationalStatus: 'MAINTENANCE',
      maintenanceNote: 'AC check',
      wifi: { ssid: 'new', password: 'p' },
      name: 'Ceiba',
    });
  });

  it('test_patchVilla_unknown_is404', async () => {
    const res = await request(t.server()).patch(`${API}/villas/nope`).set(await t.adminHeaders()).send({ name: 'X' });

    expect(res.status).toBe(404);
  });

  it('test_deleteVilla_withoutStays_removesIt', async () => {
    const villa = await createVilla('Ceiba');

    const res = await request(t.server()).delete(`${API}/villas/${villa.villaId}`).set(await t.adminHeaders());
    const after = await request(t.server()).get(`${API}/villas/${villa.villaId}`).set(await t.adminHeaders());

    expect(res.status).toBe(200);
    expect(after.status).toBe(404);
  });

  it('test_getVilla_inHouseStay_exposesCurrentGuestName', async () => {
    const villa = await createVilla('Ceiba');
    t.fake.store('stays').set('stay-1', {
      stayId: 'stay-1', villaId: villa.id, status: 'ACTIVE_STAY', checkInDate: '2026-12-01', guestProfile: { name: 'Guest Test' },
    });

    const res = await request(t.server()).get(`${API}/villas/${villa.id}`).set(await t.adminHeaders());
    const list = await request(t.server()).get(`${API}/villas`).set(await t.adminHeaders());

    expect(res.body.data.currentGuestName).toBe('Guest Test');
    expect(list.body.data[0].currentGuestName).toBe('Guest Test');
  });

  it('test_deleteVilla_withStays_is409_deactivateInstead', async () => {
    const villa = await createVilla('Ceiba');
    t.fake.store('stays').set('stay-1', { stayId: 'stay-1', villaId: villa.villaId });

    const res = await request(t.server()).delete(`${API}/villas/${villa.villaId}`).set(await t.adminHeaders());

    expect(res.status).toBe(409);
  });

  it('test_villaWrites_nonAdmin_are403', async () => {
    const villa = await createVilla('Ceiba');
    const coordinator = await t.staffHeaders('DEPARTMENT_COORDINATOR');

    const statuses = [
      (await request(t.server()).post(`${API}/villas`).set(coordinator).send(villaBody('X'))).status,
      (await request(t.server()).patch(`${API}/villas/${villa.villaId}`).set(coordinator).send({ name: 'Y' })).status,
      (await request(t.server()).delete(`${API}/villas/${villa.villaId}`).set(coordinator)).status,
      (await request(t.server()).get(`${API}/villas`).set(coordinator)).status,
    ];

    expect(statuses).toEqual([403, 403, 403, 200]);
  });
});

describe('Transport providers (GET/POST/PATCH /admin/transport-providers)', () => {
  let t: TestApp;

  beforeEach(async () => {
    t = await createTestApp();
  });

  afterEach(() => t.close());

  it('test_providers_createListFilterSearchAndPatch', async () => {
    const headers = await t.adminHeaders();
    const created = await request(t.server())
      .post(`${API}/transport-providers`)
      .set(headers)
      .send({ name: 'Riviera Transfers', phone: '+52 998 000 0000', email: 'ops@riviera.test' });
    await request(t.server()).post(`${API}/transport-providers`).set(headers).send({ name: 'Andes Cars', isActive: false });

    const all = await request(t.server()).get(`${API}/transport-providers?sort=name:asc`).set(headers);
    const active = await request(t.server()).get(`${API}/transport-providers?isActive=true`).set(headers);
    const search = await request(t.server()).get(`${API}/transport-providers?q=riviera`).set(headers);
    const patched = await request(t.server())
      .patch(`${API}/transport-providers/${created.body.data.providerId}`)
      .set(headers)
      .send({ phone: '+52 1' });

    expect(created.status).toBe(201);
    expect(created.body.data).toMatchObject({ id: created.body.data.providerId, name: 'Riviera Transfers', isActive: true });
    expect(all.body.data.map((p: { name: string }) => p.name)).toEqual(['Andes Cars', 'Riviera Transfers']);
    expect(all.body.meta).toMatchObject({ page: 1, pageSize: 25, total: 2 });
    expect(active.body.meta.total).toBe(1);
    expect(search.body.data[0].email).toBe('ops@riviera.test');
    expect(patched.body.data).toMatchObject({ phone: '+52 1', email: 'ops@riviera.test' });
  });

  it.each([[{ name: '' }], [{ name: 'X', email: 'not-an-email' }]])(
    'test_createProvider_invalid_%j_is400',
    async (body) => {
      const res = await request(t.server()).post(`${API}/transport-providers`).set(await t.adminHeaders()).send(body);

      expect(res.status).toBe(400);
    },
  );

  it('test_createProvider_nonAdmin_is403', async () => {
    const res = await request(t.server())
      .post(`${API}/transport-providers`)
      .set(await t.staffHeaders('CONCIERGE_STAFF'))
      .send({ name: 'X' });

    expect(res.status).toBe(403);
  });
});
