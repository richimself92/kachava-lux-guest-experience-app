import { Injectable } from '@nestjs/common';
import {
  ExperienceCatalogItem,
  LarderCatalogItem,
  YachtCatalog,
} from '../../domain/models/domain.models';
import { CatalogRepositoryPort } from '../../domain/ports/repository.ports';
import { getNamedFirestoreDb } from '../firebase/firebase-admin.module';
import {
  SEEDED_EXPERIENCES_CATALOG,
  SEEDED_LARDER_CATALOG,
  SEEDED_YACHT_CATALOG,
} from '../seed/sanctuary-catalog.seed';

@Injectable()
export class InMemorySeededCatalogRepository implements CatalogRepositoryPort {
  private larderItems: LarderCatalogItem[] = structuredClone(SEEDED_LARDER_CATALOG);
  private experienceItems: ExperienceCatalogItem[] = structuredClone(
    SEEDED_EXPERIENCES_CATALOG,
  );
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
          const [larderSnap, expSnap] = await Promise.all([
            db.collection('catalog_larder').get(),
            db.collection('catalog_experiences').get(),
          ]);

          if (!larderSnap.empty) {
            this.larderItems = larderSnap.docs.map((d) => d.data() as LarderCatalogItem);
          } else {
            await Promise.all(
              this.larderItems.map((item) =>
                db.collection('catalog_larder').doc(item.id).set(item, { merge: true }),
              ),
            );
          }

          if (!expSnap.empty) {
            this.experienceItems = expSnap.docs.map((d) => d.data() as ExperienceCatalogItem);
          } else {
            await Promise.all(
              this.experienceItems.map((item) =>
                db.collection('catalog_experiences').doc(item.id).set(item, { merge: true }),
              ),
            );
          }
        } catch {
          // Keep seeded catalog items if Firestore hydration fails
        } finally {
          this.hydrated = true;
        }
      })();
    }
    await this.hydrationPromise;
  }

  async getLarderCatalog(): Promise<LarderCatalogItem[]> {
    await this.ensureHydrated();
    return structuredClone(this.larderItems);
  }

  async createLarderCatalogItem(item: Partial<LarderCatalogItem>): Promise<LarderCatalogItem> {
    await this.ensureHydrated();
    const price = Number(item.price ?? 0);
    const created: LarderCatalogItem = {
      id: item.id?.trim() || `larder_${Date.now()}`,
      name: item.name || 'Artisanal Provision',
      origin: item.origin || 'Kachava Culinary Lab',
      description: item.description || '',
      price,
      category: item.category?.trim() || 'Minibar',
      quantity: item.quantity ?? 0,
      image: item.image || 'https://images.unsplash.com/photo-1540420773420-3366772f4999?auto=format&fit=crop&w=800&q=80',
      tag: item.tag || 'CURATED SELECTION',
      ...(item.dietary ? { dietary: item.dietary } : {}),
      storageType: item.storageType || 'CHILLED IN LARDER',
      isActive: item.isActive ?? true,
    };
    this.larderItems = [...this.larderItems.filter((existing) => existing.id !== created.id), created];
    const db = getNamedFirestoreDb();
    if (db) {
      void db
        .collection('catalog_larder')
        .doc(created.id)
        .set(created, { merge: true })
        .catch(() => undefined);
    }
    return structuredClone(created);
  }

  async deleteLarderCatalogItem(id: string): Promise<{ deleted: boolean; id: string }> {
    await this.ensureHydrated();
    const before = this.larderItems.length;
    this.larderItems = this.larderItems.filter((item) => item.id !== id);
    const deleted = this.larderItems.length < before;
    const db = getNamedFirestoreDb();
    if (db && deleted) {
      void db
        .collection('catalog_larder')
        .doc(id)
        .delete()
        .catch(() => undefined);
    }
    return { deleted, id };
  }

  async getExperiencesCatalog(): Promise<ExperienceCatalogItem[]> {
    await this.ensureHydrated();
    return structuredClone(this.experienceItems);
  }

  async createExperienceCatalogItem(item: Partial<ExperienceCatalogItem>): Promise<ExperienceCatalogItem> {
    await this.ensureHydrated();
    const basePriceUSD = Number(item.basePriceUSD ?? 0);
    const isIncluded = item.isIncluded ?? basePriceUSD === 0;
    const created: ExperienceCatalogItem = {
      id: item.id?.trim() || `exp_${Date.now()}`,
      title: item.title || 'Sanctuary Experience',
      subtitle: item.subtitle || item.location || 'Kachava Sanctuary',
      duration: item.duration || '2 Hours',
      location: item.location || 'Kachava Sanctuary',
      vehicleOrDetail: item.vehicleOrDetail || 'Private Curation',
      priceText: item.priceText || (isIncluded ? 'Complimentary' : `$${basePriceUSD} USD`),
      basePriceUSD,
      isIncluded,
      ...(item.inclusionLabel ? { inclusionLabel: item.inclusionLabel } : {}),
      image: item.image || 'https://images.unsplash.com/photo-1544551763-46a013bb70d5?auto=format&fit=crop&w=1200&q=80',
      category: item.category || 'Wellness & Spa',
      description: item.description || '',
      amenities: item.amenities || ['Private Host Curation'],
      actionLabel: item.actionLabel || 'Reserve Experience',
      ...(item.actionScreen ? { actionScreen: item.actionScreen } : {}),
    };
    this.experienceItems = [...this.experienceItems.filter((existing) => existing.id !== created.id), created];
    const db = getNamedFirestoreDb();
    if (db) {
      void db
        .collection('catalog_experiences')
        .doc(created.id)
        .set(created, { merge: true })
        .catch(() => undefined);
    }
    return structuredClone(created);
  }

  async deleteExperienceCatalogItem(
    id: string,
  ): Promise<{ deleted: boolean; id: string }> {
    await this.ensureHydrated();
    const before = this.experienceItems.length;
    this.experienceItems = this.experienceItems.filter((item) => item.id !== id);
    const deleted = this.experienceItems.length < before;
    const db = getNamedFirestoreDb();
    if (db && deleted) {
      void db
        .collection('catalog_experiences')
        .doc(id)
        .delete()
        .catch(() => undefined);
    }
    return { deleted, id };
  }

  async getYachtCatalog(): Promise<YachtCatalog> {
    return structuredClone(SEEDED_YACHT_CATALOG);
  }
}
