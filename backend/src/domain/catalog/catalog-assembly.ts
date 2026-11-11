import { AuditTrail, CatalogImage, CatalogItem, CatalogService, KIND_DETAIL_FIELD, LocalizedText, ServiceKind, ServiceKindDetails } from './catalog.models';
import { emptyKindDetails } from './catalog-rules';

/**
 * Builds catalog entities from validated input. New entities start from an EMPTY template
 * (blank texts, no prices, no availability): there are no business defaults in code.
 */
type PlainObject = Record<string, unknown>;

/** Recursive input shape: every field optional, nested objects partial too. */
export type DeepPartial<T> = T extends Array<infer U>
  ? Array<DeepPartial<U>>
  : T extends object
    ? { [K in keyof T]?: DeepPartial<T[K]> | null }
    : T;

const empty = (): LocalizedText => ({ en: '', es: '' });

function isPlainObject(value: unknown): value is PlainObject {
  return typeof value === 'object' && value !== null && !Array.isArray(value);
}

/** PATCH semantics: defined keys win; objects merge recursively; arrays and null replace. */
export function mergeDefined<T>(current: T, patch: unknown): T {
  if (!isPlainObject(patch) || !isPlainObject(current)) return (patch === undefined ? current : patch) as T;
  const merged: PlainObject = { ...current };
  for (const [key, value] of Object.entries(patch)) {
    if (value === undefined) continue;
    merged[key] = isPlainObject(value) && isPlainObject(merged[key]) ? mergeDefined(merged[key], value) : value;
  }
  return merged as T;
}

const KIND_TEMPLATES: { [F in keyof ServiceKindDetails]: () => NonNullable<ServiceKindDetails[F]> } = {
  bar: () => ({ ageConfirmationRequired: false }),
  dining: () => ({ pairingAvailable: false }),
  stocking: () => ({ maxPerItem: null, orderDeadlineHoursBeforeCheckIn: null }),
  experience: () => ({ itinerary: [], meetingPoint: empty(), languages: [], minAge: null }),
  wellness: () => ({ location: null, healthQuestions: [], contraindications: empty() }),
  preference: () => ({ selection: 'SINGLE', changeDeadlineHours: null }),
  transport: () => ({ airportCodes: [], priceBasis: null, flightDetailsRequired: true }),
};

function kindTemplate(kind: ServiceKind): ServiceKindDetails {
  const field = KIND_DETAIL_FIELD[kind];
  return { ...emptyKindDetails(), [field]: KIND_TEMPLATES[field]() };
}

function emptyService(kind: ServiceKind): Omit<CatalogService, 'serviceId' | 'section' | 'usageType' | keyof AuditTrail> {
  return {
    kind,
    category: null,
    name: empty(),
    shortDescription: empty(),
    description: empty(),
    tags: [],
    order: 0,
    featured: false,
    cover: null,
    gallery: [],
    pricing: { mode: 'ON_REQUEST', amount: null, currency: 'USD', chargeToFolio: false, note: empty() },
    availability: {
      weekdays: [], timeSlots: [], blockedDates: [], minLeadHours: null, cancellationHours: null,
      minGuests: null, maxGuests: null, durationMinutes: null, offeredWhen: null,
    },
    guestInfo: {
      includes: empty(), excludes: empty(), whatToBring: empty(), location: empty(),
      restrictions: empty(), cancellationPolicy: empty(),
    },
    guestForm: { date: false, time: false, guests: false, notes: false, dietary: false, health: false },
    operation: {
      providerId: null, responsibleDepartment: null, responsibleStaffId: null,
      requiresConfirmation: false, internalInstructions: '',
    },
    ...kindTemplate(kind),
    status: 'DISABLED',
  };
}

function normalizeImage(image: DeepPartial<CatalogImage> | null | undefined): CatalogImage | null {
  if (!image?.storagePath) return null;
  return {
    storagePath: image.storagePath.trim(),
    alt: mergeDefined(empty(), image.alt ?? {}),
    usageRightsConfirmed: image.usageRightsConfirmed === true,
  };
}

function trimText(text: LocalizedText): LocalizedText {
  return { en: text.en.trim(), es: text.es.trim() };
}

function normalizeService(service: CatalogService): CatalogService {
  return {
    ...service,
    name: trimText(service.name),
    cover: normalizeImage(service.cover),
    gallery: service.gallery.map((image) => normalizeImage(image) as CatalogImage),
  };
}

export function assembleNewService(
  input: DeepPartial<CatalogService> & Pick<CatalogService, 'kind' | 'section' | 'usageType'>,
  serviceId: string,
  audit: AuditTrail,
): CatalogService {
  const base = { ...emptyService(input.kind), serviceId, section: input.section, usageType: input.usageType, ...audit };
  return normalizeService(mergeDefined(base as CatalogService, { ...input, serviceId }));
}

export function assembleUpdatedService(
  current: CatalogService,
  patch: DeepPartial<CatalogService>,
  audit: Pick<AuditTrail, 'updatedAt' | 'updatedBy'>,
): CatalogService {
  return normalizeService(mergeDefined(current, { ...patch, serviceId: current.serviceId, kind: current.kind, ...audit }));
}

function emptyItem(serviceId: string, itemId: string): Omit<CatalogItem, keyof AuditTrail> {
  return {
    itemId, serviceId, name: empty(), description: empty(), category: null, image: null, priceUSD: null,
    tags: [], dietaryTags: [], allergens: [], origin: null, unit: null, storage: null, capacity: null,
    order: 0, status: 'DISABLED',
  };
}

function normalizeItem(item: CatalogItem): CatalogItem {
  return { ...item, name: trimText(item.name), image: normalizeImage(item.image) };
}

export function assembleNewItem(
  input: DeepPartial<CatalogItem>,
  serviceId: string,
  itemId: string,
  audit: AuditTrail,
): CatalogItem {
  const base = { ...emptyItem(serviceId, itemId), ...audit } as CatalogItem;
  return normalizeItem(mergeDefined(base, { ...input, serviceId, itemId }));
}

export function assembleUpdatedItem(
  current: CatalogItem,
  patch: DeepPartial<CatalogItem>,
  audit: Pick<AuditTrail, 'updatedAt' | 'updatedBy'>,
): CatalogItem {
  return normalizeItem(mergeDefined(current, { ...patch, serviceId: current.serviceId, itemId: current.itemId, ...audit }));
}
