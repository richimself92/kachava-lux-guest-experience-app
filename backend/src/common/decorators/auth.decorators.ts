import {
  createParamDecorator,
  ExecutionContext,
  SetMetadata,
} from '@nestjs/common';
import {
  RbacRole,
  StaffMember,
  StayAggregate,
} from '../../domain/models/domain.models';

export const ROLES_KEY = 'rbac_roles';
export const Roles = (...roles: RbacRole[]) => SetMetadata(ROLES_KEY, roles);

export const CurrentStay = createParamDecorator(
  (_data: unknown, ctx: ExecutionContext): StayAggregate => {
    const request = ctx.switchToHttp().getRequest();
    return request.stay as StayAggregate;
  },
);

export const CurrentStaff = createParamDecorator(
  (_data: unknown, ctx: ExecutionContext): StaffMember => {
    const request = ctx.switchToHttp().getRequest();
    return request.staff as StaffMember;
  },
);

/** Every staff role may read admin configuration; writes are HOST_ADMIN only. */
export const ANY_STAFF_ROLE: RbacRole[] = ['HOST_ADMIN', 'CONCIERGE_STAFF', 'DEPARTMENT_COORDINATOR'];

/** Audit actor recorded on writes (`createdBy` / `updatedBy`). */
export function auditActorOf(staff: StaffMember): string {
  return staff.email || staff.staffId;
}
