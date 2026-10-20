import {
  CanActivate,
  ExecutionContext,
  ForbiddenException,
  Injectable,
} from '@nestjs/common';
import { SecurityTokenService } from '../services/security-token.service';

@Injectable()
export class StepUpVerifiedGuard implements CanActivate {
  constructor(private readonly securityTokenService: SecurityTokenService) {}

  canActivate(context: ExecutionContext): boolean {
    const req = context.switchToHttp().getRequest();
    const stay = req.stay as { stayId?: string } | undefined;
    if (!stay?.stayId) {
      throw new ForbiddenException('Stay context required for step-up verification.');
    }

    const token =
      req.headers?.['x-stepup-session'] ||
      req.headers?.['X-StepUp-Session'] ||
      req.headers?.['x-stepup-token'] ||
      req.headers?.['X-StepUp-Token'];

    const isValid = this.securityTokenService.verifyStepUpToken(
      typeof token === 'string' ? token : undefined,
      stay.stayId,
    );

    if (!isValid) {
      throw new ForbiddenException(
        'Step-up verification required. Please verify your Villa Number or Last Name via /verify-step-up.',
      );
    }

    return true;
  }
}
