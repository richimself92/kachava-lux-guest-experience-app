import { Inject, Injectable, Optional } from '@nestjs/common';
import { resolveRealtimeAdminChannel } from '../../common/config/realtime-channels';
import { StayAggregate } from '../../domain/models/domain.models';
import { STAY_REPOSITORY_PORT, StayRepositoryPort } from '../../domain/ports/repository.ports';
import { newStayRealtimeChannelId } from '../../domain/realtime/realtime-signal';

export const REALTIME_ADMIN_CHANNEL_RESOLVER = Symbol('REALTIME_ADMIN_CHANNEL_RESOLVER');

/** Resolves signal channel ids; stays created before ADR-012 get theirs lazily (guest view). */
@Injectable()
export class RealtimeChannels {
  constructor(
    @Inject(STAY_REPOSITORY_PORT) private readonly stays: StayRepositoryPort,
    @Optional() @Inject(REALTIME_ADMIN_CHANNEL_RESOLVER)
    private readonly resolveAdminChannel: () => string = resolveRealtimeAdminChannel,
  ) {}

  adminChannel(): string {
    return this.resolveAdminChannel();
  }

  /**
   * Read-only: `null` when the stay is gone or has no channel yet. A channel is only created when
   * the guest view is served, so no client can be listening before then (and writes on hot stays
   * never contend with a channel update).
   */
  async stayChannel(stayId: string): Promise<string | null> {
    const stay = await this.stays.findByStayId(stayId);
    return stay?.realtimeChannelId ?? null;
  }

  /** Idempotent under races: the transactional update keeps a channel another request stored. */
  async ensureStayChannel(stay: StayAggregate): Promise<string> {
    if (stay.realtimeChannelId) return stay.realtimeChannelId;
    const updated = await this.stays.updateStay(stay.stayId, (current) =>
      current.realtimeChannelId ? current : { ...current, realtimeChannelId: newStayRealtimeChannelId() },
    );
    return updated.realtimeChannelId as string;
  }
}
