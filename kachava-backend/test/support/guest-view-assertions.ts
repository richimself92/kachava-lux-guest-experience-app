/** Keys that must never reach a guest (ADR-007): tokens, internal notes, staff ids, audit data. */
export const GUEST_FORBIDDEN_KEYS = [
  'guestTokenUuid',
  'magicLinkUrl',
  'lastNameNormalized',
  'adminNotes',
  'adminDispatchNotes',
  'assignedStaffId',
  'handledByStaffId',
  'approvedByStaffId',
  'senderStaffId',
  'staffId',
  'whatsappPhone',
  'photoStoragePath',
  'notes',
  'stepUpLockout',
];

/** Every object key found anywhere in `value` (arrays and nested objects included). */
export function collectKeys(value: unknown): Set<string> {
  const keys = new Set<string>();
  const visit = (node: unknown): void => {
    if (Array.isArray(node)) return node.forEach(visit);
    if (node === null || typeof node !== 'object') return;
    for (const [key, child] of Object.entries(node)) {
      keys.add(key);
      visit(child);
    }
  };
  visit(value);
  return keys;
}

export function forbiddenKeysIn(value: unknown): string[] {
  const keys = collectKeys(value);
  return GUEST_FORBIDDEN_KEYS.filter((k) => keys.has(k));
}
