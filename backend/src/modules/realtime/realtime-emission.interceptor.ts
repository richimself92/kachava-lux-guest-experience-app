import { CallHandler, ExecutionContext, Injectable, NestInterceptor } from '@nestjs/common';
import { Observable } from 'rxjs';
import { mergeMap } from 'rxjs/operators';
import { changeForMutation } from './realtime-routes';
import { RealtimePublisher } from './realtime-publisher.service';

const MUTATING_METHODS: ReadonlySet<string> = new Set(['POST', 'PUT', 'PATCH', 'DELETE']);

interface RoutedRequest {
  method?: string;
  route?: { path?: string };
  params?: Record<string, string | undefined>;
  stay?: { stayId?: string };
}

/**
 * ADR-012 emission: after a mutating handler succeeds, announce the change. Registered inside
 * the response envelope, so it sees the handler's own result (`stayId` of the entity).
 */
@Injectable()
export class RealtimeEmissionInterceptor implements NestInterceptor {
  constructor(private readonly publisher: RealtimePublisher) {}

  intercept(context: ExecutionContext, next: CallHandler): Observable<unknown> {
    if (context.getType() !== 'http') return next.handle();
    const req = context.switchToHttp().getRequest<RoutedRequest>();
    if (!MUTATING_METHODS.has(req.method ?? '')) return next.handle();
    return next.handle().pipe(
      mergeMap(async (data: unknown) => {
        await this.emit(req, data);
        return data;
      }),
    );
  }

  /**
   * Awaited before the response is sent: Cloud Run throttles CPU once a response is out, so a
   * background write could stall. The publisher never rejects.
   */
  private async emit(req: RoutedRequest, responseData: unknown): Promise<void> {
    const change = changeForMutation({
      routePath: req.route?.path ?? '',
      params: req.params ?? {},
      guestStayId: req.stay?.stayId,
      responseData,
    });
    if (change) await this.publisher.publish(change);
  }
}
