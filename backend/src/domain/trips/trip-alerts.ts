import * as crypto from 'crypto';
import { OperationalAlert } from '../models/domain.models';
import { Trip } from './trip.models';

export type TripAlertReason = 'REQUESTED' | 'FLIGHT_CHANGED';

export function newAlertId(): string {
  return `alt_${crypto.randomUUID()}`;
}

const TITLES: Record<TripAlertReason, (trip: Trip) => string> = {
  REQUESTED: (trip) => `${trip.villaName}: ${trip.type} trip requested`,
  FLIGHT_CHANGED: (trip) => `${trip.villaName}: flight changed`,
};

function summaryOf(trip: Trip): string {
  const pickup = `pickup ${trip.pickupAt}`;
  if (!trip.flight) return `${trip.guestName} · ${pickup}`;
  const { airline, number, scheduledAt } = trip.flight;
  return `${trip.guestName} · ${airline} ${number} at ${scheduledAt} · ${pickup}`;
}

/** Urgent transport alert (TRANSFER / HIGH) whose "open record" target is the trip. */
export function tripAlert(trip: Trip, reason: TripAlertReason, alertId: string, createdAt: string): OperationalAlert {
  return {
    alertId,
    stayId: trip.stayId,
    villaId: trip.villaId,
    villaName: trip.villaName,
    guestNames: trip.guestName,
    category: 'TRANSFER',
    severity: 'HIGH',
    title: TITLES[reason](trip),
    summary: summaryOf(trip),
    sourceDocumentPath: `trips/${trip.tripId}`,
    assignedDepartment: 'TRANSPORT',
    isAcknowledged: false,
    acknowledgedByStaffId: null,
    acknowledgedAt: null,
    createdAt,
    targetRef: { type: 'TRIP', id: trip.tripId },
  };
}
