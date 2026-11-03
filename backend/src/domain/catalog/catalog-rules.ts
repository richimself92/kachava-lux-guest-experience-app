import { BusinessRuleError, EntityNotFoundError } from '../domain-errors';
import {
  CatalogImage,
  CatalogItem,
  CatalogService,
  KIND_DETAIL_FIELD,
  KindDetailField,
  LocalizedText,
  ServiceKind,
  ServiceKindDetails,
  ServiceSnapshot,
} from './catalog.models';

const CATALOG_PATH_PREFIX = 'catalog/';
const SAFE_PATH_SEGMENT = /^[A-Za-z0-9._-]+$/;
const MINUTES_PER_HOUR = 60;

function isBlank(value: string | undefined): boolean {
  return !value || value.trim().length === 0;
}

function missingTranslations(field: string, text: LocalizedText): string[] {
  return (['en', 'es'] as const)
    .filter((lang) => isBlank(text[lang]))
    .map((lang) => `${field}.${lang} is required`);
}

/** Why a service cannot be ACTIVE: it needs a cover image and EN+ES name and short description. */
export function activationProblems(service: CatalogService): string[] {
  return [
    ...(service.cover ? [] : ['cover image is required']),
    ...missingTranslations('name', service.name),
    ...missingTranslations('shortDescription', service.shortDescription),
  ];
}

/** Why an item cannot be ACTIVE: guests see its name in both languages. */
export function itemActivationProblems(item: CatalogItem): string[] {
  return missingTranslations('name', item.name);
}

export function assertServiceCanBeActive(service: CatalogService): void {
  if (service.status !== 'ACTIVE') return;
  const problems = activationProblems(service);
  if (problems.length > 0) throw new BusinessRuleError('Service cannot be active', problems);
}

export function assertItemCanBeActive(item: CatalogItem): void {
  if (item.status !== 'ACTIVE') return;
  const problems = itemActivationProblems(item);
  if (problems.length > 0) throw new BusinessRuleError('Item cannot be active', problems);
}

const PRICE_FREE_MODES = new Set(['INCLUDED', 'ON_REQUEST']);

/** Invariants that hold for every saved service, active or not. */
export function consistencyProblems(service: CatalogService): string[] {
  const problems: string[] = [];
  if (isBlank(service.name.en) && isBlank(service.name.es)) problems.push('name needs English or Spanish text');
  if (PRICE_FREE_MODES.has(service.pricing.mode) && service.pricing.amount !== null) {
    problems.push(`pricing.amount must be empty when pricing is ${service.pricing.mode}`);
  }
  const { minGuests, maxGuests, timeSlots } = service.availability;
  if (minGuests !== null && maxGuests !== null && minGuests > maxGuests) {
    problems.push('minGuests cannot exceed maxGuests');
  }
  timeSlots
    .filter((slot) => slot.start >= slot.end)
    .forEach((slot) => problems.push(`time slot ${slot.start}-${slot.end} must end after it starts`));
  return problems;
}

export function assertServiceConsistent(service: CatalogService): void {
  const problems = consistencyProblems(service);
  if (problems.length > 0) throw new BusinessRuleError('Invalid service', problems);
}

/** Only the block matching the service kind may be provided. */
export function assertKindDetailsMatch(
  kind: ServiceKind,
  details: Partial<Record<KindDetailField, unknown>>,
): void {
  const allowed = KIND_DETAIL_FIELD[kind];
  const foreign = (Object.keys(details) as KindDetailField[]).filter(
    (field) => field !== allowed && details[field] !== undefined && details[field] !== null,
  );
  if (foreign.length > 0) {
    throw new BusinessRuleError(
      `Kind ${kind} only accepts "${allowed}" details`,
      foreign.map((field) => `${field} is not allowed`),
    );
  }
}

export function emptyKindDetails(): ServiceKindDetails {
  return {
    bar: null,
    dining: null,
    stocking: null,
    experience: null,
    wellness: null,
    preference: null,
    transport: null,
  };
}

export function isCatalogStoragePath(path: string): boolean {
  if (!path.startsWith(CATALOG_PATH_PREFIX)) return false;
  const segments = path.slice(CATALOG_PATH_PREFIX.length).split('/');
  return segments.length > 0 && segments.every((s) => SAFE_PATH_SEGMENT.test(s) && s !== '..' && s !== '.');
}

/** Saved images must be uploads signed by `POST /admin/uploads/sign` (under `catalog/`). */
export function assertCatalogImages(images: CatalogImage[]): void {
  const invalid = images.map((image) => image.storagePath).filter((path) => !isCatalogStoragePath(path));
  if (invalid.length > 0) {
    throw new BusinessRuleError(
      'Images must be uploaded through /admin/uploads/sign',
      invalid.map((path) => `${path} is not a catalog upload`),
    );
  }
}

export interface RequestedLine {
  itemId: string;
  quantity: number;
}

export interface ResolvedLine {
  item: CatalogItem | null;
  quantity: number;
}

/** Validates that the guest can order/book: active service, known and active items, limits. */
export function resolveOrderLines(
  service: CatalogService,
  items: CatalogItem[],
  requested: RequestedLine[],
): ResolvedLine[] {
  if (service.status !== 'ACTIVE') {
    throw new BusinessRuleError(`Service ${service.serviceId} is not available`);
  }
  const maxPerItem = service.stocking?.maxPerItem ?? null;
  return requested.map((line) => {
    const item = items.find((candidate) => candidate.itemId === line.itemId);
    if (!item) throw new EntityNotFoundError('Item', line.itemId);
    if (item.status !== 'ACTIVE') throw new BusinessRuleError(`Item ${line.itemId} is not available`);
    if (maxPerItem !== null && line.quantity > maxPerItem) {
      throw new BusinessRuleError(`At most ${maxPerItem} units per item can be ordered`);
    }
    return { item, quantity: line.quantity };
  });
}

function unitPriceOf(service: CatalogService, item: CatalogItem | null): number | null {
  const { mode, amount } = service.pricing;
  if (mode === 'INCLUDED') return 0;
  if (mode === 'ON_REQUEST') return null;
  const price = item?.priceUSD ?? amount;
  if (price === null || price === undefined) {
    throw new BusinessRuleError(`Service ${service.serviceId} has no price configured`);
  }
  return price;
}

function multiplierOf(service: CatalogService, partySize: number): number {
  if (service.pricing.mode === 'PER_PERSON') return partySize;
  if (service.pricing.mode !== 'PER_HOUR') return 1;
  const minutes = service.availability.durationMinutes;
  if (!minutes) throw new BusinessRuleError(`Service ${service.serviceId} has no duration for hourly pricing`);
  return minutes / MINUTES_PER_HOUR;
}

function roundCents(value: number): number {
  return Math.round(value * 100) / 100;
}

/** Copies name and price at order time so later catalog edits never change past orders. */
export function buildServiceSnapshot(
  service: CatalogService,
  lines: ResolvedLine[],
  partySize: number,
  capturedAt: string,
): ServiceSnapshot {
  const multiplier = multiplierOf(service, partySize);
  const snapshotLines = lines.map(({ item, quantity }) => {
    const unitPriceUSD = unitPriceOf(service, item);
    return {
      itemId: item?.itemId ?? null,
      name: structuredClone(item?.name ?? service.name),
      unitPriceUSD,
      quantity,
      lineTotalUSD: unitPriceUSD === null ? null : roundCents(unitPriceUSD * quantity * multiplier),
    };
  });
  const priced = snapshotLines.every((line) => line.lineTotalUSD !== null);
  return {
    serviceId: service.serviceId,
    serviceName: structuredClone(service.name),
    section: service.section,
    usageType: service.usageType,
    pricingMode: service.pricing.mode,
    chargeToFolio: service.pricing.chargeToFolio,
    currency: service.pricing.currency,
    lines: snapshotLines,
    totalUSD: priced ? roundCents(snapshotLines.reduce((sum, l) => sum + (l.lineTotalUSD ?? 0), 0)) : null,
    capturedAt,
  };
}

export type ImageUrlResolver = (path: string) => string;

export interface ResolvedImage extends CatalogImage {
  url: string;
}

export function withImageUrl(image: CatalogImage | null, urlOf: ImageUrlResolver): ResolvedImage | null {
  return image ? { ...structuredClone(image), url: urlOf(image.storagePath) } : null;
}

export interface GuestCatalogItem {
  id: string;
  itemId: string;
  name: LocalizedText;
  description: LocalizedText;
  category: string | null;
  image: ResolvedImage | null;
  priceUSD: number | null;
  tags: string[];
  dietaryTags: string[];
  allergens: string[];
  origin: string | null;
  unit: string | null;
  storage: string | null;
  capacity: CatalogItem['capacity'];
  order: number;
}

export type GuestCatalogService = Pick<
  CatalogService,
  | 'serviceId' | 'kind' | 'section' | 'category' | 'usageType' | 'name' | 'shortDescription'
  | 'description' | 'tags' | 'order' | 'featured' | 'pricing' | 'availability' | 'guestInfo'
  | 'guestForm' | keyof ServiceKindDetails
> & {
  id: string;
  cover: ResolvedImage | null;
  gallery: ResolvedImage[];
  items: GuestCatalogItem[];
};

export function toGuestCatalogItem(item: CatalogItem, urlOf: ImageUrlResolver): GuestCatalogItem {
  return structuredClone({
    id: item.itemId,
    itemId: item.itemId,
    name: item.name,
    description: item.description,
    category: item.category,
    image: withImageUrl(item.image, urlOf),
    priceUSD: item.priceUSD,
    tags: item.tags,
    dietaryTags: item.dietaryTags,
    allergens: item.allergens,
    origin: item.origin,
    unit: item.unit,
    storage: item.storage,
    capacity: item.capacity,
    order: item.order,
  });
}

/** Guest-safe allow-list projection: no operation block, no audit, no internal notes. */
export function toGuestCatalogService(
  service: CatalogService,
  activeItems: CatalogItem[],
  urlOf: ImageUrlResolver,
): GuestCatalogService {
  const s = structuredClone(service);
  return {
    id: s.serviceId,
    serviceId: s.serviceId,
    kind: s.kind,
    section: s.section,
    category: s.category,
    usageType: s.usageType,
    name: s.name,
    shortDescription: s.shortDescription,
    description: s.description,
    tags: s.tags,
    order: s.order,
    featured: s.featured,
    cover: withImageUrl(s.cover, urlOf),
    gallery: s.gallery.map((image) => withImageUrl(image, urlOf) as ResolvedImage),
    pricing: s.pricing,
    availability: s.availability,
    guestInfo: s.guestInfo,
    guestForm: s.guestForm,
    bar: s.bar,
    dining: s.dining,
    stocking: s.stocking,
    experience: s.experience,
    wellness: s.wellness,
    preference: s.preference,
    transport: s.transport,
    items: [...activeItems]
      .sort((a, b) => a.order - b.order)
      .map((item) => toGuestCatalogItem(item, urlOf)),
  };
}
