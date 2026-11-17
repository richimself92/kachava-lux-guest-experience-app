type RuntimeEnv = Readonly<Record<string, string | undefined>>;

/**
 * The backend always persists to Firestore + Cloud Storage; there is no in-memory runtime mode.
 * `USE_FIRESTORE=true` is required as an explicit acknowledgement in every environment.
 */
export function isFirestoreFlagEnabled(env: RuntimeEnv = process.env): boolean {
  return env.USE_FIRESTORE === 'true';
}

/**
 * Fails startup unless the data target is safe: production uses the managed services; any other
 * environment must point at the local emulators, so a developer machine with Google credentials
 * can never read or write the live database or bucket.
 */
export function assertFirestoreTarget(env: RuntimeEnv = process.env): void {
  if (!isFirestoreFlagEnabled(env)) {
    throw new Error('USE_FIRESTORE=true is required: the backend always persists to Firestore.');
  }
  if (env.NODE_ENV === 'production') return;
  if (!env.FIRESTORE_EMULATOR_HOST) {
    throw new Error('Outside production set FIRESTORE_EMULATOR_HOST (the live database is never used locally).');
  }
  if (!env.FIREBASE_STORAGE_EMULATOR_HOST) {
    throw new Error('Outside production set FIREBASE_STORAGE_EMULATOR_HOST (the live bucket is never used locally).');
  }
}
