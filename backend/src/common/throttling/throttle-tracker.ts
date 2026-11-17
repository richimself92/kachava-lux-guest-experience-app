import type { ThrottlerGetTrackerFunction, ThrottlerOptions } from '@nestjs/throttler';
import { bearerToken, presentedGuestToken, UUID_V4_REGEX } from '../guards/guest-credential';

/**
 * Two budgets per minute apply to every request (both must have room):
 * - `token`: per tracker (guest token, admin bearer token or client IP). A guest device polls every
 *   10 s (6/min) and an admin tab syncs every 5 s (12/min); 300/min leaves room for several
 *   devices/tabs sharing one token plus normal interactions.
 * - `ip`: per client IP (resolved through Express `trust proxy`), so rotating random tokens cannot
 *   escape the cap. 1500/min fits ~50 concurrent guests and staff behind one resort NAT IP.
 */
export const THROTTLE_TTL_MS = 60_000;
export const THROTTLE_LIMIT_PER_TRACKER = 300;
export const THROTTLE_LIMIT_PER_IP = 1500;

export interface TrackableRequest {
  params?: Record<string, string | undefined>;
  headers?: Record<string, string | string[] | undefined>;
  ip?: string;
}

type KachavaThrottler = ThrottlerOptions & {
  name: string;
  ttl: number;
  limit: number;
  getTracker: ThrottlerGetTrackerFunction;
};

export interface KachavaThrottlerOptions {
  throttlers: KachavaThrottler[];
}

/**
 * Identifies who is consuming the budget: the credential the guards authenticate (a guest token
 * from `Authorization`, `X-Guest-Token` or the route, or an admin bearer token), else the client
 * IP (resolved through Express `trust proxy`). Rotating the route `:guestUuid` while sending a
 * valid header token therefore still spends that token's budget (and the guard answers 401).
 */
export function resolveThrottleTracker(req: TrackableRequest): string {
  const bearer = bearerToken(req);
  if (bearer && !UUID_V4_REGEX.test(bearer)) return `bearer:${bearer}`;
  const guestToken = presentedGuestToken(req).toLowerCase();
  if (guestToken) return `guest:${guestToken}`;
  return resolveClientIpTracker(req);
}

export function resolveClientIpTracker(req: TrackableRequest): string {
  return `ip:${req.ip ?? 'unknown'}`;
}

export function buildThrottlerOptions(
  limit: number = THROTTLE_LIMIT_PER_TRACKER,
  ipLimit: number = THROTTLE_LIMIT_PER_IP,
): KachavaThrottlerOptions {
  return {
    throttlers: [
      {
        name: 'token',
        ttl: THROTTLE_TTL_MS,
        limit,
        getTracker: (req) => resolveThrottleTracker(req as TrackableRequest),
      },
      {
        name: 'ip',
        ttl: THROTTLE_TTL_MS,
        limit: ipLimit,
        getTracker: (req) => resolveClientIpTracker(req as TrackableRequest),
      },
    ],
  };
}
