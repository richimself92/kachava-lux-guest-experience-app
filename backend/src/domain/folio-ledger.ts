import {
  ExperienceBooking,
  FolioItem,
  FolioSummary,
  LarderOrderItem,
  StayAggregate,
} from './models/domain.models';

/** Folio line id kept for the single larder line (the shape production documents already hold). */
const LARDER_FOLIO_ITEM_ID = 'folio-4';

/**
 * Pure folio rules. Repositories apply them inside the stay transaction to the freshly read
 * stay, so folio lines and totals are always derived from the stored state, never from a
 * snapshot read earlier in the request.
 */
export function recalculateFolioSummary(current: FolioSummary, items: FolioItem[]): FolioSummary {
  const complimentarySavingsUSD = items
    .filter((i) => i.isComplimentary)
    .reduce((sum, i) => sum + (i.originalValuationUSD || 0), 0);
  const incidentalsSubtotalUSD = items
    .filter((i) => !i.isComplimentary && i.category !== 'ECOLOGICAL_LEVY')
    .reduce((sum, i) => sum + i.chargedAmountUSD, 0);
  const ecologicalLevyUSD = items
    .filter((i) => i.category === 'ECOLOGICAL_LEVY')
    .reduce((sum, i) => sum + i.chargedAmountUSD, 0);
  return {
    ...current,
    complimentarySavingsUSD,
    incidentalsSubtotalUSD,
    ecologicalLevyUSD,
    finalSettledTotalUSD: incidentalsSubtotalUSD + ecologicalLevyUSD,
  };
}

/** Adds the folio line of a paid booking charged to the folio, then refreshes totals. */
export function chargeBooking(stay: StayAggregate, booking: ExperienceBooking): void {
  if (booking.snapshot.chargeToFolio && booking.priceChargedUSD > 0) {
    stay.folioItems.push({
      folioItemId: `folio_${booking.bookingId}`,
      displayOrder: stay.folioItems.length + 1,
      title: booking.title,
      subtitle: `${booking.scheduledDate} · ${booking.scheduledTimeSlot}`,
      category: 'SERVICE',
      badgeLabel: null,
      isComplimentary: false,
      originalValuationUSD: booking.originalValuationUSD,
      chargedAmountUSD: booking.priceChargedUSD,
      status: 'PRE_AUTHORIZED',
      sourceRefId: booking.bookingId,
      createdAt: booking.createdAt,
    });
  }
  stay.folioSummary = recalculateFolioSummary(stay.folioSummary, stay.folioItems);
}

/** How the stocking order is charged: the service name (snapshot) and its folio setting. */
export interface LarderCharge {
  title: string;
  chargeToFolio: boolean;
}

/** Folio line of one ORDER service (one line per service). */
export function orderFolioItemId(serviceId: string): string {
  return `folio_order_${serviceId}`;
}

function sumLines(lines: LarderOrderItem[]): number {
  return lines.reduce((acc, line) => acc + line.lineTotalUSD, 0);
}

/**
 * Sets the folio line of `serviceId` to its order total (created when charged, removed when
 * nothing is charged) and refreshes totals. `stay.larderOrders` must already hold the new lines.
 */
export function chargeServiceOrder(stay: StayAggregate, serviceId: string, now: string, charge: LarderCharge): void {
  const lines = stay.larderOrders.filter((line) => line.serviceId === serviceId);
  const total = charge.chargeToFolio ? sumLines(lines) : 0;
  const lineId = orderFolioItemId(serviceId);
  const existing = stay.folioItems.find((item) => item.folioItemId === lineId);
  if (total <= 0) {
    stay.folioItems = stay.folioItems.filter((item) => item.folioItemId !== lineId);
  } else if (existing) {
    Object.assign(existing, { title: charge.title, subtitle: `${lines.length} items`, originalValuationUSD: total, chargedAmountUSD: total });
  } else {
    stay.folioItems.push(orderFolioLine(lineId, serviceId, stay.folioItems.length + 1, total, lines.length, now, charge.title));
  }
  rechargeLegacyLarderLine(stay);
  stay.folioSummary = recalculateFolioSummary(stay.folioSummary, stay.folioItems);
}

/**
 * Older stays hold one larder line for the whole cart. It keeps charging only the lines written
 * before per-service ordering (they carry no `createdAt`) and is removed once none is left.
 */
function rechargeLegacyLarderLine(stay: StayAggregate): void {
  const legacy = stay.folioItems.find((item) => item.folioItemId === LARDER_FOLIO_ITEM_ID);
  if (!legacy) return;
  const uncovered = stay.larderOrders.filter((line) => !line.createdAt);
  const total = legacy.chargedAmountUSD > 0 ? sumLines(uncovered) : 0;
  if (total <= 0) {
    stay.folioItems = stay.folioItems.filter((item) => item !== legacy);
    return;
  }
  Object.assign(legacy, { subtitle: `${uncovered.length} items`, originalValuationUSD: total, chargedAmountUSD: total });
}

function orderFolioLine(
  folioItemId: string,
  serviceId: string,
  displayOrder: number,
  total: number,
  count: number,
  now: string,
  title: string,
): FolioItem {
  return {
    folioItemId,
    displayOrder,
    title,
    subtitle: `${count} items`,
    category: 'LARDER',
    badgeLabel: null,
    isComplimentary: false,
    originalValuationUSD: total,
    chargedAmountUSD: total,
    status: 'PRE_AUTHORIZED',
    sourceRefId: serviceId,
    createdAt: now,
  };
}

/** Drops the folio line of a cancelled booking and refreshes totals. */
export function removeBookingCharge(stay: StayAggregate, bookingId: string): void {
  stay.folioItems = stay.folioItems.filter((item) => item.sourceRefId !== bookingId);
  stay.folioSummary = recalculateFolioSummary(stay.folioSummary, stay.folioItems);
}

/** Drops the folio line of one order service (a cancelled order) and refreshes totals. */
export function removeOrderCharge(stay: StayAggregate, serviceId: string): void {
  const lineId = orderFolioItemId(serviceId);
  stay.folioItems = stay.folioItems.filter((item) => item.folioItemId !== lineId);
  stay.folioSummary = recalculateFolioSummary(stay.folioSummary, stay.folioItems);
}

/** Re-prices the folio line of a changed booking (date, time, party) and refreshes totals. */
export function rechargeBooking(stay: StayAggregate, booking: ExperienceBooking): void {
  const line = stay.folioItems.find((item) => item.sourceRefId === booking.bookingId);
  if (line) {
    Object.assign(line, {
      subtitle: `${booking.scheduledDate} · ${booking.scheduledTimeSlot}`,
      originalValuationUSD: booking.originalValuationUSD,
      chargedAmountUSD: booking.priceChargedUSD,
    });
  }
  stay.folioSummary = recalculateFolioSummary(stay.folioSummary, stay.folioItems);
}
