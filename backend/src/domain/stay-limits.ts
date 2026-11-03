/**
 * Per-stay caps (ADV-12). A stay is one Firestore document (ADR-008), which Firestore rejects
 * above 1 MiB; list caps stop runaway growth with a clear 409, and the byte budget (checked on
 * every mutation, answered with 413) keeps headroom so size-neutral updates always succeed.
 */
export const MAX_BOOKINGS_PER_STAY = 100;
export const MAX_CONCIERGE_REQUESTS_PER_STAY = 100;
export const MAX_MESSAGES_PER_REQUEST = 100;
export const MAX_MIDSTAY_FEEDBACK_PER_STAY = 30;
export const MAX_STAY_DOCUMENT_BYTES = 900 * 1024;
