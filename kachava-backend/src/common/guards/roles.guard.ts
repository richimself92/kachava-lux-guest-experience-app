import {
  CanActivate,
  ExecutionContext,
  ForbiddenException,
  Injectable,
} from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { RbacRole, StaffMember } from '../../domain/models/domain.models';
import { ROLES_KEY } from '../decorators/auth.decorators';

@Injectable()
export class RolesGuard implements CanActivate {
  constructor(private readonly reflector: Reflector) {}

  canActivate(context: ExecutionContext): boolean {
    const requiredRoles = this.reflector.getAllAndOverride<RbacRole[]>(
      ROLES_KEY,
      [context.getHandler(), context.getClass()],
    );

    if (!requiredRoles || requiredRoles.length === 0) {
      return true;
    }

    const req = context.switchToHttp().getRequest();
    const staff = req.staff as StaffMember | undefined;

    if (!staff || !requiredRoles.includes(staff.rbacRole)) {
      throw new ForbiddenException(
        `Insufficient RBAC role permissions. Required one of: ${requiredRoles.join(', ')}.`,
      );
    }

    return true;
  }
}
