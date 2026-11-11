import { AuditTrail } from '../../domain/catalog/catalog.models';

/** The keys a PATCH body actually sent (validated DTOs leave absent fields `undefined`). */
export function definedFields<T extends object>(dto: T): Partial<T> {
  return Object.fromEntries(
    Object.entries(dto).filter(([, value]) => value !== undefined),
  ) as Partial<T>;
}

export function creationAudit(actor: string, now = new Date().toISOString()): AuditTrail {
  return { createdAt: now, createdBy: actor, updatedAt: now, updatedBy: actor };
}

export function updateAudit(actor: string, now = new Date().toISOString()): Pick<AuditTrail, 'updatedAt' | 'updatedBy'> {
  return { updatedAt: now, updatedBy: actor };
}
