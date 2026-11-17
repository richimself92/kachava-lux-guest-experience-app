type RuntimeEnv = Readonly<Record<string, string | undefined>>;

/** Fixed local/test admin channel; production must configure its own secret id. */
export const DEV_REALTIME_ADMIN_CHANNEL = 'dev-admin-channel';
export const MIN_ADMIN_CHANNEL_LENGTH = 32;

/**
 * Signal doc id staff clients listen to (ADR-012). Anyone who knows it may read "something changed
 * at T", so production requires a long random value in `REALTIME_ADMIN_CHANNEL`.
 */
export function resolveRealtimeAdminChannel(env: RuntimeEnv = process.env): string {
  const configured = env.REALTIME_ADMIN_CHANNEL?.trim();
  if (env.NODE_ENV !== 'production') return configured || DEV_REALTIME_ADMIN_CHANNEL;
  if (!configured || configured.length < MIN_ADMIN_CHANNEL_LENGTH) {
    throw new Error(
      `Missing or weak REALTIME_ADMIN_CHANNEL: production requires a random id of at least ${MIN_ADMIN_CHANNEL_LENGTH} characters.`,
    );
  }
  return configured;
}
