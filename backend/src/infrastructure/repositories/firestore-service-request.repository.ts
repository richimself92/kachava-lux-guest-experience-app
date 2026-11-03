import type { CollectionReference, DocumentData, Firestore, Query, Transaction } from 'firebase-admin/firestore';
import { normalizeSearchText, PaginatedResult } from '../../common/listing/list-query';
import { StayAggregate } from '../../domain/models/domain.models';
import { ServiceRequestPageQuery, ServiceRequestRepositoryPort } from '../../domain/ports/repository.ports';
import { projectServiceRequests, ServiceRequestEntry } from '../../domain/requests/service-requests';
import { toFirestoreDocument } from './firestore-document.mapper';

export const SERVICE_REQUESTS_COLLECTION = 'service_requests';
/** Derived, storage-only prefixes of the guest and service names (`array-contains` search). */
export const REQUEST_SEARCH_FIELD = 'searchKeywords';
const MAX_KEYWORD_LENGTH = 40;

/** Prefixes of a normalised phrase and of each of its words. */
export function phraseKeywords(text: string): string[] {
  const normalized = normalizeSearchText(text).slice(0, MAX_KEYWORD_LENGTH);
  const keywords = new Set<string>();
  for (const phrase of [normalized, ...normalized.split(' ')]) {
    for (let end = 1; end <= phrase.length; end += 1) keywords.add(phrase.slice(0, end).trim());
  }
  keywords.delete('');
  return Array.from(keywords);
}

function requestKeywords(entry: ServiceRequestEntry): string[] {
  const names = [entry.guestName, entry.serviceName.en, entry.serviceName.es];
  return Array.from(new Set(names.flatMap(phraseKeywords)));
}

function toEntry(data: DocumentData | undefined): ServiceRequestEntry {
  const stored = { ...(data ?? {}) } as ServiceRequestEntry & Record<string, unknown>;
  delete stored[REQUEST_SEARCH_FIELD];
  return stored;
}

/** Resolves the configured resort zone (null when not set); orders need it for their time. */
export type TimeZoneSource = () => Promise<string | null>;

/**
 * Writes the request entries of a stay inside the stay's own transaction: every entry of the
 * new stay is (re)written and entries the stay no longer holds are deleted, so the index heals
 * itself on the next change of an older stay.
 */
export class ServiceRequestIndexWriter {
  constructor(
    private readonly db: Firestore,
    private readonly timeZoneOf: TimeZoneSource,
  ) {}

  /** Computes the writes (may read Settings outside the transaction); call before any tx write. */
  async prepare(before: StayAggregate | null, after: StayAggregate): Promise<(tx: Transaction) => void> {
    const hasOrders = (before?.larderOrders.length ?? 0) + after.larderOrders.length > 0;
    const timeZone = hasOrders ? await this.timeZoneOf() : null;
    const next = projectServiceRequests(after, timeZone);
    const kept = new Set(next.map((e) => e.requestId));
    const stale = (before ? projectServiceRequests(before, timeZone) : []).filter((e) => !kept.has(e.requestId));
    return (tx) => {
      for (const entry of stale) tx.delete(this.collection().doc(entry.requestId));
      for (const entry of next) {
        tx.set(this.collection().doc(entry.requestId), {
          ...toFirestoreDocument(entry),
          [REQUEST_SEARCH_FIELD]: requestKeywords(entry),
        });
      }
    };
  }

  private collection(): CollectionReference {
    return this.db.collection(SERVICE_REQUESTS_COLLECTION);
  }
}

/** Section queues: every filter, the search and the date order run in Firestore. */
export class FirestoreServiceRequestRepository implements ServiceRequestRepositoryPort {
  constructor(private readonly db: Firestore) {}

  async page(query: ServiceRequestPageQuery): Promise<PaginatedResult<ServiceRequestEntry>> {
    let filtered: Query = this.collection();
    if (query.section) filtered = filtered.where('section', '==', query.section);
    if (query.status === 'OPEN') filtered = filtered.where('open', '==', true);
    else if (query.status) filtered = filtered.where('status', '==', query.status);
    if (query.q) {
      const keyword = normalizeSearchText(query.q).slice(0, MAX_KEYWORD_LENGTH);
      filtered = filtered.where(REQUEST_SEARCH_FIELD, 'array-contains', keyword);
    }
    if (query.fromAt) filtered = filtered.where('at', '>=', query.fromAt);
    if (query.toAtExclusive) filtered = filtered.where('at', '<', query.toAtExclusive);
    const ordered = filtered.orderBy('at', query.direction);
    const [countSnapshot, pageSnapshot] = await Promise.all([
      ordered.count().get(),
      ordered.offset((query.page - 1) * query.pageSize).limit(query.pageSize).get(),
    ]);
    return new PaginatedResult(
      pageSnapshot.docs.map((doc) => toEntry(doc.data())),
      { page: query.page, pageSize: query.pageSize, total: countSnapshot.data().count },
    );
  }

  async findById(requestId: string): Promise<ServiceRequestEntry | null> {
    const snapshot = await this.collection().doc(requestId).get();
    return snapshot.exists ? toEntry(snapshot.data()) : null;
  }

  private collection(): CollectionReference {
    return this.db.collection(SERVICE_REQUESTS_COLLECTION);
  }
}
