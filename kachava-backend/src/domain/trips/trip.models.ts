import { ServiceSnapshot, VehicleCapacity } from '../catalog/catalog.models';

/**
 * Transport trips (`trips/{tripId}`): one document per trip, created by the guest or by staff.
 * All instants are UTC ISO strings (`toISOString()`); resort-local input is converted with the
 * Settings `timeZone`.
 */
export const TRIP_TYPES = ['ARRIVAL', 'DEPARTURE', 'LOCAL'] as const;
export type TripType = (typeof TRIP_TYPES)[number];

export const TRIP_STATUSES = [
  'REQUESTED',
  'SENT_TO_PROVIDER',
  'CONFIRMED',
  'EN_ROUTE',
  'COMPLETED',
  'CANCELLED',
] as const;
export type TripStatus = (typeof TRIP_STATUSES)[number];

export const TRIP_CREATORS = ['GUEST', 'STAFF'] as const;
export type TripCreator = (typeof TRIP_CREATORS)[number];

/** No transition leaves these. */
export const FINAL_TRIP_STATUSES: readonly TripStatus[] = ['COMPLETED', 'CANCELLED'];
/** Requested but not confirmed yet: the trips the transport alert watches. */
export const UNCONFIRMED_TRIP_STATUSES: readonly TripStatus[] = ['REQUESTED', 'SENT_TO_PROVIDER'];
export const AIRPORT_TRIP_TYPES: readonly TripType[] = ['ARRIVAL', 'DEPARTURE'];

export interface TripFlight {
  airline: string;
  number: string;
  scheduledAt: string;
}

export interface TripDriver {
  name: string;
  phone: string;
}

export interface TripVehicle {
  description: string;
  plate: string;
}

export interface TripStatusChange {
  from: TripStatus | null;
  to: TripStatus;
  at: string;
  by: string;
  reason: string | null;
}

/** Name and price captured at request time plus the chosen vehicle's capacity. */
export interface TripServiceSnapshot extends ServiceSnapshot {
  vehicleCapacity: VehicleCapacity | null;
}

export interface Trip {
  tripId: string;
  stayId: string;
  villaId: string;
  villaName: string;
  guestName: string;
  /** Null only for trips migrated from the legacy per-stay `flightTransfer`. */
  serviceId: string | null;
  itemId: string | null;
  snapshot: TripServiceSnapshot | null;
  type: TripType;
  airportCode: string | null;
  flight: TripFlight | null;
  pickupAt: string;
  origin: string | null;
  destination: string | null;
  roundTrip: boolean;
  waitMinutes: number | null;
  passengers: number;
  luggage: number;
  /** Written by (and shown to) the guest. */
  guestNotes: string;
  /** Staff-only; never returned to guests. */
  notes: string;
  providerId: string | null;
  driver: TripDriver | null;
  vehicle: TripVehicle | null;
  status: TripStatus;
  cancellationReason: string | null;
  createdBy: TripCreator;
  statusHistory: TripStatusChange[];
  createdAt: string;
  /** Staff email or `guest:<stayId>`. */
  createdByActor: string;
  updatedAt: string;
  updatedBy: string;
}

export function isFinalTripStatus(status: TripStatus): boolean {
  return FINAL_TRIP_STATUSES.includes(status);
}

export function isAirportTrip(type: TripType): boolean {
  return AIRPORT_TRIP_TYPES.includes(type);
}
