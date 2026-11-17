import { RealtimeTopic } from '../realtime/realtime-signal';

export const REALTIME_SIGNAL_WRITER_PORT = Symbol('REALTIME_SIGNAL_WRITER_PORT');

/** Bumps the signal documents of `channelIds` (one atomic batch per change). */
export interface RealtimeSignalWriterPort {
  touch(channelIds: string[], topic: RealtimeTopic): Promise<void>;
}
