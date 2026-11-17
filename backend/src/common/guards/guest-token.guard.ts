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
import { presentedGuestToken, routeTokenMismatch, UUID_V4_REGEX } from './guest-credential';

/**
 * Resolves the guest capability token against the stay store on every request (no
 * cross-request cache), so token rotation and status changes apply immediately on every
 * instance. Storage failures propagate as 5xx; only malformed/unknown tokens yield 401.
 */
@Injectable()
export class GuestTokenGuard implements CanActivate {
  constructor(
    @Inject(STAY_REPOSITORY_PORT)
    private readonly stayRepository: StayRepositoryPort,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const req = context.switchToHttp().getRequest();
    const rawToken = presentedGuestToken(req);

    if (routeTokenMismatch(req)) {
      throw new UnauthorizedException('Guest token header does not match the requested stay.');
    }
    if (!rawToken || !UUID_V4_REGEX.test(rawToken)) {
      throw new UnauthorizedException(
        'Invalid or missing RFC 4122 UUID v4 capability token.',
      );
    }

    const stay = await this.stayRepository.findByGuestTokenUuid(rawToken.toLowerCase());
    if (!stay) {
      throw new UnauthorizedException('Sanctuary reservation token not found.');
    }

    this.enforceStayLifecycleRules(stay, req.method || 'GET');
    req.stay = stay;
    return true;
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
