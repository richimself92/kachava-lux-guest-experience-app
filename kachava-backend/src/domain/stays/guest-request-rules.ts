import { ServiceSnapshot } from '../catalog/catalog.models';
import { BusinessRuleError, EntityNotFoundError } from '../domain-errors';
import {
  chargeServiceOrder,
  LarderCharge,
  rechargeBooking,
  removeBookingCharge,
} from '../folio-ledger';
import { ExperienceBooking, FolioSummary, LarderOrderItem, StayAggregate } from '../models/domain.models';

/**
 * Guest self-service rules applied to the stay as stored at commit time (pure mutators: they
 * edit the given draft and return detached copies). A guest may cancel or change a booking only
 * while it is still REQUESTED; anything later goes through the Resort Host.
 */
export const GUEST_CANCELLATION_REASON = 'Cancelled by guest';
const GUEST_EDITABLE_STATUS: ExperienceBooking['status'] = 'REQUESTED';

export interface BookingChange {
  scheduledDate?: string;
  scheduledTimeSlot?: string;
  partySize?: number;
}

export interface JourneyMarks {
  skippedTaskIds: string[];
  completedTaskIds: string[];
}

function roundCents(value: number): number {
  return Math.round(value * 100) / 100;
}

function editableBooking(stay: StayAggregate, bookingId: string): ExperienceBooking {
  const booking = stay.experienceBookings.find((b) => b.bookingId === bookingId);
  if (!booking) throw new EntityNotFoundError('Booking', bookingId);
  if (booking.status !== GUEST_EDITABLE_STATUS) {
    throw new BusinessRuleError(`Booking is ${booking.status}; only a REQUESTED booking can be changed by the guest`);
  }
  return booking;
}

export function cancelGuestBooking(stay: StayAggregate, bookingId: string, at: string): ExperienceBooking {
  const booking = editableBooking(stay, bookingId);
  Object.assign(booking, { status: 'CANCELLED', cancellationReason: GUEST_CANCELLATION_REASON, updatedAt: at });
  removeBookingCharge(stay, bookingId);
  stay.updatedAt = at;
  return structuredClone(booking);
}

/** A PER_PERSON snapshot re-priced for `partySize` with its captured unit prices. */
export function resizeSnapshotParty(snapshot: ServiceSnapshot, partySize: number): ServiceSnapshot {
  if (snapshot.pricingMode !== 'PER_PERSON') return structuredClone(snapshot);
  const lines = snapshot.lines.map((line) => ({
    ...structuredClone(line),
    lineTotalUSD: line.unitPriceUSD === null ? null : roundCents(line.unitPriceUSD * line.quantity * partySize),
  }));
  const priced = lines.every((line) => line.lineTotalUSD !== null);
  const totalUSD = priced ? roundCents(lines.reduce((sum, line) => sum + (line.lineTotalUSD ?? 0), 0)) : null;
  return { ...structuredClone(snapshot), lines, totalUSD };
}

/** New date, time or party size for a REQUESTED booking; the price keeps the captured snapshot. */
export function changeGuestBooking(
  stay: StayAggregate,
  bookingId: string,
  change: BookingChange,
  at: string,
): ExperienceBooking {
  const booking = editableBooking(stay, bookingId);
  if (booking.usageType !== 'BOOKING') {
    throw new BusinessRuleError(`A ${booking.usageType} request has no date, time or party to change`);
  }
  const partySize = change.partySize ?? booking.partySize;
  const snapshot = resizeSnapshotParty(booking.snapshot, partySize);
  const total = snapshot.totalUSD ?? 0;
  Object.assign(booking, {
    scheduledDate: change.scheduledDate ?? booking.scheduledDate,
    scheduledTimeSlot: change.scheduledTimeSlot ?? booking.scheduledTimeSlot,
    partySize,
    snapshot,
    originalValuationUSD: total,
    priceChargedUSD: total,
    updatedAt: at,
  });
  rechargeBooking(stay, booking);
  stay.updatedAt = at;
  return structuredClone(booking);
}

function firstCreatedAt(lines: LarderOrderItem[]): string | undefined {
  return lines.map((line) => line.createdAt).filter((value): value is string => Boolean(value)).sort()[0];
}

/**
 * Replaces the lines of ONE order service (other services' lines stay untouched) and charges
 * that service's folio line. The order keeps the time it was first placed as `createdAt`.
 */
export function replaceServiceOrder(
  stay: StayAggregate,
  serviceId: string,
  lines: LarderOrderItem[],
  charge: LarderCharge,
  at: string,
): { orders: LarderOrderItem[]; folioSummary: FolioSummary } {
  const previous = stay.larderOrders.filter((line) => line.serviceId === serviceId);
  const createdAt = firstCreatedAt(previous) ?? at;
  const fresh = lines.map((line) => ({ ...structuredClone(line), serviceId, createdAt, updatedAt: at }));
  stay.larderOrders = [...stay.larderOrders.filter((line) => line.serviceId !== serviceId), ...fresh];
  stay.updatedAt = at;
  chargeServiceOrder(stay, serviceId, at, charge);
  return { orders: structuredClone(stay.larderOrders), folioSummary: structuredClone(stay.folioSummary) };
}

/** Replaces the given journey lists (absent lists are kept); duplicates are dropped. */
export function setJourneyMarks(stay: StayAggregate, marks: Partial<JourneyMarks>, at: string): JourneyMarks {
  if (marks.skippedTaskIds) stay.skippedTaskIds = [...new Set(marks.skippedTaskIds)];
  if (marks.completedTaskIds) stay.completedTaskIds = [...new Set(marks.completedTaskIds)];
  if (marks.skippedTaskIds || marks.completedTaskIds) stay.updatedAt = at;
  return {
    skippedTaskIds: [...(stay.skippedTaskIds ?? [])],
    completedTaskIds: [...(stay.completedTaskIds ?? [])],
  };
}

/** Guest photos must live in the stay's own private concierge folder (no traversal). */
export function isStayPhotoPath(stayId: string, path: string): boolean {
  const normalized = path.startsWith('/') ? path : `/${path}`;
  const folder = `/private/stays/${stayId}/concierge/`;
  if (!normalized.startsWith(folder) || normalized.length === folder.length) return false;
  return !normalized.split('/').some((segment) => segment === '..' || segment === '.');
}
