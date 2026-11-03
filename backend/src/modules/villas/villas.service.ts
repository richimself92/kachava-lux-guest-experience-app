import { Inject, Injectable } from '@nestjs/common';
import * as crypto from 'crypto';
import { paginateInMemory, PaginatedResult, toListQuery } from '../../common/listing/list-query';
import { creationAudit, definedFields, updateAudit } from '../../common/validation/patch';
import { EntityConflictError, EntityNotFoundError } from '../../domain/domain-errors';
import { Villa } from '../../domain/models/resort-config.models';
import {
  STAY_REPOSITORY_PORT,
  StayRepositoryPort,
  VILLA_REPOSITORY_PORT,
  VillaRepositoryPort,
} from '../../domain/ports/repository.ports';
import { SYNC_STAY_LIMIT } from '../admin/admin-sync.service';
import { CreateVillaDto, UpdateVillaDto, VillaListQueryDto } from './villa.dto';

/** Wire shape: the villa plus `id` and the read-only name of the in-house guest (or null). */
export type VillaView = Villa & { id: string; currentGuestName: string | null };

const VILLA_LIST_SPEC = {
  sortable: ['name', 'category', 'capacity', 'operationalStatus'],
  defaultSort: { field: 'name', direction: 'asc' as const },
};

@Injectable()
export class VillasService {
  constructor(
    @Inject(VILLA_REPOSITORY_PORT) private readonly villas: VillaRepositoryPort,
    @Inject(STAY_REPOSITORY_PORT) private readonly stays: StayRepositoryPort,
  ) {}

  async list(dto: VillaListQueryDto): Promise<PaginatedResult<VillaView>> {
    const query = toListQuery(dto, VILLA_LIST_SPEC);
    const villas = await this.villas.list({
      isActive: dto.isActive,
      operationalStatus: dto.operationalStatus,
      category: dto.category,
    });
    const page = paginateInMemory(villas, query, {
      searchText: (v) => `${v.name} ${v.category}`,
      sortValue: (v, field) => v[field as keyof Villa] as string | number,
    });
    const guests = await this.inHouseGuests();
    return new PaginatedResult(page.data.map((v) => toView(v, guests)), page.meta);
  }

  async get(villaId: string): Promise<VillaView> {
    return toView(await this.require(villaId), await this.inHouseGuests());
  }

  async create(dto: CreateVillaDto, actor: string): Promise<VillaView> {
    const created = await this.villas.create({
      villaId: crypto.randomUUID(),
      name: dto.name.trim(),
      category: dto.category.trim(),
      capacity: dto.capacity,
      wifi: { ssid: dto.wifi?.ssid ?? '', password: dto.wifi?.password ?? '' },
      operationalStatus: dto.operationalStatus,
      housekeepingStatus: dto.housekeepingStatus,
      maintenanceStatus: dto.maintenanceStatus,
      maintenanceNote: dto.maintenanceNote?.trim() ?? '',
      isActive: dto.isActive ?? true,
      ...creationAudit(actor),
    });
    return toView(created, new Map());
  }

  async update(villaId: string, dto: UpdateVillaDto, actor: string): Promise<VillaView> {
    const patch = definedFields(dto);
    const updated = await this.villas.update(villaId, (current) => ({
      ...current,
      ...patch,
      wifi: patch.wifi ? { ...patch.wifi } : current.wifi,
      ...updateAudit(actor),
    }));
    return toView(updated, await this.inHouseGuests());
  }

  /** Villas referenced by stays keep their history: they can only be deactivated. */
  async remove(villaId: string): Promise<{ deleted: true; id: string }> {
    await this.require(villaId);
    if (await this.stays.hasStaysForVilla(villaId)) {
      throw new EntityConflictError('Villa has stays; deactivate it instead of deleting it.');
    }
    await this.villas.delete(villaId);
    return { deleted: true, id: villaId };
  }

  private async require(villaId: string): Promise<Villa> {
    const villa = await this.villas.findById(villaId);
    if (!villa) throw new EntityNotFoundError('Villa', villaId);
    return villa;
  }

  /** villaId -> guest name of its in-house (ACTIVE_STAY) stay, from one bounded query. */
  private async inHouseGuests(): Promise<Map<string, string>> {
    const open = await this.stays.listOpenStays(SYNC_STAY_LIMIT);
    return new Map(open.filter((s) => s.status === 'ACTIVE_STAY').map((s) => [s.villaId, s.guestProfile.name]));
  }
}

function toView(villa: Villa, guests: Map<string, string>): VillaView {
  return { id: villa.villaId, ...villa, currentGuestName: guests.get(villa.villaId) ?? null };
}
