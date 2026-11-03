import type { CollectionReference, Firestore, Query } from 'firebase-admin/firestore';
import { EntityConflictError, EntityNotFoundError, ListScanLimitError } from '../../domain/domain-errors';
import { OperationalAlert } from '../../domain/models/domain.models';
import {
  TripAlertFactory,
  TripRepositoryPort,
  TripWindowQuery,
} from '../../domain/ports/repository.ports';
import { Trip, UNCONFIRMED_TRIP_STATUSES } from '../../domain/trips/trip.models';
import { ALERTS_COLLECTION } from './firestore-alert.repository';
import { toFirestoreDocument } from './firestore-document.mapper';

export const TRIPS_COLLECTION = 'trips';
/** Upper bound of trip documents one list request may read. */
export const TRIP_SCAN_LIMIT = 1000;
const PICKUP_FIELD = 'pickupAt';

/**
 * `trips/{tripId}`, read on every call (no process cache). Trip writes and the alert that goes
 * with them commit in one transaction, so a failed request persists neither. Range queries use
 * single-field indexes; the unconfirmed query uses the (status, pickupAt) composite index.
 */
export class FirestoreTripRepository implements TripRepositoryPort {
  constructor(
    private readonly db: Firestore,
    private readonly scanLimit = TRIP_SCAN_LIMIT,
  ) {}

  create(trip: Trip, alert: OperationalAlert | null = null): Promise<Trip> {
    return this.db.runTransaction(async (tx) => {
      const ref = this.trips().doc(trip.tripId);
      if ((await tx.get(ref)).exists) throw new EntityConflictError(`Trip ${trip.tripId} already exists.`);
      tx.set(ref, toFirestoreDocument(trip));
      if (alert) tx.set(this.alertRef(alert), toFirestoreDocument(alert));
      return structuredClone(trip);
    });
  }

  async findById(tripId: string): Promise<Trip | null> {
    const snapshot = await this.trips().doc(tripId).get();
    return snapshot.exists ? (snapshot.data() as Trip) : null;
  }

  update(tripId: string, mutate: (current: Trip) => Trip, alertOf?: TripAlertFactory): Promise<Trip> {
    return this.db.runTransaction(async (tx) => {
      const ref = this.trips().doc(tripId);
      const snapshot = await tx.get(ref);
      if (!snapshot.exists) throw new EntityNotFoundError('Trip', tripId);
      const previous = snapshot.data() as Trip;
      const next = { ...mutate(structuredClone(previous)), tripId };
      tx.set(ref, toFirestoreDocument(next));
      const alert = alertOf?.(next, previous);
      if (alert) tx.set(this.alertRef(alert), toFirestoreDocument(alert));
      return structuredClone(next);
    });
  }

  listInWindow(query: TripWindowQuery): Promise<Trip[]> {
    if (!query.fromIso && !query.toIsoExclusive) return this.bounded(this.trips());
    let windowed: Query = this.trips();
    if (query.fromIso) windowed = windowed.where(query.field, '>=', query.fromIso);
    if (query.toIsoExclusive) windowed = windowed.where(query.field, '<', query.toIsoExclusive);
    return this.bounded(windowed.orderBy(query.field, 'asc'));
  }

  listForStay(stayId: string): Promise<Trip[]> {
    return this.bounded(this.trips().where('stayId', '==', stayId));
  }

  listUnconfirmedUntil(cutoffIso: string): Promise<Trip[]> {
    return this.bounded(
      this.trips()
        .where('status', 'in', [...UNCONFIRMED_TRIP_STATUSES])
        .where(PICKUP_FIELD, '<=', cutoffIso)
        .orderBy(PICKUP_FIELD, 'asc'),
    );
  }

  private async bounded(query: Query): Promise<Trip[]> {
    const snapshot = await query.limit(this.scanLimit + 1).get();
    if (snapshot.docs.length > this.scanLimit) throw new ListScanLimitError(TRIPS_COLLECTION, this.scanLimit);
    return snapshot.docs.map((doc) => doc.data() as Trip);
  }

  private alertRef(alert: OperationalAlert) {
    return this.db.collection(ALERTS_COLLECTION).doc(alert.alertId);
  }

  private trips(): CollectionReference {
    return this.db.collection(TRIPS_COLLECTION);
  }
}
