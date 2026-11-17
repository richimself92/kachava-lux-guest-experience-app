import { BusinessRuleError } from '../domain-errors';
import { isFinalTripStatus, Trip, TripDriver, TripStatus, TripVehicle } from './trip.models';

/** The only forward move from each status; CANCELLED is reachable from any non-final status. */
const NEXT_STATUS: Partial<Record<TripStatus, TripStatus>> = {
  REQUESTED: 'SENT_TO_PROVIDER',
  SENT_TO_PROVIDER: 'CONFIRMED',
  CONFIRMED: 'EN_ROUTE',
  EN_ROUTE: 'COMPLETED',
};
const NEEDS_PROVIDER: readonly TripStatus[] = ['SENT_TO_PROVIDER', 'CONFIRMED', 'EN_ROUTE', 'COMPLETED'];
const NEEDS_DRIVER: readonly TripStatus[] = ['CONFIRMED', 'EN_ROUTE', 'COMPLETED'];

export interface TripTransitionCommand {
  to: TripStatus;
  reason?: string;
  driver?: TripDriver;
  vehicle?: TripVehicle;
  providerId?: string;
}

function isBlank(value: string | null | undefined): boolean {
  return !value || value.trim().length === 0;
}

/** What a trip in its current status must carry: a provider once sent, a driver once confirmed. */
export function statusRequirementProblems(trip: Trip): string[] {
  const problems: string[] = [];
  if (NEEDS_PROVIDER.includes(trip.status) && isBlank(trip.providerId)) problems.push('providerId is required');
  if (NEEDS_DRIVER.includes(trip.status)) {
    if (isBlank(trip.driver?.name)) problems.push('driver.name is required');
    if (isBlank(trip.driver?.phone)) problems.push('driver.phone is required');
  }
  return problems;
}

function assertMoveAllowed(from: TripStatus, command: TripTransitionCommand): void {
  if (isFinalTripStatus(from)) throw new BusinessRuleError(`Trip is ${from}, a final status; it cannot change`);
  if (command.to === 'CANCELLED') {
    if (isBlank(command.reason)) throw new BusinessRuleError('Cannot cancel the trip', ['reason is required']);
    return;
  }
  if (NEXT_STATUS[from] !== command.to) {
    throw new BusinessRuleError(`Cannot move a trip from ${from} to ${command.to}`);
  }
}

/**
 * Pure status change: validates the move, applies the provider/driver/vehicle sent with it,
 * checks the target status requirements and appends the history entry. Never mutates `trip`.
 */
export function transitionTrip(trip: Trip, command: TripTransitionCommand, actor: string, at: string): Trip {
  assertMoveAllowed(trip.status, command);
  const reason = command.to === 'CANCELLED' ? (command.reason ?? '').trim() : null;
  const next: Trip = {
    ...structuredClone(trip),
    ...(command.providerId !== undefined ? { providerId: command.providerId } : {}),
    ...(command.driver !== undefined ? { driver: structuredClone(command.driver) } : {}),
    ...(command.vehicle !== undefined ? { vehicle: structuredClone(command.vehicle) } : {}),
    status: command.to,
    cancellationReason: reason ?? trip.cancellationReason,
    updatedAt: at,
    updatedBy: actor,
  };
  const problems = statusRequirementProblems(next);
  if (problems.length > 0) throw new BusinessRuleError(`Cannot move the trip to ${command.to}`, problems);
  next.statusHistory.push({ from: trip.status, to: command.to, at, by: actor, reason });
  return next;
}
