import {
  ArgumentsHost,
  Catch,
  ExceptionFilter,
  HttpException,
  HttpStatus,
} from '@nestjs/common';
import * as crypto from 'crypto';

@Catch()
export class GlobalHttpExceptionFilter implements ExceptionFilter {
  catch(exception: unknown, host: ArgumentsHost): void {
    const ctx = host.switchToHttp();
    const response = ctx.getResponse();
    const request = ctx.getRequest();

    const statusCode =
      exception instanceof HttpException
        ? exception.getStatus()
        : HttpStatus.INTERNAL_SERVER_ERROR;

    const exceptionResponse =
      exception instanceof HttpException ? exception.getResponse() : null;

    const message = this.extractMessage(exceptionResponse, exception);
    const errorName =
      exception instanceof HttpException
        ? exception.name
        : 'InternalServerError';

    const timestamp = new Date().toISOString();

    response.status(statusCode).json({
      success: false,
      statusCode,
      error: errorName,
      message,
      timestamp,
      path: request.url,
      meta: {
        timestamp,
        requestId: `req_${crypto.randomBytes(4).toString('hex')}`,
      },
    });
  }

  private extractMessage(
    exceptionResponse: string | object | null,
    exception: unknown,
  ): string {
    if (typeof exceptionResponse === 'string') return exceptionResponse;
    if (exceptionResponse && typeof exceptionResponse === 'object') {
      const msg = (exceptionResponse as { message?: string | string[] }).message;
      if (Array.isArray(msg)) return msg.join('; ');
      if (typeof msg === 'string') return msg;
    }
    if (exception instanceof Error) return exception.message;
    return 'An unexpected error occurred';
  }
}
