import type {
  CollectionReference,
  DocumentData,
  Firestore,
  Query,
} from 'firebase-admin/firestore';
import { normalizeSearchText, PaginatedResult } from '../../common/listing/list-query';
import { EntityConflictError, ListScanLimitError } from '../../domain/domain-errors';
import { OperationalAlert, StayAggregate, StayLifecycleStatus } from '../../domain/models/domain.models';
import { ConversationPageQuery, StayAlertFactory, StayPageQuery } from '../../domain/ports/repository.ports';
import { conversationSummary } from '../../domain/conversations/conversation-rules';
import { ALERTS_COLLECTION } from './firestore-alert.repository';
import {
  AggregateStayRepository,
  StayMutator,
  StayNotFoundError,
} from './aggregate-stay.repository';
import { toFirestoreDocument } from './firestore-document.mapper';

export const STAYS_COLLECTION = 'stays';
/** Derived, storage-only field used for `array-contains` guest-name search. */
export const GUEST_SEARCH_FIELD = 'guestSearchKeywords';
/** Derived, storage-only ids of every embedded booking, larder line and concierge request. */
export const CHILD_REFS_FIELD = 'childRefIds';
/** Derived, storage-only conversation summary (Messages inbox); absent when the stay has no messages. */
export const CONVERSATION_FIELD = 'conversation';
const LAST_MESSAGE_FIELD = `${CONVERSATION_FIELD}.lastMessageAt`;
export const MAX_SEARCH_KEYWORD_LENGTH = 40;
/** Upper bound of stay documents one bounded cross-stay read may return. */
export const STAY_SCAN_LIMIT = 1000;
const OPEN_STAY_STATUSES: StayLifecycleStatus[] = ['PRE_ARRIVAL', 'ACTIVE_STAY'];
const ARRIVAL_FIELD = 'checkInDate';
const DERIVED_FIELDS = [GUEST_SEARCH_FIELD, CHILD_REFS_FIELD, CONVERSATION_FIELD];

/**
 * Firestore adapter where `stays/{stayId}` is the single source of truth. There is no
 * process-level cache: every call reads the store, every write is awaited inside a transaction
 * that rewrites only the affected stay document, and storage errors propagate to the caller.
 */
export class FirestoreStayRepository extends AggregateStayRepository {
  constructor(
    private readonly db: Firestore,
    private readonly scanLimit = STAY_SCAN_LIMIT,
  ) {
    super();
  }

  protected async findStayByToken(normalizedToken: string): Promise<StayAggregate | null> {
    const snapshot = await this.stays()
      .where('guestTokenUuid', '==', normalizedToken)
      .limit(1)
      .get();
    if (snapshot.empty) return null;
    const [doc] = snapshot.docs;
    return toStayAggregate(doc.id, doc.data());
  }

  protected async findStay(stayId: string): Promise<StayAggregate | null> {
    const snapshot = await this.stays().doc(stayId).get();
    return snapshot.exists ? toStayAggregate(snapshot.id, snapshot.data()) : null;
  }

  protected listOpenStaysBounded(): Promise<StayAggregate[]> {
    return this.listStaysByStatuses(OPEN_STAY_STATUSES);
  }

  protected async findStayByChildRef(childId: string): Promise<StayAggregate | null> {
    const snapshot = await this.stays().where(CHILD_REFS_FIELD, 'array-contains', childId).limit(1).get();
    if (snapshot.empty) return null;
    const [doc] = snapshot.docs;
    return toStayAggregate(doc.id, doc.data());
  }

  listStaysByStatuses(statuses: readonly StayLifecycleStatus[]): Promise<StayAggregate[]> {
    return this.bounded(this.stays().where('status', 'in', [...statuses]));
  }

  /** Stays without messages lack the order-by field, so Firestore leaves them out. */
  async pageConversations(query: ConversationPageQuery): Promise<PaginatedResult<StayAggregate>> {
    let filtered: Query = this.stays();
    if (query.unread !== undefined) filtered = filtered.where(`${CONVERSATION_FIELD}.hasUnread`, '==', query.unread);
    if (query.awaitingReply !== undefined) {
      filtered = filtered.where(`${CONVERSATION_FIELD}.awaitingReply`, '==', query.awaitingReply);
    }
    if (query.q) {
      const keyword = normalizeSearchText(query.q).slice(0, MAX_SEARCH_KEYWORD_LENGTH);
      filtered = filtered.where(GUEST_SEARCH_FIELD, 'array-contains', keyword);
    }
    const ordered = filtered.orderBy(LAST_MESSAGE_FIELD, query.direction);
    const [countSnapshot, pageSnapshot] = await Promise.all([
      ordered.count().get(),
      ordered.offset((query.page - 1) * query.pageSize).limit(query.pageSize).get(),
    ]);
    return new PaginatedResult(
      pageSnapshot.docs.map((doc) => toStayAggregate(doc.id, doc.data())),
      { page: query.page, pageSize: query.pageSize, total: countSnapshot.data().count },
    );
  }

  listUnreadConversations(): Promise<StayAggregate[]> {
    return this.bounded(this.stays().where(`${CONVERSATION_FIELD}.hasUnread`, '==', true));
  }

  listStaysCheckingInOn(date: string): Promise<StayAggregate[]> {
    return this.bounded(this.stays().where(ARRIVAL_FIELD, '==', date));
  }

  /** Filters, search and date order run in Firestore; `count()` gives the total. */
  async pageStays(query: StayPageQuery): Promise<PaginatedResult<StayAggregate>> {
    const dateField = query.dateField ?? ARRIVAL_FIELD;
    let filtered: Query = this.stays();
    if (query.status) filtered = filtered.where('status', '==', query.status);
    if (query.villaId) filtered = filtered.where('villaId', '==', query.villaId);
    if (query.q) {
      const keyword = normalizeSearchText(query.q).slice(0, MAX_SEARCH_KEYWORD_LENGTH);
      filtered = filtered.where(GUEST_SEARCH_FIELD, 'array-contains', keyword);
    }
    if (query.from) filtered = filtered.where(dateField, '>=', query.from);
    if (query.to) filtered = filtered.where(dateField, '<=', query.to);
    const ordered = filtered.orderBy(dateField, query.direction);
    const [countSnapshot, pageSnapshot] = await Promise.all([
      ordered.count().get(),
      ordered.offset((query.page - 1) * query.pageSize).limit(query.pageSize).get(),
    ]);
    return new PaginatedResult(
      pageSnapshot.docs.map((doc) => toStayAggregate(doc.id, doc.data())),
      { page: query.page, pageSize: query.pageSize, total: countSnapshot.data().count },
    );
  }

  async listOpenStays(limit: number): Promise<StayAggregate[]> {
    const snapshot = await this.stays()
      .where('status', 'in', OPEN_STAY_STATUSES)
      .orderBy(ARRIVAL_FIELD, 'asc')
      .limit(limit)
      .get();
    return snapshot.docs.map((doc) => toStayAggregate(doc.id, doc.data()));
  }

  async hasStaysForVilla(villaId: string): Promise<boolean> {
    const snapshot = await this.stays().where('villaId', '==', villaId).limit(1).get();
    return !snapshot.empty;
  }

  /** The stay and its alert commit together; an existing id is a conflict. */
  protected insertStay(stay: StayAggregate, alert: OperationalAlert | null = null): Promise<void> {
    return this.db.runTransaction(async (tx) => {
      const ref = this.stays().doc(stay.stayId);
      if ((await tx.get(ref)).exists) throw new EntityConflictError(`Stay ${stay.stayId} already exists.`);
      tx.set(ref, toStayDocument(stay));
      if (alert) tx.set(this.db.collection(ALERTS_COLLECTION).doc(alert.alertId), toFirestoreDocument(alert));
    });
  }

  private async bounded(query: Query): Promise<StayAggregate[]> {
    const snapshot = await query.limit(this.scanLimit + 1).get();
    if (snapshot.docs.length > this.scanLimit) throw new ListScanLimitError(STAYS_COLLECTION, this.scanLimit);
    return snapshot.docs.map((doc) => toStayAggregate(doc.id, doc.data()));
  }

  /** Stay write and its alert commit together or not at all; contention retries re-run `mutator`. */
  protected transactStay<T>(
    stayId: string,
    mutator: StayMutator<T>,
    alertOf?: StayAlertFactory<T>,
  ): Promise<T> {
    return this.db.runTransaction(async (tx) => {
      const ref = this.stays().doc(stayId);
      const snapshot = await tx.get(ref);
      if (!snapshot.exists) throw new StayNotFoundError(stayId);
      const draft = toStayAggregate(snapshot.id, snapshot.data());
      const result = mutator(draft);
      tx.set(ref, toStayDocument(draft));
      const alert = alertOf?.(result);
      if (alert) {
        tx.set(this.db.collection(ALERTS_COLLECTION).doc(alert.alertId), toFirestoreDocument(alert));
      }
      return result;
    });
  }

  private stays(): CollectionReference {
    return this.db.collection(STAYS_COLLECTION);
  }
}

/** Prefixes of the full normalised guest name and of each of its words. */
export function guestSearchKeywords(guestName: string): string[] {
  const normalized = normalizeSearchText(guestName).slice(0, MAX_SEARCH_KEYWORD_LENGTH);
  const keywords = new Set<string>();
  for (const phrase of [normalized, ...normalized.split(' ')]) {
    for (let end = 1; end <= phrase.length; end += 1) keywords.add(phrase.slice(0, end).trim());
  }
  keywords.delete('');
  return Array.from(keywords);
}

/** Ids of the stay's embedded records, so the owning stay is found with one indexed query. */
export function childRefIds(stay: StayAggregate): string[] {
  return [
    ...(stay.experienceBookings ?? []).map((b) => b.bookingId),
    ...(stay.larderOrders ?? []).map((o) => o.orderItemId),
    ...(stay.conciergeRequests ?? []).map((r) => r.requestId),
  ];
}

function toStayDocument(stay: StayAggregate): Record<string, unknown> {
  const conversation = conversationSummary(stay);
  return {
    ...toFirestoreDocument(stay),
    [GUEST_SEARCH_FIELD]: guestSearchKeywords(stay.guestProfile?.name ?? ''),
    [CHILD_REFS_FIELD]: childRefIds(stay),
    ...(conversation ? { [CONVERSATION_FIELD]: { ...conversation } } : {}),
  };
}

/** Older documents may lack embedded lists; absent lists mean "no items stored". */
function toStayAggregate(stayId: string, data: DocumentData | undefined): StayAggregate {
  const stored = { ...(data ?? {}) } as Partial<StayAggregate> & Record<string, unknown>;
  for (const field of DERIVED_FIELDS) delete stored[field];
  return {
    ...stored,
    stayId,
    larderOrders: stored.larderOrders ?? [],
    experienceBookings: stored.experienceBookings ?? [],
    conciergeRequests: stored.conciergeRequests ?? [],
    midstayFeedback: stored.midstayFeedback ?? [],
    folioItems: stored.folioItems ?? [],
  } as StayAggregate;
}
