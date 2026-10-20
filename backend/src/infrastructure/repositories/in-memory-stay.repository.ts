import { Injectable } from '@nestjs/common';
import {
  ConciergeMessage, ConciergeRequest, ExperienceBooking, FlightTransfer,
  FolioItem, FolioSummary, LarderOrderItem, MidStayFeedback,
  Personalization, StayAggregate, StayLifecycleStatus, StayRecord,
} from '../../domain/models/domain.models';
import {
  BookingFilterCriteria, ConciergeFilterCriteria, LarderFilterCriteria,
  StayFilterCriteria, StayRepositoryPort,
} from '../../domain/ports/repository.ports';
import {
  createSeededStayAggregate, DEFAULT_DEMO_GUEST_UUID, SECONDARY_SPEC_GUEST_UUID,
} from '../seed/sanctuary-seed.data';
import {
  appendMessageToStayRequest, applyBookingAssignmentUpdate,
  applyConciergeAdminUpdate, applyFolioAndStatusUpdate,
  applyLarderOrderStatusUpdate, findConciergeRequestAcrossStays,
  matchesBookingFilter, matchesConciergeFilter, matchesLarderFilter, matchesStayFilter,
} from './stay-subcollection.helper';

const VILLA_102_STAY_ALIASES = new Set([
  'stay_2026_11_villa102_miller',
  'stay_villa_102_2026_10',
]);

@Injectable()
export class InMemorySeededStayRepository implements StayRepositoryPort {
  protected readonly stays = new Map<string, StayAggregate>();

  constructor() {
    const initial = createSeededStayAggregate();
    this.stays.set(initial.stayId, initial);
  }

  async findByGuestTokenUuid(guestTokenUuid: string): Promise<StayAggregate | null> {
    const normalized = guestTokenUuid.trim().toLowerCase();
    for (const stay of this.stays.values()) {
      const matchesPrimary = stay.guestTokenUuid.toLowerCase() === normalized;
      const matchesSecondaryAlias =
        VILLA_102_STAY_ALIASES.has(stay.stayId) &&
        stay.guestTokenUuid === DEFAULT_DEMO_GUEST_UUID &&
        normalized === SECONDARY_SPEC_GUEST_UUID;
      if (matchesPrimary || matchesSecondaryAlias) return structuredClone(stay);
    }
    return null;
  }

  async findByStayId(stayId: string): Promise<StayAggregate | null> {
    const stay = this.stays.get(this.resolveCanonicalStayId(stayId));
    return stay ? structuredClone(stay) : null;
  }

  async listStays(filter?: StayFilterCriteria): Promise<StayAggregate[]> {
    return Array.from(this.stays.values())
      .filter((s) => matchesStayFilter(s, filter))
      .map((s) => structuredClone(s));
  }

  async createStay(stay: StayAggregate): Promise<StayAggregate> {
    this.stays.set(stay.stayId, structuredClone(stay));
    return structuredClone(stay);
  }

  async updateStayToken(stayId: string, newUuid: string): Promise<StayRecord> {
    const stay = this.requireStay(stayId);
    stay.guestTokenUuid = newUuid;
    stay.updatedAt = new Date().toISOString();
    return structuredClone(stay);
  }

  async updateStayStatus(stayId: string, status: StayLifecycleStatus): Promise<StayRecord> {
    const stay = this.requireStay(stayId);
    stay.status = status;
    stay.updatedAt = new Date().toISOString();
    return structuredClone(stay);
  }

  async updateStayWifi(
    stayId: string,
    wifiPatch: { wifiSsid?: string; wifiPasscode?: string },
  ): Promise<StayRecord> {
    const stay = this.requireStay(stayId);
    stay.villaAccess = {
      ...stay.villaAccess,
      wifiSsid: wifiPatch.wifiSsid?.trim() || stay.villaAccess.wifiSsid,
      wifiPasscode: wifiPatch.wifiPasscode?.trim() || stay.villaAccess.wifiPasscode,
    };
    stay.updatedAt = new Date().toISOString();
    return structuredClone(stay);
  }

  async resetAllStays(): Promise<void> {
    this.stays.clear();
  }

  async updateTransfer(stayId: string, transferPatch: Partial<FlightTransfer>): Promise<FlightTransfer> {
    const stay = this.requireStay(stayId);
    stay.flightTransfer = { ...stay.flightTransfer, ...transferPatch };
    stay.updatedAt = new Date().toISOString();
    return structuredClone(stay.flightTransfer);
  }

  async updatePersonalization(
    stayId: string,
    personalizationPatch: Partial<Personalization>,
    allergiesLabel?: string,
  ): Promise<Personalization> {
    const stay = this.requireStay(stayId);
    stay.personalization = { ...stay.personalization, ...personalizationPatch, updatedAt: new Date().toISOString() };
    if (allergiesLabel) stay.guestProfile.allergies = allergiesLabel;
    stay.updatedAt = new Date().toISOString();
    return structuredClone(stay.personalization);
  }

  async updateSignaturePrivilege(stayId: string, privilege: 'massage' | 'golf'): Promise<StayRecord> {
    const stay = this.requireStay(stayId);
    stay.selectedSignaturePrivilege = privilege;
    stay.updatedAt = new Date().toISOString();
    return structuredClone(stay);
  }

  async replaceLarderOrders(
    stayId: string,
    orders: LarderOrderItem[],
    folioItems: FolioItem[],
    folioSummary: FolioSummary,
  ): Promise<{ orders: LarderOrderItem[]; folioSummary: FolioSummary }> {
    const stay = this.requireStay(stayId);
    stay.larderOrders = structuredClone(orders);
    stay.folioItems = structuredClone(folioItems);
    stay.folioSummary = structuredClone(folioSummary);
    stay.updatedAt = new Date().toISOString();
    return { orders: structuredClone(stay.larderOrders), folioSummary: structuredClone(stay.folioSummary) };
  }

  async listLarderOrdersAcrossStays(filter?: LarderFilterCriteria): Promise<LarderOrderItem[]> {
    return Array.from(this.stays.values())
      .flatMap((s) => s.larderOrders)
      .filter((item) => matchesLarderFilter(item, filter))
      .map((item) => structuredClone(item));
  }

  async updateLarderOrderStatus(
    orderItemId: string,
    patch: Partial<LarderOrderItem>,
  ): Promise<LarderOrderItem | null> {
    return applyLarderOrderStatusUpdate(this.stays.values(), orderItemId, patch);
  }

  async createBooking(
    stayId: string,
    booking: ExperienceBooking,
    folioItems: FolioItem[],
    folioSummary: FolioSummary,
  ): Promise<ExperienceBooking> {
    const stay = this.requireStay(stayId);
    stay.experienceBookings.unshift(structuredClone(booking));
    stay.folioItems = structuredClone(folioItems);
    stay.folioSummary = structuredClone(folioSummary);
    stay.updatedAt = new Date().toISOString();
    return structuredClone(booking);
  }

  async listBookingsForStay(stayId: string): Promise<ExperienceBooking[]> {
    return structuredClone(this.requireStay(stayId).experienceBookings);
  }

  async listBookingsAcrossStays(filter?: BookingFilterCriteria): Promise<ExperienceBooking[]> {
    return Array.from(this.stays.values())
      .flatMap((s) => s.experienceBookings)
      .filter((b) => matchesBookingFilter(b, filter))
      .map((b) => structuredClone(b));
  }

  async updateBookingAssignment(
    bookingId: string,
    patch: Partial<ExperienceBooking>,
  ): Promise<ExperienceBooking | null> {
    return applyBookingAssignmentUpdate(this.stays.values(), bookingId, patch);
  }

  async listConciergeRequestsForStay(stayId: string): Promise<ConciergeRequest[]> {
    return structuredClone(this.requireStay(stayId).conciergeRequests);
  }

  async listConciergeRequestsAcrossStays(
    filter?: ConciergeFilterCriteria,
  ): Promise<ConciergeRequest[]> {
    return Array.from(this.stays.values())
      .flatMap((s) => s.conciergeRequests)
      .filter((r) => matchesConciergeFilter(r, filter))
      .map((r) => structuredClone(r));
  }

  async findConciergeRequestById(requestId: string): Promise<ConciergeRequest | null> {
    return findConciergeRequestAcrossStays(this.stays.values(), requestId);
  }

  async createConciergeRequest(
    stayId: string,
    request: ConciergeRequest,
  ): Promise<ConciergeRequest> {
    this.requireStay(stayId).conciergeRequests.unshift(structuredClone(request));
    return structuredClone(request);
  }

  async appendConciergeMessage(
    stayId: string,
    requestId: string,
    message: ConciergeMessage,
  ): Promise<ConciergeRequest | null> {
    return appendMessageToStayRequest(this.requireStay(stayId), requestId, message);
  }

  async updateConciergeRequestAdmin(
    requestId: string,
    patch: Partial<ConciergeRequest>,
    newMessage?: ConciergeMessage,
  ): Promise<ConciergeRequest | null> {
    return applyConciergeAdminUpdate(this.stays.values(), requestId, patch, newMessage);
  }

  async createMidStayFeedback(
    stayId: string,
    feedback: MidStayFeedback,
  ): Promise<MidStayFeedback> {
    this.requireStay(stayId).midstayFeedback.unshift(structuredClone(feedback));
    return structuredClone(feedback);
  }

  async listMidStayFeedbackAcrossStays(): Promise<MidStayFeedback[]> {
    return Array.from(this.stays.values())
      .flatMap((s) => s.midstayFeedback)
      .map((f) => structuredClone(f));
  }

  async getFolioForStay(
    stayId: string,
  ): Promise<{ folioSummary: FolioSummary; folioItems: FolioItem[] }> {
    const stay = this.requireStay(stayId);
    return {
      folioSummary: structuredClone(stay.folioSummary),
      folioItems: structuredClone(stay.folioItems),
    };
  }

  async updateFolioAndStatus(
    stayId: string,
    folioSummary: FolioSummary,
    folioItems: FolioItem[],
    newStatus?: StayLifecycleStatus,
    lateCheckoutRequested?: boolean,
  ): Promise<{ folioSummary: FolioSummary; folioItems: FolioItem[]; status: StayLifecycleStatus }> {
    return applyFolioAndStatusUpdate(
      this.requireStay(stayId),
      folioSummary,
      folioItems,
      newStatus,
      lateCheckoutRequested,
    );
  }

  protected resolveCanonicalStayId(stayId: string): string {
    if (VILLA_102_STAY_ALIASES.has(stayId) && !this.stays.has(stayId)) {
      return 'stay_2026_11_villa102_miller';
    }
    return stayId;
  }

  protected requireStay(stayId: string): StayAggregate {
    const resolvedId = this.resolveCanonicalStayId(stayId);
    const stay = this.stays.get(resolvedId);
    if (!stay) throw new Error(`Stay with ID ${stayId} not found`);
    return stay;
  }
}
