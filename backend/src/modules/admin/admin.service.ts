import { resolveRealtimeAdminChannel } from '../../common/config/realtime-channels';
import { Inject, Injectable, NotFoundException, UnauthorizedException } from '@nestjs/common';
import * as crypto from 'crypto';
import {
  buildAdminServiceStaff,
  resolveAdminServiceEmail,
} from '../../common/config/admin-identity';
import { guestPortalBaseUrl } from '../../common/config/guest-portal';
import { auditActorOf } from '../../common/decorators/auth.decorators';
import { SecurityTokenService } from '../../common/services/security-token.service';
import { BusinessRuleError, EntityNotFoundError } from '../../domain/domain-errors';
import { OperationalAlert, StaffMember, StayAggregate, StayRecord } from '../../domain/models/domain.models';
import {
  STAY_REPOSITORY_PORT,
  StayRepositoryPort,
  VILLA_REPOSITORY_PORT,
  VillaRepositoryPort,
} from '../../domain/ports/repository.ports';
import { VillaAvailabilityService } from '../villas/villa-availability.service';
import { buildNewStay } from './new-stay.builder';
import { AdminLoginDto, CreateReservationDto } from './dto/admin.dto';

@Injectable()
export class AdminService {
  constructor(
    @Inject(STAY_REPOSITORY_PORT) private readonly stayRepo: StayRepositoryPort,
    @Inject(VILLA_REPOSITORY_PORT) private readonly villaRepo: VillaRepositoryPort,
    private readonly securityTokenService: SecurityTokenService,
    private readonly availability: VillaAvailabilityService,
  ) {}

  /**
   * Silent admin login (plan rule 5): only the technical identity configured in
   * `ADMIN_SERVICE_EMAIL` receives a HOST_ADMIN session. No staff document is required and
   * any other email (or a missing configuration) is rejected.
   */
  loginStaff(dto: AdminLoginDto): { token: string; staff: StaffMember; realtime: { adminChannel: string } } {
    const configured = resolveAdminServiceEmail();
    if (!configured || dto.email.trim().toLowerCase() !== configured) {
      throw new UnauthorizedException('Invalid staff credentials.');
    }
    const staff = buildAdminServiceStaff(configured);
    const realtime = { adminChannel: resolveRealtimeAdminChannel() };
    return { token: this.securityTokenService.issueStaffToken(staff), staff, realtime };
  }

  /** The new stay and its NEW_RESERVATION notification commit together. */
  async createReservation(
    dto: CreateReservationDto,
    staff: StaffMember,
  ): Promise<{ stay: StayAggregate; magicLinkUrl: string }> {
    const villa = await this.villaRepo.findById(dto.villaId);
    if (!villa) throw new EntityNotFoundError('Villa', dto.villaId);
    if (!villa.isActive) throw new BusinessRuleError(`Villa ${villa.name} is inactive`);
    if (dto.guestsCount && dto.guestsCount > villa.capacity) {
      throw new BusinessRuleError(`Villa ${villa.name} hosts at most ${villa.capacity} guests`);
    }
    await this.availability.assertVillaFree(villa, dto);
    const newUuid = crypto.randomUUID();
    const magicLinkUrl = `${guestPortalBaseUrl()}/?guestId=${newUuid}`;
    const newStay = buildNewStay(dto, villa, {
      stayId: `stay_${crypto.randomUUID()}`,
      guestTokenUuid: newUuid,
      magicLinkUrl,
      now: new Date().toISOString(),
    });
    const created = await this.stayRepo.createStay(newStay, newReservationAlert(newStay, staff));
    return { stay: created, magicLinkUrl };
  }

  async regenerateStayToken(
    stayId: string,
  ): Promise<{ stayId: string; guestTokenUuid: string; magicLinkUrl: string }> {
    await this.requireStay(stayId);
    const newUuid = crypto.randomUUID();
    const updated: StayRecord = await this.stayRepo.updateStayToken(stayId, newUuid);
    return {
      stayId: updated.stayId,
      guestTokenUuid: updated.guestTokenUuid,
      magicLinkUrl: `${guestPortalBaseUrl()}/?guestId=${newUuid}`,
    };
  }

  private async requireStay(stayId: string): Promise<StayAggregate> {
    const existing = await this.stayRepo.findByStayId(stayId);
    if (!existing) throw new NotFoundException(`Stay ${stayId} not found.`);
    return existing;
  }
}

function newReservationAlert(stay: StayAggregate, staff: StaffMember): OperationalAlert {
  return {
    alertId: `alt_${crypto.randomUUID()}`,
    stayId: stay.stayId,
    villaId: stay.villaId,
    villaName: stay.villaName,
    guestNames: stay.guestProfile.name,
    category: 'RESERVATION',
    severity: 'NORMAL',
    title: `${stay.villaName}: new reservation`,
    summary: `${stay.guestProfile.name} · ${stay.checkInDate} – ${stay.checkOutDate} · by ${auditActorOf(staff)}`,
    sourceDocumentPath: `stays/${stay.stayId}`,
    assignedDepartment: null,
    isAcknowledged: false,
    acknowledgedByStaffId: null,
    acknowledgedAt: null,
    createdAt: stay.createdAt,
    targetRef: { type: 'STAY', id: stay.stayId },
    event: 'NEW_RESERVATION',
  };
}
