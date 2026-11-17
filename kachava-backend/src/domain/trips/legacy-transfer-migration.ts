import { ISO_DATE_PATTERN } from '../../common/validation/field-limits';
import { SettingsRequiredError } from '../domain-errors';
import { FlightTransfer, StayAggregate } from '../models/domain.models';
import { ResortSettings } from '../models/resort-config.models';
import { toInstantIso, zonedLocalToUtc } from '../time/zoned-time';
import { tripShapeProblems } from './trip-rules';
import { Trip, TripDriver, TripStatus, TripVehicle } from './trip.models';

/**
 * Plans the ARRIVAL trip that replaces a stay's legacy embedded `flightTransfer`. Pure: the
 * runner (`scripts/migrate-flight-transfers.ts`) reads stays and writes trips. Legacy times are
 * resort wall times (any zone label such as "CST" is ignored) read in the Settings `timeZone`.
 */
export const MIGRATION_ACTOR = 'migration:flightTransfer';
const MIGRATION_REASON = 'Migrated from stays.flightTransfer';
const LEGACY_STATUSES: Record<string, TripStatus> = {
  Confirmed: 'CONFIRMED',
  'En Route': 'EN_ROUTE',
  Completed: 'COMPLETED',
};
const CLOCK_TIME = /^(\d{1,2}):(\d{2})\s*(AM|PM)?\b/i;

export type LegacyArrivalPlan = { trip: Trip } | { skip: string };

/** Deterministic id: re-running the migration finds the trip instead of duplicating it. */
export function legacyArrivalTripId(stayId: string): string {
  return `trip_legacy_arrival_${stayId}`;
}

const text = (value: string | undefined | null) => (value ?? '').trim();

/** "14:05", "2:05 PM", "11:35 AM CST" -> "HH:mm" (24 h), or null. */
function parseClock(value: string | undefined): string | null {
  const match = CLOCK_TIME.exec(text(value));
  if (!match) return null;
  let hour = Number(match[1]);
  const meridiem = match[3]?.toUpperCase();
  if (meridiem && (hour < 1 || hour > 12)) return null;
  if (meridiem) hour = (hour % 12) + (meridiem === 'PM' ? 12 : 0);
  if (hour > 23 || Number(match[2]) > 59) return null;
  return `${String(hour).padStart(2, '0')}:${match[2]}`;
}

function landingInstant(transfer: FlightTransfer, stay: StayAggregate, timeZone: string): string | null {
  const landing = text(transfer.estimatedLanding);
  if (/^\d{4}-\d{2}-\d{2}T.*(Z|[+-]\d{2}:\d{2})$/.test(landing)) return toInstantIso(landing, null);
  const date = [text(transfer.arrivalDate), text(stay.checkInDate)].find((d) => ISO_DATE_PATTERN.test(d));
  const clock = parseClock(transfer.arrivalTime) ?? parseClock(transfer.estimatedLanding);
  if (!date || !clock) return null;
  return zonedLocalToUtc(`${date}T${clock}`, timeZone).toISOString();
}

/** The configured airport whose code appears as a word in the legacy text ("Name (CUN)"). */
function configuredAirportIn(value: string, settings: ResortSettings): string | null {
  const upper = text(value).toUpperCase();
  return settings.airports.map((a) => a.code).find((code) => new RegExp(`\\b${code}\\b`).test(upper)) ?? null;
}

function driverOf(transfer: FlightTransfer): TripDriver | null {
  const name = text(transfer.assignedDriver) || text(transfer.assignedStaffName);
  const phone = text(transfer.driverPhone);
  return name || phone ? { name, phone } : null;
}

function vehicleOf(transfer: FlightTransfer): TripVehicle | null {
  const description = text(transfer.vehicleModel);
  const plate = text(transfer.fleetNumber);
  return description || plate ? { description, plate } : null;
}

/** A positive total wins; legacy documents often hold a 0 placeholder next to the real counts. */
function luggageOf(transfer: FlightTransfer): number {
  const total = Number(transfer.luggageCount) || 0;
  if (total > 0) return total;
  return (Number(transfer.luggageChecked) || 0) + (Number(transfer.luggageCarryOn) || 0);
}

interface LegacyFacts {
  airportCode: string;
  scheduledAt: string;
  passengers: number;
}

function buildTrip(stay: StayAggregate, transfer: FlightTransfer, facts: LegacyFacts, at: string): Trip {
  const status = LEGACY_STATUSES[transfer.status] ?? 'REQUESTED';
  return {
    tripId: legacyArrivalTripId(stay.stayId), stayId: stay.stayId, villaId: stay.villaId, villaName: stay.villaName,
    guestName: text(stay.guestProfile?.name), serviceId: null, itemId: null, snapshot: null, type: 'ARRIVAL',
    airportCode: facts.airportCode,
    flight: { airline: text(transfer.airline), number: text(transfer.flightNumber), scheduledAt: facts.scheduledAt },
    pickupAt: facts.scheduledAt, origin: text(transfer.meetingPoint) || text(transfer.terminal) || null,
    destination: null, roundTrip: false, waitMinutes: null, passengers: facts.passengers, luggage: luggageOf(transfer),
    guestNotes: text(transfer.notes), notes: text(transfer.adminDispatchNotes), providerId: null,
    driver: driverOf(transfer), vehicle: vehicleOf(transfer), status, cancellationReason: null, createdBy: 'GUEST',
    statusHistory: [{ from: null, to: status, at, by: MIGRATION_ACTOR, reason: MIGRATION_REASON }],
    createdAt: at, createdByActor: MIGRATION_ACTOR, updatedAt: at, updatedBy: MIGRATION_ACTOR,
  };
}

function legacyFacts(stay: StayAggregate, settings: ResortSettings & { timeZone: string }): LegacyFacts | string {
  const transfer = stay.flightTransfer;
  const airportCode = configuredAirportIn(transfer.arrivalAirport, settings);
  if (!airportCode) return `airport "${text(transfer.arrivalAirport)}" is not configured in Settings`;
  const scheduledAt = landingInstant(transfer, stay, settings.timeZone);
  if (!scheduledAt) return 'landing time not recognized';
  const passengers = transfer.partySize > 0 ? transfer.partySize : stay.guestsCount;
  if (!(passengers > 0)) return 'party size unknown';
  return { airportCode, scheduledAt, passengers };
}

export function planLegacyArrival(stay: StayAggregate, settings: ResortSettings, at: string): LegacyArrivalPlan {
  const { timeZone } = settings;
  if (!timeZone) throw new SettingsRequiredError(['timeZone']);
  if (settings.airports.length === 0) throw new SettingsRequiredError(['airports']);
  const transfer = stay.flightTransfer;
  if (!transfer || transfer.status === 'Not Requested') return { skip: 'transfer not requested' };
  if (!text(transfer.flightNumber)) return { skip: 'no flight number' };
  const facts = legacyFacts(stay, { ...settings, timeZone });
  if (typeof facts === 'string') return { skip: facts };
  const trip = buildTrip(stay, transfer, facts, at);
  const problems = tripShapeProblems(trip);
  return problems.length > 0 ? { skip: problems.join('; ') } : { trip };
}
