import { Inject, Injectable } from '@nestjs/common';
import * as crypto from 'crypto';
import { paginateInMemory, PaginatedResult, toListQuery } from '../../common/listing/list-query';
import { creationAudit, updateAudit } from '../../common/validation/patch';
import {
  assembleNewItem,
  assembleNewService,
  assembleUpdatedItem,
  assembleUpdatedService,
  DeepPartial,
} from '../../domain/catalog/catalog-assembly';
import {
  assertCatalogImages,
  assertItemCanBeActive,
  assertKindDetailsMatch,
  assertServiceCanBeActive,
  assertServiceConsistent,
  ResolvedImage,
  withImageUrl,
} from '../../domain/catalog/catalog-rules';
import {
  CatalogImage,
  CatalogItem,
  CatalogService,
  KindDetailField,
} from '../../domain/catalog/catalog.models';
import { BusinessRuleError, EntityNotFoundError } from '../../domain/domain-errors';
import {
  CATALOG_IMAGE_STORAGE_PORT,
  CatalogImageStoragePort,
  SERVICE_ITEM_REPOSITORY_PORT,
  SERVICE_REPOSITORY_PORT,
  ServiceItemRepositoryPort,
  ServiceRepositoryPort,
  SETTINGS_REPOSITORY_PORT,
  SettingsRepositoryPort,
  TRANSPORT_PROVIDER_REPOSITORY_PORT,
  TransportProviderRepositoryPort,
} from '../../domain/ports/repository.ports';
import { CreateItemDto, ItemListQueryDto, UpdateItemDto } from './dto/item.dto';
import { CreateServiceDto, ServiceListQueryDto, UpdateServiceDto } from './dto/service.dto';

/** Wire shape: the entity plus `id` and resolved image URLs. */
export type AdminServiceView = Omit<CatalogService, 'cover' | 'gallery'> & {
  id: string;
  cover: ResolvedImage | null;
  gallery: ResolvedImage[];
};
export type AdminItemView = Omit<CatalogItem, 'image'> & { id: string; image: ResolvedImage | null };

const KIND_FIELDS: KindDetailField[] = ['bar', 'dining', 'stocking', 'experience', 'wellness', 'preference', 'transport'];
export const SERVICE_LIST_SPEC = {
  sortable: ['order', 'name'],
  defaultSort: { field: 'order', direction: 'asc' as const },
};
const ITEM_LIST_SPEC = {
  sortable: ['order', 'name', 'priceUSD'],
  defaultSort: { field: 'order', direction: 'asc' as const },
};

export function displayName(entity: { name: { en: string; es: string } }): string {
  return entity.name.en || entity.name.es;
}

/** Admin catalog: services and their items, validated against the ADR-009 rules. */
@Injectable()
export class CatalogAdminService {
  constructor(
    @Inject(SERVICE_REPOSITORY_PORT) private readonly services: ServiceRepositoryPort,
    @Inject(SERVICE_ITEM_REPOSITORY_PORT) private readonly items: ServiceItemRepositoryPort,
    @Inject(TRANSPORT_PROVIDER_REPOSITORY_PORT) private readonly providers: TransportProviderRepositoryPort,
    @Inject(SETTINGS_REPOSITORY_PORT) private readonly settings: SettingsRepositoryPort,
    @Inject(CATALOG_IMAGE_STORAGE_PORT) private readonly images: CatalogImageStoragePort,
  ) {}

  async listServices(dto: ServiceListQueryDto): Promise<PaginatedResult<AdminServiceView>> {
    const query = toListQuery(dto, SERVICE_LIST_SPEC);
    const services = await this.services.list({
      section: dto.section, status: dto.status, usageType: dto.usageType, kind: dto.kind, featured: dto.featured,
    });
    const page = paginateInMemory(services, query, {
      searchText: (s) => `${s.name.en} ${s.name.es} ${s.category ?? ''} ${s.tags.join(' ')}`,
      sortValue: (s, field) => (field === 'name' ? displayName(s) : s.order),
    });
    return new PaginatedResult(page.data.map((s) => this.serviceView(s)), page.meta);
  }

  async getService(serviceId: string): Promise<AdminServiceView> {
    return this.serviceView(await this.requireService(serviceId));
  }

  async createService(dto: CreateServiceDto, actor: string): Promise<AdminServiceView> {
    assertKindDetailsMatch(dto.kind, kindBlocksOf(dto));
    await this.assertReferencesExist(dto);
    const service = assembleNewService(dto as DeepPartial<CatalogService> & CreateServiceDto, crypto.randomUUID(), creationAudit(actor));
    this.assertValidService(service);
    return this.serviceView(await this.services.create(service));
  }

  async updateService(serviceId: string, dto: UpdateServiceDto, actor: string): Promise<AdminServiceView> {
    await this.assertReferencesExist(dto);
    const updated = await this.services.update(serviceId, (current) => {
      if (dto.kind && dto.kind !== current.kind) throw new BusinessRuleError('The kind of a service cannot be changed');
      assertKindDetailsMatch(current.kind, kindBlocksOf(dto));
      const next = assembleUpdatedService(current, dto as DeepPartial<CatalogService>, updateAudit(actor));
      this.assertValidService(next);
      return next;
    });
    return this.serviceView(updated);
  }

  async listItems(serviceId: string, dto: ItemListQueryDto): Promise<PaginatedResult<AdminItemView>> {
    await this.requireService(serviceId);
    const query = toListQuery(dto, ITEM_LIST_SPEC);
    const items = await this.items.list({ serviceId, status: dto.status, category: dto.category });
    const page = paginateInMemory(items, query, {
      searchText: (i) => `${i.name.en} ${i.name.es} ${i.category ?? ''} ${i.tags.join(' ')}`,
      sortValue: (i, field) => (field === 'name' ? displayName(i) : field === 'priceUSD' ? i.priceUSD : i.order),
    });
    return new PaginatedResult(page.data.map((i) => this.itemView(i)), page.meta);
  }

  async createItem(serviceId: string, dto: CreateItemDto, actor: string): Promise<AdminItemView> {
    await this.requireService(serviceId);
    const item = assembleNewItem(dto as DeepPartial<CatalogItem>, serviceId, crypto.randomUUID(), creationAudit(actor));
    assertValidItem(item);
    return this.itemView(await this.items.create(item));
  }

  async updateItem(serviceId: string, itemId: string, dto: UpdateItemDto, actor: string): Promise<AdminItemView> {
    await this.requireItem(serviceId, itemId);
    const updated = await this.items.update(itemId, (current) => {
      const next = assembleUpdatedItem(current, dto as DeepPartial<CatalogItem>, updateAudit(actor));
      assertValidItem(next);
      return next;
    });
    return this.itemView(updated);
  }

  async requireService(serviceId: string): Promise<CatalogService> {
    const service = await this.services.findById(serviceId);
    if (!service) throw new EntityNotFoundError('Service', serviceId);
    return service;
  }

  async requireItem(serviceId: string, itemId: string): Promise<CatalogItem> {
    await this.requireService(serviceId);
    const item = await this.items.findById(itemId);
    if (!item || item.serviceId !== serviceId) throw new EntityNotFoundError('Item', itemId);
    return item;
  }

  private assertValidService(service: CatalogService): void {
    assertServiceConsistent(service);
    assertCatalogImages([...(service.cover ? [service.cover] : []), ...service.gallery]);
    assertServiceCanBeActive(service);
  }

  /** Provider and airports referenced by the request must already exist. */
  private async assertReferencesExist(dto: UpdateServiceDto | CreateServiceDto): Promise<void> {
    const providerId = dto.operation?.providerId;
    if (providerId && !(await this.providers.findById(providerId))) {
      throw new BusinessRuleError(`Transport provider ${providerId} does not exist`);
    }
    const codes = dto.transport?.airportCodes ?? [];
    if (codes.length === 0) return;
    const configured = new Set((await this.settings.get()).airports.map((a) => a.code));
    const unknown = codes.filter((code) => !configured.has(code));
    if (unknown.length > 0) {
      throw new BusinessRuleError('Airports must be configured in Settings first', unknown.map((c) => `${c} is unknown`));
    }
  }

  serviceView(service: CatalogService): AdminServiceView {
    const urlOf = (path: string) => this.images.publicUrl(path);
    return {
      id: service.serviceId,
      ...service,
      cover: withImageUrl(service.cover, urlOf),
      gallery: service.gallery.map((image: CatalogImage) => withImageUrl(image, urlOf) as ResolvedImage),
    };
  }

  private itemView(item: CatalogItem): AdminItemView {
    return { id: item.itemId, ...item, image: withImageUrl(item.image, (path) => this.images.publicUrl(path)) };
  }
}

function kindBlocksOf(dto: Partial<Record<KindDetailField, unknown>>): Partial<Record<KindDetailField, unknown>> {
  return Object.fromEntries(KIND_FIELDS.map((field) => [field, dto[field]]));
}

function assertValidItem(item: CatalogItem): void {
  if (!displayName(item)) throw new BusinessRuleError('Invalid item', ['name needs English or Spanish text']);
  if (item.image) assertCatalogImages([item.image]);
  assertItemCanBeActive(item);
}
