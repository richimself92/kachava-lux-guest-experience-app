import { FolioSettlement, LarderCharge, SettledFolio, settleFolio } from '../../domain/folio-ledger';
import {
  ConciergeMessage,
  ConciergeRequest,
  ExperienceBooking,
  FlightTransfer,
  FolioItem,
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
  BookingFilterCriteria,
  ConciergeFilterCriteria,
  ConversationPageQuery,
  LarderFilterCriteria,
  StayAlertFactory,
  StayPageQuery,
  StayRepositoryPort,
} from '../../domain/ports/repository.ports';
import {
  collectBookings,
  collectConciergeRequests,
  collectLarderOrders,
  collectMidStayFeedback,
} from '../../domain/stay-projections';
import { StayDocumentTooLargeError, StayNotFoundError } from '../../domain/stay-errors';
import { MAX_STAY_DOCUMENT_BYTES } from '../../domain/stay-limits';
import * as guestRules from '../../domain/stays/guest-request-rules';
import { BookingChange, JourneyMarks } from '../../domain/stays/guest-request-rules';
import * as mutations from './stay-mutations';

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
  /** The stay holding the booking, larder line or concierge request `childId` (indexed lookup). */
  protected abstract findStayByChildRef(childId: string): Promise<StayAggregate | null>;
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

  updateStayStatus(stayId: string, status: StayLifecycleStatus): Promise<StayRecord> {
    return this.mutateStay(stayId, (s) => mutations.changeStayStatus(s, status));
  }

  updateStayWifi(
    stayId: string,
    wifiPatch: { wifiSsid?: string; wifiPasscode?: string },
  ): Promise<StayRecord> {
    return this.mutateStay(stayId, (s) => mutations.patchStayWifi(s, wifiPatch));
  }

  updateTransfer(
    stayId: string,
    transferPatch: Partial<FlightTransfer>,
    alertOf?: StayAlertFactory<FlightTransfer>,
  ): Promise<FlightTransfer> {
    return this.mutateStay(stayId, (s) => mutations.patchTransfer(s, transferPatch), alertOf);
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

  updateSignaturePrivilege(stayId: string, privilege: 'massage' | 'golf'): Promise<StayRecord> {
    return this.mutateStay(stayId, (s) => mutations.selectSignaturePrivilege(s, privilege));
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

  async listLarderOrdersAcrossStays(filter?: LarderFilterCriteria): Promise<LarderOrderItem[]> {
    return collectLarderOrders(await this.listOpenStaysBounded(), filter);
  }

  updateLarderOrderStatus(
    orderItemId: string,
    patch: Partial<LarderOrderItem>,
  ): Promise<LarderOrderItem | null> {
    const stayIds = [orderItemId, orderItemId.replace(/^larder_/, '')];
    return this.mutateOwningStay(
      orderItemId,
      (s) => mutations.ownsLarderOrder(s, orderItemId),
      (s) => mutations.applyLarderOrderStatusUpdate(s, orderItemId, patch),
      stayIds,
    );
  }

  createBooking(
    stayId: string,
    booking: ExperienceBooking,
    alertOf?: StayAlertFactory<ExperienceBooking>,
  ): Promise<ExperienceBooking> {
    return this.mutateStay(stayId, (s) => mutations.addBooking(s, booking), alertOf);
  }

  async listBookingsForStay(stayId: string): Promise<ExperienceBooking[]> {
    return (await this.requireStay(stayId)).experienceBookings;
  }

  async listBookingsAcrossStays(filter?: BookingFilterCriteria): Promise<ExperienceBooking[]> {
    return collectBookings(await this.listOpenStaysBounded(), filter);
  }

  updateBookingAssignment(
    bookingId: string,
    patch: Partial<ExperienceBooking>,
  ): Promise<ExperienceBooking | null> {
    return this.mutateOwningStay(
      bookingId,
      (s) => mutations.ownsBooking(s, bookingId),
      (s) => mutations.applyBookingAssignmentUpdate(s, bookingId, patch),
    );
  }

  async listConciergeRequestsForStay(stayId: string): Promise<ConciergeRequest[]> {
    return (await this.requireStay(stayId)).conciergeRequests;
  }

  async listConciergeRequestsAcrossStays(
    filter?: ConciergeFilterCriteria,
  ): Promise<ConciergeRequest[]> {
    return collectConciergeRequests(await this.listOpenStaysBounded(), filter);
  }

  async findConciergeRequestById(requestId: string): Promise<ConciergeRequest | null> {
    const owner = await this.findStayByChildRef(requestId);
    return owner?.conciergeRequests.find((r) => r.requestId === requestId) ?? null;
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

  updateConciergeRequestAdmin(
    requestId: string,
    patch: Partial<ConciergeRequest>,
    newMessage?: ConciergeMessage,
  ): Promise<ConciergeRequest | null> {
    return this.mutateOwningStay(
      requestId,
      (s) => mutations.ownsConciergeRequest(s, requestId),
      (s) => mutations.applyConciergeAdminUpdate(s, requestId, patch, newMessage),
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

  async getFolioForStay(
    stayId: string,
  ): Promise<{ folioSummary: FolioSummary; folioItems: FolioItem[] }> {
    const stay = await this.requireStay(stayId);
    return { folioSummary: stay.folioSummary, folioItems: stay.folioItems };
  }

  settleFolio(
    stayId: string,
    settlement: FolioSettlement,
    alertOf?: StayAlertFactory<SettledFolio>,
  ): Promise<SettledFolio> {
    return this.mutateStay(stayId, (s) => settleFolio(s, settlement), alertOf);
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

  private async requireStay(stayId: string): Promise<StayAggregate> {
    const stay = await this.findStay(stayId);
    if (!stay) throw new StayNotFoundError(stayId);
    return stay;
  }

  /** Finds the owner through the child-id index (or the candidate stay ids), never by scanning. */
  private async mutateOwningStay<T>(
    childId: string,
    owns: (stay: StayAggregate) => boolean,
    mutator: StayMutator<T | null>,
    candidateStayIds: string[] = [],
  ): Promise<T | null> {
    const candidates = [
      await this.findStayByChildRef(childId),
      ...(await Promise.all(candidateStayIds.map((id) => this.findStay(id)))),
    ];
    const owner = candidates.find((stay): stay is StayAggregate => stay !== null && owns(stay));
    return owner ? this.mutateStay(owner.stayId, mutator) : null;
  }
}
