import { Injectable } from '@nestjs/common';
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
  StayFilterCriteria,
} from '../../domain/ports/repository.ports';
import { getNamedFirestoreDb } from '../firebase/firebase-admin.module';
import { InMemorySeededStayRepository } from './in-memory-stay.repository';

const STAY_SUBCOLLECTIONS = [
  'larder_orders',
  'experience_bookings',
  'concierge_requests',
  'midstay_feedback',
  'midstay_checkins',
  'folio_items',
];

/**
 * Hybrid GCP Firestore Repository Adapter targeting `projects/kavacha-app/databases/kavacha-db`.
 * Uses `getFirestore(app, 'kavacha-db')` when `USE_FIRESTORE=true` (local dev & Cloud Run)
 * while preserving fast, deterministic in-memory execution during `NODE_ENV=test`.
 */
@Injectable()
export class FirestoreStayRepositoryAdapter extends InMemorySeededStayRepository {
  private hydrated = false;
  private hydrationPromise: Promise<void> | null = null;

  async ensureHydrated(): Promise<void> {
    if (this.hydrated) return;
    const db = getNamedFirestoreDb();
    if (!db) {
      this.hydrated = true;
      return;
    }
    if (!this.hydrationPromise) {
      this.hydrationPromise = (async () => {
        try {
          const snap = await db.collection('stays').get();
          this.stays.clear();
          for (const doc of snap.docs) {
            const data = doc.data() as StayAggregate;
            if (data && data.stayId) {
              this.stays.set(data.stayId, data);
            }
          }
        } catch {
          // Fall back to existing state if Firestore read fails
        } finally {
          this.hydrated = true;
        }
      })();
    }
    await this.hydrationPromise;
  }

  private syncToFirestoreAsync(work: () => Promise<void>): void {
    const db = getNamedFirestoreDb();
    if (!db) return;
    void work().catch(() => {
      // Non-blocking background write-through sync
    });
  }

  private persistFullStay(stayId: string, extraWork?: (stayRef: FirebaseFirestore.DocumentReference) => Promise<void>): void {
    this.syncToFirestoreAsync(async () => {
      const db = getNamedFirestoreDb();
      if (!db) return;
      const fullStay = this.stays.get(this.resolveCanonicalStayId(stayId));
      if (fullStay) {
        const stayRef = db.collection('stays').doc(fullStay.stayId);
        await stayRef.set(fullStay, { merge: true });
        if (extraWork) await extraWork(stayRef);
      }
    });
  }

  private persistAllStays(): void {
    this.syncToFirestoreAsync(async () => {
      const db = getNamedFirestoreDb();
      if (!db) return;
      for (const stay of this.stays.values()) {
        await db.collection('stays').doc(stay.stayId).set(stay, { merge: true });
      }
    });
  }

  override async findByGuestTokenUuid(guestTokenUuid: string): Promise<StayAggregate | null> {
    await this.ensureHydrated();
    return super.findByGuestTokenUuid(guestTokenUuid);
  }

  override async findByStayId(stayId: string): Promise<StayAggregate | null> {
    await this.ensureHydrated();
    return super.findByStayId(stayId);
  }

  override async listStays(filter?: StayFilterCriteria): Promise<StayAggregate[]> {
    await this.ensureHydrated();
    return super.listStays(filter);
  }

  override async createStay(stay: StayAggregate): Promise<StayAggregate> {
    await this.ensureHydrated();
    const created = await super.createStay(stay);
    this.persistFullStay(created.stayId);
    return created;
  }

  override async updateStayToken(stayId: string, newUuid: string): Promise<StayRecord> {
    await this.ensureHydrated();
    const updated = await super.updateStayToken(stayId, newUuid);
    this.persistFullStay(stayId);
    return updated;
  }

  override async updateStayStatus(
    stayId: string,
    status: StayLifecycleStatus,
  ): Promise<StayRecord> {
    await this.ensureHydrated();
    const updated = await super.updateStayStatus(stayId, status);
    this.persistFullStay(stayId);
    return updated;
  }

  override async updateStayWifi(
    stayId: string,
    wifiPatch: { wifiSsid?: string; wifiPasscode?: string },
  ): Promise<StayRecord> {
    await this.ensureHydrated();
    const updated = await super.updateStayWifi(stayId, wifiPatch);
    this.persistFullStay(stayId);
    return updated;
  }

  override async resetAllStays(): Promise<void> {
    await this.ensureHydrated();
    await super.resetAllStays();
    this.syncToFirestoreAsync(async () => {
      const db = getNamedFirestoreDb();
      if (!db) return;
      const staysSnap = await db.collection('stays').get();
      for (const stayDoc of staysSnap.docs) {
        for (const sub of STAY_SUBCOLLECTIONS) {
          const subSnap = await stayDoc.ref.collection(sub).get();
          await Promise.all(subSnap.docs.map((d) => d.ref.delete()));
        }
        await stayDoc.ref.delete();
      }
    });
  }

  override async updateTransfer(
    stayId: string,
    transferPatch: Partial<FlightTransfer>,
  ): Promise<FlightTransfer> {
    await this.ensureHydrated();
    const updated = await super.updateTransfer(stayId, transferPatch);
    this.persistFullStay(stayId);
    return updated;
  }

  override async updatePersonalization(
    stayId: string,
    personalizationPatch: Partial<Personalization>,
    allergiesLabel?: string,
  ): Promise<Personalization> {
    await this.ensureHydrated();
    const updated = await super.updatePersonalization(
      stayId,
      personalizationPatch,
      allergiesLabel,
    );
    this.persistFullStay(stayId);
    return updated;
  }

  override async updateSignaturePrivilege(
    stayId: string,
    privilege: 'massage' | 'golf',
  ): Promise<StayRecord> {
    await this.ensureHydrated();
    const updated = await super.updateSignaturePrivilege(stayId, privilege);
    this.persistFullStay(stayId);
    return updated;
  }

  override async replaceLarderOrders(
    stayId: string,
    orders: LarderOrderItem[],
    folioItems: FolioItem[],
    folioSummary: FolioSummary,
  ): Promise<{ orders: LarderOrderItem[]; folioSummary: FolioSummary }> {
    await this.ensureHydrated();
    const result = await super.replaceLarderOrders(stayId, orders, folioItems, folioSummary);
    this.persistFullStay(stayId);
    return result;
  }

  override async listLarderOrdersAcrossStays(
    filter?: LarderFilterCriteria,
  ): Promise<LarderOrderItem[]> {
    await this.ensureHydrated();
    return super.listLarderOrdersAcrossStays(filter);
  }

  async listAllLarderOrders(filter?: LarderFilterCriteria): Promise<LarderOrderItem[]> {
    return this.listLarderOrdersAcrossStays(filter);
  }

  override async updateLarderOrderStatus(
    orderItemId: string,
    patch: Partial<LarderOrderItem>,
  ): Promise<LarderOrderItem | null> {
    await this.ensureHydrated();
    const updated = await super.updateLarderOrderStatus(orderItemId, patch);
    if (updated) this.persistAllStays();
    return updated;
  }

  override async createBooking(
    stayId: string,
    booking: ExperienceBooking,
    folioItems: FolioItem[],
    folioSummary: FolioSummary,
  ): Promise<ExperienceBooking> {
    await this.ensureHydrated();
    const created = await super.createBooking(stayId, booking, folioItems, folioSummary);
    this.persistFullStay(stayId, async (stayRef) => {
      await stayRef.collection('experience_bookings').doc(created.bookingId).set(created);
    });
    return created;
  }

  override async listBookingsForStay(stayId: string): Promise<ExperienceBooking[]> {
    await this.ensureHydrated();
    return super.listBookingsForStay(stayId);
  }

  override async listBookingsAcrossStays(
    filter?: BookingFilterCriteria,
  ): Promise<ExperienceBooking[]> {
    await this.ensureHydrated();
    return super.listBookingsAcrossStays(filter);
  }

  async listAllBookings(filter?: BookingFilterCriteria): Promise<ExperienceBooking[]> {
    return this.listBookingsAcrossStays(filter);
  }

  override async updateBookingAssignment(
    bookingId: string,
    patch: Partial<ExperienceBooking>,
  ): Promise<ExperienceBooking | null> {
    await this.ensureHydrated();
    const updated = await super.updateBookingAssignment(bookingId, patch);
    if (updated) this.persistAllStays();
    return updated;
  }

  override async listConciergeRequestsForStay(stayId: string): Promise<ConciergeRequest[]> {
    await this.ensureHydrated();
    return super.listConciergeRequestsForStay(stayId);
  }

  override async listConciergeRequestsAcrossStays(
    filter?: ConciergeFilterCriteria,
  ): Promise<ConciergeRequest[]> {
    await this.ensureHydrated();
    return super.listConciergeRequestsAcrossStays(filter);
  }

  async listAllConciergeRequests(
    filter?: ConciergeFilterCriteria,
  ): Promise<ConciergeRequest[]> {
    return this.listConciergeRequestsAcrossStays(filter);
  }

  override async findConciergeRequestById(requestId: string): Promise<ConciergeRequest | null> {
    await this.ensureHydrated();
    return super.findConciergeRequestById(requestId);
  }

  override async createConciergeRequest(
    stayId: string,
    request: ConciergeRequest,
  ): Promise<ConciergeRequest> {
    await this.ensureHydrated();
    const created = await super.createConciergeRequest(stayId, request);
    this.persistFullStay(stayId, async (stayRef) => {
      await stayRef.collection('concierge_requests').doc(created.requestId).set(created);
    });
    return created;
  }

  override async appendConciergeMessage(
    stayId: string,
    requestId: string,
    message: ConciergeMessage,
  ): Promise<ConciergeRequest | null> {
    await this.ensureHydrated();
    const updated = await super.appendConciergeMessage(stayId, requestId, message);
    if (updated) this.persistAllStays();
    return updated;
  }

  override async updateConciergeRequestAdmin(
    requestId: string,
    patch: Partial<ConciergeRequest>,
    newMessage?: ConciergeMessage,
  ): Promise<ConciergeRequest | null> {
    await this.ensureHydrated();
    const updated = await super.updateConciergeRequestAdmin(requestId, patch, newMessage);
    if (updated) this.persistAllStays();
    return updated;
  }

  override async createMidStayFeedback(
    stayId: string,
    feedback: MidStayFeedback,
  ): Promise<MidStayFeedback> {
    await this.ensureHydrated();
    const created = await super.createMidStayFeedback(stayId, feedback);
    this.persistFullStay(stayId, async (stayRef) => {
      await stayRef.collection('midstay_feedback').doc(created.feedbackId).set(created);
    });
    return created;
  }

  override async listMidStayFeedbackAcrossStays(): Promise<MidStayFeedback[]> {
    await this.ensureHydrated();
    return super.listMidStayFeedbackAcrossStays();
  }

  override async getFolioForStay(
    stayId: string,
  ): Promise<{ folioSummary: FolioSummary; folioItems: FolioItem[] }> {
    await this.ensureHydrated();
    return super.getFolioForStay(stayId);
  }

  override async updateFolioAndStatus(
    stayId: string,
    folioSummary: FolioSummary,
    folioItems: FolioItem[],
    newStatus?: StayLifecycleStatus,
    lateCheckoutRequested?: boolean,
  ) {
    await this.ensureHydrated();
    const updated = await super.updateFolioAndStatus(
      stayId,
      folioSummary,
      folioItems,
      newStatus,
      lateCheckoutRequested,
    );
    this.persistFullStay(stayId);
    return updated;
  }
}
