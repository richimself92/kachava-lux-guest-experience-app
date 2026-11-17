import type { CollectionReference, Firestore } from 'firebase-admin/firestore';
import { NotificationReadRepositoryPort } from '../../domain/ports/repository.ports';

export const NOTIFICATION_READS_COLLECTION = 'notification_reads';
/** Firestore transactions accept at most 500 writes. */
const WRITES_PER_TRANSACTION = 400;

interface ReadMarker {
  notificationId: string;
  readAt: string;
  readBy: string;
}

/**
 * `notification_reads/{notificationId}`: read state of notifications computed on read (arrival
 * day, overdue task, unconfirmed trip). Ids are deterministic per event, so a marker sticks.
 */
export class FirestoreNotificationReadRepository implements NotificationReadRepositoryPort {
  constructor(private readonly db: Firestore) {}

  async readAtOf(ids: readonly string[]): Promise<Map<string, string>> {
    const snapshots = await Promise.all(ids.map((id) => this.reads().doc(id).get()));
    const found = new Map<string, string>();
    for (const snapshot of snapshots) {
      if (snapshot.exists) found.set(snapshot.id, (snapshot.data() as ReadMarker).readAt);
    }
    return found;
  }

  async markRead(ids: readonly string[], staffId: string, at: string): Promise<void> {
    for (let start = 0; start < ids.length; start += WRITES_PER_TRANSACTION) {
      const chunk = ids.slice(start, start + WRITES_PER_TRANSACTION);
      await this.db.runTransaction(async (tx) => {
        for (const id of chunk) {
          const marker: ReadMarker = { notificationId: id, readAt: at, readBy: staffId };
          tx.set(this.reads().doc(id), { ...marker });
        }
      });
    }
  }

  private reads(): CollectionReference {
    return this.db.collection(NOTIFICATION_READS_COLLECTION);
  }
}
