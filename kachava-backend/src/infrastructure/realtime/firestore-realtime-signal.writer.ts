import { FieldValue, Firestore } from 'firebase-admin/firestore';
import { RealtimeSignalWriterPort } from '../../domain/ports/realtime-signal.port';
import { RealtimeTopic } from '../../domain/realtime/realtime-signal';

/** Clients may `get`/listen to single docs here (firestore.rules); never list or write. */
export const REALTIME_SIGNALS_COLLECTION = 'realtime_signals';

/**
 * Updates each channel doc in place (`merge`), so the collection holds one doc per channel and
 * needs no TTL. Only `{at, topic, seq}` is written: no business data ever reaches a signal.
 */
export class FirestoreRealtimeSignalWriter implements RealtimeSignalWriterPort {
  constructor(private readonly db: Firestore) {}

  async touch(channelIds: string[], topic: RealtimeTopic): Promise<void> {
    const batch = this.db.batch();
    for (const channelId of channelIds) {
      const signal = { at: FieldValue.serverTimestamp(), topic, seq: FieldValue.increment(1) };
      batch.set(this.db.collection(REALTIME_SIGNALS_COLLECTION).doc(channelId), signal, { merge: true });
    }
    await batch.commit();
  }
}
