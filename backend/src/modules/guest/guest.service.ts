import { Inject, Injectable } from '@nestjs/common';
import {
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
  GenerateUploadUrlDto,
  UpdateJourneyDto,
  UpdateServiceOrderDto,
  UpdatePersonalizationDto,
} from './dto/guest.dto';
import { GuestAlertFolioHelper } from './guest-alert-folio.helper';
import { GuestBookingService } from './guest-booking.service';
import { GuestConciergeService } from './guest-concierge.service';

@Injectable()
export class GuestService {
  constructor(
    @Inject(STAY_REPOSITORY_PORT)
    private readonly stayRepo: StayRepositoryPort,
    private readonly alertFolioHelper: GuestAlertFolioHelper,
    private readonly bookingService: GuestBookingService,
    private readonly conciergeService: GuestConciergeService,
  ) {}

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

  updateJourney(stay: StayAggregate, dto: UpdateJourneyDto) {
    return this.stayRepo.setJourneyMarks(stay.stayId, {
      ...(dto.skippedTaskIds ? { skippedTaskIds: dto.skippedTaskIds } : {}),
      ...(dto.completedTaskIds ? { completedTaskIds: dto.completedTaskIds } : {}),
    });
  }

  updateServiceOrder(stay: StayAggregate, serviceId: string, dto: UpdateServiceOrderDto) {
    return this.bookingService.updateServiceOrder(stay, serviceId, dto.items);
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

}
