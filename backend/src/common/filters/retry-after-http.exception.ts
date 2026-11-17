import { HttpException } from '@nestjs/common';

/** An HTTP error whose response carries a `Retry-After` header (seconds). */
export class RetryAfterHttpException extends HttpException {
  constructor(
    status: number,
    message: string,
    readonly retryAfterSeconds: number,
  ) {
    super(message, status);
  }
}
