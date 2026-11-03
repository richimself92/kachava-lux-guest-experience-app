import {
  ExperienceBooking,
  FolioItem,
  FolioSummary,
  LarderOrderItem,
  StayAggregate,
  StayLifecycleStatus,
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

/** Sets the single larder line to the order total (creating it when needed) and refreshes totals. */
export function chargeLarderOrder(
  stay: StayAggregate,
  orders: LarderOrderItem[],
  now: string,
  charge: LarderCharge,
): void {
  const total = charge.chargeToFolio ? orders.reduce((acc, o) => acc + o.lineTotalUSD, 0) : 0;
  const existing = stay.folioItems.find((fi) => fi.category === 'LARDER');
  if (existing) {
    existing.title = charge.title;
    existing.subtitle = `${orders.length} items`;
    existing.originalValuationUSD = total;
    existing.chargedAmountUSD = total;
  } else if (total > 0) {
    stay.folioItems.push(larderFolioLine(stay.folioItems.length + 1, total, orders.length, now, charge.title));
  }
  stay.folioSummary = recalculateFolioSummary(stay.folioSummary, stay.folioItems);
}

function larderFolioLine(
  displayOrder: number,
  total: number,
  count: number,
  now: string,
  title: string,
): FolioItem {
  return {
    folioItemId: LARDER_FOLIO_ITEM_ID,
    displayOrder,
    title,
    subtitle: `${count} items`,
    category: 'LARDER',
    badgeLabel: null,
    isComplimentary: false,
    originalValuationUSD: total,
    chargedAmountUSD: total,
    status: 'PRE_AUTHORIZED',
    sourceRefId: 'larder-cart',
    createdAt: now,
  };
}

/** Checkout settlement; `status` omitted keeps the current lifecycle status. */
export interface FolioSettlement {
  settledAt: string;
  status?: StayLifecycleStatus;
  lateCheckoutRequested?: boolean;
  approvedByStaffId?: string;
  /** Admin approval keeps the guest's original checkout time when one exists. */
  keepFirstCheckoutTime?: boolean;
}

export interface SettledFolio {
  folioSummary: FolioSummary;
  folioItems: FolioItem[];
  status: StayLifecycleStatus;
}

/** Settles every folio line currently stored on the stay. */
export function settleFolio(stay: StayAggregate, settlement: FolioSettlement): SettledFolio {
  const previousCheckout = stay.folioSummary.checkedOutAt;
  stay.folioItems = stay.folioItems.map((item) => ({ ...item, status: 'SETTLED' as const }));
  stay.folioSummary = {
    ...stay.folioSummary,
    paymentStatus: 'SETTLED',
    isCheckedOut: true,
    checkedOutAt: (settlement.keepFirstCheckoutTime && previousCheckout) || settlement.settledAt,
    ...(settlement.approvedByStaffId ? { approvedByStaffId: settlement.approvedByStaffId } : {}),
  };
  if (settlement.status) stay.status = settlement.status;
  if (settlement.lateCheckoutRequested !== undefined) {
    stay.flightTransfer.lateCheckoutRequested = settlement.lateCheckoutRequested;
  }
  return {
    folioSummary: structuredClone(stay.folioSummary),
    folioItems: structuredClone(stay.folioItems),
    status: stay.status,
  };
}
