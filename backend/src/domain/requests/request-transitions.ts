import { BusinessRuleError, EntityNotFoundError } from '../domain-errors';
import { removeBookingCharge, removeOrderCharge } from '../folio-ledger';
import { ExperienceBooking, LarderOrderItem, StayAggregate } from '../models/domain.models';
import { bookingRequestStatus, orderRequestStatus, RequestKind, RequestStatus } from './service-requests';

/** Staff actions of the request queue; each one is its own button in the row detail. */
export const REQUEST_ACTIONS = ['CONFIRM', 'START', 'COMPLETE', 'CANCEL'] as const;
export type RequestAction = (typeof REQUEST_ACTIONS)[number];

/** Statuses each action may start from; the target status of each action. */
const ALLOWED_FROM: Record<RequestAction, readonly RequestStatus[]> = {
  CONFIRM: ['RECEIVED'],
  START: ['RECEIVED', 'CONFIRMED'],
  COMPLETE: ['CONFIRMED', 'PREPARING'],
  CANCEL: ['RECEIVED', 'CONFIRMED', 'PREPARING'],
};
const TARGET: Record<RequestAction, RequestStatus> = {
  CONFIRM: 'CONFIRMED',
  START: 'PREPARING',
  COMPLETE: 'DONE',
  CANCEL: 'CANCELLED',
};
const BOOKING_STATUS: Record<RequestStatus, ExperienceBooking['status']> = {
  RECEIVED: 'REQUESTED',
  CONFIRMED: 'CONFIRMED',
  PREPARING: 'IN_PREPARATION',
  DONE: 'COMPLETED',
  CANCELLED: 'CANCELLED',
};
/** Words the guest portal and the open-request counters already understand. */
const ORDER_STATUS: Record<RequestStatus, string> = {
  RECEIVED: 'Pending',
  CONFIRMED: 'Confirmed',
  PREPARING: 'Preparing',
  DONE: 'Completed',
  CANCELLED: 'Cancelled',
};

export interface RequestRef {
  kind: RequestKind;
  /** Booking id, or the ordered service id for an order. */
  id: string;
}

export interface RequestMove {
  action: RequestAction;
  reason?: string;
  at: string;
}

function nextStatus(current: RequestStatus, move: RequestMove): RequestStatus {
  if (!ALLOWED_FROM[move.action].includes(current)) {
    throw new BusinessRuleError(`A ${current} request cannot be moved with ${move.action}`);
  }
  if (move.action === 'CANCEL' && !move.reason?.trim()) {
    throw new BusinessRuleError('A cancellation needs a reason');
  }
  return TARGET[move.action];
}

function moveBooking(stay: StayAggregate, bookingId: string, move: RequestMove): void {
  const booking = stay.experienceBookings.find((b) => b.bookingId === bookingId);
  if (!booking) throw new EntityNotFoundError('Request', bookingId);
  const to = nextStatus(bookingRequestStatus(booking.status), move);
  booking.status = BOOKING_STATUS[to];
  booking.updatedAt = move.at;
  if (to === 'CANCELLED') {
    booking.cancellationReason = move.reason!.trim();
    removeBookingCharge(stay, bookingId);
  }
}

function moveOrder(stay: StayAggregate, serviceId: string, move: RequestMove): void {
  const lines: LarderOrderItem[] = stay.larderOrders.filter((l) => l.serviceId === serviceId);
  if (lines.length === 0) throw new EntityNotFoundError('Request', serviceId);
  const statuses = lines.map((l) => orderRequestStatus(l.provisioningStatus));
  const current = statuses.find((s) => s !== 'DONE' && s !== 'CANCELLED') ?? statuses[0];
  const to = nextStatus(current, move);
  for (const line of lines) {
    line.provisioningStatus = ORDER_STATUS[to];
    line.updatedAt = move.at;
    if (to === 'CANCELLED') line.cancellationReason = move.reason!.trim();
  }
  if (to === 'CANCELLED') removeOrderCharge(stay, serviceId);
}

/**
 * Applies a staff action to one booking or order of the stay (pure mutator on the draft):
 * 404 when unknown, 422 when the action does not apply to the current status or a cancel
 * has no reason. Cancelling drops the request's folio charge.
 */
export function applyRequestTransition(stay: StayAggregate, ref: RequestRef, move: RequestMove): void {
  if (ref.kind === 'BOOKING') moveBooking(stay, ref.id, move);
  else moveOrder(stay, ref.id, move);
  stay.updatedAt = move.at;
}
