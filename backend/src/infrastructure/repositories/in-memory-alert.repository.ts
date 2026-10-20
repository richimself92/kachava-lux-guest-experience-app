import { Injectable } from '@nestjs/common';
import { OperationalAlert } from '../../domain/models/domain.models';
import {
  AlertFilterCriteria,
  AlertRepositoryPort,
} from '../../domain/ports/repository.ports';
import { getNamedFirestoreDb } from '../firebase/firebase-admin.module';
import { createSeededOperationalAlerts } from '../seed/sanctuary-seed.data';

@Injectable()
export class InMemorySeededAlertRepository implements AlertRepositoryPort {
  private readonly alerts: OperationalAlert[] = createSeededOperationalAlerts();
  private hydrated = false;
  private hydrationPromise: Promise<void> | null = null;

  private async ensureHydrated(): Promise<void> {
    if (this.hydrated) return;
    const db = getNamedFirestoreDb();
    if (!db) {
      this.hydrated = true;
      return;
    }
    if (!this.hydrationPromise) {
      this.hydrationPromise = (async () => {
        try {
          const snap = await db.collection('operational_alerts').get();
          this.alerts.length = 0;
          const loaded = snap.docs
            .map((doc) => doc.data() as OperationalAlert)
            .filter((a) => Boolean(a && a.alertId))
            .sort((a, b) => (b.createdAt || '').localeCompare(a.createdAt || ''));
          this.alerts.push(...loaded);
        } catch {
          // Keep existing in-memory alerts if Firestore read fails
        } finally {
          this.hydrated = true;
        }
      })();
    }
    await this.hydrationPromise;
  }

  async createAlert(alert: OperationalAlert): Promise<OperationalAlert> {
    await this.ensureHydrated();
    const copy = structuredClone(alert);
    this.alerts.unshift(copy);
    const db = getNamedFirestoreDb();
    if (db) {
      void db
        .collection('operational_alerts')
        .doc(copy.alertId)
        .set(copy, { merge: true })
        .catch(() => undefined);
    }
    return structuredClone(copy);
  }

  async listAlerts(
    filter?: AlertFilterCriteria,
  ): Promise<{ alerts: OperationalAlert[]; unreadCount: number }> {
    await this.ensureHydrated();
    const unreadCount = this.alerts.filter((a) => !a.isAcknowledged).length;
    const filtered = this.alerts.filter((a) => {
      if (filter?.isAcknowledged !== undefined && a.isAcknowledged !== filter.isAcknowledged) {
        return false;
      }
      if (filter?.category && a.category !== filter.category) return false;
      if (filter?.severity && a.severity !== filter.severity) return false;
      if (filter?.assignedDepartment && a.assignedDepartment !== filter.assignedDepartment) {
        return false;
      }
      return true;
    });
    return {
      alerts: structuredClone(filtered),
      unreadCount,
    };
  }

  async acknowledgeAlert(
    alertId: string,
    staffId: string,
  ): Promise<OperationalAlert | null> {
    await this.ensureHydrated();
    const alert = this.alerts.find((a) => a.alertId === alertId);
    if (!alert) return null;
    alert.isAcknowledged = true;
    alert.acknowledgedByStaffId = staffId;
    alert.acknowledgedAt = new Date().toISOString();
    const db = getNamedFirestoreDb();
    if (db) {
      void db
        .collection('operational_alerts')
        .doc(alertId)
        .set(
          {
            isAcknowledged: true,
            acknowledgedByStaffId: staffId,
            acknowledgedAt: alert.acknowledgedAt,
          },
          { merge: true },
        )
        .catch(() => undefined);
    }
    return structuredClone(alert);
  }

  async resetAllAlerts(): Promise<void> {
    await this.ensureHydrated();
    this.alerts.length = 0;
    const db = getNamedFirestoreDb();
    if (db) {
      void db
        .collection('operational_alerts')
        .get()
        .then((snap) => Promise.all(snap.docs.map((d) => d.ref.delete())))
        .catch(() => undefined);
    }
  }
}
