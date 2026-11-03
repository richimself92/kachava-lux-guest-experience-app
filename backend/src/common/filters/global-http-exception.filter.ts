import {
  ArgumentsHost,
  Catch,
  ExceptionFilter,
  HttpStatus,
  Logger,
} from '@nestjs/common';
import * as crypto from 'crypto';
import { classifyError } from './error-classification';

/**
 * Uniform error envelope. Server-side failures (5xx) never echo internal details (storage
 * messages, project ids, index URLs) to clients; the full error is logged instead.
 */
@Catch()
export class GlobalHttpExceptionFilter implements ExceptionFilter {
  private readonly logger = new Logger(GlobalHttpExceptionFilter.name);

  catch(exception: unknown, host: ArgumentsHost): void {
    const ctx = host.switchToHttp();
    const response = ctx.getResponse();
    const request = ctx.getRequest();
    const classified = classifyError(exception);
    if (classified.status >= HttpStatus.INTERNAL_SERVER_ERROR) {
      this.logger.error(
        `Unhandled error on ${request.method} ${request.url}`,
        exception instanceof Error ? exception.stack : String(exception),
      );
    }
    if (classified.retryAfterSeconds !== undefined) {
      response.setHeader('Retry-After', String(classified.retryAfterSeconds));
    }
    const timestamp = new Date().toISOString();
    response.status(classified.status).json({
      success: false,
      statusCode: classified.status,
      error: classified.error,
      message: classified.message,
      ...(classified.code ? { code: classified.code, details: classified.details ?? [] } : {}),
      timestamp,
      path: request.url,
      meta: { timestamp, requestId: `req_${crypto.randomBytes(4).toString('hex')}` },
    });
  }
}
