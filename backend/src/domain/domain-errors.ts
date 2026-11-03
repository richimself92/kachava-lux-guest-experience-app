/**
 * Storage- and HTTP-agnostic domain errors. The global exception filter maps them to
 * 404 (not found), 409 (conflict) and 422 (business rule violated).
 */
export class EntityNotFoundError extends Error {
  constructor(entity: string, id: string) {
    super(`${entity} ${id} not found.`);
    this.name = 'EntityNotFoundError';
  }
}

export class EntityConflictError extends Error {
  constructor(message: string) {
    super(message);
    this.name = 'EntityConflictError';
  }
}

export class BusinessRuleError extends Error {
  constructor(
    message: string,
    readonly details: string[] = [],
    /** Stable machine-readable reason clients can branch on (e.g. link to Settings). */
    readonly code?: string,
  ) {
    super(details.length > 0 ? `${message}: ${details.join('; ')}` : message);
    this.name = 'BusinessRuleError';
  }
}

export const SETTINGS_REQUIRED = 'SETTINGS_REQUIRED';

/** The request needs resort settings that are not configured yet (`missing` names them). */
export class SettingsRequiredError extends BusinessRuleError {
  constructor(missing: string[]) {
    super('Resort settings are incomplete', missing, SETTINGS_REQUIRED);
    this.name = 'SettingsRequiredError';
  }
}

/** A bounded read found more documents than the endpoint is allowed to scan. */
export class ListScanLimitError extends Error {
  constructor(collection: string, limit: number) {
    super(`${collection} holds more than ${limit} matching documents; narrow the filters.`);
    this.name = 'ListScanLimitError';
  }
}
