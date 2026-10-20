import { Injectable } from '@nestjs/common';
import * as crypto from 'crypto';
import {
  Department,
  RbacRole,
  StaffMember,
} from '../../domain/models/domain.models';

const UUID_V4_REGEX =
  /^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;

export interface VerifiedStaffPayload {
  staffId: string;
  email: string;
  rbacRole: RbacRole;
  department: Department;
  exp: number;
}

@Injectable()
export class SecurityTokenService {
  private readonly stepUpSecret =
    process.env.STEPUP_HMAC_SECRET || 'kachava-stepup-hmac-secret-2026';
  private readonly staffJwtSecret =
    process.env.STAFF_JWT_SECRET || 'kachava-staff-jwt-secret-2026';

  isValidUuidV4(candidate: string | undefined | null): boolean {
    if (!candidate || typeof candidate !== 'string') return false;
    return UUID_V4_REGEX.test(candidate.trim());
  }

  issueStepUpToken(stayId: string, guestTokenUuid: string): string {
    const payload = {
      type: 'STEP_UP',
      stayId,
      guestTokenUuid,
      exp: Date.now() + 24 * 60 * 60 * 1000,
    };
    return this.signPayload(payload, this.stepUpSecret);
  }

  verifyStepUpToken(token: string | undefined, expectedStayId: string): boolean {
    if (!token) return false;
    const decoded = this.verifyPayload<{
      type: string;
      stayId: string;
      exp: number;
    }>(token, this.stepUpSecret);
    if (!decoded) return false;
    return (
      decoded.type === 'STEP_UP' &&
      decoded.stayId === expectedStayId &&
      decoded.exp > Date.now()
    );
  }

  issueStaffToken(staff: StaffMember): string {
    const payload: VerifiedStaffPayload = {
      staffId: staff.staffId,
      email: staff.email,
      rbacRole: staff.rbacRole,
      department: staff.department,
      exp: Date.now() + 12 * 60 * 60 * 1000,
    };
    return this.signPayload(payload, this.staffJwtSecret);
  }

  verifyStaffToken(token: string | undefined): VerifiedStaffPayload | null {
    if (!token || this.isValidUuidV4(token)) return null;
    const decoded = this.verifyPayload<VerifiedStaffPayload>(
      token,
      this.staffJwtSecret,
    );
    if (!decoded || decoded.exp <= Date.now() || !decoded.staffId) {
      return null;
    }
    return decoded;
  }

  private signPayload(payload: object, secret: string): string {
    const encoded = Buffer.from(JSON.stringify(payload)).toString('base64url');
    const sig = crypto
      .createHmac('sha256', secret)
      .update(encoded)
      .digest('base64url');
    return `${encoded}.${sig}`;
  }

  private verifyPayload<T>(token: string, secret: string): T | null {
    const parts = token.split('.');
    if (parts.length !== 2) return null;
    const [encoded, signature] = parts;
    const expectedSig = crypto
      .createHmac('sha256', secret)
      .update(encoded)
      .digest('base64url');
    if (signature !== expectedSig) return null;
    try {
      return JSON.parse(Buffer.from(encoded, 'base64url').toString('utf8')) as T;
    } catch {
      return null;
    }
  }
}
