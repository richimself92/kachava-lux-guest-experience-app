import { Department } from '../models/stay.models';

/**
 * Service catalog model (ADR-009). A service is what the guest sees in a section; its items are
 * the menu/products/options/vehicles. Everything is created from the admin: nothing is preloaded.
 */
export const SERVICE_SECTIONS = ['IN_VILLA', 'DINING', 'EXPERIENCES', 'WELLNESS', 'TRANSPORTATION'] as const;
export type ServiceSection = (typeof SERVICE_SECTIONS)[number];

/** The template that decides which type-specific block the service carries. */
export const SERVICE_KINDS = [
  'BAR',
  'BREAKFAST',
  'SPECIAL_MENU',
  'VILLA_STOCKING',
  'EXPERIENCE',
  'WELLNESS',
  'PREFERENCE',
  'TRANSPORT',
] as const;
export type ServiceKind = (typeof SERVICE_KINDS)[number];

export const USAGE_TYPES = ['ORDER', 'BOOKING', 'PREFERENCE', 'TRIP'] as const;
export type UsageType = (typeof USAGE_TYPES)[number];

export const PRICING_MODES = ['INCLUDED', 'FIXED', 'PER_PERSON', 'PER_UNIT', 'PER_HOUR', 'ON_REQUEST'] as const;
export type PricingMode = (typeof PRICING_MODES)[number];

export const CATALOG_STATUSES = ['ACTIVE', 'DISABLED'] as const;
export type CatalogStatus = (typeof CATALOG_STATUSES)[number];

export const WEEKDAYS = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'] as const;
export type Weekday = (typeof WEEKDAYS)[number];

export const OFFERED_WHEN = ['BEFORE_ARRIVAL', 'DURING_STAY', 'BOTH'] as const;
export type OfferedWhen = (typeof OFFERED_WHEN)[number];

export const WELLNESS_LOCATIONS = ['VILLA', 'SPA', 'BOTH'] as const;
export const SELECTION_MODES = ['SINGLE', 'MULTIPLE'] as const;
export const TRANSPORT_PRICE_BASIS = ['PER_TRIP', 'PER_VEHICLE'] as const;

/** Visible text is always bilingual; a missing translation is an empty string, never auto-filled. */
export interface LocalizedText {
  en: string;
  es: string;
}

/** An uploaded photo: the `storagePath` returned by `POST /admin/uploads/sign` (under `catalog/`). */
export interface CatalogImage {
  storagePath: string;
  alt: LocalizedText;
  /** Staff confirmed Kachava may use this photo. */
  usageRightsConfirmed: boolean;
}

export const GALLERY_MAX_IMAGES = 8;

export interface ServicePricing {
  mode: PricingMode;
  /** USD amount; null for INCLUDED / ON_REQUEST or when every item carries its own price. */
  amount: number | null;
  currency: 'USD';
  chargeToFolio: boolean;
  note: LocalizedText;
}

export interface TimeSlot {
  start: string;
  end: string;
}

export interface ServiceAvailability {
  weekdays: Weekday[];
  timeSlots: TimeSlot[];
  blockedDates: string[];
  minLeadHours: number | null;
  cancellationHours: number | null;
  minGuests: number | null;
  maxGuests: number | null;
  durationMinutes: number | null;
  offeredWhen: OfferedWhen | null;
}

export interface ServiceGuestInfo {
  includes: LocalizedText;
  excludes: LocalizedText;
  whatToBring: LocalizedText;
  location: LocalizedText;
  restrictions: LocalizedText;
  cancellationPolicy: LocalizedText;
}

/** Which inputs the guest form asks for. */
export interface ServiceGuestForm {
  date: boolean;
  time: boolean;
  guests: boolean;
  notes: boolean;
  dietary: boolean;
  health: boolean;
}

/** Staff-only; never returned to guests. */
export interface ServiceOperation {
  providerId: string | null;
  responsibleDepartment: Department | null;
  responsibleStaffId: string | null;
  requiresConfirmation: boolean;
  internalInstructions: string;
}

export interface BarDetails {
  ageConfirmationRequired: boolean;
}

export interface DiningDetails {
  pairingAvailable: boolean;
}

export interface StockingDetails {
  maxPerItem: number | null;
  orderDeadlineHoursBeforeCheckIn: number | null;
}

export interface ItineraryStep {
  title: LocalizedText;
  description: LocalizedText;
  durationMinutes: number | null;
}

export interface ExperienceDetails {
  itinerary: ItineraryStep[];
  meetingPoint: LocalizedText;
  languages: string[];
  minAge: number | null;
}

export interface WellnessDetails {
  location: (typeof WELLNESS_LOCATIONS)[number] | null;
  healthQuestions: LocalizedText[];
  contraindications: LocalizedText;
}

export interface PreferenceDetails {
  selection: (typeof SELECTION_MODES)[number];
  changeDeadlineHours: number | null;
}

export interface TransportDetails {
  /** Airport codes configured in Settings. */
  airportCodes: string[];
  priceBasis: (typeof TRANSPORT_PRICE_BASIS)[number] | null;
  flightDetailsRequired: boolean;
}

/** Exactly one block is set: the one matching `kind` (see KIND_DETAIL_FIELD). */
export interface ServiceKindDetails {
  bar: BarDetails | null;
  dining: DiningDetails | null;
  stocking: StockingDetails | null;
  experience: ExperienceDetails | null;
  wellness: WellnessDetails | null;
  preference: PreferenceDetails | null;
  transport: TransportDetails | null;
}

export type KindDetailField = keyof ServiceKindDetails;

export const KIND_DETAIL_FIELD: Record<ServiceKind, KindDetailField> = {
  BAR: 'bar',
  BREAKFAST: 'dining',
  SPECIAL_MENU: 'dining',
  VILLA_STOCKING: 'stocking',
  EXPERIENCE: 'experience',
  WELLNESS: 'wellness',
  PREFERENCE: 'preference',
  TRANSPORT: 'transport',
};

export interface AuditTrail {
  createdAt: string;
  createdBy: string;
  updatedAt: string;
  updatedBy: string;
}

export interface CatalogService extends ServiceKindDetails, AuditTrail {
  serviceId: string;
  kind: ServiceKind;
  section: ServiceSection;
  category: string | null;
  usageType: UsageType;
  name: LocalizedText;
  shortDescription: LocalizedText;
  description: LocalizedText;
  tags: string[];
  order: number;
  featured: boolean;
  cover: CatalogImage | null;
  gallery: CatalogImage[];
  pricing: ServicePricing;
  availability: ServiceAvailability;
  guestInfo: ServiceGuestInfo;
  guestForm: ServiceGuestForm;
  operation: ServiceOperation;
  status: CatalogStatus;
}

export interface VehicleCapacity {
  passengers: number;
  luggage: number;
}

export interface CatalogItem extends AuditTrail {
  itemId: string;
  serviceId: string;
  name: LocalizedText;
  description: LocalizedText;
  /** Grouping inside the service: bar category, menu course, product family... */
  category: string | null;
  image: CatalogImage | null;
  /** Own price; null means the service pricing applies. */
  priceUSD: number | null;
  tags: string[];
  dietaryTags: string[];
  allergens: string[];
  origin: string | null;
  unit: string | null;
  storage: string | null;
  capacity: VehicleCapacity | null;
  order: number;
  status: CatalogStatus;
}

/** What an order/booking stores about the service at the moment the guest asked for it. */
export interface ServiceSnapshot {
  serviceId: string;
  serviceName: LocalizedText;
  section: ServiceSection;
  usageType: UsageType;
  pricingMode: PricingMode;
  chargeToFolio: boolean;
  currency: 'USD';
  lines: Array<{
    itemId: string | null;
    name: LocalizedText;
    unitPriceUSD: number | null;
    quantity: number;
    lineTotalUSD: number | null;
  }>;
  totalUSD: number | null;
  capturedAt: string;
}
