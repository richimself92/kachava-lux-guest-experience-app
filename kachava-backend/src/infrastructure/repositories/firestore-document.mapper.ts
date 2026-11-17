/**
 * Converts a plain domain object into a Firestore-safe document. Firestore rejects `undefined`
 * field values, so optional fields left undefined by partial patches are dropped.
 */
export function toFirestoreDocument<T extends object>(value: T): Record<string, unknown> {
  return JSON.parse(JSON.stringify(value)) as Record<string, unknown>;
}
