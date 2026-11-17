import { normalizeSearchText } from '../../common/listing/list-query';
import { Trip, TripStatus, TripType } from './trip.models';

export interface TripFilter {
  status?: TripStatus;
  type?: TripType;
  providerId?: string;
  villaId?: string;
  /** Guest name (accent-free) or flight number (spaces ignored, "TA123" finds "TA 123"). */
  q?: string;
}

const compact = (value: string) => normalizeSearchText(value).replace(/\s+/g, '');

function matchesSearch(trip: Trip, q: string): boolean {
  const text = normalizeSearchText(q);
  if (normalizeSearchText(trip.guestName).includes(text)) return true;
  return Boolean(trip.flight) && compact(trip.flight?.number ?? '').includes(compact(q));
}

/** Equality filters and search applied to an already bounded read. */
export function filterTrips(trips: readonly Trip[], filter: TripFilter): Trip[] {
  return trips.filter(
    (trip) =>
      (!filter.status || trip.status === filter.status) &&
      (!filter.type || trip.type === filter.type) &&
      (!filter.providerId || trip.providerId === filter.providerId) &&
      (!filter.villaId || trip.villaId === filter.villaId) &&
      (!filter.q || matchesSearch(trip, filter.q)),
  );
}
