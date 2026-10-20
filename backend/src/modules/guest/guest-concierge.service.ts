import {
  Inject,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import * as crypto from 'crypto';
import { GuestTokenGuard } from '../../common/guards/guest-token.guard';
import {
  ConciergeRequest,
  FolioItem,
  FolioSummary,
  MidStayFeedback,
  StayAggregate,
} from '../../domain/models/domain.models';
import {
  SignedUrlResult,
  STAY_REPOSITORY_PORT,
  StayRepositoryPort,
  STORAGE_SIGNER_PORT,
  StorageSignerPort,
} from '../../domain/ports/repository.ports';
import {
  CreateConciergeMessageDto,
  CreateConciergeRequestDto,
  CreateMidStayCheckInDto,
  ExpressCheckoutDto,
  GenerateUploadUrlDto,
} from './dto/guest.dto';
import { GuestAlertFolioHelper } from './guest-alert-folio.helper';

@Injectable()
export class GuestConciergeService {
  constructor(
    @Inject(STAY_REPOSITORY_PORT)
    private readonly stayRepo: StayRepositoryPort,
    @Inject(STORAGE_SIGNER_PORT)
    private readonly storageSigner: StorageSignerPort,
    private readonly alertFolioHelper: GuestAlertFolioHelper,
  ) {}

  async createConciergeRequest(
    stay: StayAggregate,
    dto: CreateConciergeRequestDto,
  ): Promise<ConciergeRequest> {
    const request = this.buildConciergeTicket(stay, dto);
    const created = await this.stayRepo.createConciergeRequest(stay.stayId, request);
    GuestTokenGuard.invalidateCache();
    await this.alertFolioHelper.emitAlert(stay, {
      category: 'CONCIERGE',
      severity: request.priority,
      title: `${stay.villaName} Concierge Ticket: ${request.title}`,
      summary: request.details,
      sourceDocumentPath: `stays/${stay.stayId}/concierge_requests/${request.requestId}`,
      assignedDepartment: request.assignedDepartment,
    });
    return created;
  }

  async appendConciergeMessage(
    stay: StayAggregate,
    requestId: string,
    dto: CreateConciergeMessageDto,
  ): Promise<ConciergeRequest> {
    const updated = await this.stayRepo.appendConciergeMessage(stay.stayId, requestId, {
      sender: 'GUEST',
      senderName: dto.senderName || stay.guestProfile.name,
      text: dto.text,
      sentAt: new Date().toISOString(),
    });
    if (!updated) {
      throw new NotFoundException(`Concierge request ${requestId} not found.`);
    }
    GuestTokenGuard.invalidateCache();
    await this.alertFolioHelper.emitAlert(stay, {
      category: 'CONCIERGE',
      severity: 'NORMAL',
      title: `${stay.villaName} New Chat Message from ${stay.guestProfile.name}`,
      summary: dto.text,
      sourceDocumentPath: `stays/${stay.stayId}/concierge_requests/${requestId}`,
      assignedDepartment: 'CONCIERGE',
    });
    return updated;
  }

  generateUploadUrl(
    stay: StayAggregate,
    dto: GenerateUploadUrlDto,
  ): Promise<SignedUrlResult> {
    return this.storageSigner.generateSignedPutUrl({
      stayId: stay.stayId,
      requestId: dto.requestId || `req_${Date.now()}`,
      fileName: dto.fileName,
      contentType: dto.contentType,
      fileSizeBytes: dto.fileSizeBytes,
    });
  }

  async submitMidStayCheckIn(
    stay: StayAggregate,
    dto: CreateMidStayCheckInDto,
  ): Promise<MidStayFeedback> {
    const sentiment =
      dto.selectedSentiment || (dto.rating && dto.rating <= 3 ? 'direct' : 'serene');
    const isUrgent =
      (dto.rating !== undefined && dto.rating <= 3) ||
      sentiment === 'direct' ||
      sentiment === 'tuned';
    const feedback = this.buildMidStayFeedback(stay, dto, sentiment);
    const saved = await this.stayRepo.createMidStayFeedback(stay.stayId, feedback);
    GuestTokenGuard.invalidateCache();
    await this.alertFolioHelper.emitAlert(stay, {
      category: 'MIDSTAY',
      severity: isUrgent ? 'URGENT' : 'NORMAL',
      title: isUrgent
        ? `[< 7 Min SLA] ${stay.villaName} Urgent Mid-Stay Recovery (${sentiment})`
        : `${stay.villaName} Mid-Stay Check-In (${sentiment})`,
      summary: feedback.note || `Aspects: ${feedback.selectedAspects.join(', ')}`,
      sourceDocumentPath: `stays/${stay.stayId}/midstay_feedback/${feedback.feedbackId}`,
      assignedDepartment: 'CONCIERGE',
    });
    return saved;
  }

  private buildMidStayFeedback(
    stay: StayAggregate,
    dto: CreateMidStayCheckInDto,
    sentiment: MidStayFeedback['selectedSentiment'],
  ): MidStayFeedback {
    return {
      feedbackId: `fb_${crypto.randomBytes(4).toString('hex')}`,
      stayId: stay.stayId,
      villaId: stay.villaId,
      villaName: stay.villaName,
      guestNames: stay.guestProfile.name,
      dayOfStay: dto.dayOfStay || 2,
      rating: dto.rating ?? 5,
      selectedSentiment: sentiment,
      selectedAspects: dto.selectedAspects || [],
      housekeepingPreferences: dto.housekeepingPreferences || [],
      note: dto.note || '',
      status: 'DISPATCHED_TO_HOST',
      handledByStaffId: 'staff_eduardo',
      createdAt: new Date().toISOString(),
    };
  }

  async processExpressCheckout(
    stay: StayAggregate,
    dto: ExpressCheckoutDto,
  ): Promise<{ folioSummary: FolioSummary; folioItems: FolioItem[]; status: string }> {
    const settledItems = stay.folioItems.map((i) => ({ ...i, status: 'SETTLED' as const }));
    const updatedSummary: FolioSummary = {
      ...stay.folioSummary,
      paymentStatus: 'SETTLED',
      isCheckedOut: true,
      checkedOutAt: new Date().toISOString(),
    };
    const result = await this.stayRepo.updateFolioAndStatus(
      stay.stayId, updatedSummary, settledItems, stay.status, dto.lateCheckoutRequested,
    );
    GuestTokenGuard.invalidateCache();
    await this.alertFolioHelper.emitAlert(stay, {
      category: 'CHECKOUT',
      severity: 'HIGH',
      title: `${stay.villaName} Express Checkout Initiated ($${updatedSummary.finalSettledTotalUSD} USD)`,
      summary: dto.lateCheckoutRequested
        ? `Guest requested Late Checkout (${dto.requestedCheckoutTime || '2:00 PM'}) and settled folio.`
        : `Guest completed Express Digital Checkout. Chauffeur Carlos M. alerted.`,
      sourceDocumentPath: `stays/${stay.stayId}`,
      assignedDepartment: 'CONCIERGE',
    });
    return result;
  }

  private buildConciergeTicket(
    stay: StayAggregate,
    dto: CreateConciergeRequestDto,
  ): ConciergeRequest {
    const now = new Date().toISOString();
    const isIssue = dto.type === 'issue';
    const text = dto.details || dto.title;
    return {
      requestId: `req_${crypto.randomBytes(4).toString('hex')}`,
      stayId: stay.stayId, villaId: stay.villaId, villaName: stay.villaName,
      guestNames: stay.guestProfile.name,
      type: dto.type || 'request', category: dto.category || 'Concierge',
      priority: isIssue ? 'URGENT' : 'NORMAL', title: dto.title,
      timeLabel: 'Requested just now',
      location: dto.location || `${stay.villaName} — ${stay.suiteName}`,
      status: 'Requested', currentStep: 1,
      assignedStaffId: 'staff_eduardo',
      assignedTo: 'HOST ADMIN',
      assignedDepartment: isIssue ? 'ENGINEERING' : 'CONCIERGE',
      assignedAt: now, notifiedAt: now,
      details: text, notes: 'Received by Concierge Desk.',
      photoStoragePath: dto.photoStoragePath || null, isCompleted: false,
      messages: [{ sender: 'GUEST', senderName: stay.guestProfile.name, text, sentAt: now }],
      createdAt: now, updatedAt: now,
    };
  }
}
