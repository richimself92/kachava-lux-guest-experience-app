import type { Firestore } from 'firebase-admin/firestore';
import {
  AlertRepositoryPort,
  CatalogRepositoryPort,
  StayRepositoryPort,
} from '../../domain/ports/repository.ports';
import { FirestoreAlertRepository } from '../repositories/firestore-alert.repository';
import { FirestoreCatalogRepository } from '../repositories/firestore-catalog.repository';
import { FirestoreStayRepository } from '../repositories/firestore-stay.repository';
import { InMemorySeededAlertRepository } from '../repositories/in-memory-alert.repository';
import { InMemorySeededCatalogRepository } from '../repositories/in-memory-catalog.repository';
import { InMemorySeededStayRepository } from '../repositories/in-memory-stay.repository';

/**
 * Adapter selection: a Firestore handle (USE_FIRESTORE=true) selects the Firestore adapters,
 * which are the single source of truth; otherwise the seeded in-memory adapters are used.
 */
export function createStayRepository(
  db: Firestore | null,
  alerts?: AlertRepositoryPort,
): StayRepositoryPort {
  if (db) return new FirestoreStayRepository(db);
  const inMemoryAlerts = alerts instanceof InMemorySeededAlertRepository ? alerts : undefined;
  return new InMemorySeededStayRepository(inMemoryAlerts);
}

export function createAlertRepository(db: Firestore | null): AlertRepositoryPort {
  return db ? new FirestoreAlertRepository(db) : new InMemorySeededAlertRepository();
}

export function createCatalogRepository(db: Firestore | null): CatalogRepositoryPort {
  return db ? new FirestoreCatalogRepository(db) : new InMemorySeededCatalogRepository();
}
