import { Injectable } from '@nestjs/common';
import {
  acknowledge,
  AlertListing,
  newestAlerts,
  summarizeAlerts,
} from '../../domain/alert-projections';
import { OperationalAlert } from '../../domain/models/domain.models';
import {
  AlertFilterCriteria,
  AlertRepositoryPort,
} from '../../domain/ports/repository.ports';
import { createSeededOperationalAlerts } from '../seed/sanctuary-seed.data';

/** Process-local alert store for local development and tests. Never used in Firestore mode. */
@Injectable()
export class InMemorySeededAlertRepository implements AlertRepositoryPort {
  private readonly alerts: OperationalAlert[] = createSeededOperationalAlerts();

  async createAlert(alert: OperationalAlert): Promise<OperationalAlert> {
    this.insertNow(alert);
    return structuredClone(alert);
  }

  /** Synchronous insert used by the in-memory stay store to commit a mutation and its alert together. */
  insertNow(alert: OperationalAlert): void {
    this.alerts.unshift(structuredClone(alert));
  }

  async listAlerts(filter?: AlertFilterCriteria): Promise<AlertListing> {
    return summarizeAlerts(newestAlerts(this.alerts), filter);
  }

  async acknowledgeAlert(alertId: string, staffId: string): Promise<OperationalAlert | null> {
    const alert = this.alerts.find((a) => a.alertId === alertId);
    return alert ? acknowledge(alert, staffId) : null;
  }

  async resetAllAlerts(): Promise<void> {
    this.alerts.length = 0;
  }
}
