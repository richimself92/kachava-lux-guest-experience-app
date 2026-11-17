import { AlertCategory, OperationalAlert } from '../../src/domain/models/domain.models';
import { ALERTS_COLLECTION } from '../../src/infrastructure/repositories/firestore-alert.repository';
import { FakeFirestore } from './fake-firestore';

/** Operational alerts written to the fake store, newest first, optionally of one category. */
export function storedAlerts(fake: FakeFirestore, category?: AlertCategory): OperationalAlert[] {
  const alerts = Array.from(fake.store(ALERTS_COLLECTION).values()) as unknown as OperationalAlert[];
  return alerts
    .filter((alert) => !category || alert.category === category)
    .sort((a, b) => b.createdAt.localeCompare(a.createdAt));
}
