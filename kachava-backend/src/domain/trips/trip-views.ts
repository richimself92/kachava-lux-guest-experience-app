import { isUnconfirmedDue } from './trip-rules';
import { Trip } from './trip.models';

/**
 * Guest-safe ALLOW-list (ADR-007): a field added to Trip stays hidden from guests until it is
 * listed here on purpose. Never listed: staff `notes`, `providerId` (and so any provider contact),
 * `statusHistory` and audit actors (staff emails), internal stay/villa ids.
 */
const GUEST_TRIP_KEYS = [
  'tripId', 'type', 'status', 'serviceId', 'itemId', 'snapshot', 'airportCode', 'flight',
  'pickupAt', 'origin', 'destination', 'roundTrip', 'waitMinutes', 'passengers', 'luggage',
  'guestNotes', 'driver', 'vehicle', 'cancellationReason', 'createdBy', 'createdAt',
] as const satisfies ReadonlyArray<keyof Trip>;

export type GuestTripView = Pick<Trip, (typeof GUEST_TRIP_KEYS)[number]> & { id: string };

export type AdminTripView = Trip & {
  id: string;
  /** Not confirmed and pickup within `transportAlertLeadHours`; null when that is not configured. */
  unconfirmedDue: boolean | null;
};

export function toGuestTripView(trip: Trip): GuestTripView {
  const view = { id: trip.tripId } as GuestTripView;
  for (const key of GUEST_TRIP_KEYS) {
    (view as Record<string, unknown>)[key] = structuredClone(trip[key]);
  }
  return view;
}

export function toAdminTripView(trip: Trip, now: Date, leadHours: number | null): AdminTripView {
  return { id: trip.tripId, ...structuredClone(trip), unconfirmedDue: isUnconfirmedDue(trip, now, leadHours) };
}
