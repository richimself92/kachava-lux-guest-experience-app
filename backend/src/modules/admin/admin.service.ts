import { Inject, Injectable, NotFoundException, UnauthorizedException } from '@nestjs/common';
import * as crypto from 'crypto';
import { GuestTokenGuard } from '../../common/guards/guest-token.guard';
import { SecurityTokenService } from '../../common/services/security-token.service';
import {
  AlertCategory,
  AlertSeverity,
  Department,
  FlightTransfer,
  OperationalAlert,
  Personalization,
  StaffMember,
  StayAggregate,
  StayLifecycleStatus,
  StayRecord,
} from '../../domain/models/domain.models';
import {
  ALERT_REPOSITORY_PORT,
  AlertFilterCriteria,
  AlertRepositoryPort,
  BookingFilterCriteria,
  ConciergeFilterCriteria,
  LarderFilterCriteria,
  STAFF_REPOSITORY_PORT,
  StaffRepositoryPort,
  STAY_REPOSITORY_PORT,
  StayFilterCriteria,
  StayRepositoryPort,
} from '../../domain/ports/repository.ports';
import { createSeededStayAggregate } from '../../infrastructure/seed/sanctuary-seed.data';
import { AdminFulfillmentService } from './admin-fulfillment.service';
import {
  AdminLoginDto,
  ApproveCheckoutDto,
  AssignBookingDto,
  AssignTransferDto,
  CreateExperienceCatalogDto,
  CreateLarderCatalogDto,
  CreateReservationDto,
  UpdateAdminConciergeDto,
  UpdateLarderStatusDto,
  UpdateStayWifiDto,
} from './dto/admin.dto';

@Injectable()
export class AdminService {
  constructor(
    @Inject(STAY_REPOSITORY_PORT) private readonly stayRepo: StayRepositoryPort,
    @Inject(ALERT_REPOSITORY_PORT) private readonly alertRepo: AlertRepositoryPort,
    @Inject(STAFF_REPOSITORY_PORT) private readonly staffRepo: StaffRepositoryPort,
    private readonly securityTokenService: SecurityTokenService,
    private readonly fulfillmentService: AdminFulfillmentService,
  ) {}

  async loginStaff(dto: AdminLoginDto): Promise<{ token: string; staff: StaffMember }> {
    const staff = await this.staffRepo.findByEmail(dto.email);
    if (!staff) throw new UnauthorizedException('Invalid sanctuary staff credentials.');
    return { token: this.securityTokenService.issueStaffToken(staff), staff };
  }

  listAlerts(filter: AlertFilterCriteria) {
    return this.alertRepo.listAlerts(filter);
  }

  async acknowledgeAlert(alertId: string, staff: StaffMember): Promise<OperationalAlert> {
    const updated = await this.alertRepo.acknowledgeAlert(alertId, staff.staffId);
    if (!updated) throw new NotFoundException(`Operational alert ${alertId} not found.`);
    return updated;
  }

  listStays(filter: StayFilterCriteria) {
    return this.stayRepo.listStays(filter);
  }

  async createReservation(
    dto: CreateReservationDto,
  ): Promise<{ stay: StayAggregate; magicLinkUrl: string }> {
    const newUuid = crypto.randomUUID();
    const baseDomain = (process.env.GUEST_PORTAL_URL || 'http://localhost:3000').replace(/\/$/, '');
    const magicLinkUrl = `${baseDomain}/?guestId=${newUuid}`;
    const newStay = this.buildNewStayAggregate(dto, newUuid, magicLinkUrl);
    const created = await this.stayRepo.createStay(newStay);
    return { stay: created, magicLinkUrl };
  }

  private buildNewStayAggregate(dto: CreateReservationDto, newUuid: string, magicLinkUrl: string): StayAggregate {
    const template = createSeededStayAggregate();
    const villaId = dto.villaId || 'villa-102';
    const villaNum = (dto.villaName || villaId).replace(/[^0-9]/g, '') || '102';
    const celebration = dto.occasion || dto.celebration || 'Sanctuary Residency';
    const now = new Date().toISOString();
    const guestsCount = dto.guestsCount ?? 2;
    return {
      ...template,
      stayId: `stay_${Date.now()}_${villaId}`, guestTokenUuid: newUuid, magicLinkUrl,
      status: 'PRE_ARRIVAL', villaId, villaName: dto.villaName || villaId,
      suiteName: this.extractSuiteName(dto.villaName, dto.suiteName),
      stayDatesLabel: this.resolveStayDatesLabel(dto),
      checkInDate: dto.checkIn || '',
      checkOutDate: dto.checkOut || '',
      nights: this.calculateNights(dto),
      guestsCount,
      guestProfile: this.buildGuestProfile(template, dto, celebration),
      hostInfo: { ...template.hostInfo, name: 'HOST ADMIN', shortName: 'HOST ADMIN', role: 'HOST ADMIN' },
      villaAccess: {
        ...template.villaAccess,
        wifiSsid: dto.wifiSsid?.trim() || `Kachava_Sanctuary_${villaNum}`,
        wifiPasscode: dto.wifiPasscode?.trim() || 'stillness2026',
      },
      flightTransfer: this.buildCleanTransfer(template, guestsCount),
      personalization: this.buildCleanPersonalization(celebration, now),
      folioSummary: { ...template.folioSummary, complimentarySavingsUSD: 0, incidentalsSubtotalUSD: 0, ecologicalLevyUSD: 0, finalSettledTotalUSD: 0, paymentStatus: 'PRE_AUTHORIZED', isCheckedOut: false },
      folioItems: [], larderOrders: [], experienceBookings: [], conciergeRequests: [], midstayFeedback: [],
      createdAt: now, updatedAt: now,
    };
  }

  private calculateNights(dto: CreateReservationDto): number {
    if (typeof dto.nights === 'number' && dto.nights > 0) {
      return dto.nights;
    }
    if (dto.checkIn && dto.checkOut) {
      const normalizeDate = (raw: string) =>
        /\b\d{4}\b/.test(raw) ? raw.trim() : `${raw.trim()}, 2026`;
      const inDate = new Date(normalizeDate(dto.checkIn));
      const outDate = new Date(normalizeDate(dto.checkOut));
      if (!Number.isNaN(inDate.getTime()) && !Number.isNaN(outDate.getTime())) {
        const diffDays = Math.round((outDate.getTime() - inDate.getTime()) / 86400000);
        if (diffDays > 0) return diffDays;
      }
    }
    return 3;
  }

  private buildCleanTransfer(template: StayAggregate, partySize: number): FlightTransfer {
    return {
      ...template.flightTransfer,
      arrivalDate: '', arrivalAirport: '', airline: '', flightNumber: '', terminal: '',
      arrivalTime: '', estimatedLanding: '', partySize,
      luggageCount: 0, luggageChecked: 0, luggageCarryOn: 0, notes: '',
      status: 'Not Requested', assignedStaffId: '', assignedStaffName: '', assignedDriver: '',
      vehicleModel: '', fleetNumber: '', meetingPoint: '', adminDispatchNotes: '',
      departureFlightNumber: '', departureRoute: '', departureTimeLabel: '',
      lateCheckoutRequested: false, notifiedAt: null,
    };
  }

  private buildCleanPersonalization(celebration: string, now: string): Personalization {
    return {
      currentStep: 1,
      tripPurpose: celebration,
      occasionDetails: '',
      selectedInterests: [],
      dietary: '',
      dietaryAllergies: [],
      allergies: '',
      villaScent: '',
      scentProfile: '',
      pillowType: '',
      pillowSelection: '',
      temperatureCurve: '',
      lightingRhythm: '',
      housekeepingCadence: '',
      commChannel: 'WhatsApp',
      updatedAt: now,
    };
  }

  private buildGuestProfile(template: StayAggregate, dto: CreateReservationDto, celebration: string) {
    const lastName = dto.guestName.trim().split(/\s+/).pop()?.toLowerCase() || 'guest';
    return {
      ...template.guestProfile,
      name: dto.guestName,
      lastNameNormalized: lastName,
      partner: dto.partnerName || '',
      celebration,
      folioCard: 'On File',
      dietaryProfile: '',
      allergies: '',
      inVillaBar: '',
      email: dto.email || '',
      phone: dto.phone || '',
    };
  }

  private resolveStayDatesLabel(dto: CreateReservationDto): string {
    if (dto.checkIn && dto.checkOut) return `${dto.checkIn} – ${dto.checkOut}`;
    return dto.stayDatesLabel || 'Dec 01–05, 2026';
  }

  private extractSuiteName(villaName?: string, suiteName?: string): string {
    if (suiteName?.trim()) return suiteName.trim();
    if (villaName && (villaName.includes('—') || villaName.includes('-'))) {
      const extracted = villaName.split(/—|-/).slice(1).join('-').trim();
      if (extracted) return extracted;
    }
    return 'Sanctuary Villa';
  }

  async updateStayStatus(stayId: string, status: StayLifecycleStatus): Promise<StayRecord> {
    const existing = await this.stayRepo.findByStayId(stayId);
    if (!existing) throw new NotFoundException(`Stay ${stayId} not found.`);
    const updated = await this.stayRepo.updateStayStatus(stayId, status);
    GuestTokenGuard.invalidateCache();
    return updated;
  }

  async updateStayWifi(stayId: string, dto: UpdateStayWifiDto): Promise<StayRecord> {
    const existing = await this.stayRepo.findByStayId(stayId);
    if (!existing) throw new NotFoundException(`Stay ${stayId} not found.`);
    const updated = await this.stayRepo.updateStayWifi(stayId, {
      wifiSsid: dto.wifiSsid?.trim() || existing.villaAccess.wifiSsid,
      wifiPasscode: dto.wifiPasscode?.trim() || existing.villaAccess.wifiPasscode,
    });
    GuestTokenGuard.invalidateCache();
    return updated;
  }

  async resetAllData(): Promise<{ reset: boolean }> {
    await this.stayRepo.resetAllStays();
    await this.alertRepo.resetAllAlerts();
    GuestTokenGuard.invalidateCache();
    return { reset: true };
  }

  async regenerateStayToken(
    stayId: string,
  ): Promise<{ stayId: string; guestTokenUuid: string; magicLinkUrl: string }> {
    const existing = await this.stayRepo.findByStayId(stayId);
    if (!existing) throw new NotFoundException(`Stay ${stayId} not found.`);
    const newUuid = crypto.randomUUID();
    const updated: StayRecord = await this.stayRepo.updateStayToken(stayId, newUuid);
    GuestTokenGuard.invalidateCache();
    const baseDomain = process.env.GUEST_PORTAL_URL || 'http://localhost:3000';
    return {
      stayId: updated.stayId,
      guestTokenUuid: updated.guestTokenUuid,
      magicLinkUrl: `${baseDomain}/?guestId=${newUuid}`,
    };
  }

  async updateStayTransfer(stayId: string, dto: AssignTransferDto): Promise<FlightTransfer> {
    const existing = await this.stayRepo.findByStayId(stayId);
    if (!existing) throw new NotFoundException(`Stay ${stayId} not found.`);
    const driverName =
      dto.assignedStaffName ?? dto.assignedDriver ?? existing.flightTransfer.assignedDriver;
    const updated = await this.stayRepo.updateTransfer(stayId, {
      assignedStaffId: dto.assignedStaffId ?? existing.flightTransfer.assignedStaffId,
      assignedStaffName: driverName,
      assignedDriver: driverName,
      vehicleModel: dto.vehicleModel ?? existing.flightTransfer.vehicleModel,
      meetingPoint: dto.meetingPoint ?? existing.flightTransfer.meetingPoint,
      status: dto.status || existing.flightTransfer.status,
      adminDispatchNotes: dto.adminDispatchNotes ?? existing.flightTransfer.adminDispatchNotes,
      notifiedAt: new Date().toISOString(),
    });
    GuestTokenGuard.invalidateCache();
    return updated;
  }

  listCatalogExperiences() { return this.fulfillmentService.listCatalogExperiences(); }
  createCatalogExperience(dto: CreateExperienceCatalogDto) { return this.fulfillmentService.createCatalogExperience(dto); }
  deleteCatalogExperience(id: string) { return this.fulfillmentService.deleteCatalogExperience(id); }
  listCatalogLarder() { return this.fulfillmentService.listCatalogLarder(); }
  createCatalogLarder(dto: CreateLarderCatalogDto) { return this.addLarderCatalogItem(dto); }
  addLarderCatalogItem(dto: CreateLarderCatalogDto) {
    return this.fulfillmentService.createCatalogLarder({
      ...dto,
      category: dto.category?.trim() || 'Minibar',
    });
  }
  deleteCatalogLarder(id: string) { return this.fulfillmentService.deleteCatalogLarder(id); }
  listBookings(filter: BookingFilterCriteria) { return this.fulfillmentService.listBookings(filter); }
  assignBooking(bookingId: string, dto: AssignBookingDto) { return this.fulfillmentService.assignBooking(bookingId, dto); }
  listLarderOrders(filter: LarderFilterCriteria) { return this.fulfillmentService.listLarderOrders(filter); }
  updateLarderOrderStatus(orderId: string, dto: UpdateLarderStatusDto) { return this.fulfillmentService.updateLarderOrderStatus(orderId, dto); }
  listConciergeRequests(filter: ConciergeFilterCriteria) { return this.fulfillmentService.listConciergeRequests(filter); }
  updateConciergeRequest(requestId: string, dto: UpdateAdminConciergeDto, staff: StaffMember) { return this.fulfillmentService.updateConciergeRequest(requestId, dto, staff); }
  generateConciergePhotoGetUrl(requestId: string) { return this.fulfillmentService.generateConciergePhotoGetUrl(requestId); }
  listMidStayFeedback() { return this.fulfillmentService.listMidStayFeedback(); }
  approveCheckout(stayId: string, dto: ApproveCheckoutDto, staff: StaffMember) { return this.fulfillmentService.approveCheckout(stayId, dto, staff); }
  listStaff(department?: string) { return this.staffRepo.listStaff(department); }

  parseAlertQuery(query: Record<string, string | undefined>): AlertFilterCriteria {
    return {
      isAcknowledged: query.isAcknowledged !== undefined ? query.isAcknowledged === 'true' : undefined,
      category: query.category as AlertCategory | undefined,
      severity: query.severity as AlertSeverity | undefined,
      assignedDepartment: query.assignedDepartment as Department | undefined,
    };
  }
}
