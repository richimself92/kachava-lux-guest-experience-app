import { Logger } from '@nestjs/common';
import { FieldValue } from 'firebase-admin/firestore';
import {
  DEV_REALTIME_ADMIN_CHANNEL,
  resolveRealtimeAdminChannel,
} from '../../src/common/config/realtime-channels';
import { StayAggregate } from '../../src/domain/models/domain.models';
import { StayRepositoryPort } from '../../src/domain/ports/repository.ports';
import { GLOBAL_CHANNEL } from '../../src/domain/realtime/realtime-signal';
import {
  FirestoreRealtimeSignalWriter,
  REALTIME_SIGNALS_COLLECTION,
} from '../../src/infrastructure/realtime/firestore-realtime-signal.writer';
import { RecordingRealtimeSignalWriter } from '../../src/infrastructure/realtime/recording-realtime-signal.writer';
import { RealtimeChannels } from '../../src/modules/realtime/realtime-channels.service';
import { RealtimePublisher } from '../../src/modules/realtime/realtime-publisher.service';

const ADMIN_CHANNEL = 'admin-secret-channel';

/** Only the two calls the channel service makes; every other port method is unused here. */
class StayStub {
  readonly stays = new Map<string, Partial<StayAggregate>>();
  updates = 0;

  async findByStayId(stayId: string) {
    return (this.stays.get(stayId) as StayAggregate) ?? null;
  }

  async updateStay(stayId: string, change: (current: StayAggregate) => StayAggregate) {
    this.updates += 1;
    const updated = change(this.stays.get(stayId) as StayAggregate);
    this.stays.set(stayId, updated);
    return updated;
  }

  asPort(): StayRepositoryPort {
    return this as unknown as StayRepositoryPort;
  }
}

describe('RealtimePublisher (ADR-012 signal documents)', () => {
  let stays: StayStub;
  let writer: RecordingRealtimeSignalWriter;
  let publisher: RealtimePublisher;

  beforeEach(() => {
    stays = new StayStub();
    stays.stays.set('stay-1', { stayId: 'stay-1', realtimeChannelId: 's_ana' });
    writer = new RecordingRealtimeSignalWriter();
    publisher = new RealtimePublisher(writer, new RealtimeChannels(stays.asPort(), () => ADMIN_CHANNEL));
  });

  it('test_stayChange_touchesAdminAndThatStayChannel_inOneBatch', async () => {
    await publisher.publish({ scope: 'stay', stayId: 'stay-1', topic: 'messages' });

    expect(writer.batches).toEqual([{ channelIds: [ADMIN_CHANNEL, 's_ana'], topic: 'messages' }]);
  });

  it('test_globalChange_touchesAdminAndGlobal', async () => {
    await publisher.publish({ scope: 'global', topic: 'catalog' });

    expect(writer.batches).toEqual([{ channelIds: [ADMIN_CHANNEL, GLOBAL_CHANNEL], topic: 'catalog' }]);
  });

  it('test_adminOnlyChange_touchesOnlyAdmin', async () => {
    await publisher.publish({ scope: 'admin-only', topic: 'notifications' });

    expect(writer.batches).toEqual([{ channelIds: [ADMIN_CHANNEL], topic: 'notifications' }]);
  });

  it('test_olderStayWithoutChannel_touchesOnlyAdmin_andWritesNothingToTheStay', async () => {
    stays.stays.set('stay-old', { stayId: 'stay-old' });

    await publisher.publish({ scope: 'stay', stayId: 'stay-old', topic: 'stay' });

    expect(writer.batches).toEqual([{ channelIds: [ADMIN_CHANNEL], topic: 'stay' }]);
    expect(stays.updates).toBe(0);
  });

  it('test_ensureStayChannel_generatesOnce_andPersists', async () => {
    const channels = new RealtimeChannels(stays.asPort(), () => ADMIN_CHANNEL);
    stays.stays.set('stay-old', { stayId: 'stay-old' });

    const first = await channels.ensureStayChannel(stays.stays.get('stay-old') as StayAggregate);
    const second = await channels.ensureStayChannel(stays.stays.get('stay-old') as StayAggregate);

    expect(first).toMatch(/^s_[0-9a-f-]{36}$/);
    expect(second).toBe(first);
    expect(stays.updates).toBe(1);
  });

  it('test_unknownStay_stillTouchesAdmin', async () => {
    await publisher.publish({ scope: 'stay', stayId: 'gone', topic: 'tasks' });

    expect(writer.batches).toEqual([{ channelIds: [ADMIN_CHANNEL], topic: 'tasks' }]);
  });

  it('test_writeFailure_isLogged_andNeverRejects', async () => {
    const logged = jest.spyOn(Logger.prototype, 'error').mockImplementation(() => undefined);
    const failing = { touch: () => Promise.reject(new Error('firestore down')) };
    const fragile = new RealtimePublisher(failing, new RealtimeChannels(stays.asPort(), () => ADMIN_CHANNEL));

    await expect(fragile.publish({ scope: 'global', topic: 'settings' })).resolves.toBeUndefined();

    expect(logged).toHaveBeenCalledWith(expect.stringContaining('firestore down'));
    logged.mockRestore();
  });
});

describe('FirestoreRealtimeSignalWriter', () => {
  it('test_touch_mergesOnlyAtTopicSeq_intoEachChannelDoc_withOneCommit', async () => {
    const sets: Array<{ path: string; data: Record<string, unknown>; options: unknown }> = [];
    let commits = 0;
    const db = {
      collection: (name: string) => ({ doc: (id: string) => ({ path: `${name}/${id}` }) }),
      batch: () => ({
        set: (ref: { path: string }, data: Record<string, unknown>, options: unknown) => sets.push({ path: ref.path, data, options }),
        commit: async () => {
          commits += 1;
        },
      }),
    };

    await new FirestoreRealtimeSignalWriter(db as never).touch(['admin-x', 's_ana'], 'messages');

    expect(commits).toBe(1);
    expect(sets.map((s) => s.path)).toEqual([`${REALTIME_SIGNALS_COLLECTION}/admin-x`, `${REALTIME_SIGNALS_COLLECTION}/s_ana`]);
    for (const { data, options } of sets) {
      expect(Object.keys(data).sort()).toEqual(['at', 'seq', 'topic']);
      expect(data.topic).toBe('messages');
      expect(data.at).toEqual(FieldValue.serverTimestamp());
      expect(data.seq).toEqual(FieldValue.increment(1));
      expect(options).toEqual({ merge: true });
    }
  });
});

describe('resolveRealtimeAdminChannel', () => {
  it('test_configuredChannel_isUsed', () => {
    expect(resolveRealtimeAdminChannel({ REALTIME_ADMIN_CHANNEL: 'a'.repeat(40), NODE_ENV: 'production' })).toBe('a'.repeat(40));
  });

  it('test_production_withoutOrWithWeakChannel_failsFast', () => {
    expect(() => resolveRealtimeAdminChannel({ NODE_ENV: 'production' })).toThrow(/REALTIME_ADMIN_CHANNEL/);
    expect(() => resolveRealtimeAdminChannel({ NODE_ENV: 'production', REALTIME_ADMIN_CHANNEL: 'short' })).toThrow(
      /REALTIME_ADMIN_CHANNEL/,
    );
  });

  it('test_outsideProduction_defaultsToFixedDevChannel', () => {
    expect(resolveRealtimeAdminChannel({ NODE_ENV: 'development' })).toBe(DEV_REALTIME_ADMIN_CHANNEL);
    expect(resolveRealtimeAdminChannel({})).toBe(DEV_REALTIME_ADMIN_CHANNEL);
  });
});
