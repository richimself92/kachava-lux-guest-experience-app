import {
  BadRequestException,
  Inject,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { ListQueryDto, paginateInMemory, PaginatedResult, toListQuery } from '../../common/listing/list-query';
import {
  ConciergeMessage,
  ConciergeRequest,
  ExperienceBooking,
  LarderOrderItem,
  MidStayFeedback,
  StaffMember,
  StayLifecycleStatus,
} from '../../domain/models/domain.models';
import {
  SignedUrlResult,
  STAY_REPOSITORY_PORT,
  StayRepositoryPort,
  STORAGE_SIGNER_PORT,
  StorageSignerPort,
} from '../../domain/ports/repository.ports';
import {
  ApproveCheckoutDto,
  AssignBookingDto,
  BookingListQueryDto,
  ConciergeListQueryDto,
  LarderOrderListQueryDto,
  UpdateAdminConciergeDto,
  UpdateLarderStatusDto,
} from './dto/admin.dto';

const BOOKING_LIST_SPEC = {
  sortable: ['scheduledDate', 'createdAt', 'status'],
  defaultSort: { field: 'scheduledDate', direction: 'asc' as const },
};
const LARDER_LIST_SPEC = {
  sortable: ['updatedAt', 'name', 'villaName'],
  defaultSort: { field: 'updatedAt', direction: 'desc' as const },
};
const CONCIERGE_LIST_SPEC = {
  sortable: ['createdAt', 'priority', 'status'],
  defaultSort: { field: 'createdAt', direction: 'desc' as const },
};
const FEEDBACK_LIST_SPEC = {
  sortable: ['createdAt', 'rating'],
  defaultSort: { field: 'createdAt', direction: 'desc' as const },
};

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
    @Inject(STORAGE_SIGNER_PORT)
    private readonly storageSigner: StorageSignerPort,
  ) {}

  async listBookings(dto: BookingListQueryDto): Promise<PaginatedResult<ExperienceBooking>> {
    const query = toListQuery(dto, BOOKING_LIST_SPEC);
    const bookings = await this.stayRepo.listBookingsAcrossStays({
      section: dto.section,
      usageType: dto.usageType,
      status: dto.status,
      assignedDepartment: dto.assignedDepartment,
      scheduledDate: dto.scheduledDate,
    });
    return paginateInMemory(bookings, query, {
      searchText: (b) => `${b.title} ${b.guestNames} ${b.villaName}`,
      sortValue: (b, field) => b[field as 'scheduledDate' | 'createdAt' | 'status'],
    });
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
    return updated;
  }

  async listLarderOrders(dto: LarderOrderListQueryDto): Promise<PaginatedResult<LarderOrderItem>> {
    const query = toListQuery(dto, LARDER_LIST_SPEC);
    const orders = await this.stayRepo.listLarderOrdersAcrossStays({
      provisioningStatus: dto.provisioningStatus,
      category: dto.category,
      villaId: dto.villaId,
    });
    return paginateInMemory(orders, query, {
      searchText: (o) => `${o.name} ${o.guestNames} ${o.villaName}`,
      sortValue: (o, field) => o[field as 'updatedAt' | 'name' | 'villaName'],
    });
  }

  async updateLarderOrderStatus(
    orderId: string,
    dto: UpdateLarderStatusDto,
  ): Promise<LarderOrderItem> {
    const statusValue = dto.provisioningStatus || dto.status;
    if (!statusValue) throw new BadRequestException('provisioningStatus is required.');
    const updated = await this.stayRepo.updateLarderOrderStatus(orderId, {
      assignedStaffId: dto.assignedStaffId,
      assignedStaffName: dto.assignedStaffName,
      provisioningStatus: statusValue,
      assignedAt: new Date().toISOString(),
    });
    if (!updated) {
      throw new NotFoundException(`Larder order item ${orderId} not found.`);
    }
    return updated;
  }

  async listConciergeRequests(dto: ConciergeListQueryDto): Promise<PaginatedResult<ConciergeRequest>> {
    const query = toListQuery(dto, CONCIERGE_LIST_SPEC);
    const requests = await this.stayRepo.listConciergeRequestsAcrossStays({
      status: dto.status,
      priority: dto.priority,
      assignedDepartment: dto.assignedDepartment,
      category: dto.category,
      villaId: dto.villaId,
    });
    return paginateInMemory(requests, query, {
      searchText: (r) => `${r.title} ${r.details} ${r.guestNames} ${r.villaName}`,
      sortValue: (r, field) => r[field as 'createdAt' | 'priority' | 'status'],
    });
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
    return updated;
  }

  async generateConciergePhotoGetUrl(
    requestId: string,
  ): Promise<SignedUrlResult> {
    const req = await this.stayRepo.findConciergeRequestById(requestId);
    if (!req) {
      throw new NotFoundException(`Concierge request ${requestId} not found.`);
    }
    if (!req.photoStoragePath) {
      throw new NotFoundException(`Concierge request ${requestId} has no photo.`);
    }
    return this.storageSigner.generateSignedGetUrl(req.photoStoragePath);
  }

  async listMidStayFeedback(dto: ListQueryDto): Promise<PaginatedResult<MidStayFeedback>> {
    const query = toListQuery(dto, FEEDBACK_LIST_SPEC);
    const feedback = await this.stayRepo.listMidStayFeedbackAcrossStays();
    return paginateInMemory(feedback, query, {
      searchText: (f) => `${f.note} ${f.guestNames} ${f.villaName}`,
      sortValue: (f, field) => (field === 'rating' ? f.rating ?? null : f.createdAt),
    });
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
    const result = await this.stayRepo.settleFolio(stayId, {
      settledAt: new Date().toISOString(),
      status: 'CHECKED_OUT',
      lateCheckoutRequested: dto.approveLateCheckout,
      approvedByStaffId: staff.staffId,
      keepFirstCheckoutTime: true,
    });
    return {
      stayId,
      status: result.status,
      approvedByStaffId: staff.staffId,
      lateCheckoutApproved: Boolean(dto.approveLateCheckout),
    };
  }
}
