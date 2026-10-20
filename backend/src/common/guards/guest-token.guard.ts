import {
  CanActivate,
  ExecutionContext,
  ForbiddenException,
  Inject,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { StayAggregate } from '../../domain/models/domain.models';
import {
  STAY_REPOSITORY_PORT,
  StayRepositoryPort,
} from '../../domain/ports/repository.ports';

const UUID_V4_REGEX =
  /^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
const CACHE_TTL_MS = 60 * 1000; // 60 seconds TTL

interface CachedStayEntry {
  stay: StayAggregate;
  expiresAt: number;
}

@Injectable()
export class GuestTokenGuard implements CanActivate {
  private static readonly stayCache = new Map<string, CachedStayEntry>();

  constructor(
    @Inject(STAY_REPOSITORY_PORT)
    private readonly stayRepository: StayRepositoryPort,
  ) {}

  static invalidateCache(): void {
    GuestTokenGuard.stayCache.clear();
  }

  clearCache(): void {
    GuestTokenGuard.stayCache.clear();
  }

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const req = context.switchToHttp().getRequest();
    const rawToken = this.extractCandidateUuid(req);

    if (!rawToken || !UUID_V4_REGEX.test(rawToken)) {
      throw new UnauthorizedException(
        'Invalid or missing RFC 4122 UUID v4 capability token.',
      );
    }

    const stay = await this.resolveStayWithCache(rawToken.toLowerCase());
    if (!stay) {
      throw new UnauthorizedException('Sanctuary reservation token not found.');
    }

    this.enforceStayLifecycleRules(stay, req.method || 'GET');
    req.stay = stay;
    return true;
  }

  private extractCandidateUuid(req: {
    headers?: Record<string, string | undefined>;
    params?: Record<string, string | undefined>;
  }): string | undefined {
    const authHeader = req.headers?.authorization || req.headers?.Authorization;
    if (authHeader && authHeader.startsWith('Bearer ')) {
      return authHeader.slice(7).trim();
    }
    const guestHeader =
      req.headers?.['x-guest-token'] || req.headers?.['X-Guest-Token'];
    if (guestHeader) {
      return guestHeader.trim();
    }
    return req.params?.guestUuid?.trim();
  }

  private async resolveStayWithCache(uuid: string): Promise<StayAggregate | null> {
    const now = Date.now();
    const cached = GuestTokenGuard.stayCache.get(uuid);
    if (cached && cached.expiresAt > now) {
      return structuredClone(cached.stay);
    }
    const stay = await this.stayRepository.findByGuestTokenUuid(uuid);
    if (stay) {
      GuestTokenGuard.stayCache.set(uuid, {
        stay: structuredClone(stay),
        expiresAt: now + CACHE_TTL_MS,
      });
    }
    return stay;
  }

  private enforceStayLifecycleRules(stay: StayAggregate, httpMethod: string): void {
    const method = httpMethod.toUpperCase();
    if (stay.status === 'PRE_ARRIVAL' || stay.status === 'ACTIVE_STAY') {
      return;
    }

    if (stay.status === 'CHECKED_OUT') {
      if (method !== 'GET') {
        throw new ForbiddenException(
          'Your stay has checked out. Post-departure access is strictly read-only.',
        );
      }
      if (!this.isWithinPostCheckoutWindow(stay)) {
        throw new ForbiddenException(
          'Your post-checkout read-only access window has expired.',
        );
      }
      return;
    }

    throw new ForbiddenException(
      `Access denied for reservation in ${stay.status} status.`,
    );
  }

  private isWithinPostCheckoutWindow(stay: StayAggregate): boolean {
    const readOnlyHours = Number(process.env.POST_CHECKOUT_READONLY_HOURS || '48');
    const referenceIso = stay.folioSummary?.checkedOutAt || stay.checkOutTimestamp;
    const referenceMs = Date.parse(referenceIso);
    if (Number.isNaN(referenceMs)) return true;
    const elapsedHours = (Date.now() - referenceMs) / (1000 * 60 * 60);
    return elapsedHours <= readOnlyHours;
  }
}
