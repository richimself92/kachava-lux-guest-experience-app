import { Inject, Injectable } from '@nestjs/common';
import { paginateInMemory, PaginatedResult, toListQuery } from '../../common/listing/list-query';
import { GuestCatalogService as GuestCatalogServiceView, toGuestCatalogService } from '../../domain/catalog/catalog-rules';
import { CatalogItem } from '../../domain/catalog/catalog.models';
import {
  CATALOG_IMAGE_STORAGE_PORT,
  CatalogImageStoragePort,
  SERVICE_ITEM_REPOSITORY_PORT,
  SERVICE_REPOSITORY_PORT,
  ServiceItemRepositoryPort,
  ServiceRepositoryPort,
} from '../../domain/ports/repository.ports';
import { displayName, SERVICE_LIST_SPEC } from './catalog-admin.service';
import { GuestCatalogQueryDto } from './dto/service.dto';

/** Guest catalog: ACTIVE services with their ACTIVE items, guest-safe projection only. */
@Injectable()
export class GuestCatalogService {
  constructor(
    @Inject(SERVICE_REPOSITORY_PORT) private readonly services: ServiceRepositoryPort,
    @Inject(SERVICE_ITEM_REPOSITORY_PORT) private readonly items: ServiceItemRepositoryPort,
    @Inject(CATALOG_IMAGE_STORAGE_PORT) private readonly images: CatalogImageStoragePort,
  ) {}

  async list(dto: GuestCatalogQueryDto): Promise<PaginatedResult<GuestCatalogServiceView>> {
    const query = toListQuery(dto, SERVICE_LIST_SPEC);
    const services = await this.services.list({ status: 'ACTIVE', section: dto.section });
    const page = paginateInMemory(services, query, {
      searchText: (s) => `${s.name.en} ${s.name.es} ${s.category ?? ''} ${s.tags.join(' ')}`,
      sortValue: (s, field) => (field === 'name' ? displayName(s) : s.order),
    });
    const itemsByService = groupByService(page.data.length > 0 ? await this.items.list({ status: 'ACTIVE' }) : []);
    const urlOf = (path: string) => this.images.publicUrl(path);
    return new PaginatedResult(
      page.data.map((s) => toGuestCatalogService(s, itemsByService.get(s.serviceId) ?? [], urlOf)),
      page.meta,
    );
  }
}

function groupByService(items: CatalogItem[]): Map<string, CatalogItem[]> {
  const grouped = new Map<string, CatalogItem[]>();
  for (const item of items) grouped.set(item.serviceId, [...(grouped.get(item.serviceId) ?? []), item]);
  return grouped;
}
