import { LocalizedText, ServiceSection } from '../catalog/catalog.models';
import { ExperienceBooking, LarderOrderItem, StayAggregate } from '../models/domain.models';
import { orderRefId } from '../stays/open-requests';
import { resortWallTime } from '../time/zoned-time';

/**
 * Section request queues (Experiences, Dining, Wellness): one entry per guest booking and one per
 * order (the lines of one service). Entries are a read projection of the stay, rewritten in the
 * same transaction as the stay, so the queue is paged by indexed Firestore queries.
 * The status vocabulary is the one the guest sees: Received, Confirmed, Preparing, Done, Cancelled.
 */
export const REQUEST_STATUSES = ['RECEIVED', 'CONFIRMED', 'PREPARING', 'DONE', 'CANCELLED'] as const;
export type RequestStatus = (typeof REQUEST_STATUSES)[number];
/** Status filter values: one status, or every request still to be handled. */
export const REQUEST_STATUS_FILTERS = [...REQUEST_STATUSES, 'OPEN'] as const;
export type RequestStatusFilter = (typeof REQUEST_STATUS_FILTERS)[number];
export type RequestKind = 'BOOKING' | 'ORDER';

export interface ServiceRequestLine {
  name: LocalizedText;
  quantity: number;
}

export interface ServiceRequestEntry {
  /** The booking id, or `orderRefId(stayId, serviceId)` for an order. */
  requestId: string;
  kind: RequestKind;
  stayId: string;
  villaId: string;
  villaName: string;
  guestName: string;
  serviceId: string;
  serviceName: LocalizedText;
  /** Null for older order lines stored without their section. */
  section: ServiceSection | null;
  /** Resort wall time (YYYY-MM-DDTHH:mm): the booked slot, or when the order was placed. */
  at: string;
  /** Party size of a booking; total units of an order. */
  quantity: number;
  status: RequestStatus;
  open: boolean;
  lines: ServiceRequestLine[];
  totalUSD: number | null;
  cancellationReason: string | null;
  createdAt: string;
  updatedAt: string;
}

const CLOSED: readonly RequestStatus[] = ['DONE', 'CANCELLED'];

export function isOpenRequestStatus(status: RequestStatus): boolean {
  return !CLOSED.includes(status);
}

export function bookingRequestStatus(status: ExperienceBooking['status']): RequestStatus {
  switch (status) {
    case 'CONFIRMED':
      return 'CONFIRMED';
    case 'IN_PREPARATION':
      return 'PREPARING';
    case 'COMPLETED':
      return 'DONE';
    case 'CANCELLED':
      return 'CANCELLED';
    default:
      return 'RECEIVED';
  }
}

/** Order statuses are free text on older lines; the same words the guest portal reads. */
export function orderRequestStatus(provisioningStatus: string): RequestStatus {
  const s = (provisioningStatus ?? '').toLowerCase();
  if (s.includes('cancel')) return 'CANCELLED';
  if (['deliver', 'complete', 'stocked', 'done'].some((w) => s.includes(w))) return 'DONE';
  if (['progress', 'prepar', 'provision'].some((w) => s.includes(w))) return 'PREPARING';
  if (s.includes('confirm') || s.includes('assign')) return 'CONFIRMED';
  return 'RECEIVED';
}

/** The wall time of an instant, or its UTC minutes when the resort zone is not configured. */
function wallTimeOf(instantIso: string, timeZone: string | null): string {
  return timeZone ? resortWallTime(new Date(instantIso), timeZone) : instantIso.slice(0, 16);
}

function bookingEntry(stay: StayAggregate, b: ExperienceBooking): ServiceRequestEntry {
  const status = bookingRequestStatus(b.status);
  return {
    requestId: b.bookingId,
    kind: 'BOOKING',
    stayId: stay.stayId,
    villaId: stay.villaId,
    villaName: stay.villaName,
    guestName: stay.guestProfile?.name ?? b.guestNames,
    serviceId: b.serviceId,
    serviceName: structuredClone(b.snapshot?.serviceName ?? { en: b.title, es: b.title }),
    section: b.section ?? b.snapshot?.section ?? null,
    at: `${b.scheduledDate}T${b.scheduledTimeSlot || '00:00'}`,
    quantity: b.partySize,
    status,
    open: isOpenRequestStatus(status),
    lines: (b.snapshot?.lines ?? []).map((l) => ({ name: structuredClone(l.name), quantity: l.quantity })),
    totalUSD: b.snapshot?.totalUSD ?? b.priceChargedUSD,
    cancellationReason: status === 'CANCELLED' ? b.cancellationReason || null : null,
    createdAt: b.createdAt,
    updatedAt: b.updatedAt ?? b.createdAt,
  };
}

/** One order = the lines of one service; its status is the first open line's (else the first). */
function orderEntry(stay: StayAggregate, lines: LarderOrderItem[], timeZone: string | null): ServiceRequestEntry {
  const [first] = lines;
  const statuses = lines.map((l) => orderRequestStatus(l.provisioningStatus));
  const status = statuses.find(isOpenRequestStatus) ?? statuses[0];
  const placedAt = lines.map((l) => l.createdAt ?? l.updatedAt).sort()[0];
  const updatedAt = lines.map((l) => l.updatedAt).sort().reverse()[0];
  return {
    requestId: orderRefId(stay.stayId, first.serviceId),
    kind: 'ORDER',
    stayId: stay.stayId,
    villaId: stay.villaId,
    villaName: stay.villaName,
    guestName: stay.guestProfile?.name ?? first.guestNames,
    serviceId: first.serviceId,
    serviceName: structuredClone(first.serviceName ?? { en: first.name, es: first.name }),
    section: first.section ?? null,
    at: wallTimeOf(placedAt, timeZone),
    quantity: lines.reduce((sum, l) => sum + l.quantity, 0),
    status,
    open: isOpenRequestStatus(status),
    lines: lines.map((l) => ({ name: structuredClone(l.itemName ?? { en: l.name, es: l.name }), quantity: l.quantity })),
    totalUSD: Math.round(lines.reduce((sum, l) => sum + l.lineTotalUSD, 0) * 100) / 100,
    cancellationReason: status === 'CANCELLED' ? first.cancellationReason || null : null,
    createdAt: placedAt,
    updatedAt,
  };
}

/** Every booking and order of the stay as queue entries (orders need the zone for their time). */
export function projectServiceRequests(stay: StayAggregate, timeZone: string | null): ServiceRequestEntry[] {
  const byService = new Map<string, LarderOrderItem[]>();
  for (const line of stay.larderOrders ?? []) {
    byService.set(line.serviceId, [...(byService.get(line.serviceId) ?? []), line]);
  }
  return [
    ...(stay.experienceBookings ?? []).map((b) => bookingEntry(stay, b)),
    ...Array.from(byService.values()).map((lines) => orderEntry(stay, lines, timeZone)),
  ];
}
