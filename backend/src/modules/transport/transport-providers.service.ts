import { Inject, Injectable } from '@nestjs/common';
import * as crypto from 'crypto';
import { paginateInMemory, PaginatedResult, toListQuery } from '../../common/listing/list-query';
import { creationAudit, definedFields, updateAudit } from '../../common/validation/patch';
import { EntityNotFoundError } from '../../domain/domain-errors';
import { TransportProvider } from '../../domain/models/resort-config.models';
import {
  TRANSPORT_PROVIDER_REPOSITORY_PORT,
  TransportProviderRepositoryPort,
} from '../../domain/ports/repository.ports';
import {
  CreateTransportProviderDto,
  TransportProviderListQueryDto,
  UpdateTransportProviderDto,
} from './transport-provider.dto';

export type TransportProviderView = TransportProvider & { id: string };

function toView(provider: TransportProvider): TransportProviderView {
  return { id: provider.providerId, ...provider };
}

const PROVIDER_LIST_SPEC = {
  sortable: ['name'],
  defaultSort: { field: 'name', direction: 'asc' as const },
};

@Injectable()
export class TransportProvidersService {
  constructor(
    @Inject(TRANSPORT_PROVIDER_REPOSITORY_PORT)
    private readonly providers: TransportProviderRepositoryPort,
  ) {}

  async list(dto: TransportProviderListQueryDto): Promise<PaginatedResult<TransportProviderView>> {
    const query = toListQuery(dto, PROVIDER_LIST_SPEC);
    const providers = await this.providers.list({ isActive: dto.isActive });
    const page = paginateInMemory(providers, query, {
      searchText: (p) => `${p.name} ${p.email} ${p.phone}`,
      sortValue: (p) => p.name,
    });
    return new PaginatedResult(page.data.map(toView), page.meta);
  }

  async get(providerId: string): Promise<TransportProviderView> {
    const provider = await this.providers.findById(providerId);
    if (!provider) throw new EntityNotFoundError('Transport provider', providerId);
    return toView(provider);
  }

  async create(dto: CreateTransportProviderDto, actor: string): Promise<TransportProviderView> {
    const created = await this.providers.create({
      providerId: crypto.randomUUID(),
      name: dto.name.trim(),
      phone: dto.phone?.trim() ?? '',
      email: dto.email?.trim().toLowerCase() ?? '',
      isActive: dto.isActive ?? true,
      ...creationAudit(actor),
    });
    return toView(created);
  }

  async update(providerId: string, dto: UpdateTransportProviderDto, actor: string): Promise<TransportProviderView> {
    const patch = definedFields(dto);
    const updated = await this.providers.update(providerId, (current) => ({ ...current, ...patch, ...updateAudit(actor) }));
    return toView(updated);
  }
}
