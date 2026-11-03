import { Injectable } from '@nestjs/common';
import { buildExperienceCatalogItem, buildLarderCatalogItem } from '../../domain/catalog-items';
import {
  ExperienceCatalogItem,
  LarderCatalogItem,
  YachtCatalog,
} from '../../domain/models/domain.models';
import { CatalogRepositoryPort } from '../../domain/ports/repository.ports';
import {
  SEEDED_EXPERIENCES_CATALOG,
  SEEDED_LARDER_CATALOG,
  SEEDED_YACHT_CATALOG,
} from '../seed/sanctuary-catalog.seed';

/** Process-local catalogs for local development and tests. Never used in Firestore mode. */
@Injectable()
export class InMemorySeededCatalogRepository implements CatalogRepositoryPort {
  private larderItems: LarderCatalogItem[] = structuredClone(SEEDED_LARDER_CATALOG);
  private experienceItems: ExperienceCatalogItem[] = structuredClone(SEEDED_EXPERIENCES_CATALOG);

  async getLarderCatalog(): Promise<LarderCatalogItem[]> {
    return structuredClone(this.larderItems);
  }

  async createLarderCatalogItem(item: Partial<LarderCatalogItem>): Promise<LarderCatalogItem> {
    const created = buildLarderCatalogItem(item);
    this.larderItems = [...this.larderItems.filter((existing) => existing.id !== created.id), created];
    return structuredClone(created);
  }

  async deleteLarderCatalogItem(id: string): Promise<{ deleted: boolean; id: string }> {
    const before = this.larderItems.length;
    this.larderItems = this.larderItems.filter((item) => item.id !== id);
    return { deleted: this.larderItems.length < before, id };
  }

  async getExperiencesCatalog(): Promise<ExperienceCatalogItem[]> {
    return structuredClone(this.experienceItems);
  }

  async createExperienceCatalogItem(
    item: Partial<ExperienceCatalogItem>,
  ): Promise<ExperienceCatalogItem> {
    const created = buildExperienceCatalogItem(item);
    this.experienceItems = [
      ...this.experienceItems.filter((existing) => existing.id !== created.id),
      created,
    ];
    return structuredClone(created);
  }

  async deleteExperienceCatalogItem(id: string): Promise<{ deleted: boolean; id: string }> {
    const before = this.experienceItems.length;
    this.experienceItems = this.experienceItems.filter((item) => item.id !== id);
    return { deleted: this.experienceItems.length < before, id };
  }

  async getYachtCatalog(): Promise<YachtCatalog> {
    return structuredClone(SEEDED_YACHT_CATALOG);
  }
}
