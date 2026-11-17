import {
  CanActivate,
  ExecutionContext,
  Inject,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import {
  ADMIN_SERVICE_STAFF_ID,
  buildAdminServiceStaff,
  resolveAdminServiceEmail,
} from '../config/admin-identity';
import { StaffMember } from '../../domain/models/domain.models';
import {
  STAFF_REPOSITORY_PORT,
  StaffRepositoryPort,
} from '../../domain/ports/repository.ports';
import { FirebaseIdTokenVerifier } from '../services/firebase-id-token.verifier';
import { SecurityTokenService } from '../services/security-token.service';

/**
 * Authenticates `/api/v1/admin/*` callers. Accepts a staff token issued by
 * `POST /admin/auth/login` (the env-configured admin identity, or a rostered staff member)
 * or a Firebase ID token of a rostered staff member.
 * Anything else (missing, unknown, forged, rejected) is a 401: there is no default identity.
 */
@Injectable()
export class AdminAuthGuard implements CanActivate {
  constructor(
    @Inject(STAFF_REPOSITORY_PORT)
    private readonly staffRepository: StaffRepositoryPort,
    private readonly securityTokenService: SecurityTokenService,
    private readonly firebaseIdTokenVerifier: FirebaseIdTokenVerifier,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const req = context.switchToHttp().getRequest();
    const token = this.extractBearerToken(req);
    if (!token || this.securityTokenService.isValidUuidV4(token)) {
      throw new UnauthorizedException(
        'Valid staff authentication Bearer token is required for /api/v1/admin/* endpoints.',
      );
    }

    const staff = await this.resolveStaffIdentity(token);
    if (!staff || !staff.isActive) {
      throw new UnauthorizedException('Invalid or expired staff authentication token.');
    }

    req.staff = staff;
    return true;
  }

  private extractBearerToken(req: {
    headers?: Record<string, string | undefined>;
  }): string | undefined {
    const authHeader = req.headers?.authorization || req.headers?.Authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return undefined;
    }
    return authHeader.slice(7).trim() || undefined;
  }

  private async resolveStaffIdentity(token: string): Promise<StaffMember | null> {
    const staffToken = this.securityTokenService.verifyStaffToken(token);
    if (staffToken?.staffId === ADMIN_SERVICE_STAFF_ID) {
      const configured = resolveAdminServiceEmail();
      return configured && staffToken.email === configured ? buildAdminServiceStaff(configured) : null;
    }
    if (staffToken) {
      return this.staffRepository.findByStaffId(staffToken.staffId);
    }
    const identity = await this.firebaseIdTokenVerifier.verify(token);
    if (!identity) return null;
    const byUid = await this.staffRepository.findByFirebaseUid(identity.uid);
    if (byUid || !identity.email) return byUid;
    return this.staffRepository.findByEmail(identity.email);
  }
}
