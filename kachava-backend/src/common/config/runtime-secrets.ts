import * as crypto from 'crypto';
import { isFirestoreFlagEnabled } from './runtime-flags';

type RuntimeEnv = Readonly<Record<string, string | undefined>>;

export const MIN_SECRET_LENGTH = 32;
export const REQUIRED_SECRET_NAMES = ['STAFF_JWT_SECRET'] as const;
export type SecretName = (typeof REQUIRED_SECRET_NAMES)[number];

const ephemeralSecrets = new Map<SecretName, string>();

/** Production and every Firestore-backed run (the local emulator included) need strong, explicit secrets. */
function isStrictSecretMode(env: RuntimeEnv): boolean {
  return env.NODE_ENV === 'production' || isFirestoreFlagEnabled(env);
}

function requireStrongSecret(name: SecretName, value: string | undefined): string {
  if (!value || value.length < MIN_SECRET_LENGTH) {
    throw new Error(
      `Missing or weak secret ${name}: production/Firestore mode requires at least ` +
        `${MIN_SECRET_LENGTH} characters. Set ${name} in the service environment.`,
    );
  }
  return value;
}

/** Unit tests without a configured secret get a random value that lives only in this process. */
function ephemeralSecret(name: SecretName): string {
  const existing = ephemeralSecrets.get(name);
  if (existing) return existing;
  const generated = crypto.randomBytes(MIN_SECRET_LENGTH).toString('hex');
  ephemeralSecrets.set(name, generated);
  return generated;
}

export function resolveSecret(name: SecretName, env: RuntimeEnv = process.env): string {
  if (isStrictSecretMode(env)) return requireStrongSecret(name, env[name]);
  return env[name] || ephemeralSecret(name);
}

/** Fails startup before any module is built when a strict-mode secret is missing or weak. */
export function assertProductionSecrets(env: RuntimeEnv = process.env): void {
  for (const name of REQUIRED_SECRET_NAMES) resolveSecret(name, env);
}
