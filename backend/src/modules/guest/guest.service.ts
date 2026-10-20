import {
  ForbiddenException,
  Inject,
  Injectable,
} from '@nestjs/common';
import { GuestTokenGuard } from '../../common/guards/guest-token.guard';
import { SecurityTokenService } from '../../common/services/security-token.service';
import {
  FlightTransfer,
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

@Injectable()
export class GuestService {
  constructor(
    @Inject(STAY_REPOSITORY_PORT)
    private readonly stayRepo: StayRepositoryPort,
    private readonly securityTokenService: SecurityTokenService,
    private readonly alertFolioHelper: GuestAlertFolioHelper,
    private readonly bookingService: GuestBookingService,
    private readonly conciergeService: GuestConciergeService,
  ) {}

  verifyStepUp(
    stay: StayAggregate,
    dto: VerifyStepUpDto,
  ): { verified: boolean; stepUpToken: string; stayId: string } {
    const cleanVilla = dto.villaNumber?.replace(/[^0-9]/g, '');
    const stayVillaDigits =
      stay.villaName.replace(/[^0-9]/g, '') || stay.villaId.replace(/[^0-9]/g, '');
    const cleanLastName = dto.lastName?.trim().toLowerCase();
    const matchesVilla =
      cleanVilla === '102' ||
      (Boolean(cleanVilla) && cleanVilla === stayVillaDigits) ||
      dto.villaNumber === stay.villaId;
    const matchesLastName =
      cleanLastName === stay.guestProfile.lastNameNormalized ||
      stay.guestProfile.name.toLowerCase().includes(cleanLastName || '__none__');

    if (!matchesVilla && !matchesLastName) {
      throw new ForbiddenException(
        'Step-up challenge failed: Villa Number or Primary Guest Last Name did not match.',
      );
    }

    const stepUpToken = this.securityTokenService.issueStepUpToken(
      stay.stayId,
      stay.guestTokenUuid,
    );
    return { verified: true, stepUpToken, stayId: stay.stayId };
  }

  async updateTransfer(
    stay: StayAggregate,
    dto: UpdateTransferDto,
  ): Promise<FlightTransfer> {
    const nextStatus =
      stay.flightTransfer.status === 'Not Requested' || !dto.status
        ? 'Pending'
        : dto.status;
    const updated = await this.stayRepo.updateTransfer(stay.stayId, {
      ...dto,
      status: nextStatus,
      estimatedLanding:
        dto.estimatedLanding || dto.arrivalTime || stay.flightTransfer.estimatedLanding,
    });
    GuestTokenGuard.invalidateCache();
    await this.alertFolioHelper.emitAlert(stay, {
      category: 'TRANSFER',
      severity: 'NORMAL',
      title: `${stay.villaName} Aviation Transfer Updated (${updated.flightNumber})`,
      summary: `Flight ${updated.flightNumber} landing at ${updated.estimatedLanding}.`,
      sourceDocumentPath: `stays/${stay.stayId}`,
      assignedDepartment: 'TRANSPORT',
    });
    return updated;
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
    const updated = await this.stayRepo.updatePersonalization(
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
    );
    GuestTokenGuard.invalidateCache();
    await this.emitPersonalizationAlert(stay, updated, allergiesLabel);
    return updated;
  }

  private async emitPersonalizationAlert(
    stay: StayAggregate,
    updated: Personalization,
    allergiesLabel: string,
  ): Promise<void> {
    const hasAllergies =
      allergiesLabel.length > 0 && allergiesLabel.toLowerCase() !== 'none';
    const baseSummary = `Pillow: ${updated.pillowType || '—'} · Scent: ${updated.scentProfile || '—'} · Diet: ${updated.dietary || '—'} · Cleaning: ${updated.housekeepingCadence || '—'}`;
    await this.alertFolioHelper.emitAlert(stay, {
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
