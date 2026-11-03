import { LarderCharge } from '../../domain/folio-ledger';
import {
  ConciergeMessage,
  ConciergeRequest,
  ExperienceBooking,
  FolioSummary,
  LarderOrderItem,
  MidStayFeedback,
  OperationalAlert,
  Personalization,
  StayAggregate,
  StayLifecycleStatus,
  StayRecord,
} from '../../domain/models/domain.models';
import { PaginatedResult } from '../../common/listing/list-query';
import {
  ConversationPageQuery,
  StayAlertFactory,
  StayPageQuery,
  StayRepositoryPort,
} from '../../domain/ports/repository.ports';
import {
  collectMidStayFeedback,
} from '../../domain/stay-projections';
import { StayDocumentTooLargeError, StayNotFoundError } from '../../domain/stay-errors';
import { MAX_STAY_DOCUMENT_BYTES } from '../../domain/stay-limits';
import * as guestRules from '../../domain/stays/guest-request-rules';
import { BookingChange, JourneyMarks } from '../../domain/stays/guest-request-rules';
import * as mutations from './stay-mutations';
import { applyRequestTransition, RequestMove, RequestRef } from '../../domain/requests/request-transitions';

function nowIso(): string {
  return new Date().toISOString();
}

export { StayNotFoundError };

export type StayMutator<T> = (draft: StayAggregate) => T;

/**
 * Template Method base: every StayRepositoryPort mutation is expressed through a few storage
 * primitives, keeping the business semantics independent of the Firestore adapter.
 * Each stay aggregate is persisted as one document; a mutation rewrites only that document
 * (plus, atomically, the operational alert built by `alertOf`). Mutators run against the
 * stay as stored at commit time and must be re-runnable (transactions may retry them).
 */
export abstract class AggregateStayRepository implements StayRepositoryPort {
  protected abstract findStayByToken(normalizedToken: string): Promise<StayAggregate | null>;
  protected abstract findStay(stayId: string): Promise<StayAggregate | null>;
  /** Open (pre-arrival and in-house) stays: the scope of cross-stay operational lists. */
  protected abstract listOpenStaysBounded(): Promise<StayAggregate[]>;
  protected abstract insertStay(stay: StayAggregate, alert?: OperationalAlert | null): Promise<void>;
  /** Storage primitive: read, mutate and write one stay (plus its alert) atomically. */
  protected abstract transactStay<T>(
    stayId: string,
    mutator: StayMutator<T>,
    alertOf?: StayAlertFactory<T>,
  ): Promise<T>;
  abstract pageStays(query: StayPageQuery): Promise<PaginatedResult<StayAggregate>>;
  abstract listOpenStays(limit: number): Promise<StayAggregate[]>;
  abstract listStaysByStatuses(statuses: readonly StayLifecycleStatus[]): Promise<StayAggregate[]>;
  abstract listStaysCheckingInOn(date: string): Promise<StayAggregate[]>;
  abstract pageConversations(query: ConversationPageQuery): Promise<PaginatedResult<StayAggregate>>;
  abstract listUnreadConversations(): Promise<StayAggregate[]>;
  abstract hasStaysForVilla(villaId: string): Promise<boolean>;

  findByGuestTokenUuid(guestTokenUuid: string): Promise<StayAggregate | null> {
    return this.findStayByToken(guestTokenUuid.trim().toLowerCase());
  }

  findByStayId(stayId: string): Promise<StayAggregate | null> {
    return this.findStay(stayId);
  }

  async createStay(stay: StayAggregate, alert: OperationalAlert | null = null): Promise<StayAggregate> {
    await this.insertStay(structuredClone(stay), alert);
    return structuredClone(stay);
  }

  updateStay(stayId: string, change: (current: StayAggregate) => StayAggregate): Promise<StayAggregate> {
    return this.mutateStay(stayId, (draft) => {
      const next = change(structuredClone(draft));
      Object.assign(draft, next, { stayId });
      return structuredClone(draft);
    });
  }

  updateStayToken(stayId: string, newUuid: string): Promise<StayRecord> {
    return this.mutateStay(stayId, (s) => mutations.rotateGuestToken(s, newUuid));
  }

  updatePersonalization(
    stayId: string,
    personalizationPatch: Partial<Personalization>,
    allergiesLabel?: string,
    alertOf?: StayAlertFactory<Personalization>,
  ): Promise<Personalization> {
    return this.mutateStay(
      stayId,
      (s) => mutations.patchPersonalization(s, personalizationPatch, allergiesLabel),
      alertOf,
    );
  }

  replaceServiceOrder(
    stayId: string,
    serviceId: string,
    lines: LarderOrderItem[],
    charge: LarderCharge,
    alertOf?: StayAlertFactory<{ orders: LarderOrderItem[]; folioSummary: FolioSummary }>,
  ): Promise<{ orders: LarderOrderItem[]; folioSummary: FolioSummary }> {
    return this.mutateStay(stayId, (s) => guestRules.replaceServiceOrder(s, serviceId, lines, charge, nowIso()), alertOf);
  }

  cancelGuestBooking(
    stayId: string,
    bookingId: string,
    alertOf?: StayAlertFactory<ExperienceBooking>,
  ): Promise<ExperienceBooking> {
    return this.mutateStay(stayId, (s) => guestRules.cancelGuestBooking(s, bookingId, nowIso()), alertOf);
  }

  changeGuestBooking(
    stayId: string,
    bookingId: string,
    change: BookingChange,
    alertOf?: StayAlertFactory<ExperienceBooking>,
  ): Promise<ExperienceBooking> {
    return this.mutateStay(stayId, (s) => guestRules.changeGuestBooking(s, bookingId, change, nowIso()), alertOf);
  }

  setJourneyMarks(stayId: string, marks: Partial<JourneyMarks>): Promise<JourneyMarks> {
    return this.mutateStay(stayId, (s) => guestRules.setJourneyMarks(s, marks, nowIso()));
  }

  createBooking(
    stayId: string,
    booking: ExperienceBooking,
    alertOf?: StayAlertFactory<ExperienceBooking>,
  ): Promise<ExperienceBooking> {
    return this.mutateStay(stayId, (s) => mutations.addBooking(s, booking), alertOf);
  }

  async transitionServiceRequest(stayId: string, ref: RequestRef, move: RequestMove): Promise<void> {
    await this.mutateStay(stayId, (s) => applyRequestTransition(s, ref, move));
  }

  createConciergeRequest(
    stayId: string,
    request: ConciergeRequest,
    alertOf?: StayAlertFactory<ConciergeRequest>,
  ): Promise<ConciergeRequest> {
    return this.mutateStay(stayId, (s) => mutations.addConciergeRequest(s, request), alertOf);
  }

  appendConciergeMessage(
    stayId: string,
    requestId: string,
    message: ConciergeMessage,
    alertOf?: StayAlertFactory<ConciergeRequest | null>,
  ): Promise<ConciergeRequest | null> {
    return this.mutateStay(
      stayId,
      (s) => mutations.appendMessageToStayRequest(s, requestId, message),
      alertOf,
    );
  }

  createMidStayFeedback(
    stayId: string,
    feedback: MidStayFeedback,
    alertOf?: StayAlertFactory<MidStayFeedback>,
  ): Promise<MidStayFeedback> {
    return this.mutateStay(stayId, (s) => mutations.addMidStayFeedback(s, feedback), alertOf);
  }

  async listMidStayFeedbackAcrossStays(): Promise<MidStayFeedback[]> {
    return collectMidStayFeedback(await this.listOpenStaysBounded());
  }

  /** Every mutation is rejected (413) if it would push the stay above its byte budget. */
  private mutateStay<T>(
    stayId: string,
    mutator: StayMutator<T>,
    alertOf?: StayAlertFactory<T>,
  ): Promise<T> {
    const withinBudget: StayMutator<T> = (draft) => {
      const result = mutator(draft);
      const bytes = Buffer.byteLength(JSON.stringify(draft));
      if (bytes > MAX_STAY_DOCUMENT_BYTES) throw new StayDocumentTooLargeError(bytes);
      return result;
    };
    return this.transactStay(stayId, withinBudget, alertOf);
  }

}
