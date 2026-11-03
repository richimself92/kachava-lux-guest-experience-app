type RuntimeEnv = Readonly<Record<string, string | undefined>>;

/**
 * Single source of truth for "the backend runs against Firebase/GCP".
 * Production deploys set `USE_FIRESTORE=true`; `USE_GCP_FIRESTORE=true` is the legacy alias.
 */
export function isFirestoreFlagEnabled(env: RuntimeEnv = process.env): boolean {
  return env.USE_FIRESTORE === 'true' || env.USE_GCP_FIRESTORE === 'true';
}

/**
 * `POST /admin/reset` wipes every stay and alert. It exists for local/E2E zero-state testing only
 * and is disabled whenever the process runs in production or against Firestore.
 */
export function isAdminResetAllowed(env: RuntimeEnv = process.env): boolean {
  return env.NODE_ENV !== 'production' && !isFirestoreFlagEnabled(env);
}
