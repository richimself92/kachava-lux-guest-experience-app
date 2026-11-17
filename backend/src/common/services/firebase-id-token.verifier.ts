import { Injectable } from '@nestjs/common';
import * as admin from 'firebase-admin';
import { isFirestoreFlagEnabled } from '../config/runtime-flags';

export interface VerifiedFirebaseIdentity {
  uid: string;
  email?: string;
}

function isFirebaseAuthRejection(error: unknown): boolean {
  const code = (error as { code?: unknown } | null)?.code;
  return typeof code === 'string' && code.startsWith('auth/');
}

/**
 * Verifies Firebase Authentication ID tokens for staff sign-in. The email is returned only when
 * Firebase marks it verified, because the admin guard may match staff members by email.
 * A token Firebase rejects (expired, revoked, malformed) yields `null`;
 * infrastructure failures (e.g. fetching Google public keys) propagate as errors.
 */
@Injectable()
export class FirebaseIdTokenVerifier {
  async verify(token: string): Promise<VerifiedFirebaseIdentity | null> {
    if (!this.isEnabled()) return null;
    try {
      const decoded = await admin.auth().verifyIdToken(token);
      return decoded.email && decoded.email_verified === true
        ? { uid: decoded.uid, email: decoded.email }
        : { uid: decoded.uid };
    } catch (error) {
      if (isFirebaseAuthRejection(error)) return null;
      throw error;
    }
  }

  private isEnabled(): boolean {
    return isFirestoreFlagEnabled() && admin.apps.length > 0;
  }
}
