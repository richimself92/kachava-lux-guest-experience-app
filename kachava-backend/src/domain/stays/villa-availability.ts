import { BusinessRuleError } from '../domain-errors';
import { StayAggregate } from '../models/domain.models';
import { Villa } from '../models/resort-config.models';
import { isOpenStay } from './open-requests';

/** Nights a reservation occupies: ISO calendar dates, `checkOut` exclusive (departure day is free). */
export interface StayNights {
  checkIn: string;
  checkOut: string;
}

const OUT_OF_SERVICE_STATUSES: readonly Villa['operationalStatus'][] = ['MAINTENANCE', 'BLOCKED'];

/**
 * The single villa overlap rule: an open stay (pre-arrival or in-house) blocks the requested
 * nights when their night ranges intersect. A stay leaving on day D does not block an arrival on
 * D; cancelled, checked-out and expired stays (and undated legacy
 * records) never block. ISO dates compare lexicographically.
 */
export function stayBlocksRange(
  stay: Pick<StayAggregate, 'status' | 'checkInDate' | 'checkOutDate'>,
  range: StayNights,
  resortToday?: string,
): boolean {
  const { checkInDate, checkOutDate } = stay;
  if (!isOpenStay(stay) || !checkInDate || !checkOutDate) return false;
  if (resortToday && isOverstay(stay, resortToday)) return true;
  return checkInDate < range.checkOut && checkOutDate > range.checkIn;
}

/**
 * An in-house guest past the departure date still holds the villa until staff check them out:
 * no new nights can be promised on it (the dashboard flags the overstay in red).
 */
export function isOverstay(
  stay: Pick<StayAggregate, 'status' | 'checkOutDate'>,
  resortToday: string,
): boolean {
  return stay.status === 'ACTIVE_STAY' && !!stay.checkOutDate && stay.checkOutDate < resortToday;
}

/** A reservation range starts today or later (resort day) and spans at least one night. */
export function assertBookableRange(range: StayNights, resortToday: string): void {
  if (range.checkIn < resortToday) throw new BusinessRuleError('checkIn cannot be in the past');
  if (range.checkOut <= range.checkIn) throw new BusinessRuleError('checkOut must be after checkIn');
}

/** Active villas that are not out of service (maintenance, blocked) can take new reservations. */
export function isVillaInService(villa: Villa): boolean {
  return villa.isActive
    && !OUT_OF_SERVICE_STATUSES.includes(villa.operationalStatus)
    && villa.maintenanceStatus !== 'IN_MAINTENANCE';
}
