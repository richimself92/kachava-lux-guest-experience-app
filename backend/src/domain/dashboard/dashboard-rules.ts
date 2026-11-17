import { StayAggregate, StayRecord } from '../models/domain.models';
import { Villa } from '../models/resort-config.models';
import { LocalizedText } from '../catalog/catalog.models';
import { conversationSummary } from '../conversations/conversation-rules';
import { isOpenBooking, isOpenStay, openBookingCount, openOrderCount } from '../stays/open-requests';
import { isFinalTripStatus, Trip } from '../trips/trip.models';

/**
 * Dashboard rules (plan v2, "Dashboard"). Pure functions over the resort day `today`
 * (YYYY-MM-DD in the Settings time zone); stays carry calendar check-in/check-out dates.
 */
export type ActivityStatus = 'ARRIVAL' | 'IN_HOUSE' | 'DEPARTURE';

export interface ActivityState {
  status: ActivityStatus;
  /** In-house after the check-out date (overstay). */
  overdue: boolean;
}

export interface ActivityRow extends ActivityState {
  stayId: string;
  guestName: string;
  villaId: string;
  villaName: string;
}

export interface DashboardActivity {
  rows: ActivityRow[];
  /** Every row of today's activity ("View all"). */
  total: number;
}

export interface DashboardKpis {
  occupiedVillas: number;
  availableVillas: number;
  occupancyPct: number;
  arrivals: number;
  departures: number;
  openRequests: number;
}

export interface DashboardKpiInput {
  villas: Villa[];
  /** Open stays (pre-arrival and in-house); closed ones are ignored. */
  stays: StayAggregate[];
  today: string;
  openTrips: number;
  openTasks: number;
}

/** Villa states that take a free villa out of service. */
const OUT_OF_SERVICE_STATUSES: readonly Villa['operationalStatus'][] = ['MAINTENANCE', 'BLOCKED'];
const ACTIVITY_ORDER: Record<ActivityStatus, number> = { DEPARTURE: 0, ARRIVAL: 1, IN_HOUSE: 2 };

/**
 * Departure when check-out is today (wins over arrival on the same day); Arrival when check-in is
 * today; In-house once checked in (overdue after the check-out date). Future, cancelled and
 * closed stays are not part of today's activity (null).
 */
export function deriveActivityStatus(
  stay: Pick<StayRecord, 'status' | 'checkInDate' | 'checkOutDate'>,
  today: string,
): ActivityState | null {
  if (!isOpenStay(stay)) return null;
  if (stay.checkOutDate === today) return { status: 'DEPARTURE', overdue: false };
  if (stay.checkInDate === today) return { status: 'ARRIVAL', overdue: false };
  if (stay.status !== 'ACTIVE_STAY') return null;
  return { status: 'IN_HOUSE', overdue: Boolean(stay.checkOutDate) && (stay.checkOutDate as string) < today };
}

function compareRows(a: ActivityRow, b: ActivityRow): number {
  if (a.overdue !== b.overdue) return a.overdue ? -1 : 1;
  const byStatus = ACTIVITY_ORDER[a.status] - ACTIVITY_ORDER[b.status];
  return byStatus !== 0 ? byStatus : a.guestName.localeCompare(b.guestName, 'en', { sensitivity: 'base' });
}

/** Today's activity: overstays first, then departures, arrivals and in-house; at most `limit` rows. */
export function buildActivity(stays: StayAggregate[], today: string, limit: number): DashboardActivity {
  const rows: ActivityRow[] = [];
  for (const stay of stays) {
    const state = deriveActivityStatus(stay, today);
    if (!state) continue;
    rows.push({
      stayId: stay.stayId,
      guestName: stay.guestProfile?.name ?? '',
      villaId: stay.villaId,
      villaName: stay.villaName,
      ...state,
    });
  }
  rows.sort(compareRows);
  return { rows: rows.slice(0, limit), total: rows.length };
}

/**
 * occupied = active villas with an in-house stay; available = active − occupied − out of service
 * (a free villa in maintenance or blocked); occupancy = occupied / active (whole percent);
 * arrivals / departures = open stays checking in / out today;
 * open requests = open orders + open bookings + open trips + open tasks.
 */
export function computeDashboardKpis(input: DashboardKpiInput): DashboardKpis {
  const openStays = input.stays.filter(isOpenStay);
  const activeVillas = input.villas.filter((villa) => villa.isActive);
  const inHouseVillaIds = new Set(openStays.filter((s) => s.status === 'ACTIVE_STAY').map((s) => s.villaId));
  const occupied = activeVillas.filter((villa) => inHouseVillaIds.has(villa.villaId));
  const outOfService = activeVillas.filter(
    (villa) => !inHouseVillaIds.has(villa.villaId) && OUT_OF_SERVICE_STATUSES.includes(villa.operationalStatus),
  );
  const occupancyPct = activeVillas.length === 0 ? 0 : Math.round((occupied.length / activeVillas.length) * 100);
  const guestRequests = openStays.reduce((sum, s) => sum + openOrderCount(s) + openBookingCount(s), 0);
  return {
    occupiedVillas: occupied.length,
    availableVillas: activeVillas.length - occupied.length - outOfService.length,
    occupancyPct,
    arrivals: openStays.filter((s) => s.checkInDate === input.today).length,
    departures: openStays.filter((s) => s.checkOutDate === input.today).length,
    openRequests: guestRequests + input.openTrips + input.openTasks,
  };
}

/** The guest's next concrete event: the flight (arrival/departure day) or the next booking. */
export interface ActivityNext {
  kind: 'FLIGHT' | 'BOOKING';
  /** Flight time (else pickup), UTC ISO; null without a trip. */
  at: string | null;
  flightNumber: string | null;
  /** NONE = no transfer booked; NO_DRIVER = not confirmed yet; DRIVER_CONFIRMED = driver assigned. */
  transfer: 'NONE' | 'NO_DRIVER' | 'DRIVER_CONFIRMED' | null;
  title: LocalizedText | null;
  /** Booking resort day (YYYY-MM-DD) and time (HH:mm). */
  date: string | null;
  time: string | null;
}

export interface ActivityDetails {
  stayStatus: StayRecord['status'];
  /** Open guest requests (orders, bookings, trips) and unread guest messages. */
  pending: { requests: number; messages: number };
  next: ActivityNext | null;
}

const DRIVER_STATUSES: readonly Trip['status'][] = ['CONFIRMED', 'EN_ROUTE', 'COMPLETED'];
const EMPTY_NEXT: ActivityNext = {
  kind: 'FLIGHT', at: null, flightNumber: null, transfer: 'NONE', title: null, date: null, time: null,
};

function flightNext(trip: Trip | undefined): ActivityNext {
  if (!trip) return EMPTY_NEXT;
  const flight = trip.flight;
  return {
    ...EMPTY_NEXT,
    at: flight?.scheduledAt ?? trip.pickupAt,
    flightNumber: flight ? `${flight.airline} ${flight.number}`.trim() : null,
    transfer: DRIVER_STATUSES.includes(trip.status) ? 'DRIVER_CONFIRMED' : 'NO_DRIVER',
  };
}

function bookingNext(stay: StayAggregate, today: string): ActivityNext | null {
  const upcoming = (stay.experienceBookings ?? [])
    .filter((b) => isOpenBooking(b) && b.scheduledDate >= today)
    .sort((a, b) => `${a.scheduledDate}T${a.scheduledTimeSlot}`.localeCompare(`${b.scheduledDate}T${b.scheduledTimeSlot}`));
  const next = upcoming[0];
  if (!next) return null;
  return {
    ...EMPTY_NEXT,
    kind: 'BOOKING',
    transfer: null,
    title: structuredClone(next.snapshot?.serviceName ?? { en: next.title, es: next.title }),
    date: next.scheduledDate,
    time: next.scheduledTimeSlot || null,
  };
}

/** Next event, pending counts and the stay status of one activity row (`trips` of that stay). */
export function activityDetails(row: ActivityState, stay: StayAggregate, trips: Trip[], today: string): ActivityDetails {
  const open = trips.filter((t) => t.stayId === stay.stayId && !isFinalTripStatus(t.status));
  const live = trips.filter((t) => t.stayId === stay.stayId && t.status !== 'CANCELLED');
  const flightDay = !row.overdue && row.status !== 'IN_HOUSE';
  return {
    stayStatus: stay.status,
    pending: {
      requests: openOrderCount(stay) + openBookingCount(stay) + open.length,
      messages: conversationSummary(stay)?.unreadCount ?? 0,
    },
    next: flightDay ? flightNext(live.find((t) => t.type === row.status)) : bookingNext(stay, today),
  };
}
