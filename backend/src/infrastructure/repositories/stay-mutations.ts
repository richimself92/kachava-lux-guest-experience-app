import { chargeBooking } from '../../domain/folio-ledger';
import {
  ConciergeMessage,
  ConciergeRequest,
  ExperienceBooking,
  MidStayFeedback,
  Personalization,
  StayAggregate,
  StayRecord,
} from '../../domain/models/domain.models';
import { newStayRealtimeChannelId } from '../../domain/realtime/realtime-signal';
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

/** The realtime channel rotates with the token, so an old link can no longer follow the stay. */
export function rotateGuestToken(stay: StayAggregate, newUuid: string): StayRecord {
  stay.guestTokenUuid = newUuid;
  stay.realtimeChannelId = newStayRealtimeChannelId();
  touch(stay);
  return structuredClone(stay);
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
