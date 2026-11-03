import {
  Inject,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import * as crypto from 'crypto';
import { SettledFolio } from '../../domain/folio-ledger';
import {
  ConciergeRequest,
  MidStayFeedback,
  OperationalAlert,
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
    private readonly alerts: GuestAlertFolioHelper,
  ) {}

  async createConciergeRequest(
    stay: StayAggregate,
    dto: CreateConciergeRequestDto,
  ): Promise<ConciergeRequest> {
    const request = this.buildConciergeTicket(stay, dto);
    return this.stayRepo.createConciergeRequest(stay.stayId, request, () =>
      this.alerts.buildAlert(stay, {
        category: 'CONCIERGE',
        severity: request.priority,
        title: `${stay.villaName} Concierge Ticket: ${request.title}`,
        summary: request.details,
        sourceDocumentPath: `stays/${stay.stayId}/concierge_requests/${request.requestId}`,
        assignedDepartment: request.assignedDepartment,
      }),
    );
  }

  async appendConciergeMessage(
    stay: StayAggregate,
    requestId: string,
    dto: CreateConciergeMessageDto,
  ): Promise<ConciergeRequest> {
    const message = {
      sender: 'GUEST' as const,
      senderName: dto.senderName || stay.guestProfile.name,
      text: dto.text,
      sentAt: new Date().toISOString(),
    };
    const updated = await this.stayRepo.appendConciergeMessage(
      stay.stayId,
      requestId,
      message,
      (found) => (found ? this.chatMessageAlert(stay, requestId, dto.text) : null),
    );
    if (!updated) {
      throw new NotFoundException(`Concierge request ${requestId} not found.`);
    }
    return updated;
  }

  /** Every guest message is an ACTION notification that opens the stay's conversation. */
  private chatMessageAlert(stay: StayAggregate, requestId: string, text: string): OperationalAlert {
    return {
      ...this.chatMessageAlertBase(stay, requestId, text),
      event: 'GUEST_MESSAGE',
      targetRef: { type: 'CONVERSATION', id: stay.stayId },
    };
  }

  private chatMessageAlertBase(stay: StayAggregate, requestId: string, text: string): OperationalAlert {
    return this.alerts.buildAlert(stay, {
      category: 'CONCIERGE',
      severity: 'HIGH',
      title: `${stay.villaName} New Chat Message from ${stay.guestProfile.name}`,
      summary: text,
      sourceDocumentPath: `stays/${stay.stayId}/concierge_requests/${requestId}`,
      assignedDepartment: 'CONCIERGE',
    });
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
    return this.stayRepo.createMidStayFeedback(stay.stayId, feedback, () =>
      this.alerts.buildAlert(stay, {
        category: 'MIDSTAY',
        severity: isUrgent ? 'URGENT' : 'NORMAL',
        title: isUrgent
          ? `[< 7 Min SLA] ${stay.villaName} Urgent Mid-Stay Recovery (${sentiment})`
          : `${stay.villaName} Mid-Stay Check-In (${sentiment})`,
        summary: feedback.note || `Aspects: ${feedback.selectedAspects.join(', ')}`,
        sourceDocumentPath: `stays/${stay.stayId}/midstay_feedback/${feedback.feedbackId}`,
        assignedDepartment: 'CONCIERGE',
      }),
    );
  }

  private buildMidStayFeedback(
    stay: StayAggregate,
    dto: CreateMidStayCheckInDto,
    sentiment: MidStayFeedback['selectedSentiment'],
  ): MidStayFeedback {
    return {
      feedbackId: `fb_${crypto.randomUUID()}`,
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
      handledByStaffId: null,
      createdAt: new Date().toISOString(),
    };
  }

  /** Settles the folio as stored at commit time; the guest's snapshot only identifies the stay. */
  processExpressCheckout(stay: StayAggregate, dto: ExpressCheckoutDto): Promise<SettledFolio> {
    const settlement = {
      settledAt: new Date().toISOString(),
      lateCheckoutRequested: dto.lateCheckoutRequested,
    };
    return this.stayRepo.settleFolio(stay.stayId, settlement, (settled) =>
      this.alerts.buildAlert(stay, {
        category: 'CHECKOUT',
        severity: 'HIGH',
        title: `${stay.villaName} Express Checkout Initiated ($${settled.folioSummary.finalSettledTotalUSD} USD)`,
        summary: dto.lateCheckoutRequested
          ? `Guest requested late checkout${dto.requestedCheckoutTime ? ` (${dto.requestedCheckoutTime})` : ''} and settled the folio.`
          : 'Guest completed express checkout.',
        sourceDocumentPath: `stays/${stay.stayId}`,
        assignedDepartment: 'CONCIERGE',
      }),
    );
  }

  private buildConciergeTicket(
    stay: StayAggregate,
    dto: CreateConciergeRequestDto,
  ): ConciergeRequest {
    const now = new Date().toISOString();
    const isIssue = dto.type === 'issue';
    const text = dto.details || dto.title;
    return {
      requestId: `req_${crypto.randomUUID()}`,
      stayId: stay.stayId, villaId: stay.villaId, villaName: stay.villaName,
      guestNames: stay.guestProfile.name,
      type: dto.type || 'request', category: dto.category || 'Concierge',
      priority: isIssue ? 'URGENT' : 'NORMAL', title: dto.title,
      timeLabel: 'Requested just now',
      location: dto.location || `${stay.villaName} — ${stay.suiteName}`,
      status: 'Requested', currentStep: 1,
      assignedStaffId: null,
      assignedTo: '',
      assignedDepartment: isIssue ? 'ENGINEERING' : 'CONCIERGE',
      assignedAt: now, notifiedAt: now,
      details: text, notes: '',
      photoStoragePath: dto.photoStoragePath || null, isCompleted: false,
      messages: [{ sender: 'GUEST', senderName: stay.guestProfile.name, text, sentAt: now }],
      createdAt: now, updatedAt: now,
    };
  }
}
