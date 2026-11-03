import { CatalogService } from '../catalog/catalog.models';
import { BusinessRuleError } from '../domain-errors';
import { ResortSettings } from '../models/resort-config.models';
import { toInstantIso } from '../time/zoned-time';
import {
  assertServiceServesAirport,
  assertValidTrip,
  resolveAirport,
  suggestedPickupAt,
} from './trip-rules';
import { statusRequirementProblems } from './trip-transitions';
import {
  isAirportTrip,
  isFinalTripStatus,
  Trip,
  TripCreator,
  TripDriver,
  TripFlight,
  TripServiceSnapshot,
  TripType,
  TripVehicle,
} from './trip.models';

/** Flight as sent by clients; `scheduledAt` may be a resort wall time (see toInstantIso). */
export type FlightInput = TripFlight;

export interface TripScheduleInput {
  type: TripType;
  airportCode?: string;
  flight?: FlightInput;
  pickupAt?: string;
}

export interface TripSchedule {
  airportCode: string | null;
  flight: TripFlight | null;
  pickupAt: string;
}

function normalizeFlight(flight: FlightInput, timeZone: string | null): TripFlight {
  return {
    airline: flight.airline.trim(),
    number: flight.number.trim(),
    scheduledAt: toInstantIso(flight.scheduledAt, timeZone),
  };
}

function airportSchedule(input: TripScheduleInput, settings: ResortSettings, service: CatalogService): TripSchedule {
  const missing = [
    ...(input.airportCode ? [] : [`airportCode is required for ${input.type} trips`]),
    ...(input.flight ? [] : [`flight is required for ${input.type} trips`]),
  ];
  if (!input.airportCode || !input.flight) throw new BusinessRuleError('Invalid trip', missing);
  const airport = resolveAirport(settings, input.airportCode);
  assertServiceServesAirport(service, airport.code);
  const flight = normalizeFlight(input.flight, settings.timeZone);
  const pickupAt = input.pickupAt
    ? toInstantIso(input.pickupAt, settings.timeZone)
    : suggestedPickupAt(input.type, flight.scheduledAt, airport);
  return { airportCode: airport.code, flight, pickupAt };
}

/**
 * Airport, flight and pickup of a new trip. Airports come from Settings; a departure without an
 * explicit pickup leaves the airport buffer before the flight, an arrival is met at landing.
 */
export function resolveSchedule(input: TripScheduleInput, settings: ResortSettings, service: CatalogService): TripSchedule {
  if (isAirportTrip(input.type)) return airportSchedule(input, settings, service);
  if (!input.pickupAt) throw new BusinessRuleError('Invalid trip', ['pickupAt is required for LOCAL trips']);
  return {
    airportCode: input.airportCode ?? null,
    flight: input.flight ? { ...input.flight } : null,
    pickupAt: toInstantIso(input.pickupAt, settings.timeZone),
  };
}

export interface TripDetailsInput {
  origin?: string | null;
  destination?: string | null;
  roundTrip?: boolean;
  waitMinutes?: number | null;
  passengers: number;
  luggage?: number;
  guestNotes?: string;
  notes?: string;
  providerId?: string | null;
}

export interface NewTripInput {
  tripId: string;
  stay: { stayId: string; villaId: string; villaName: string; guestName: string };
  type: TripType;
  schedule: TripSchedule;
  details: TripDetailsInput;
  serviceId: string;
  itemId: string | null;
  snapshot: TripServiceSnapshot;
  createdBy: TripCreator;
  actor: string;
  at: string;
}

function trimmedOrNull(value: string | null | undefined): string | null {
  const trimmed = value?.trim();
  return trimmed ? trimmed : null;
}

/** A REQUESTED trip with its first history entry; shape and vehicle capacity are validated. */
export function assembleNewTrip(input: NewTripInput): Trip {
  const { details: d, stay } = input;
  const trip: Trip = {
    tripId: input.tripId, stayId: stay.stayId, villaId: stay.villaId, villaName: stay.villaName, guestName: stay.guestName,
    serviceId: input.serviceId, itemId: input.itemId, snapshot: input.snapshot, type: input.type, ...input.schedule,
    origin: trimmedOrNull(d.origin), destination: trimmedOrNull(d.destination), roundTrip: d.roundTrip ?? false,
    waitMinutes: d.waitMinutes ?? null, passengers: d.passengers, luggage: d.luggage ?? 0,
    guestNotes: d.guestNotes?.trim() ?? '', notes: d.notes?.trim() ?? '', providerId: d.providerId ?? null,
    driver: null, vehicle: null, status: 'REQUESTED', cancellationReason: null, createdBy: input.createdBy,
    statusHistory: [{ from: null, to: 'REQUESTED', at: input.at, by: input.actor, reason: null }],
    createdAt: input.at, createdByActor: input.actor, updatedAt: input.at, updatedBy: input.actor,
  };
  assertValidTrip(trip);
  return trip;
}

export interface TripPatch extends Partial<Omit<TripDetailsInput, 'passengers'>> {
  airportCode?: string;
  flight?: FlightInput;
  pickupAt?: string;
  passengers?: number;
  driver?: TripDriver | null;
  vehicle?: TripVehicle | null;
}

function withoutUndefined<T extends object>(value: T): Partial<T> {
  return Object.fromEntries(Object.entries(value).filter(([, v]) => v !== undefined)) as Partial<T>;
}

function applySchedulePatch(next: Trip, patch: TripPatch, settings: ResortSettings): void {
  if (patch.airportCode !== undefined) next.airportCode = patch.airportCode;
  if (patch.flight !== undefined) next.flight = normalizeFlight(patch.flight, settings.timeZone);
  const airportMoved = patch.airportCode !== undefined || patch.flight !== undefined;
  const airport = airportMoved && isAirportTrip(next.type) && next.airportCode
    ? resolveAirport(settings, next.airportCode)
    : null;
  if (patch.pickupAt !== undefined) {
    next.pickupAt = toInstantIso(patch.pickupAt, settings.timeZone);
  } else if (airport && next.flight) {
    next.pickupAt = suggestedPickupAt(next.type, next.flight.scheduledAt, airport);
  }
}

/**
 * Staff edit of a non-final trip. When the airport or flight changes and no pickup is sent, the
 * suggested pickup is recomputed. The result must keep its shape, capacity and status invariants.
 */
export function applyTripPatch(current: Trip, patch: TripPatch, settings: ResortSettings, actor: string, at: string): Trip {
  if (isFinalTripStatus(current.status)) {
    throw new BusinessRuleError(`Trip is ${current.status}, a final status; it cannot be edited`);
  }
  const { airportCode, flight, pickupAt, ...plain } = patch;
  const next: Trip = { ...structuredClone(current), ...structuredClone(withoutUndefined(plain)), updatedAt: at, updatedBy: actor };
  applySchedulePatch(next, { airportCode, flight, pickupAt }, settings);
  assertValidTrip(next);
  const problems = statusRequirementProblems(next);
  if (problems.length > 0) throw new BusinessRuleError('Invalid trip', problems);
  return next;
}
