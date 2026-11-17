import request from 'supertest';
import { DEV_REALTIME_ADMIN_CHANNEL } from '../../src/common/config/realtime-channels';
import { REALTIME_SIGNAL_WRITER_PORT } from '../../src/domain/ports/realtime-signal.port';
import { RecordingRealtimeSignalWriter } from '../../src/infrastructure/realtime/recording-realtime-signal.writer';
import { STAYS_COLLECTION } from '../../src/infrastructure/repositories/firestore-stay.repository';
import { routeTopic } from '../../src/modules/realtime/realtime-routes';
import { TEST_GUEST_TOKEN } from '../support/stay-fixtures';
import {
  createTestApp,
  createVillaAndStay,
  CreatedStay,
  GUEST_STAY_PATH,
  seedGuestFixtures,
  TEST_ADMIN_EMAIL,
  TestApp,
} from '../support/test-app';
import {
  arrivalBody,
  createTransportService,
  FixedClock,
  patchSettings,
  setUpTripWorld,
  TRANSPORT_SETTINGS,
} from '../support/trip-setup';

const ADMIN = '/api/v1/admin';
const MUTATING = new Set(['post', 'put', 'patch', 'delete']);
const STAY_CHANNEL = /^s_[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/;

/** ADR-012: every successful write bumps Firestore signal docs; clients re-fetch on change. */
describe('Realtime signal documents', () => {
  let t: TestApp;
  let signals: RecordingRealtimeSignalWriter;
  let ana: CreatedStay;
  let bruno: CreatedStay;

  const guestView = async (token: string) => (await request(t.server()).get(`/api/v1/stays/${token}`)).body.data;
  const storedChannel = (stayId: string) => t.fake.store(STAYS_COLLECTION).get(stayId)?.realtimeChannelId;

  beforeEach(async () => {
    t = await createTestApp(undefined, { clock: new FixedClock() });
    signals = t.app.get(REALTIME_SIGNAL_WRITER_PORT);
    ana = await createVillaAndStay(t, { villaName: 'Villa A', guestName: 'Ana Guest' });
    bruno = await createVillaAndStay(t, { villaName: 'Villa B', guestName: 'Bruno Guest' });
    signals.batches.length = 0;
  });

  afterEach(() => t.close());

  describe('channel ids handed to clients', () => {
    it('test_adminLogin_returnsAdminChannel', async () => {
      const res = await request(t.server()).post(`${ADMIN}/auth/login`).send({ email: TEST_ADMIN_EMAIL });

      expect(res.body.data.realtime).toEqual({ adminChannel: DEV_REALTIME_ADMIN_CHANNEL });
    });

    it('test_newStay_hasItsOwnChannel_exposedOnlyInItsGuestView', async () => {
      const anaView = await guestView(ana.guestTokenUuid);
      const brunoView = await guestView(bruno.guestTokenUuid);

      expect(anaView.realtime).toEqual({ channel: storedChannel(ana.stayId), global: 'global' });
      expect(anaView.realtime.channel).toMatch(STAY_CHANNEL);
      expect(brunoView.realtime.channel).not.toBe(anaView.realtime.channel);
      expect(JSON.stringify(anaView)).not.toContain(DEV_REALTIME_ADMIN_CHANNEL);
      expect(JSON.stringify(anaView)).not.toContain(brunoView.realtime.channel);
    });

    it('test_olderStayWithoutChannel_getsOnePersistedOnFirstRead', async () => {
      seedGuestFixtures(t.fake);

      const first = await guestView(TEST_GUEST_TOKEN);
      const second = await guestView(TEST_GUEST_TOKEN);

      expect(first.realtime.channel).toMatch(STAY_CHANNEL);
      expect(second.realtime.channel).toBe(first.realtime.channel);
    });

    it('test_tokenRegeneration_rotatesTheChannel_andSignalsTheNewOne', async () => {
      const before = storedChannel(ana.stayId);

      const res = await request(t.server()).post(`${ADMIN}/stays/${ana.stayId}/regenerate-token`).set(await t.adminHeaders());

      const after = (await guestView(res.body.data.guestTokenUuid)).realtime.channel;
      expect(after).toMatch(STAY_CHANNEL);
      expect(after).not.toBe(before);
      expect(signals.batches).toEqual([{ channelIds: [DEV_REALTIME_ADMIN_CHANNEL, after], topic: 'stay' }]);
    });
  });

  describe('signals written after successful writes', () => {
    it('test_guestChatMessage_touchesAdminAndThatStayChannel', async () => {
      const guest = `/api/v1/stays/${ana.guestTokenUuid}`;
      const thread = await request(t.server()).post(`${guest}/concierge-requests`).send({ title: 'Host', details: 'Hi' });
      signals.batches.length = 0;

      await request(t.server()).post(`${guest}/concierge-requests/${thread.body.data.requestId}/messages`).send({ text: 'Towels' }).expect(201);

      expect(signals.batches).toEqual([{ channelIds: [DEV_REALTIME_ADMIN_CHANNEL, storedChannel(ana.stayId)], topic: 'messages' }]);
    });

    it('test_adminTripTransition_touchesAdminAndThatStayChannel', async () => {
      const world = await setUpTripWorld(t);
      const admin = await t.adminHeaders();
      const trip = await request(t.server()).post(`${ADMIN}/trips`).set(admin).send({ stayId: world.stay.stayId, ...arrivalBody(world.serviceId) });
      signals.batches.length = 0;

      await request(t.server()).post(`${ADMIN}/trips/${trip.body.data.id ?? trip.body.data.tripId}/transition`).set(admin)
        .send({ to: 'SENT_TO_PROVIDER', providerId: world.providerId }).expect(200);

      expect(signals.batches).toEqual([{ channelIds: [DEV_REALTIME_ADMIN_CHANNEL, storedChannel(world.stay.stayId)], topic: 'trips' }]);
    });

    it('test_catalogChange_touchesAdminAndGlobal', async () => {
      await patchSettings(t, TRANSPORT_SETTINGS);
      signals.batches.length = 0;

      await createTransportService(t);

      expect(signals.batches).toEqual([{ channelIds: [DEV_REALTIME_ADMIN_CHANNEL, 'global'], topic: 'catalog' }]);
    });

    it('test_failedWritesReadsAndLogin_signalNothing', async () => {
      const admin = await t.adminHeaders();

      await request(t.server()).post(`${ADMIN}/conversations/${ana.stayId}/messages`).set(admin).send({ text: '' }).expect(400);
      await request(t.server()).get(`${ADMIN}/settings`).set(admin).expect(200);
      await request(t.server()).get(GUEST_STAY_PATH).expect(401);

      expect(signals.batches).toEqual([]);
    });
  });

  it('test_everyMutatingRoute_hasATopicOrIsExplicitlySilent', () => {
    const stack = t.app.getHttpAdapter().getInstance()._router.stack as Array<{
      route?: { path: string; methods: Record<string, boolean> };
    }>;
    const unmapped = stack
      .filter((layer) => layer.route && Object.keys(layer.route.methods).some((m) => MUTATING.has(m)))
      .map((layer) => layer.route!.path)
      .filter((path) => routeTopic(path) === undefined);

    expect(unmapped).toEqual([]);
  });
});
