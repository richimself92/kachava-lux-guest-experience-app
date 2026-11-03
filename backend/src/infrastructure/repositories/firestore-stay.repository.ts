import type {
  CollectionReference,
  DocumentData,
  Firestore,
} from 'firebase-admin/firestore';
import { StayAggregate } from '../../domain/models/domain.models';
import { StayAlertFactory } from '../../domain/ports/repository.ports';
import { ALERTS_COLLECTION } from './firestore-alert.repository';
import {
  AggregateStayRepository,
  StayMutator,
  StayNotFoundError,
} from './aggregate-stay.repository';
import { toFirestoreDocument } from './firestore-document.mapper';

export const STAYS_COLLECTION = 'stays';

/**
 * Firestore adapter where `stays/{stayId}` is the single source of truth. There is no
 * process-level cache: every call reads the store, every write is awaited inside a transaction
 * that rewrites only the affected stay document, and storage errors propagate to the caller.
 */
export class FirestoreStayRepository extends AggregateStayRepository {
  constructor(private readonly db: Firestore) {
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

  protected async listAllStays(): Promise<StayAggregate[]> {
    const snapshot = await this.stays().get();
    return snapshot.docs.map((doc) => toStayAggregate(doc.id, doc.data()));
  }

  protected async insertStay(stay: StayAggregate): Promise<void> {
    await this.stays().doc(stay.stayId).create(toFirestoreDocument(stay));
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
      tx.set(ref, toFirestoreDocument(draft));
      const alert = alertOf?.(result);
      if (alert) {
        tx.set(this.db.collection(ALERTS_COLLECTION).doc(alert.alertId), toFirestoreDocument(alert));
      }
      return result;
    });
  }

  protected async deleteAllStays(): Promise<void> {
    await this.db.recursiveDelete(this.stays());
  }

  private stays(): CollectionReference {
    return this.db.collection(STAYS_COLLECTION);
  }
}

/** Older documents may lack embedded lists; absent lists mean "no items stored". */
function toStayAggregate(stayId: string, data: DocumentData | undefined): StayAggregate {
  const stored = (data ?? {}) as Partial<StayAggregate>;
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
