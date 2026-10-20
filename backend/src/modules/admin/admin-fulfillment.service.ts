import {
  Inject,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { GuestTokenGuard } from '../../common/guards/guest-token.guard';
import {
  ConciergeMessage,
  ConciergeRequest,
  ExperienceBooking,
  LarderOrderItem,
  StaffMember,
  StayLifecycleStatus,
} from '../../domain/models/domain.models';
import {
  BookingFilterCriteria,
  CATALOG_REPOSITORY_PORT,
  CatalogRepositoryPort,
  ConciergeFilterCriteria,
  LarderFilterCriteria,
  SignedUrlResult,
  STAY_REPOSITORY_PORT,
  StayRepositoryPort,
  STORAGE_SIGNER_PORT,
  StorageSignerPort,
} from '../../domain/ports/repository.ports';
import {
  ApproveCheckoutDto,
  AssignBookingDto,
  CreateExperienceCatalogDto,
  CreateLarderCatalogDto,
  UpdateAdminConciergeDto,
  UpdateLarderStatusDto,
} from './dto/admin.dto';

const STEP_MAP: Record<ConciergeRequest['status'], 1 | 2 | 3 | 4> = {
  Requested: 1,
  Assigned: 2,
  'In Progress': 3,
  Completed: 4,
};

@Injectable()
export class AdminFulfillmentService {
  constructor(
    @Inject(STAY_REPOSITORY_PORT)
    private readonly stayRepo: StayRepositoryPort,
    @Inject(CATALOG_REPOSITORY_PORT)
    private readonly catalogRepo: CatalogRepositoryPort,
    @Inject(STORAGE_SIGNER_PORT)
    private readonly storageSigner: StorageSignerPort,
  ) {}

  listCatalogExperiences() {
    return this.catalogRepo.getExperiencesCatalog();
  }

  createCatalogExperience(dto: CreateExperienceCatalogDto) {
    return this.catalogRepo.createExperienceCatalogItem(dto);
  }

  deleteCatalogExperience(id: string) {
    return this.catalogRepo.deleteExperienceCatalogItem(id);
  }

  listCatalogLarder() {
    return this.catalogRepo.getLarderCatalog();
  }

  createCatalogLarder(dto: CreateLarderCatalogDto) {
    return this.catalogRepo.createLarderCatalogItem(dto);
  }

  deleteCatalogLarder(id: string) {
    return this.catalogRepo.deleteLarderCatalogItem(id);
  }

  listBookings(filter: BookingFilterCriteria) {
    return this.stayRepo.listBookingsAcrossStays(filter);
  }

  async assignBooking(
    bookingId: string,
    dto: AssignBookingDto,
  ): Promise<ExperienceBooking> {
    const now = new Date().toISOString();
    const updated = await this.stayRepo.updateBookingAssignment(bookingId, {
      ...dto,
      cancellationReason: dto.cancellationReason,
      assignedAt: now,
      notifiedAt: now,
    });
    if (!updated) {
      throw new NotFoundException(`Booking ${bookingId} not found.`);
    }
    GuestTokenGuard.invalidateCache();
    return updated;
  }

  listLarderOrders(filter: LarderFilterCriteria) {
    return this.stayRepo.listLarderOrdersAcrossStays(filter);
  }

  async updateLarderOrderStatus(
    orderId: string,
    dto: UpdateLarderStatusDto,
  ): Promise<LarderOrderItem> {
    const statusValue = dto.provisioningStatus || dto.status || 'Stocked in Villa';
    const updated = await this.stayRepo.updateLarderOrderStatus(orderId, {
      assignedStaffId: dto.assignedStaffId,
      assignedStaffName: dto.assignedStaffName,
      provisioningStatus: statusValue,
      assignedAt: new Date().toISOString(),
    });
    if (!updated) {
      throw new NotFoundException(`Larder order item ${orderId} not found.`);
    }
    GuestTokenGuard.invalidateCache();
    return updated;
  }

  listConciergeRequests(filter: ConciergeFilterCriteria) {
    return this.stayRepo.listConciergeRequestsAcrossStays(filter);
  }

  async updateConciergeRequest(
    requestId: string,
    dto: UpdateAdminConciergeDto,
    staff: StaffMember,
  ): Promise<ConciergeRequest> {
    const now = new Date().toISOString();
    const step = dto.currentStep || (dto.status ? STEP_MAP[dto.status] : undefined);
    const replyText = dto.replyMessage || dto.message;
    const chatMessage: ConciergeMessage | undefined = replyText
      ? {
          sender: 'CONCIERGE',
          senderStaffId: staff.staffId,
          senderName: staff.shortName || staff.fullName,
          text: replyText,
          sentAt: now,
        }
      : undefined;

    const patch: Partial<ConciergeRequest> = {
      ...(dto.status ? { status: dto.status } : {}),
      ...(step ? { currentStep: step, isCompleted: step === 4 } : {}),
      ...(dto.assignedStaffId ? { assignedStaffId: dto.assignedStaffId } : {}),
      ...(dto.assignedTo ? { assignedTo: dto.assignedTo } : {}),
      ...(dto.assignedDepartment ? { assignedDepartment: dto.assignedDepartment } : {}),
      ...(dto.notes ? { notes: dto.notes } : {}),
      assignedAt: now,
      notifiedAt: now,
    };

    const updated = await this.stayRepo.updateConciergeRequestAdmin(
      requestId,
      patch,
      chatMessage,
    );
    if (!updated) {
      throw new NotFoundException(`Concierge request ${requestId} not found.`);
    }
    GuestTokenGuard.invalidateCache();
    return updated;
  }

  async generateConciergePhotoGetUrl(
    requestId: string,
  ): Promise<SignedUrlResult> {
    const req = await this.stayRepo.findConciergeRequestById(requestId);
    if (!req) {
      throw new NotFoundException(`Concierge request ${requestId} not found.`);
    }
    const path =
      req.photoStoragePath ||
      `/private/stays/${req.stayId}/concierge/${requestId}/attachment.jpg`;
    return this.storageSigner.generateSignedGetUrl(path);
  }

  listMidStayFeedback() {
    return this.stayRepo.listMidStayFeedbackAcrossStays();
  }

  async approveCheckout(
    stayId: string,
    dto: ApproveCheckoutDto,
    staff: StaffMember,
  ): Promise<{
    stayId: string;
    status: StayLifecycleStatus;
    approvedByStaffId: string;
    lateCheckoutApproved: boolean;
  }> {
    const stay = await this.stayRepo.findByStayId(stayId);
    if (!stay) {
      throw new NotFoundException(`Stay ${stayId} not found.`);
    }
    const now = new Date().toISOString();
    const updatedSummary = {
      ...stay.folioSummary,
      paymentStatus: 'SETTLED' as const,
      isCheckedOut: true,
      checkedOutAt: stay.folioSummary.checkedOutAt || now,
      approvedByStaffId: staff.staffId,
    };
    const settledItems = stay.folioItems.map((fi) => ({
      ...fi,
      status: 'SETTLED' as const,
    }));
    const result = await this.stayRepo.updateFolioAndStatus(
      stayId,
      updatedSummary,
      settledItems,
      'CHECKED_OUT',
      dto.approveLateCheckout,
    );
    GuestTokenGuard.invalidateCache();
    return {
      stayId,
      status: result.status,
      approvedByStaffId: staff.staffId,
      lateCheckoutApproved: Boolean(dto.approveLateCheckout),
    };
  }
}
