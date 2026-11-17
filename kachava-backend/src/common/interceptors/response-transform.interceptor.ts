import {
  CallHandler,
  ExecutionContext,
  Injectable,
  NestInterceptor,
} from '@nestjs/common';
import * as crypto from 'crypto';
import { Observable } from 'rxjs';
import { map } from 'rxjs/operators';
import { PaginatedResult } from '../listing/list-query';

function requestMeta() {
  return {
    timestamp: new Date().toISOString(),
    requestId: `req_${crypto.randomBytes(4).toString('hex')}`,
  };
}

@Injectable()
export class ResponseTransformInterceptor implements NestInterceptor {
  intercept(
    _context: ExecutionContext,
    next: CallHandler,
  ): Observable<Record<string, unknown>> {
    return next.handle().pipe(
      map((data: unknown) =>
        data instanceof PaginatedResult
          ? { success: true, data: data.data, meta: { ...data.meta, ...data.extraMeta, ...requestMeta() } }
          : { success: true, data, meta: requestMeta() },
      ),
    );
  }
}
