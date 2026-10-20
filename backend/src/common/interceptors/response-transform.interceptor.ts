import {
  CallHandler,
  ExecutionContext,
  Injectable,
  NestInterceptor,
} from '@nestjs/common';
import * as crypto from 'crypto';
import { Observable } from 'rxjs';
import { map } from 'rxjs/operators';

@Injectable()
export class ResponseTransformInterceptor implements NestInterceptor {
  intercept(
    _context: ExecutionContext,
    next: CallHandler,
  ): Observable<Record<string, unknown>> {
    return next.handle().pipe(
      map((data: unknown) => ({
        success: true,
        data,
        meta: {
          timestamp: new Date().toISOString(),
          requestId: `req_${crypto.randomBytes(4).toString('hex')}`,
        },
      })),
    );
  }
}
