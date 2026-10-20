import { Injectable } from '@nestjs/common';
import { StaffMember } from '../../domain/models/domain.models';
import { StaffRepositoryPort } from '../../domain/ports/repository.ports';
import { SEEDED_STAFF_MEMBERS } from '../seed/sanctuary-catalog.seed';

@Injectable()
export class InMemorySeededStaffRepository implements StaffRepositoryPort {
  private readonly staff: StaffMember[] = structuredClone(SEEDED_STAFF_MEMBERS);

  async listStaff(department?: string): Promise<StaffMember[]> {
    const active = this.staff.filter((s) => s.isActive);
    if (!department) return structuredClone(active);
    const normalized = department.trim().toUpperCase();
    return structuredClone(active.filter((s) => s.department === normalized));
  }

  async findByStaffId(staffId: string): Promise<StaffMember | null> {
    const found = this.staff.find((s) => s.staffId === staffId && s.isActive);
    return found ? structuredClone(found) : null;
  }

  async findByEmail(email: string): Promise<StaffMember | null> {
    const normalized = email.trim().toLowerCase();
    const found = this.staff.find(
      (s) => s.email.toLowerCase() === normalized && s.isActive,
    );
    return found ? structuredClone(found) : null;
  }

  async findByFirebaseUid(firebaseUid: string): Promise<StaffMember | null> {
    const found = this.staff.find(
      (s) => s.firebaseUid === firebaseUid && s.isActive,
    );
    return found ? structuredClone(found) : null;
  }
}
