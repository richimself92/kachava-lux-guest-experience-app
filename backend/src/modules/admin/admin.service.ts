import {
  ForbiddenException,
  Inject,
  Injectable,
  NotFoundException,
  UnauthorizedException,
} from '@nestjs/common';
import { isAdminResetAllowed } from '../../common/config/runtime-flags';
import * as crypto from 'crypto';
import { SecurityTokenService } from '../../common/services/security-token.service';
import {
  AlertCategory,
  AlertSeverity,
  Department,
  FlightTransfer,
  OperationalAlert,
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
import { AdminFulfillmentService } from './admin-fulfillment.service';
import { buildNewStay } from './new-stay.builder';
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

  /**
   * Email-only staff login, pending owner decision (Firebase Auth vs staff passcodes):
   * any rostered email receives a staff token; `passcode`/`password` are accepted but NOT checked.
   */
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
    const stayId = `stay_${crypto.randomUUID()}`;
    const newStay = buildNewStay(dto, {
      stayId,
      guestTokenUuid: newUuid,
      magicLinkUrl,
      now: new Date().toISOString(),
    });
    const created = await this.stayRepo.createStay(newStay);
    return { stay: created, magicLinkUrl };
  }

  async updateStayStatus(stayId: string, status: StayLifecycleStatus): Promise<StayRecord> {
    const existing = await this.stayRepo.findByStayId(stayId);
    if (!existing) throw new NotFoundException(`Stay ${stayId} not found.`);
    const updated = await this.stayRepo.updateStayStatus(stayId, status);
    return updated;
  }

  async updateStayWifi(stayId: string, dto: UpdateStayWifiDto): Promise<StayRecord> {
    const existing = await this.stayRepo.findByStayId(stayId);
    if (!existing) throw new NotFoundException(`Stay ${stayId} not found.`);
    const updated = await this.stayRepo.updateStayWifi(stayId, {
      wifiSsid: dto.wifiSsid?.trim() || existing.villaAccess.wifiSsid,
      wifiPasscode: dto.wifiPasscode?.trim() || existing.villaAccess.wifiPasscode,
    });
    return updated;
  }

  async resetAllData(): Promise<{ reset: boolean }> {
    if (!isAdminResetAllowed()) {
      throw new ForbiddenException('Data reset is disabled in this environment.');
    }
    await this.stayRepo.resetAllStays();
    await this.alertRepo.resetAllAlerts();
    return { reset: true };
  }

  async regenerateStayToken(
    stayId: string,
  ): Promise<{ stayId: string; guestTokenUuid: string; magicLinkUrl: string }> {
    const existing = await this.stayRepo.findByStayId(stayId);
    if (!existing) throw new NotFoundException(`Stay ${stayId} not found.`);
    const newUuid = crypto.randomUUID();
    const updated: StayRecord = await this.stayRepo.updateStayToken(stayId, newUuid);
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
