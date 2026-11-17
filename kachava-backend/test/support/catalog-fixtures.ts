import { CatalogItem, CatalogService } from '../../src/domain/catalog/catalog.models';

/** Neutral test-only catalog entities (no real business data). */
const empty = { en: '', es: '' };
const audit = {
  createdAt: '2026-01-01T00:00:00.000Z',
  createdBy: 'test',
  updatedAt: '2026-01-01T00:00:00.000Z',
  updatedBy: 'test',
};

export function serviceFixture(overrides: Partial<CatalogService> = {}): CatalogService {
  return {
    serviceId: 'svc-1',
    kind: 'EXPERIENCE',
    section: 'EXPERIENCES',
    category: null,
    usageType: 'BOOKING',
    name: { en: 'Test service', es: 'Servicio de prueba' },
    shortDescription: { en: 'Short', es: 'Corta' },
    description: empty,
    tags: [],
    order: 1,
    featured: false,
    cover: { storagePath: 'catalog/services/cover.jpg', alt: { en: 'Cover', es: 'Portada' }, usageRightsConfirmed: true },
    gallery: [],
    pricing: { mode: 'PER_PERSON', amount: 10, currency: 'USD', chargeToFolio: true, note: empty },
    availability: {
      weekdays: [],
      timeSlots: [],
      blockedDates: [],
      minLeadHours: null,
      cancellationHours: null,
      minGuests: null,
      maxGuests: null,
      durationMinutes: null,
      offeredWhen: null,
    },
    guestInfo: {
      includes: empty,
      excludes: empty,
      whatToBring: empty,
      location: empty,
      restrictions: empty,
      cancellationPolicy: empty,
    },
    guestForm: { date: true, time: true, guests: true, notes: true, dietary: false, health: false },
    operation: {
      providerId: null,
      responsibleDepartment: null,
      responsibleStaffId: null,
      requiresConfirmation: true,
      internalInstructions: 'staff only',
    },
    bar: null,
    dining: null,
    stocking: null,
    experience: { itinerary: [], meetingPoint: empty, languages: [], minAge: null },
    wellness: null,
    preference: null,
    transport: null,
    status: 'ACTIVE',
    ...audit,
    ...overrides,
  };
}

export function itemFixture(overrides: Partial<CatalogItem> = {}): CatalogItem {
  return {
    itemId: 'item-1',
    serviceId: 'svc-1',
    name: { en: 'Test item', es: 'Artículo de prueba' },
    description: empty,
    category: null,
    image: null,
    priceUSD: 5,
    tags: [],
    dietaryTags: [],
    allergens: [],
    origin: null,
    unit: null,
    storage: null,
    capacity: null,
    order: 1,
    status: 'ACTIVE',
    ...audit,
    ...overrides,
  };
}
