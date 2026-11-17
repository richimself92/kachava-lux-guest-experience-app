import { Inject, Injectable, Logger } from '@nestjs/common';
import { REALTIME_SIGNAL_WRITER_PORT, RealtimeSignalWriterPort } from '../../domain/ports/realtime-signal.port';
import { GLOBAL_CHANNEL, RealtimeChange } from '../../domain/realtime/realtime-signal';
import { RealtimeChannels } from './realtime-channels.service';

/**
 * The single entry point for announcing changes (HTTP interceptor and any non-HTTP writer).
 * Never rejects: the business write already succeeded, so a signalling failure is only logged.
 */
@Injectable()
export class RealtimePublisher {
  private readonly logger = new Logger(RealtimePublisher.name);

  constructor(
    @Inject(REALTIME_SIGNAL_WRITER_PORT) private readonly writer: RealtimeSignalWriterPort,
    private readonly channels: RealtimeChannels,
  ) {}

  async publish(change: RealtimeChange): Promise<void> {
    try {
      await this.writer.touch(await this.channelsFor(change), change.topic);
    } catch (error) {
      this.logger.error(`Realtime signal ${change.topic} not published: ${(error as Error).message}`);
    }
  }

  private async channelsFor(change: RealtimeChange): Promise<string[]> {
    const channels = [this.channels.adminChannel()];
    if (change.scope === 'global') channels.push(GLOBAL_CHANNEL);
    if (change.scope === 'stay' && change.stayId) {
      const stayChannel = await this.channels.stayChannel(change.stayId);
      if (stayChannel) channels.push(stayChannel);
    }
    return channels;
  }
}
