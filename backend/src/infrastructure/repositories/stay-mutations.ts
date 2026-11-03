import { chargeBooking, chargeLarderOrder, LarderCharge } from '../../domain/folio-ledger';
import {
  ConciergeMessage,
  ConciergeRequest,
  ExperienceBooking,
  FlightTransfer,
  FolioSummary,
  LarderOrderItem,
  MidStayFeedback,
  Personalization,
  StayAggregate,
  StayLifecycleStatus,
  StayRecord,
} from '../../domain/models/domain.models';
import { StayLimitExceededError } from '../../domain/stay-errors';
import {
  MAX_BOOKINGS_PER_STAY,
  MAX_CONCIERGE_REQUESTS_PER_STAY,
  MAX_MESSAGES_PER_REQUEST,
  MAX_MIDSTAY_FEEDBACK_PER_STAY,
} from '../../domain/stay-limits';

/**
 * Pure, storage-agnostic mutators applied to a single stay aggregate. Each one mutates the
 * given draft and returns a detached copy of the affected entity (or null when not found).
 */
function assertRoomFor(list: unknown[], max: number, listName: string): void {
  if (list.length >= max) throw new StayLimitExceededError(listName, max);
}

function touch(stay: StayAggregate): void {
  stay.updatedAt = new Date().toISOString();
}

export function rotateGuestToken(stay: StayAggregate, newUuid: string): StayRecord {
  stay.guestTokenUuid = newUuid;
  touch(stay);
  return structuredClone(stay);
}

export function changeStayStatus(stay: StayAggregate, status: StayLifecycleStatus): StayRecord {
  stay.status = status;
  touch(stay);
  return structuredClone(stay);
}

export function patchStayWifi(
  stay: StayAggregate,
  wifiPatch: { wifiSsid?: string; wifiPasscode?: string },
): StayRecord {
  stay.villaAccess = {
    ...stay.villaAccess,
    wifiSsid: wifiPatch.wifiSsid?.trim() || stay.villaAccess.wifiSsid,
    wifiPasscode: wifiPatch.wifiPasscode?.trim() || stay.villaAccess.wifiPasscode,
  };
  touch(stay);
  return structuredClone(stay);
}

export function patchTransfer(
  stay: StayAggregate,
  transferPatch: Partial<FlightTransfer>,
): FlightTransfer {
  stay.flightTransfer = { ...stay.flightTransfer, ...transferPatch };
  touch(stay);
  return structuredClone(stay.flightTransfer);
}

export function patchPersonalization(
  stay: StayAggregate,
  personalizationPatch: Partial<Personalization>,
  allergiesLabel?: string,
): Personalization {
  const now = new Date().toISOString();
  stay.personalization = { ...stay.personalization, ...personalizationPatch, updatedAt: now };
  if (allergiesLabel) stay.guestProfile.allergies = allergiesLabel;
  stay.updatedAt = now;
  return structuredClone(stay.personalization);
}

export function selectSignaturePrivilege(
  stay: StayAggregate,
  privilege: 'massage' | 'golf',
): StayRecord {
  stay.selectedSignaturePrivilege = privilege;
  touch(stay);
  return structuredClone(stay);
}

/** Replaces the larder order and re-prices its folio line from the stored folio. */
export function replaceLarderAndFolio(
  stay: StayAggregate,
  orders: LarderOrderItem[],
  charge: LarderCharge,
): { orders: LarderOrderItem[]; folioSummary: FolioSummary } {
  stay.larderOrders = structuredClone(orders);
  touch(stay);
  chargeLarderOrder(stay, stay.larderOrders, stay.updatedAt, charge);
  return { orders: structuredClone(stay.larderOrders), folioSummary: structuredClone(stay.folioSummary) };
}

/** Stores the booking and charges it to the stored folio. */
export function addBooking(stay: StayAggregate, booking: ExperienceBooking): ExperienceBooking {
  assertRoomFor(stay.experienceBookings, MAX_BOOKINGS_PER_STAY, 'bookings');
  stay.experienceBookings.unshift(structuredClone(booking));
  chargeBooking(stay, booking);
  touch(stay);
  return structuredClone(booking);
}

export function addConciergeRequest(stay: StayAggregate, request: ConciergeRequest): ConciergeRequest {
  assertRoomFor(stay.conciergeRequests, MAX_CONCIERGE_REQUESTS_PER_STAY, 'concierge requests');
  stay.conciergeRequests.unshift(structuredClone(request));
  return structuredClone(request);
}

export function addMidStayFeedback(stay: StayAggregate, feedback: MidStayFeedback): MidStayFeedback {
  assertRoomFor(stay.midstayFeedback, MAX_MIDSTAY_FEEDBACK_PER_STAY, 'mid-stay check-ins');
  stay.midstayFeedback.unshift(structuredClone(feedback));
  return structuredClone(feedback);
}

export function ownsConciergeRequest(stay: StayAggregate, requestId: string): boolean {
  return stay.conciergeRequests.some((r) => r.requestId === requestId);
}

export function ownsBooking(stay: StayAggregate, bookingId: string): boolean {
  return stay.experienceBookings.some((b) => b.bookingId === bookingId);
}

/** Admin larder actions address a stay's whole order by item id, stay id or `larder_<stayId>`. */
export function ownsLarderOrder(stay: StayAggregate, orderItemId: string): boolean {
  const referencesStay =
    stay.larderOrders.some((o) => o.orderItemId === orderItemId) ||
    stay.stayId === orderItemId ||
    orderItemId === `larder_${stay.stayId}`;
  return referencesStay && stay.larderOrders.length > 0;
}

export function applyConciergeAdminUpdate(
  stay: StayAggregate,
  requestId: string,
  patch: Partial<ConciergeRequest>,
  newMessage?: ConciergeMessage,
): ConciergeRequest | null {
  const target = stay.conciergeRequests.find((r) => r.requestId === requestId);
  if (!target) return null;
  if (newMessage) assertRoomFor(target.messages, MAX_MESSAGES_PER_REQUEST, 'messages per request');
  Object.assign(target, patch, { updatedAt: new Date().toISOString() });
  if (newMessage) target.messages.push(structuredClone(newMessage));
  return structuredClone(target);
}

export function applyLarderOrderStatusUpdate(
  stay: StayAggregate,
  orderItemId: string,
  patch: Partial<LarderOrderItem>,
): LarderOrderItem | null {
  if (!ownsLarderOrder(stay, orderItemId)) return null;
  const now = new Date().toISOString();
  for (const item of stay.larderOrders) {
    Object.assign(item, patch, { updatedAt: now });
  }
  return structuredClone(stay.larderOrders[0]);
}

export function applyBookingAssignmentUpdate(
  stay: StayAggregate,
  bookingId: string,
  patch: Partial<ExperienceBooking>,
): ExperienceBooking | null {
  const target = stay.experienceBookings.find((b) => b.bookingId === bookingId);
  if (!target) return null;
  Object.assign(target, patch);
  return structuredClone(target);
}

export function appendMessageToStayRequest(
  stay: StayAggregate,
  requestId: string,
  message: ConciergeMessage,
): ConciergeRequest | null {
  const req = stay.conciergeRequests.find((r) => r.requestId === requestId);
  if (!req) return null;
  assertRoomFor(req.messages, MAX_MESSAGES_PER_REQUEST, 'messages per request');
  req.messages.push(structuredClone(message));
  req.updatedAt = message.sentAt;
  return structuredClone(req);
}
