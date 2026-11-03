import {
  Inject,
  Injectable,
  NotFoundException,
  UnauthorizedException,
} from '@nestjs/common';
import * as crypto from 'crypto';
import {
  buildAdminServiceStaff,
  resolveAdminServiceEmail,
} from '../../common/config/admin-identity';
import { paginateInMemory, PaginatedResult, toListQuery } from '../../common/listing/list-query';
import { SecurityTokenService } from '../../common/services/security-token.service';
import { BusinessRuleError, EntityNotFoundError } from '../../domain/domain-errors';
import {
  FlightTransfer,
  OperationalAlert,
  StaffMember,
  StayAggregate,
  StayLifecycleStatus,
  StayRecord,
} from '../../domain/models/domain.models';
import {
  ALERT_REPOSITORY_PORT,
  AlertRepositoryPort,
  STAFF_REPOSITORY_PORT,
  StaffRepositoryPort,
  STAY_REPOSITORY_PORT,
  StayRepositoryPort,
  VILLA_REPOSITORY_PORT,
  VillaRepositoryPort,
} from '../../domain/ports/repository.ports';
import { nightsBetween, buildNewStay } from './new-stay.builder';
import {
  AdminLoginDto,
  AlertListQueryDto,
  AssignTransferDto,
  CreateReservationDto,
  StaffListQueryDto,
  StayListQueryDto,
  UpdateStayWifiDto,
} from './dto/admin.dto';

const STAY_LIST_SPEC = {
  sortable: ['checkInDate'],
  defaultSort: { field: 'checkInDate', direction: 'asc' as const },
};
const ALERT_LIST_SPEC = {
  sortable: ['createdAt', 'severity'],
  defaultSort: { field: 'createdAt', direction: 'desc' as const },
};
const STAFF_LIST_SPEC = {
  sortable: ['fullName', 'department'],
  defaultSort: { field: 'fullName', direction: 'asc' as const },
};

@Injectable()
export class AdminService {
  constructor(
    @Inject(STAY_REPOSITORY_PORT) private readonly stayRepo: StayRepositoryPort,
    @Inject(ALERT_REPOSITORY_PORT) private readonly alertRepo: AlertRepositoryPort,
    @Inject(STAFF_REPOSITORY_PORT) private readonly staffRepo: StaffRepositoryPort,
    @Inject(VILLA_REPOSITORY_PORT) private readonly villaRepo: VillaRepositoryPort,
    private readonly securityTokenService: SecurityTokenService,
  ) {}

  /**
   * Silent admin login (plan rule 5): only the technical identity configured in
   * `ADMIN_SERVICE_EMAIL` receives a HOST_ADMIN session. No staff document is required and
   * any other email (or a missing configuration) is rejected.
   */
  loginStaff(dto: AdminLoginDto): { token: string; staff: StaffMember } {
    const configured = resolveAdminServiceEmail();
    if (!configured || dto.email.trim().toLowerCase() !== configured) {
      throw new UnauthorizedException('Invalid staff credentials.');
    }
    const staff = buildAdminServiceStaff(configured);
    return { token: this.securityTokenService.issueStaffToken(staff), staff };
  }

  async listAlerts(dto: AlertListQueryDto): Promise<PaginatedResult<OperationalAlert>> {
    const query = toListQuery(dto, ALERT_LIST_SPEC);
    const listing = await this.alertRepo.listAlerts({
      isAcknowledged: dto.isAcknowledged,
      category: dto.category,
      severity: dto.severity,
      assignedDepartment: dto.assignedDepartment,
    });
    const page = paginateInMemory(listing.alerts, query, {
      searchText: (a) => `${a.title} ${a.summary} ${a.villaName} ${a.guestNames}`,
      sortValue: (a, field) => (field === 'severity' ? a.severity : a.createdAt),
    });
    return new PaginatedResult(page.data, page.meta, { unreadCount: listing.unreadCount });
  }

  async acknowledgeAlert(alertId: string, staff: StaffMember): Promise<OperationalAlert> {
    const updated = await this.alertRepo.acknowledgeAlert(alertId, staff.staffId);
    if (!updated) throw new NotFoundException(`Operational alert ${alertId} not found.`);
    return updated;
  }

  listStays(dto: StayListQueryDto): Promise<PaginatedResult<StayAggregate>> {
    const query = toListQuery(dto, STAY_LIST_SPEC);
    return this.stayRepo.pageStays({
      status: dto.status,
      villaId: dto.villaId,
      from: dto.from,
      to: dto.to,
      q: query.q,
      page: query.page,
      pageSize: query.pageSize,
      direction: query.sort.direction,
    });
  }

  async createReservation(
    dto: CreateReservationDto,
  ): Promise<{ stay: StayAggregate; magicLinkUrl: string }> {
    const villa = await this.villaRepo.findById(dto.villaId);
    if (!villa) throw new EntityNotFoundError('Villa', dto.villaId);
    if (!villa.isActive) throw new BusinessRuleError(`Villa ${villa.name} is inactive`);
    if (nightsBetween(dto.checkIn, dto.checkOut) < 1) throw new BusinessRuleError('checkOut must be after checkIn');
    if (dto.guestsCount && dto.guestsCount > villa.capacity) {
      throw new BusinessRuleError(`Villa ${villa.name} hosts at most ${villa.capacity} guests`);
    }
    const newUuid = crypto.randomUUID();
    const magicLinkUrl = `${guestPortalBaseUrl()}/?guestId=${newUuid}`;
    const newStay = buildNewStay(dto, villa, {
      stayId: `stay_${crypto.randomUUID()}`,
      guestTokenUuid: newUuid,
      magicLinkUrl,
      now: new Date().toISOString(),
    });
    const created = await this.stayRepo.createStay(newStay);
    return { stay: created, magicLinkUrl };
  }

  async updateStayStatus(stayId: string, status: StayLifecycleStatus): Promise<StayRecord> {
    await this.requireStay(stayId);
    return this.stayRepo.updateStayStatus(stayId, status);
  }

  async updateStayWifi(stayId: string, dto: UpdateStayWifiDto): Promise<StayRecord> {
    const existing = await this.requireStay(stayId);
    return this.stayRepo.updateStayWifi(stayId, {
      wifiSsid: dto.wifiSsid?.trim() || existing.villaAccess.wifiSsid,
      wifiPasscode: dto.wifiPasscode?.trim() || existing.villaAccess.wifiPasscode,
    });
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

  async updateStayTransfer(stayId: string, dto: AssignTransferDto): Promise<FlightTransfer> {
    const existing = await this.requireStay(stayId);
    const driverName =
      dto.assignedStaffName ?? dto.assignedDriver ?? existing.flightTransfer.assignedDriver;
    return this.stayRepo.updateTransfer(stayId, {
      assignedStaffId: dto.assignedStaffId ?? existing.flightTransfer.assignedStaffId,
      assignedStaffName: driverName,
      assignedDriver: driverName,
      vehicleModel: dto.vehicleModel ?? existing.flightTransfer.vehicleModel,
      meetingPoint: dto.meetingPoint ?? existing.flightTransfer.meetingPoint,
      status: dto.status || existing.flightTransfer.status,
      adminDispatchNotes: dto.adminDispatchNotes ?? existing.flightTransfer.adminDispatchNotes,
      notifiedAt: new Date().toISOString(),
    });
  }

  async listStaff(dto: StaffListQueryDto): Promise<PaginatedResult<StaffMember>> {
    const query = toListQuery(dto, STAFF_LIST_SPEC);
    const staff = await this.staffRepo.listStaff(dto.department);
    return paginateInMemory(staff, query, {
      searchText: (s) => `${s.fullName} ${s.email} ${s.role}`,
      sortValue: (s, field) => (field === 'department' ? s.department : s.fullName),
    });
  }

  private async requireStay(stayId: string): Promise<StayAggregate> {
    const existing = await this.stayRepo.findByStayId(stayId);
    if (!existing) throw new NotFoundException(`Stay ${stayId} not found.`);
    return existing;
  }
}

/** Base URL of the guest portal used in magic links (deployment configuration). */
function guestPortalBaseUrl(): string {
  return (process.env.GUEST_PORTAL_URL || 'http://localhost:3000').replace(/\/$/, '');
}
