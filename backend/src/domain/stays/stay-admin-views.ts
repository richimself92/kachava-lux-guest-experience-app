import { LocalizedText, ServiceSnapshot } from '../catalog/catalog.models';
import {
  FolioItem,
  FolioSummary,
  HostInfo,
  StayAggregate,
  StayLifecycleStatus,
  StayStatusChange,
} from '../models/domain.models';
import { isFinalTripStatus, Trip } from '../trips/trip.models';
import {
  isOpenBooking,
  isOpenConciergeRequest,
  isOpenOrderLine,
  openBookingCount,
  openConciergeCount,
  openOrderCount,
  orderRefId,
} from './open-requests';

/** Label a new stay shows until staff assign a Resort Host. */
export const UNASSIGNED_HOST_LABEL = 'HOST ADMIN';

/** Admin read models of a stay (Reservations, Guests, Folio). Staff-only: never sent to guests. */
export interface ReservationRow {
  id: string;
  guestName: string;
  villaId: string;
  villaName: string;
  checkIn: string | null;
  checkOut: string | null;
  status: StayLifecycleStatus;
  resortHostName: string | null;
  magicLinkUrl: string;
}

export interface StayDetail extends ReservationRow {
  nights: number;
  guestsCount: number;
  partnerName: string;
  email: string;
  phone: string;
  language: string | null;
  occasion: string;
  resortHost: { staffId: string | null; name: string } | null;
  wifi: { ssid: string; password: string };
  internalNotes: string;
  cancellationReason: string | null;
  statusHistory: StayStatusChange[];
  createdAt: string;
  updatedAt: string;
}

function assignedHost(host: HostInfo | undefined): { staffId: string | null; name: string } | null {
  if (!host) return null;
  const assigned = Boolean(host.staffId) || (Boolean(host.name) && host.name !== UNASSIGNED_HOST_LABEL);
  return assigned ? { staffId: host.staffId || null, name: host.name } : null;
}

/** The link is always built from the current token, so a regenerated token is reflected. */
export function toReservationRow(stay: StayAggregate, magicLinkBase: string): ReservationRow {
  return {
    id: stay.stayId,
    guestName: stay.guestProfile?.name ?? '',
    villaId: stay.villaId,
    villaName: stay.villaName,
    checkIn: stay.checkInDate ?? null,
    checkOut: stay.checkOutDate ?? null,
    status: stay.status,
    resortHostName: assignedHost(stay.hostInfo)?.name ?? null,
    magicLinkUrl: `${magicLinkBase}${stay.guestTokenUuid}`,
  };
}

export function toStayDetail(stay: StayAggregate, magicLinkBase: string): StayDetail {
  const profile = stay.guestProfile;
  return {
    ...toReservationRow(stay, magicLinkBase),
    nights: stay.nights,
    guestsCount: stay.guestsCount,
    partnerName: profile.partner ?? '',
    email: profile.email ?? '',
    phone: profile.phone ?? '',
    language: profile.language ?? null,
    occasion: profile.celebration ?? '',
    resortHost: assignedHost(stay.hostInfo),
    wifi: { ssid: stay.villaAccess.wifiSsid, password: stay.villaAccess.wifiPasscode },
    internalNotes: stay.internalNotes ?? '',
    cancellationReason: stay.cancellationReason ?? null,
    statusHistory: structuredClone(stay.statusHistory ?? []),
    createdAt: stay.createdAt,
    updatedAt: stay.updatedAt,
  };
}

/** One acquired service of the stay (an order, a booking or a trip) with its snapshot. */
export interface FolioService {
  type: 'ORDER' | 'BOOKING' | 'TRIP';
  id: string;
  serviceId: string | null;
  name: LocalizedText;
  status: string;
  date: string | null;
  totalUSD: number | null;
  chargeToFolio: boolean | null;
  lines: Array<{ itemId: string | null; name: LocalizedText; unitPriceUSD: number | null; quantity: number; lineTotalUSD: number | null }>;
  snapshot: ServiceSnapshot | null;
}

export interface StayFolio {
  stay: { id: string; guestName: string; villaId: string; villaName: string; checkIn: string | null; checkOut: string | null; nights: number; status: StayLifecycleStatus };
  services: FolioService[];
  /** Latest mid-stay rating, if the guest gave one. */
  rating: { rating: number | null; sentiment: string; note: string; createdAt: string } | null;
  charges: { items: FolioItem[]; summary: FolioSummary; totalUSD: number };
  /** No PMS is integrated: reservation origin and payments are never simulated. */
  pmsIntegrated: false;
}

function orderServices(stay: StayAggregate): FolioService[] {
  const byService = new Map<string, FolioService>();
  for (const line of stay.larderOrders) {
    const id = orderRefId(stay.stayId, line.serviceId);
    const entry = byService.get(id) ?? {
      type: 'ORDER' as const, id, serviceId: line.serviceId, name: { en: '', es: '' }, status: line.provisioningStatus,
      date: line.updatedAt, totalUSD: 0, chargeToFolio: null, lines: [], snapshot: null,
    };
    entry.lines.push({
      itemId: line.catalogItemId || null, name: line.itemName ?? { en: line.name, es: line.name },
      unitPriceUSD: line.unitPriceUSD, quantity: line.quantity, lineTotalUSD: line.lineTotalUSD,
    });
    entry.totalUSD = (entry.totalUSD ?? 0) + line.lineTotalUSD;
    if (isOpenOrderLine(line)) entry.status = line.provisioningStatus;
    byService.set(id, entry);
  }
  const charge = stay.folioItems.find((item) => item.category === 'LARDER');
  return Array.from(byService.values()).map((entry) => ({ ...entry, name: charge ? { en: charge.title, es: charge.title } : entry.name }));
}

function bookingServices(stay: StayAggregate): FolioService[] {
  return stay.experienceBookings.map((b) => ({
    type: 'BOOKING' as const, id: b.bookingId, serviceId: b.serviceId,
    name: b.snapshot?.serviceName ?? { en: b.title, es: b.title }, status: b.status,
    date: b.scheduledDate || null, totalUSD: b.snapshot?.totalUSD ?? b.priceChargedUSD,
    chargeToFolio: b.snapshot?.chargeToFolio ?? null, lines: structuredClone(b.snapshot?.lines ?? []),
    snapshot: structuredClone(b.snapshot ?? null),
  }));
}

function tripServices(trips: Trip[]): FolioService[] {
  return trips.map((t) => ({
    type: 'TRIP' as const, id: t.tripId, serviceId: t.serviceId,
    name: t.snapshot?.serviceName ?? { en: `${t.type} trip`, es: `${t.type} trip` }, status: t.status,
    date: t.pickupAt, totalUSD: t.snapshot?.totalUSD ?? null, chargeToFolio: t.snapshot?.chargeToFolio ?? null,
    lines: structuredClone(t.snapshot?.lines ?? []), snapshot: structuredClone(t.snapshot ?? null),
  }));
}

/** "Stay summary": acquired services with their snapshots, the mid-stay rating and the charges. */
export function buildStayFolio(stay: StayAggregate, trips: Trip[]): StayFolio {
  const latest = [...stay.midstayFeedback].sort((a, b) => b.createdAt.localeCompare(a.createdAt))[0];
  return {
    stay: {
      id: stay.stayId, guestName: stay.guestProfile?.name ?? '', villaId: stay.villaId, villaName: stay.villaName,
      checkIn: stay.checkInDate ?? null, checkOut: stay.checkOutDate ?? null, nights: stay.nights, status: stay.status,
    },
    services: [...orderServices(stay), ...bookingServices(stay), ...tripServices(trips)],
    rating: latest
      ? { rating: latest.rating ?? null, sentiment: latest.selectedSentiment, note: latest.note, createdAt: latest.createdAt }
      : null,
    charges: {
      items: structuredClone(stay.folioItems),
      summary: structuredClone(stay.folioSummary),
      totalUSD: stay.folioSummary.finalSettledTotalUSD,
    },
    pmsIntegrated: false,
  };
}

export interface GuestRow {
  stayId: string;
  guestName: string;
  villaId: string;
  villaName: string;
  checkIn: string | null;
  checkOut: string | null;
  status: StayLifecycleStatus;
  language: string | null;
  hasAllergies: boolean;
  openRequests: number;
}

function allergyItems(stay: StayAggregate): string[] {
  const listed = stay.personalization?.dietaryAllergies ?? [];
  const label = stay.guestProfile?.allergies || stay.personalization?.allergies || '';
  const items = listed.length > 0 ? listed : label.split(',');
  return items.map((item) => item.trim()).filter((item) => item && item.toLowerCase() !== 'none');
}

/** Open guest requests: orders, bookings and Resort Host requests on the stay plus open trips. */
export function toGuestRow(stay: StayAggregate, openTrips: number): GuestRow {
  return {
    stayId: stay.stayId,
    guestName: stay.guestProfile?.name ?? '',
    villaId: stay.villaId,
    villaName: stay.villaName,
    checkIn: stay.checkInDate ?? null,
    checkOut: stay.checkOutDate ?? null,
    status: stay.status,
    language: stay.guestProfile?.language ?? null,
    hasAllergies: allergyItems(stay).length > 0,
    openRequests: openOrderCount(stay) + openBookingCount(stay) + openConciergeCount(stay) + openTrips,
  };
}

export interface GuestRequestEntry {
  type: 'ORDER' | 'BOOKING' | 'REQUEST' | 'TRIP';
  id: string;
  title: string;
  status: string;
  open: boolean;
  createdAt: string;
}

function requestHistory(stay: StayAggregate, trips: Trip[]): GuestRequestEntry[] {
  const entries: GuestRequestEntry[] = [
    ...stay.experienceBookings.map((b) => ({
      type: 'BOOKING' as const, id: b.bookingId, title: b.title, status: b.status, open: isOpenBooking(b), createdAt: b.createdAt,
    })),
    ...stay.conciergeRequests.map((r) => ({
      type: 'REQUEST' as const, id: r.requestId, title: r.title, status: r.status, open: isOpenConciergeRequest(r), createdAt: r.createdAt,
    })),
    ...stay.larderOrders.map((o) => ({
      type: 'ORDER' as const, id: o.orderItemId, title: `${o.name} × ${o.quantity}`, status: o.provisioningStatus,
      open: isOpenOrderLine(o), createdAt: o.updatedAt,
    })),
    ...trips.map((t) => ({
      type: 'TRIP' as const, id: t.tripId, title: `${t.type} trip`, status: t.status, open: !isFinalTripStatus(t.status), createdAt: t.createdAt,
    })),
  ];
  return entries.sort((a, b) => b.createdAt.localeCompare(a.createdAt));
}

/** Staff-only guest profile of one stay. */
export function toGuestProfileView(stay: StayAggregate, trips: Trip[]) {
  const p = stay.personalization;
  const items = allergyItems(stay);
  return {
    ...toGuestRow(stay, trips.filter((t) => !isFinalTripStatus(t.status)).length),
    partnerName: stay.guestProfile.partner ?? '',
    email: stay.guestProfile.email ?? '',
    phone: stay.guestProfile.phone ?? '',
    preferences: {
      pillow: p.pillowSelection || p.pillowType || '',
      scent: p.scentProfile || p.villaScent || '',
      dietary: p.dietary || stay.guestProfile.dietaryProfile || '',
      temperature: p.temperatureCurve ?? '',
      lighting: p.lightingRhythm ?? '',
      housekeeping: p.housekeepingCadence ?? '',
      interests: [...(p.selectedInterests ?? [])],
      communication: p.commChannel || stay.guestProfile.communicationPref || '',
      choices: stay.experienceBookings
        .filter((b) => b.usageType === 'PREFERENCE')
        .map((b) => ({ bookingId: b.bookingId, serviceId: b.serviceId, title: b.title, status: b.status })),
    },
    allergies: { hasAllergies: items.length > 0, items, label: items.join(', ') },
    occasion: { celebration: stay.guestProfile.celebration ?? '', details: p.occasionDetails ?? '' },
    requestHistory: requestHistory(stay, trips),
    internalNotes: stay.internalNotes ?? '',
  };
}

export type GuestProfileView = ReturnType<typeof toGuestProfileView>;
