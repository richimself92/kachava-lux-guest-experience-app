import { StaffMember } from '../../domain/models/domain.models';

type RuntimeEnv = Readonly<Record<string, string | undefined>>;

/** Stable id of the technical admin identity; it never exists as a staff document. */
export const ADMIN_SERVICE_STAFF_ID = 'admin-service';
const EMAIL_SHAPE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

/**
 * The admin console signs in silently as the technical identity configured in
 * `ADMIN_SERVICE_EMAIL` (plan rule 5). It does not come from the database.
 */
export function resolveAdminServiceEmail(env: RuntimeEnv = process.env): string | null {
  const email = env.ADMIN_SERVICE_EMAIL?.trim().toLowerCase();
  return email ? email : null;
}

/** Production refuses to start without a valid admin identity (fail closed). */
export function assertAdminIdentityConfigured(env: RuntimeEnv = process.env): void {
  if (env.NODE_ENV !== 'production') return;
  const email = resolveAdminServiceEmail(env);
  if (!email || !EMAIL_SHAPE.test(email)) {
    throw new Error('ADMIN_SERVICE_EMAIL must be set to a valid email in production.');
  }
}

export function buildAdminServiceStaff(email: string): StaffMember {
  return {
    staffId: ADMIN_SERVICE_STAFF_ID,
    firebaseUid: '',
    fullName: email,
    shortName: email,
    role: 'HOST_ADMIN',
    department: 'CONCIERGE',
    rbacRole: 'HOST_ADMIN',
    email,
    phone: '',
    avatarUrl: '',
    isActive: true,
  };
}
