import { RetryAfterHttpException } from '../../src/common/filters/retry-after-http.exception';
import {
  STEP_UP_LOCKOUT_WINDOW_MS,
  STEP_UP_MAX_FAILED_ATTEMPTS,
  StepUpAttemptLimiter,
} from '../../src/common/services/step-up-attempt-limiter';

const START = Date.parse('2026-11-12T10:00:00.000Z');

describe('StepUpAttemptLimiter (5 failed attempts per stay per 15 minutes)', () => {
  let limiter: StepUpAttemptLimiter;

  beforeEach(() => {
    jest.useFakeTimers({ now: START });
    limiter = new StepUpAttemptLimiter();
  });

  afterEach(() => jest.useRealTimers());

  function failTimes(stayId: string, count: number): void {
    for (let i = 0; i < count; i += 1) limiter.recordFailure(stayId);
  }

  it('test_limiter_fourFailures_stillAllowsAnAttempt', () => {
    failTimes('stay_a', STEP_UP_MAX_FAILED_ATTEMPTS - 1);

    expect(() => limiter.assertCanAttempt('stay_a')).not.toThrow();
  });

  it('test_limiter_fiveFailures_locksWith429AndRetryAfterUntilWindowEnds', () => {
    failTimes('stay_a', STEP_UP_MAX_FAILED_ATTEMPTS);
    jest.setSystemTime(START + 60_000);

    const error = (() => {
      try {
        limiter.assertCanAttempt('stay_a');
      } catch (e) {
        return e as RetryAfterHttpException;
      }
      return null;
    })();

    expect(error).toBeInstanceOf(RetryAfterHttpException);
    expect(error?.getStatus()).toBe(429);
    expect(error?.retryAfterSeconds).toBe((STEP_UP_LOCKOUT_WINDOW_MS - 60_000) / 1000);
  });

  it('test_limiter_lockoutIsPerStay', () => {
    failTimes('stay_a', STEP_UP_MAX_FAILED_ATTEMPTS);

    expect(() => limiter.assertCanAttempt('stay_b')).not.toThrow();
  });

  it('test_limiter_afterWindowExpires_allowsAttemptsAgain', () => {
    failTimes('stay_a', STEP_UP_MAX_FAILED_ATTEMPTS);
    jest.setSystemTime(START + STEP_UP_LOCKOUT_WINDOW_MS + 1);

    expect(() => limiter.assertCanAttempt('stay_a')).not.toThrow();
  });

  it('test_limiter_successClearsEarlierFailures', () => {
    failTimes('stay_a', STEP_UP_MAX_FAILED_ATTEMPTS - 1);
    limiter.recordSuccess('stay_a');
    failTimes('stay_a', STEP_UP_MAX_FAILED_ATTEMPTS - 1);

    expect(() => limiter.assertCanAttempt('stay_a')).not.toThrow();
  });
});
