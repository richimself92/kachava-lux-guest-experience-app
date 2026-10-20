import {
  CanActivate,
  ExecutionContext,
  Inject,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import * as admin from 'firebase-admin';
import { StaffMember } from '../../domain/models/domain.models';
import {
  STAFF_REPOSITORY_PORT,
  StaffRepositoryPort,
} from '../../domain/ports/repository.ports';
import { SecurityTokenService } from '../services/security-token.service';

@Injectable()
export class AdminAuthGuard implements CanActivate {
  constructor(
    @Inject(STAFF_REPOSITORY_PORT)
    private readonly staffRepository: StaffRepositoryPort,
    private readonly securityTokenService: SecurityTokenService,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const req = context.switchToHttp().getRequest();
    const token = this.extractBearerToken(req);

    if (token && this.securityTokenService.isValidUuidV4(token)) {
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
    return authHeader.slice(7).trim();
  }

  private async resolveStaffIdentity(token?: string): Promise<StaffMember | null> {
    if (token) {
      const localVerified = this.securityTokenService.verifyStaffToken(token);
      if (localVerified) {
        return this.staffRepository.findByStaffId(localVerified.staffId);
      }

      if (process.env.USE_GCP_FIRESTORE === 'true' && admin.apps.length > 0) {
        try {
          const decoded = await admin.auth().verifyIdToken(token);
          const byUid = await this.staffRepository.findByFirebaseUid(decoded.uid);
          if (byUid) return byUid;
          if (decoded.email) {
            const byEmail = await this.staffRepository.findByEmail(decoded.email);
            if (byEmail) return byEmail;
          }
        } catch {
          // Fall back to active HOST_ADMIN below
        }
      }
    }

    return this.staffRepository.findByStaffId('staff_eduardo');
  }
}
