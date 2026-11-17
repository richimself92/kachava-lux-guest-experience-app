import { CatalogService } from '../catalog/catalog.models';
import { BusinessRuleError, SettingsRequiredError } from '../domain-errors';
import { AirportSetting, ResortSettings } from '../models/resort-config.models';
import { isAirportTrip, Trip, TripFlight, TripType, UNCONFIRMED_TRIP_STATUSES } from './trip.models';

const MS_PER_HOUR = 3_600_000;

function isBlank(value: string | null | undefined): boolean {
  return !value || value.trim().length === 0;
}

/**
 * The airport of an ARRIVAL/DEPARTURE trip must be configured in Settings (else
 * SETTINGS_REQUIRED) with its departure buffer, and be active.
 */
export function resolveAirport(settings: ResortSettings, code: string): AirportSetting {
  const airport = settings.airports.find((candidate) => candidate.code === code);
  if (!airport) throw new SettingsRequiredError([`airports.${code}`]);
  if (typeof airport.departureBufferHours !== 'number') {
    throw new SettingsRequiredError([`airports.${code}.departureBufferHours`]);
  }
  if (!airport.isActive) throw new BusinessRuleError(`Airport ${code} is not active`);
  return airport;
}

/** Hours before pickup at which an unconfirmed trip becomes urgent (Settings, no default). */
export function requireLeadHours(settings: ResortSettings): number {
  if (settings.transportAlertLeadHours === null || settings.transportAlertLeadHours === undefined) {
    throw new SettingsRequiredError(['transportAlertLeadHours']);
  }
  return settings.transportAlertLeadHours;
}

/** Arrivals are picked up at landing; departures leave the airport buffer before the flight. */
export function suggestedPickupAt(type: TripType, flightAtIso: string, airport: AirportSetting): string {
  if (type !== 'DEPARTURE') return flightAtIso;
  return new Date(Date.parse(flightAtIso) - airport.departureBufferHours * MS_PER_HOUR).toISOString();
}

function airportTripProblems(trip: Trip): string[] {
  return [
    ...(isBlank(trip.airportCode) ? [`airportCode is required for ${trip.type} trips`] : []),
    ...(trip.flight ? [] : [`flight is required for ${trip.type} trips`]),
    ...(trip.roundTrip ? ['roundTrip applies to LOCAL trips only'] : []),
    ...(trip.waitMinutes !== null ? ['waitMinutes applies to LOCAL trips only'] : []),
  ];
}

function localTripProblems(trip: Trip): string[] {
  return [
    ...(isBlank(trip.origin) ? ['origin is required for LOCAL trips'] : []),
    ...(isBlank(trip.destination) ? ['destination is required for LOCAL trips'] : []),
    ...(trip.airportCode !== null ? ['airportCode applies to airport trips only'] : []),
    ...(trip.flight !== null ? ['flight applies to airport trips only'] : []),
  ];
}

/** Fields each trip type needs (and the ones it must not carry). */
export function tripShapeProblems(trip: Trip): string[] {
  return isAirportTrip(trip.type) ? airportTripProblems(trip) : localTripProblems(trip);
}

/** Passengers and luggage must fit the vehicle item chosen at request time. */
export function capacityProblems(trip: Trip): string[] {
  const capacity = trip.snapshot?.vehicleCapacity;
  if (!capacity) return [];
  return [
    ...(trip.passengers > capacity.passengers ? [`passengers exceed the vehicle capacity of ${capacity.passengers}`] : []),
    ...(trip.luggage > capacity.luggage ? [`luggage exceeds the vehicle capacity of ${capacity.luggage}`] : []),
  ];
}

export function assertValidTrip(trip: Trip): void {
  const problems = [...tripShapeProblems(trip), ...capacityProblems(trip)];
  if (problems.length > 0) throw new BusinessRuleError('Invalid trip', problems);
}

/** Guests ask ahead: pickup in the future and at least the service's `minLeadHours` away. */
export function assertGuestLeadTime(pickupAtIso: string, now: Date, minLeadHours: number | null): void {
  const hoursAhead = (Date.parse(pickupAtIso) - now.getTime()) / MS_PER_HOUR;
  if (hoursAhead <= 0) throw new BusinessRuleError('The pickup time must be in the future');
  if (minLeadHours !== null && hoursAhead < minLeadHours) {
    throw new BusinessRuleError(`Trips must be requested at least ${minLeadHours} hours ahead`);
  }
}

/** A transport service that lists airports only serves those. */
export function assertServiceServesAirport(service: CatalogService, airportCode: string): void {
  const served = service.transport?.airportCodes ?? [];
  if (served.length > 0 && !served.includes(airportCode)) {
    throw new BusinessRuleError(`Service ${service.serviceId} does not serve airport ${airportCode}`);
  }
}

/**
 * Not confirmed yet and the pickup is at most `leadHours` away (or already past).
 * Null when the lead time is not configured: the flag is unknown, never guessed.
 */
export function isUnconfirmedDue(trip: Trip, now: Date, leadHours: number | null): boolean | null {
  if (leadHours === null) return null;
  if (!UNCONFIRMED_TRIP_STATUSES.includes(trip.status)) return false;
  return Date.parse(trip.pickupAt) - now.getTime() <= leadHours * MS_PER_HOUR;
}

/** Latest pickup instant that is already due for a lead time of `leadHours`. */
export function unconfirmedDueCutoff(now: Date, leadHours: number): string {
  return new Date(now.getTime() + leadHours * MS_PER_HOUR).toISOString();
}

function sameFlight(a: TripFlight | null, b: TripFlight | null): boolean {
  if (!a || !b) return a === b;
  return a.airline === b.airline && a.number === b.number && a.scheduledAt === b.scheduledAt;
}

export function flightChanged(previous: Trip, next: Trip): boolean {
  return !sameFlight(previous.flight, next.flight);
}
