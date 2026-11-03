import { RealtimeSignalWriterPort } from '../../domain/ports/realtime-signal.port';
import { RealtimeTopic } from '../../domain/realtime/realtime-signal';

export interface RecordedSignalBatch {
  channelIds: string[];
  topic: RealtimeTopic;
}

/** In-memory writer used when Firestore is off (`USE_FIRESTORE` not `true`, i.e. tests). */
export class RecordingRealtimeSignalWriter implements RealtimeSignalWriterPort {
  readonly batches: RecordedSignalBatch[] = [];

  async touch(channelIds: string[], topic: RealtimeTopic): Promise<void> {
    this.batches.push({ channelIds: [...channelIds], topic });
  }
}
