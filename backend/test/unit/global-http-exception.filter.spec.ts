import { ArgumentsHost, BadRequestException, Logger } from '@nestjs/common';
import { GlobalHttpExceptionFilter } from '../../src/common/filters/global-http-exception.filter';
import { RetryAfterHttpException } from '../../src/common/filters/retry-after-http.exception';
import {
  StayDocumentTooLargeError,
  StayLimitExceededError,
  StayNotFoundError,
} from '../../src/domain/stay-errors';

interface CapturedResponse {
  status: number;
  headers: Record<string, string>;
  body: { statusCode: number; message: string; error: string };
}

function runFilter(exception: unknown): CapturedResponse {
  const captured = { status: 0, headers: {}, body: {} } as CapturedResponse;
  const response = {
    setHeader: (name: string, value: string) => (captured.headers[name] = value),
    status(code: number) {
      captured.status = code;
      return this;
    },
    json: (body: CapturedResponse['body']) => (captured.body = body),
  };
  const host = {
    switchToHttp: () => ({
      getResponse: () => response,
      getRequest: () => ({ method: 'GET', url: '/api/v1/stays/x' }),
    }),
  } as unknown as ArgumentsHost;
  new GlobalHttpExceptionFilter().catch(exception, host);
  return captured;
}

describe('GlobalHttpExceptionFilter', () => {
  let logSpy: jest.SpyInstance;

  beforeEach(() => {
    logSpy = jest.spyOn(Logger.prototype, 'error').mockImplementation(() => undefined);
  });

  afterEach(() => logSpy.mockRestore());

  it('test_filter_unhandledStorageError_returnsGeneric500AndLogsDetails', () => {
    const secret = '9 FAILED_PRECONDITION: index https://console.firebase.google.com/project/kavacha-app';

    const res = runFilter(new Error(secret));

    expect(res.status).toBe(500);
    expect(res.body.message).not.toContain('kavacha-app');
    expect(res.body.message).toBe('An unexpected error occurred.');
    expect(JSON.stringify(logSpy.mock.calls)).toContain('kavacha-app');
  });

  it('test_filter_stayNotFoundError_returns404', () => {
    const res = runFilter(new StayNotFoundError('stay_x'));

    expect(res.status).toBe(404);
    expect(res.body.error).toBe('NotFound');
  });

  it('test_filter_firestoreAbortedContention_returns503WithRetryAfter', () => {
    const aborted = Object.assign(new Error('10 ABORTED: Too much contention.'), { code: 10 });

    const res = runFilter(aborted);

    expect(res.status).toBe(503);
    expect(res.headers['Retry-After']).toBe('1');
    expect(res.body.message).not.toContain('ABORTED');
  });

  it('test_filter_firestoreDocumentTooLarge_returns413', () => {
    const tooLarge = Object.assign(
      new Error('3 INVALID_ARGUMENT: Document cannot be written because its size (1048999 bytes) exceeds the maximum allowed size of 1,048,576 bytes.'),
      { code: 3 },
    );

    expect(runFilter(tooLarge).status).toBe(413);
    expect(runFilter(new StayDocumentTooLargeError(950_000)).status).toBe(413);
  });

  it('test_filter_bodyParserEntityTooLarge_returns413', () => {
    const bodyParserError = Object.assign(new Error('request entity too large'), {
      type: 'entity.too.large',
      status: 413,
      statusCode: 413,
      expose: true,
    });

    const res = runFilter(bodyParserError);

    expect(res.status).toBe(413);
    expect(logSpy).not.toHaveBeenCalled();
  });

  it('test_filter_stayListLimitExceeded_returns409WithReason', () => {
    const res = runFilter(new StayLimitExceededError('bookings', 100));

    expect(res.status).toBe(409);
    expect(res.body.message).toContain('bookings');
  });

  it('test_filter_retryAfterHttpException_setsRetryAfterHeader', () => {
    const res = runFilter(new RetryAfterHttpException(429, 'Too many attempts.', 900));

    expect(res.status).toBe(429);
    expect(res.headers['Retry-After']).toBe('900');
  });

  it('test_filter_clientHttpException_keepsItsMessage', () => {
    const res = runFilter(new BadRequestException(['title must be shorter']));

    expect(res.status).toBe(400);
    expect(res.body.message).toBe('title must be shorter');
    expect(logSpy).not.toHaveBeenCalled();
  });
});
