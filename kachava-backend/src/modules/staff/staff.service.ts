import { Inject, Injectable } from '@nestjs/common';
import * as crypto from 'crypto';
import { paginateInMemory, PaginatedResult, toListQuery } from '../../common/listing/list-query';
import { definedFields } from '../../common/validation/patch';
import { EntityConflictError, EntityNotFoundError } from '../../domain/domain-errors';
import { StaffMember } from '../../domain/models/domain.models';
import { STAFF_ROSTER_REPOSITORY_PORT, StaffRosterRepositoryPort } from '../../domain/ports/repository.ports';
import { CreateStaffDto, StaffListQueryDto, UpdateStaffDto } from './staff.dto';

/** Wire shape: the staff member plus `id`. */
export type StaffView = StaffMember & { id: string };

const STAFF_LIST_SPEC = {
  sortable: ['fullName', 'department', 'rbacRole', 'email'],
  defaultSort: { field: 'fullName', direction: 'asc' as const },
};
type SortableField = 'fullName' | 'department' | 'rbacRole' | 'email';

function toView(staff: StaffMember): StaffView {
  return { id: staff.staffId, ...staff };
}

function firstName(fullName: string): string {
  return fullName.trim().split(/\s+/)[0] ?? '';
}

/**
 * Staff roster (Settings › Staff). Nothing is seeded: staff are created here and feed every owner
 * picker (tasks, Resort Host, service responsible). Emails are unique, stored lower-case.
 */
@Injectable()
export class StaffService {
  constructor(@Inject(STAFF_ROSTER_REPOSITORY_PORT) private readonly roster: StaffRosterRepositoryPort) {}

  async list(dto: StaffListQueryDto): Promise<PaginatedResult<StaffView>> {
    const query = toListQuery(dto, STAFF_LIST_SPEC);
    const staff = await this.roster.list({
      isActive: dto.isActive,
      rbacRole: dto.rbacRole,
      department: dto.department,
    });
    const page = paginateInMemory(staff, query, {
      searchText: (s) => `${s.fullName} ${s.email} ${s.phone} ${s.role}`,
      sortValue: (s, field) => s[field as SortableField],
    });
    return new PaginatedResult(page.data.map(toView), page.meta);
  }

  async get(staffId: string): Promise<StaffView> {
    return toView(await this.require(staffId));
  }

  async create(dto: CreateStaffDto): Promise<StaffView> {
    const email = dto.email.trim().toLowerCase();
    await this.assertEmailFree(email);
    const fullName = dto.fullName.trim();
    const created = await this.roster.create({
      staffId: `staff_${crypto.randomUUID()}`,
      firebaseUid: '',
      fullName,
      shortName: firstName(fullName),
      role: dto.role?.trim() ?? '',
      department: dto.department,
      rbacRole: dto.rbacRole,
      email,
      phone: dto.phone?.trim() ?? '',
      avatarUrl: '',
      isActive: true,
    });
    return toView(created);
  }

  async update(staffId: string, dto: UpdateStaffDto): Promise<StaffView> {
    await this.require(staffId);
    const patch = definedFields(dto) as Partial<StaffMember>;
    if (patch.email !== undefined) {
      patch.email = patch.email.trim().toLowerCase();
      await this.assertEmailFree(patch.email, staffId);
    }
    if (patch.fullName !== undefined) {
      patch.fullName = patch.fullName.trim();
      patch.shortName = firstName(patch.fullName);
    }
    for (const field of ['phone', 'role'] as const) {
      if (patch[field] !== undefined) patch[field] = patch[field]!.trim();
    }
    return toView(await this.roster.update(staffId, (current) => ({ ...current, ...patch })));
  }

  private async assertEmailFree(email: string, exceptStaffId?: string): Promise<void> {
    const holders = await this.roster.list({ email });
    if (holders.some((s) => s.staffId !== exceptStaffId)) {
      throw new EntityConflictError(`A staff member already uses ${email}.`);
    }
  }

  private async require(staffId: string): Promise<StaffMember> {
    const staff = await this.roster.findById(staffId);
    if (!staff) throw new EntityNotFoundError('Staff member', staffId);
    return staff;
  }
}
