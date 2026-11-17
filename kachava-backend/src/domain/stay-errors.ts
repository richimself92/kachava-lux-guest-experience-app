/**
 * Storage-agnostic stay errors. They carry no HTTP knowledge; the global exception filter maps
 * them to status codes (404, 409, 413).
 */
export class StayNotFoundError extends Error {
  constructor(stayId: string) {
    super(`Stay with ID ${stayId} not found`);
    this.name = 'StayNotFoundError';
  }
}

/** A per-stay list reached its cap (keeps the single stay document far below 1 MiB). */
export class StayLimitExceededError extends Error {
  constructor(listName: string, max: number) {
    super(`This stay already holds the maximum of ${max} ${listName}.`);
    this.name = 'StayLimitExceededError';
  }
}

/** The stay document would exceed the storage budget after the mutation. */
export class StayDocumentTooLargeError extends Error {
  constructor(bytes: number) {
    super(`Stay document would grow to ${bytes} bytes, above the storage budget.`);
    this.name = 'StayDocumentTooLargeError';
  }
}
