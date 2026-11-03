import { FolioSettlement, SettledFolio, settleFolio } from '../../domain/folio-ledger';
import {
  ConciergeMessage,
  ConciergeRequest,
  ExperienceBooking,
  FlightTransfer,
  FolioItem,
  FolioSummary,
  LarderOrderItem,
  MidStayFeedback,
  Personalization,
  StayAggregate,
  StayLifecycleStatus,
  StayRecord,
} from '../../domain/models/domain.models';
import {
  BookingFilterCriteria,
  ConciergeFilterCriteria,
  LarderFilterCriteria,
  StayAlertFactory,
  StayFilterCriteria,
  StayRepositoryPort,
} from '../../domain/ports/repository.ports';
import {
  collectBookings,
  collectConciergeRequests,
  collectLarderOrders,
  collectMidStayFeedback,
  matchesStayFilter,
} from '../../domain/stay-projections';
import { StayDocumentTooLargeError, StayNotFoundError } from '../../domain/stay-errors';
import { MAX_STAY_DOCUMENT_BYTES } from '../../domain/stay-limits';
import * as mutations from './stay-mutations';

export { StayNotFoundError };

export type StayMutator<T> = (draft: StayAggregate) => T;

/**
 * Template Method base: every StayRepositoryPort operation is expressed through six storage
 * primitives, so the in-memory and Firestore adapters share identical business semantics.
 * Each stay aggregate is persisted as one document; a mutation rewrites only that document
 * (plus, atomically, the operational alert built by `alertOf`). Mutators run against the
 * stay as stored at commit time and must be re-runnable (transactions may retry them).
 */
export abstract class AggregateStayRepository implements StayRepositoryPort {
  protected abstract findStayByToken(normalizedToken: string): Promise<StayAggregate | null>;
  protected abstract findStay(stayId: string): Promise<StayAggregate | null>;
  protected abstract listAllStays(): Promise<StayAggregate[]>;
  protected abstract insertStay(stay: StayAggregate): Promise<void>;
  /** Storage primitive: read, mutate and write one stay (plus its alert) atomically. */
  protected abstract transactStay<T>(
    stayId: string,
    mutator: StayMutator<T>,
    alertOf?: StayAlertFactory<T>,
  ): Promise<T>;
  protected abstract deleteAllStays(): Promise<void>;

  findByGuestTokenUuid(guestTokenUuid: string): Promise<StayAggregate | null> {
    return this.findStayByToken(guestTokenUuid.trim().toLowerCase());
  }

  findByStayId(stayId: string): Promise<StayAggregate | null> {
    return this.findStay(stayId);
  }

  async listStays(filter?: StayFilterCriteria): Promise<StayAggregate[]> {
    return (await this.listAllStays()).filter((s) => matchesStayFilter(s, filter));
  }

  async createStay(stay: StayAggregate): Promise<StayAggregate> {
    await this.insertStay(structuredClone(stay));
    return structuredClone(stay);
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

  resetAllStays(): Promise<void> {
    return this.deleteAllStays();
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

  replaceLarderOrders(
    stayId: string,
    orders: LarderOrderItem[],
    alertOf?: StayAlertFactory<{ orders: LarderOrderItem[]; folioSummary: FolioSummary }>,
  ): Promise<{ orders: LarderOrderItem[]; folioSummary: FolioSummary }> {
    return this.mutateStay(stayId, (s) => mutations.replaceLarderAndFolio(s, orders), alertOf);
  }

  async listLarderOrdersAcrossStays(filter?: LarderFilterCriteria): Promise<LarderOrderItem[]> {
    return collectLarderOrders(await this.listAllStays(), filter);
  }

  updateLarderOrderStatus(
    orderItemId: string,
    patch: Partial<LarderOrderItem>,
  ): Promise<LarderOrderItem | null> {
    return this.mutateOwningStay(
      (s) => mutations.ownsLarderOrder(s, orderItemId),
      (s) => mutations.applyLarderOrderStatusUpdate(s, orderItemId, patch),
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
    return collectBookings(await this.listAllStays(), filter);
  }

  updateBookingAssignment(
    bookingId: string,
    patch: Partial<ExperienceBooking>,
  ): Promise<ExperienceBooking | null> {
    return this.mutateOwningStay(
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
    return collectConciergeRequests(await this.listAllStays(), filter);
  }

  async findConciergeRequestById(requestId: string): Promise<ConciergeRequest | null> {
    const stays = await this.listAllStays();
    const found = stays.flatMap((s) => s.conciergeRequests).find((r) => r.requestId === requestId);
    return found ?? null;
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
    return collectMidStayFeedback(await this.listAllStays());
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

  private async mutateOwningStay<T>(
    owns: (stay: StayAggregate) => boolean,
    mutator: StayMutator<T | null>,
  ): Promise<T | null> {
    const owner = (await this.listAllStays()).find(owns);
    return owner ? this.mutateStay(owner.stayId, mutator) : null;
  }
}
