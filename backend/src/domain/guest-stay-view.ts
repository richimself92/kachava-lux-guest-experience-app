import {
  ConciergeMessage,
  ConciergeRequest,
  ExperienceBooking,
  FlightTransfer,
  FolioItem,
  FolioSummary,
  GuestProfile,
  HostInfo,
  LarderOrderItem,
  MidStayFeedback,
  Personalization,
  StayAggregate,
  VillaAccess,
} from './models/domain.models';

/**
 * ADR-007 guest-safe projection. Every list below is an explicit ALLOW-list: a field added to the
 * stay model stays hidden from guests until it is added here on purpose (with a test).
 * Never listed: guest token / magic link, `lastNameNormalized`, internal notes (`notes`,
 * `adminNotes`, `adminDispatchNotes`), staff ids/phones/emails, `approvedByStaffId`,
 * `photoStoragePath`, audit timestamps of the stay, and any operational/staff-only data.
 */
const STAY_KEYS = [
  'status', 'villaName', 'suiteName', 'stayDatesLabel', 'nights', 'guestsCount',
  'selectedSignaturePrivilege',
] as const satisfies ReadonlyArray<keyof StayAggregate>;
const GUEST_PROFILE_KEYS = ['name', 'partner', 'celebration', 'folioCard'] as const satisfies ReadonlyArray<keyof GuestProfile>;
/** Resident host: display name, role label and photo only. */
const HOST_KEYS = ['name', 'shortName', 'role', 'avatarUrl'] as const satisfies ReadonlyArray<keyof HostInfo>;
const VILLA_ACCESS_KEYS = ['digitalKeyStatus', 'wifiSsid', 'wifiPasscode'] as const satisfies ReadonlyArray<keyof VillaAccess>;
const TRANSFER_KEYS = [
  'arrivalDate', 'arrivalAirport', 'airline', 'flightNumber', 'arrivalTime', 'terminal',
  'estimatedLanding', 'partySize', 'luggageCount', 'luggageChecked', 'luggageCarryOn', 'status',
  'assignedDriver', 'vehicleModel', 'meetingPoint',
] as const satisfies ReadonlyArray<keyof FlightTransfer>;
const PERSONALIZATION_KEYS = [
  'currentStep', 'tripPurpose', 'occasionDetails', 'selectedInterests', 'dietary',
  'dietaryAllergies', 'allergies', 'villaScent', 'scentProfile', 'pillowType', 'pillowSelection',
  'temperatureCurve', 'lightingRhythm', 'housekeepingCadence', 'commChannel',
] as const satisfies ReadonlyArray<keyof Personalization>;
const LARDER_KEYS = [
  'orderItemId', 'serviceId', 'catalogItemId', 'name', 'itemName', 'category', 'unitPriceUSD', 'quantity', 'lineTotalUSD',
  'provisioningStatus',
] as const satisfies ReadonlyArray<keyof LarderOrderItem>;
const BOOKING_KEYS = [
  'bookingId', 'serviceId', 'itemId', 'section', 'usageType', 'category', 'snapshot', 'title', 'scheduledDate',
  'scheduledTimeSlot', 'partySize', 'isIncludedWithStay', 'originalValuationUSD',
  'priceChargedUSD', 'status', 'cancellationReason',
] as const satisfies ReadonlyArray<keyof ExperienceBooking>;
const CONCIERGE_KEYS = [
  'requestId', 'type', 'category', 'title', 'timeLabel', 'location', 'status', 'currentStep',
  'details', 'isCompleted', 'createdAt', 'updatedAt',
] as const satisfies ReadonlyArray<keyof ConciergeRequest>;
const MESSAGE_KEYS = ['sender', 'senderName', 'text', 'sentAt'] as const satisfies ReadonlyArray<keyof ConciergeMessage>;
const FOLIO_ITEM_KEYS = [
  'folioItemId', 'displayOrder', 'title', 'subtitle', 'category', 'badgeLabel', 'isComplimentary',
  'originalValuationUSD', 'chargedAmountUSD', 'status',
] as const satisfies ReadonlyArray<keyof FolioItem>;
const FOLIO_SUMMARY_KEYS = [
  'complimentarySavingsUSD', 'incidentalsSubtotalUSD', 'ecologicalLevyUSD', 'finalSettledTotalUSD',
  'paymentStatus', 'isCheckedOut', 'checkedOutAt',
] as const satisfies ReadonlyArray<keyof FolioSummary>;
const FEEDBACK_KEYS = [
  'feedbackId', 'dayOfStay', 'rating', 'selectedSentiment', 'selectedAspects',
  'housekeepingPreferences', 'note', 'createdAt',
] as const satisfies ReadonlyArray<keyof MidStayFeedback>;

/** Copies only `keys` (skipping absent ones) as a detached value. */
function pick<T extends object, K extends keyof T>(source: T, keys: readonly K[]): Pick<T, K> {
  const view = {} as Pick<T, K>;
  for (const key of keys) {
    if (source?.[key] !== undefined) view[key] = structuredClone(source[key]);
  }
  return view;
}

export type GuestTransferView = Pick<FlightTransfer, (typeof TRANSFER_KEYS)[number]>;
export type GuestBookingView = Pick<ExperienceBooking, (typeof BOOKING_KEYS)[number]>;
export type GuestLarderOrderView = Pick<LarderOrderItem, (typeof LARDER_KEYS)[number]>;
export type GuestFolioSummaryView = Pick<FolioSummary, (typeof FOLIO_SUMMARY_KEYS)[number]>;
export type GuestConciergeRequestView = Pick<ConciergeRequest, (typeof CONCIERGE_KEYS)[number]> & {
  messages: Array<Pick<ConciergeMessage, (typeof MESSAGE_KEYS)[number]>>;
};
export interface GuestFolioView {
  folioSummary: GuestFolioSummaryView;
  folioItems: Array<Pick<FolioItem, (typeof FOLIO_ITEM_KEYS)[number]>>;
}

export function toGuestTransferView(transfer: FlightTransfer): GuestTransferView {
  const view = pick(transfer, TRANSFER_KEYS);
  view.assignedDriver = transfer.assignedDriver || transfer.assignedStaffName || '';
  return view;
}

export function toGuestBookingView(booking: ExperienceBooking): GuestBookingView {
  return pick(booking, BOOKING_KEYS);
}

export function toGuestLarderOrderView(order: LarderOrderItem): GuestLarderOrderView {
  return pick(order, LARDER_KEYS);
}

export function toGuestConciergeRequestView(request: ConciergeRequest): GuestConciergeRequestView {
  return {
    ...pick(request, CONCIERGE_KEYS),
    messages: (request.messages ?? []).map((m) => pick(m, MESSAGE_KEYS)),
  };
}

export function toGuestFolioSummaryView(summary: FolioSummary): GuestFolioSummaryView {
  return pick(summary, FOLIO_SUMMARY_KEYS);
}

export function toGuestFolioView(folio: { folioSummary: FolioSummary; folioItems: FolioItem[] }): GuestFolioView {
  return {
    folioSummary: toGuestFolioSummaryView(folio.folioSummary),
    folioItems: folio.folioItems.map((item) => pick(item, FOLIO_ITEM_KEYS)),
  };
}

export function toGuestFeedbackView(feedback: MidStayFeedback) {
  return pick(feedback, FEEDBACK_KEYS);
}

export function toGuestPersonalizationView(personalization: Personalization) {
  return pick(personalization, PERSONALIZATION_KEYS);
}

/** The only shape of a stay that guest routes may return. */
export function toGuestStayView(stay: StayAggregate) {
  return {
    ...pick(stay, STAY_KEYS),
    guestProfile: pick(stay.guestProfile, GUEST_PROFILE_KEYS),
    hostInfo: pick(stay.hostInfo, HOST_KEYS),
    villaAccess: pick(stay.villaAccess, VILLA_ACCESS_KEYS),
    flightTransfer: toGuestTransferView(stay.flightTransfer),
    personalization: toGuestPersonalizationView(stay.personalization),
    larderOrders: stay.larderOrders.map(toGuestLarderOrderView),
    experienceBookings: stay.experienceBookings.map(toGuestBookingView),
    conciergeRequests: stay.conciergeRequests.map(toGuestConciergeRequestView),
    midstayFeedback: stay.midstayFeedback.map(toGuestFeedbackView),
    ...toGuestFolioView(stay),
  };
}

export type GuestStayView = ReturnType<typeof toGuestStayView>;
