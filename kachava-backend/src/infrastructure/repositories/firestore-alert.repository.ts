import type { CollectionReference, Firestore, Query } from 'firebase-admin/firestore';
import { acknowledge } from '../../domain/alert-projections';
import { OperationalAlert } from '../../domain/models/domain.models';
import { AlertRepositoryPort } from '../../domain/ports/repository.ports';
import { toFirestoreDocument } from './firestore-document.mapper';

export const ALERTS_COLLECTION = 'operational_alerts';
/** Firestore transactions accept at most 500 writes. */
const WRITES_PER_TRANSACTION = 400;

/** Firestore-backed alerts: read on every call, awaited writes, errors propagate. */
export class FirestoreAlertRepository implements AlertRepositoryPort {
  constructor(private readonly db: Firestore) {}

  async createAlert(alert: OperationalAlert): Promise<OperationalAlert> {
    await this.alerts().doc(alert.alertId).set(toFirestoreDocument(alert));
    return structuredClone(alert);
  }

  acknowledgeAlert(alertId: string, staffId: string): Promise<OperationalAlert | null> {
    return this.db.runTransaction(async (tx) => {
      const ref = this.alerts().doc(alertId);
      const snapshot = await tx.get(ref);
      if (!snapshot.exists) return null;
      const updated = acknowledge(snapshot.data() as OperationalAlert, staffId);
      tx.set(ref, toFirestoreDocument(updated));
      return updated;
    });
  }

  async listRecent(window: { fromIso?: string; toIsoExclusive?: string }, limit: number): Promise<OperationalAlert[]> {
    let query: Query = this.alerts();
    if (window.fromIso) query = query.where('createdAt', '>=', window.fromIso);
    if (window.toIsoExclusive) query = query.where('createdAt', '<', window.toIsoExclusive);
    const snapshot = await query.orderBy('createdAt', 'desc').limit(limit).get();
    return snapshot.docs.map((doc) => doc.data() as OperationalAlert);
  }

  async acknowledgeMany(alertIds: readonly string[], staffId: string, at: string): Promise<number> {
    let changed = 0;
    for (let start = 0; start < alertIds.length; start += WRITES_PER_TRANSACTION) {
      const chunk = alertIds.slice(start, start + WRITES_PER_TRANSACTION);
      changed += await this.db.runTransaction(async (tx) => {
        const refs = chunk.map((id) => this.alerts().doc(id));
        const snapshots = await Promise.all(refs.map((ref) => tx.get(ref)));
        let count = 0;
        snapshots.forEach((snapshot, index) => {
          const alert = snapshot.data() as OperationalAlert | undefined;
          if (!snapshot.exists || !alert || alert.isAcknowledged) return;
          tx.set(refs[index], toFirestoreDocument({ ...alert, isAcknowledged: true, acknowledgedByStaffId: staffId, acknowledgedAt: at }));
          count += 1;
        });
        return count;
      });
    }
    return changed;
  }

  async resetAllAlerts(): Promise<void> {
    await this.db.recursiveDelete(this.alerts());
  }

  private alerts(): CollectionReference {
    return this.db.collection(ALERTS_COLLECTION);
  }
}
