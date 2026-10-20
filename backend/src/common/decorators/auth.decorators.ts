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
