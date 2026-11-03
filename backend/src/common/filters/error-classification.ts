import { HttpException, HttpStatus } from '@nestjs/common';
import {
  StayDocumentTooLargeError,
  StayLimitExceededError,
  StayNotFoundError,
} from '../../domain/stay-errors';
import { RetryAfterHttpException } from './retry-after-http.exception';

export interface ClassifiedError {
  status: number;
  error: string;
  /** Safe for clients; 5xx always use a generic text (details are logged server-side only). */
  message: string;
  retryAfterSeconds?: number;
}

const GRPC_INVALID_ARGUMENT = 3;
const GRPC_ABORTED = 10;
const GRPC_UNAVAILABLE = 14;
const CONTENTION_RETRY_AFTER_SECONDS = 1;
const GENERIC_SERVER_MESSAGE = 'An unexpected error occurred.';
const BUSY_MESSAGE = 'The service is busy. Please retry shortly.';
const TOO_LARGE_MESSAGE = 'This stay has reached its storage limit.';

function grpcCode(exception: unknown): number | undefined {
  const code = (exception as { code?: unknown } | null)?.code;
  return typeof code === 'number' ? code : undefined;
}

/**
 * Express body-parser failures (`entity.too.large` -> 413, `entity.parse.failed` -> 400, ...) are
 * `http-errors` objects: a 4xx `status` with `expose: true` marks the message as client-safe.
 */
function exposedClientError(exception: unknown): ClassifiedError | null {
  const candidate = exception as { status?: unknown; expose?: unknown; message?: unknown } | null;
  const status = candidate?.status;
  if (candidate?.expose !== true || typeof status !== 'number' || status < 400 || status >= 500) {
    return null;
  }
  return { status, error: 'ClientError', message: String(candidate.message ?? 'Request rejected.') };
}

function isDocumentSizeRejection(exception: unknown): boolean {
  return (
    grpcCode(exception) === GRPC_INVALID_ARGUMENT &&
    exception instanceof Error &&
    exception.message.includes('exceeds the maximum allowed size')
  );
}

/** Maps any thrown value to the HTTP answer the client receives. */
export function classifyError(exception: unknown): ClassifiedError {
  if (exception instanceof HttpException) return classifyHttpException(exception);
  if (exception instanceof StayNotFoundError) {
    return { status: HttpStatus.NOT_FOUND, error: 'NotFound', message: 'Stay not found.' };
  }
  if (exception instanceof StayLimitExceededError) {
    return { status: HttpStatus.CONFLICT, error: 'Conflict', message: exception.message };
  }
  if (exception instanceof StayDocumentTooLargeError || isDocumentSizeRejection(exception)) {
    return { status: HttpStatus.PAYLOAD_TOO_LARGE, error: 'PayloadTooLarge', message: TOO_LARGE_MESSAGE };
  }
  const clientError = exposedClientError(exception);
  if (clientError) return clientError;
  const code = grpcCode(exception);
  if (code === GRPC_ABORTED || code === GRPC_UNAVAILABLE) {
    return {
      status: HttpStatus.SERVICE_UNAVAILABLE,
      error: 'ServiceUnavailable',
      message: BUSY_MESSAGE,
      retryAfterSeconds: CONTENTION_RETRY_AFTER_SECONDS,
    };
  }
  return { status: HttpStatus.INTERNAL_SERVER_ERROR, error: 'InternalServerError', message: GENERIC_SERVER_MESSAGE };
}

function classifyHttpException(exception: HttpException): ClassifiedError {
  const status = exception.getStatus();
  const retryAfterSeconds =
    exception instanceof RetryAfterHttpException ? exception.retryAfterSeconds : undefined;
  const message =
    status >= HttpStatus.INTERNAL_SERVER_ERROR
      ? GENERIC_SERVER_MESSAGE
      : extractMessage(exception.getResponse());
  return { status, error: exception.name, message, retryAfterSeconds };
}

function extractMessage(response: string | object): string {
  if (typeof response === 'string') return response;
  const msg = (response as { message?: string | string[] }).message;
  if (Array.isArray(msg)) return msg.join('; ');
  return typeof msg === 'string' ? msg : 'Request failed.';
}
