import {
  BadRequestException,
  Inject,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import * as crypto from 'crypto';
import { BusinessRuleError } from '../../domain/domain-errors';
import { isStayPhotoPath } from '../../domain/stays/guest-request-rules';
import {
  ConciergeMessage,
  ConciergeRequest,
  MidStayFeedback,
  OperationalAlert,
  StayAggregate,
} from '../../domain/models/domain.models';
import {
  SignedPhotoUpload,
  STAY_REPOSITORY_PORT,
  StayRepositoryPort,
  STORAGE_SIGNER_PORT,
  StorageSignerPort,
} from '../../domain/ports/repository.ports';
import {
  CreateConciergeMessageDto,
  CreateConciergeRequestDto,
  CreateMidStayCheckInDto,
  GenerateUploadUrlDto,
} from './dto/guest.dto';
import { GuestAlertFolioHelper } from './guest-alert-folio.helper';

/** Staff-facing alert text of a message that only carries a photo. */
const PHOTO_ALERT_SUMMARY = 'Photo';

/** A guest may only attach photos uploaded to the stay's own private concierge folder. */
function assertOwnPhoto(stay: StayAggregate, path: string | undefined): void {
  if (path && !isStayPhotoPath(stay.stayId, path)) {
    throw new BusinessRuleError('photoStoragePath must come from this stay\'s upload-url');
  }
}

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
    assertOwnPhoto(stay, dto.photoStoragePath);
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
    const text = (dto.text ?? '').trim();
    if (!text && !dto.photoStoragePath) throw new BadRequestException('A message needs text or a photo.');
    assertOwnPhoto(stay, dto.photoStoragePath);
    const message: ConciergeMessage = {
      sender: 'GUEST',
      senderName: dto.senderName || stay.guestProfile.name,
      text,
      sentAt: new Date().toISOString(),
      ...(dto.photoStoragePath ? { photoStoragePath: dto.photoStoragePath } : {}),
    };
    const updated = await this.stayRepo.appendConciergeMessage(
      stay.stayId,
      requestId,
      message,
      (found) => (found ? this.chatMessageAlert(stay, requestId, text || PHOTO_ALERT_SUMMARY) : null),
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
  ): Promise<SignedPhotoUpload> {
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
