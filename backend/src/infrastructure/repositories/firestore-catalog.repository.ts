import type { CollectionReference, Firestore } from 'firebase-admin/firestore';
import { buildExperienceCatalogItem, buildLarderCatalogItem } from '../../domain/catalog-items';
import {
  ExperienceCatalogItem,
  LarderCatalogItem,
  YachtCatalog,
} from '../../domain/models/domain.models';
import { CatalogRepositoryPort } from '../../domain/ports/repository.ports';
import { SEEDED_YACHT_CATALOG } from '../seed/sanctuary-catalog.seed';
import { toFirestoreDocument } from './firestore-document.mapper';

export const LARDER_CATALOG_COLLECTION = 'catalog_larder';
export const EXPERIENCE_CATALOG_COLLECTION = 'catalog_experiences';

/**
 * Firestore-backed catalogs: read on every call, never seeded at startup, awaited writes.
 * The yacht catalog is a static vessel specification and is served from code.
 */
export class FirestoreCatalogRepository implements CatalogRepositoryPort {
  constructor(private readonly db: Firestore) {}

  getLarderCatalog(): Promise<LarderCatalogItem[]> {
    return this.readAll<LarderCatalogItem>(LARDER_CATALOG_COLLECTION);
  }

  async createLarderCatalogItem(item: Partial<LarderCatalogItem>): Promise<LarderCatalogItem> {
    const created = buildLarderCatalogItem(item);
    await this.collection(LARDER_CATALOG_COLLECTION).doc(created.id).set(toFirestoreDocument(created));
    return created;
  }

  deleteLarderCatalogItem(id: string): Promise<{ deleted: boolean; id: string }> {
    return this.deleteIfExists(LARDER_CATALOG_COLLECTION, id);
  }

  getExperiencesCatalog(): Promise<ExperienceCatalogItem[]> {
    return this.readAll<ExperienceCatalogItem>(EXPERIENCE_CATALOG_COLLECTION);
  }

  async createExperienceCatalogItem(
    item: Partial<ExperienceCatalogItem>,
  ): Promise<ExperienceCatalogItem> {
    const created = buildExperienceCatalogItem(item);
    await this.collection(EXPERIENCE_CATALOG_COLLECTION)
      .doc(created.id)
      .set(toFirestoreDocument(created));
    return created;
  }

  deleteExperienceCatalogItem(id: string): Promise<{ deleted: boolean; id: string }> {
    return this.deleteIfExists(EXPERIENCE_CATALOG_COLLECTION, id);
  }

  async getYachtCatalog(): Promise<YachtCatalog> {
    return structuredClone(SEEDED_YACHT_CATALOG);
  }

  private async readAll<T>(collectionName: string): Promise<T[]> {
    const snapshot = await this.collection(collectionName).get();
    return snapshot.docs.map((doc) => doc.data() as T);
  }

  private deleteIfExists(collectionName: string, id: string): Promise<{ deleted: boolean; id: string }> {
    return this.db.runTransaction(async (tx) => {
      const ref = this.collection(collectionName).doc(id);
      const snapshot = await tx.get(ref);
      if (snapshot.exists) tx.delete(ref);
      return { deleted: snapshot.exists, id };
    });
  }

  private collection(name: string): CollectionReference {
    return this.db.collection(name);
  }
}
