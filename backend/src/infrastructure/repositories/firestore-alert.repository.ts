import type { CollectionReference, Firestore } from 'firebase-admin/firestore';
import {
  acknowledge,
  ALERT_READ_LIMIT,
  AlertListing,
  summarizeAlerts,
} from '../../domain/alert-projections';
import { OperationalAlert } from '../../domain/models/domain.models';
import {
  AlertFilterCriteria,
  AlertRepositoryPort,
} from '../../domain/ports/repository.ports';
import { toFirestoreDocument } from './firestore-document.mapper';

export const ALERTS_COLLECTION = 'operational_alerts';

/** Firestore-backed alerts: read on every call, awaited writes, errors propagate. */
export class FirestoreAlertRepository implements AlertRepositoryPort {
  constructor(private readonly db: Firestore) {}

  async createAlert(alert: OperationalAlert): Promise<OperationalAlert> {
    await this.alerts().doc(alert.alertId).set(toFirestoreDocument(alert));
    return structuredClone(alert);
  }

  async listAlerts(filter?: AlertFilterCriteria): Promise<AlertListing> {
    const snapshot = await this.alerts()
      .orderBy('createdAt', 'desc')
      .limit(ALERT_READ_LIMIT)
      .get();
    return summarizeAlerts(
      snapshot.docs.map((doc) => doc.data() as OperationalAlert),
      filter,
    );
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

  async resetAllAlerts(): Promise<void> {
    await this.db.recursiveDelete(this.alerts());
  }

  private alerts(): CollectionReference {
    return this.db.collection(ALERTS_COLLECTION);
  }
}
