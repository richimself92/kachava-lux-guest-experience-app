import {
  ConciergeRequest,
  ExperienceBooking,
  LarderOrderItem,
  StayAggregate,
  StayLifecycleStatus,
} from '../models/domain.models';

/** Stays that are still upcoming or in-house; every other status is closed. */
export const OPEN_STAY_STATUSES: readonly StayLifecycleStatus[] = ['PRE_ARRIVAL', 'ACTIVE_STAY'];

const CLOSED_BOOKING_STATUSES: readonly ExperienceBooking['status'][] = ['COMPLETED', 'CANCELLED'];
/** Larder statuses are free text written by the admin; these words close an order line. */
const CLOSED_ORDER_WORDS = ['stocked', 'delivered', 'completed', 'cancelled'];

export function isOpenStay(stay: Pick<StayAggregate, 'status'>): boolean {
  return OPEN_STAY_STATUSES.includes(stay.status);
}

export function isOpenBooking(booking: ExperienceBooking): boolean {
  return !CLOSED_BOOKING_STATUSES.includes(booking.status);
}

export function isOpenOrderLine(line: LarderOrderItem): boolean {
  const status = (line.provisioningStatus ?? '').trim().toLowerCase();
  return !CLOSED_ORDER_WORDS.some((word) => status.startsWith(word));
}

export function isOpenConciergeRequest(request: ConciergeRequest): boolean {
  return !request.isCompleted && request.status !== 'Completed';
}

/** One order per stay and service (its lines are replaced together); the source id of its task. */
export function orderRefId(stayId: string, serviceId: string): string {
  return `${stayId}_${serviceId}`;
}

/** Orders of the stay with at least one open line, one per service. */
export function openOrderCount(stay: StayAggregate): number {
  const open = new Set(stay.larderOrders.filter(isOpenOrderLine).map((line) => orderRefId(stay.stayId, line.serviceId)));
  return open.size;
}

export function openBookingCount(stay: StayAggregate): number {
  return stay.experienceBookings.filter(isOpenBooking).length;
}

export function openConciergeCount(stay: StayAggregate): number {
  return stay.conciergeRequests.filter(isOpenConciergeRequest).length;
}
