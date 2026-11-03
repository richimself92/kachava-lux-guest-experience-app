import { HttpStatus, Injectable } from '@nestjs/common';
import { RetryAfterHttpException } from '../filters/retry-after-http.exception';

export const STEP_UP_MAX_FAILED_ATTEMPTS = 5;
export const STEP_UP_LOCKOUT_WINDOW_MS = 15 * 60_000;

interface FailureWindow {
  count: number;
  startedAtMs: number;
}

/**
 * Step-up brute-force limit, separate from the general throttler: at most 5 failed answers per
 * stay per 15 minutes; then every attempt (even a correct one) gets 429 + Retry-After until the
 * window ends. A success clears the stay's failures.
 *
 * Counters live in process memory (like the general throttler), so with N Cloud Run instances
 * the effective cap is N x 5 per window; move them to the store if instances grow.
 */
@Injectable()
export class StepUpAttemptLimiter {
  private readonly failures = new Map<string, FailureWindow>();

  assertCanAttempt(stayId: string): void {
    const window = this.activeWindow(stayId);
    if (!window || window.count < STEP_UP_MAX_FAILED_ATTEMPTS) return;
    const remainingMs = window.startedAtMs + STEP_UP_LOCKOUT_WINDOW_MS - Date.now();
    throw new RetryAfterHttpException(
      HttpStatus.TOO_MANY_REQUESTS,
      'Too many verification attempts. Please try again later.',
      Math.max(1, Math.ceil(remainingMs / 1000)),
    );
  }

  recordFailure(stayId: string): void {
    const window = this.activeWindow(stayId) ?? { count: 0, startedAtMs: Date.now() };
    this.failures.set(stayId, { ...window, count: window.count + 1 });
  }

  recordSuccess(stayId: string): void {
    this.failures.delete(stayId);
  }

  private activeWindow(stayId: string): FailureWindow | null {
    const window = this.failures.get(stayId);
    if (!window) return null;
    if (Date.now() - window.startedAtMs < STEP_UP_LOCKOUT_WINDOW_MS) return window;
    this.failures.delete(stayId);
    return null;
  }
}
