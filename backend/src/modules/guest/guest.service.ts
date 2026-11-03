import {
  ForbiddenException,
  Inject,
  Injectable,
} from '@nestjs/common';
import { SecurityTokenService } from '../../common/services/security-token.service';
import { StepUpAttemptLimiter } from '../../common/services/step-up-attempt-limiter';
import {
  FlightTransfer,
  OperationalAlert,
  Personalization,
  StayAggregate,
} from '../../domain/models/domain.models';
import {
  STAY_REPOSITORY_PORT,
  StayRepositoryPort,
} from '../../domain/ports/repository.ports';
import {
  CreateBookingDto,
  CreateConciergeMessageDto,
  CreateConciergeRequestDto,
  CreateMidStayCheckInDto,
  ExpressCheckoutDto,
  GenerateUploadUrlDto,
  UpdateLarderOrderDto,
  UpdatePersonalizationDto,
  UpdateTransferDto,
  VerifyStepUpDto,
} from './dto/guest.dto';
import { GuestAlertFolioHelper } from './guest-alert-folio.helper';
import { GuestBookingService } from './guest-booking.service';
import { GuestConciergeService } from './guest-concierge.service';
import { matchesGuestLastName } from './step-up-last-name.matcher';

@Injectable()
export class GuestService {
  constructor(
    @Inject(STAY_REPOSITORY_PORT)
    private readonly stayRepo: StayRepositoryPort,
    private readonly securityTokenService: SecurityTokenService,
    private readonly alertFolioHelper: GuestAlertFolioHelper,
    private readonly bookingService: GuestBookingService,
    private readonly conciergeService: GuestConciergeService,
    private readonly stepUpLimiter: StepUpAttemptLimiter,
  ) {}

  /**
   * Step-up answers are the villa number or the primary guest's last name. Both are visible in
   * the guest view (villa name, guest name), so this only proves possession of a session that
   * already holds the link; a secret not exposed to guests is a pending owner decision. Failed
   * answers are rate limited per stay (StepUpAttemptLimiter).
   */
  verifyStepUp(
    stay: StayAggregate,
    dto: VerifyStepUpDto,
  ): { verified: boolean; stepUpToken: string } {
    this.stepUpLimiter.assertCanAttempt(stay.stayId);
    if (!this.matchesStepUpAnswer(stay, dto)) {
      this.stepUpLimiter.recordFailure(stay.stayId);
      throw new ForbiddenException(
        'Step-up challenge failed: Villa Number or Primary Guest Last Name did not match.',
      );
    }
    this.stepUpLimiter.recordSuccess(stay.stayId);
    const stepUpToken = this.securityTokenService.issueStepUpToken(
      stay.stayId,
      stay.guestTokenUuid,
    );
    return { verified: true, stepUpToken };
  }

  private matchesStepUpAnswer(stay: StayAggregate, dto: VerifyStepUpDto): boolean {
    const cleanVilla = dto.villaNumber?.replace(/[^0-9]/g, '');
    const stayVillaDigits =
      stay.villaName.replace(/[^0-9]/g, '') || stay.villaId.replace(/[^0-9]/g, '');
    const matchesVilla =
      (Boolean(cleanVilla) && cleanVilla === stayVillaDigits) ||
      dto.villaNumber === stay.villaId;
    return matchesVilla || matchesGuestLastName(stay.guestProfile, dto.lastName);
  }

  async updateTransfer(
    stay: StayAggregate,
    dto: UpdateTransferDto,
  ): Promise<FlightTransfer> {
    const nextStatus =
      stay.flightTransfer.status === 'Not Requested' || !dto.status
        ? 'Pending'
        : dto.status;
    const patch = {
      ...dto,
      status: nextStatus,
      estimatedLanding:
        dto.estimatedLanding || dto.arrivalTime || stay.flightTransfer.estimatedLanding,
    };
    return this.stayRepo.updateTransfer(stay.stayId, patch, (updated) =>
      this.alertFolioHelper.buildAlert(stay, {
        category: 'TRANSFER',
        severity: 'NORMAL',
        title: `${stay.villaName} Aviation Transfer Updated (${updated.flightNumber})`,
        summary: `Flight ${updated.flightNumber} landing at ${updated.estimatedLanding}.`,
        sourceDocumentPath: `stays/${stay.stayId}`,
        assignedDepartment: 'TRANSPORT',
      }),
    );
  }

  async updatePersonalization(
    stay: StayAggregate,
    dto: UpdatePersonalizationDto,
  ): Promise<Personalization> {
    const allergiesList =
      dto.dietaryAllergies !== undefined
        ? dto.dietaryAllergies
        : dto.allergies
          ? [dto.allergies]
          : [];
    const allergiesLabel = (allergiesList.join(', ') || dto.allergies || '').trim();
    return this.stayRepo.updatePersonalization(
      stay.stayId,
      {
        ...dto,
        pillowType: dto.pillowType || dto.pillowSelection || stay.personalization.pillowType,
        pillowSelection:
          dto.pillowSelection || dto.pillowType || stay.personalization.pillowSelection,
        villaScent: dto.villaScent || dto.scentProfile || stay.personalization.villaScent,
        scentProfile: dto.scentProfile || dto.villaScent || stay.personalization.scentProfile,
        housekeepingCadence:
          dto.housekeepingCadence ?? stay.personalization.housekeepingCadence ?? '',
        dietaryAllergies: allergiesList,
        allergies: allergiesLabel,
      },
      allergiesLabel || undefined,
      (updated) => this.personalizationAlert(stay, updated, allergiesLabel),
    );
  }

  private personalizationAlert(
    stay: StayAggregate,
    updated: Personalization,
    allergiesLabel: string,
  ): OperationalAlert {
    const hasAllergies =
      allergiesLabel.length > 0 && allergiesLabel.toLowerCase() !== 'none';
    const baseSummary = `Pillow: ${updated.pillowType || '—'} · Scent: ${updated.scentProfile || '—'} · Diet: ${updated.dietary || '—'} · Cleaning: ${updated.housekeepingCadence || '—'}`;
    return this.alertFolioHelper.buildAlert(stay, {
      category: 'DIETARY',
      severity: hasAllergies ? 'URGENT' : 'NORMAL',
      title: hasAllergies
        ? `${stay.villaName} Dietary & Allergy Update: ${allergiesLabel}`
        : `${stay.villaName} Stay Preferences Updated (${updated.pillowType || 'Standard'} · ${updated.scentProfile || 'Default'})`,
      summary: hasAllergies
        ? `${baseSummary} · Allergies: ${allergiesLabel} · Notes: ${updated.occasionDetails || '—'}`
        : `${baseSummary} · Notes: ${updated.occasionDetails || '—'}`,
      sourceDocumentPath: `stays/${stay.stayId}`,
      assignedDepartment: 'CULINARY',
    });
  }

  updateLarderOrder(stay: StayAggregate, dto: UpdateLarderOrderDto) {
    return this.bookingService.updateLarderOrder(stay, dto);
  }

  createBooking(stay: StayAggregate, dto: CreateBookingDto) {
    return this.bookingService.createBooking(stay, dto);
  }

  createConciergeRequest(stay: StayAggregate, dto: CreateConciergeRequestDto) {
    return this.conciergeService.createConciergeRequest(stay, dto);
  }

  appendConciergeMessage(
    stay: StayAggregate,
    requestId: string,
    dto: CreateConciergeMessageDto,
  ) {
    return this.conciergeService.appendConciergeMessage(stay, requestId, dto);
  }

  generateUploadUrl(stay: StayAggregate, dto: GenerateUploadUrlDto) {
    return this.conciergeService.generateUploadUrl(stay, dto);
  }

  submitMidStayCheckIn(stay: StayAggregate, dto: CreateMidStayCheckInDto) {
    return this.conciergeService.submitMidStayCheckIn(stay, dto);
  }

  processExpressCheckout(stay: StayAggregate, dto: ExpressCheckoutDto) {
    return this.conciergeService.processExpressCheckout(stay, dto);
  }
}
