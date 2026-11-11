import {
  ConciergeRequest,
  ExperienceBooking,
  FolioItem,
  LarderOrderItem,
  MidStayFeedback,
  StayAggregate,
} from '../../src/domain/models/domain.models';
import { Villa } from '../../src/domain/models/resort-config.models';
import { buildNewStay } from '../../src/modules/admin/new-stay.builder';

/** Neutral test-only fixtures. They exist only under test/ and never reach the runtime. */
export function villaFixture(overrides: Partial<Villa> = {}): Villa {
  return {
    villaId: 'villa-a',
    name: 'Test Villa',
    category: 'Test category',
    capacity: 6,
    wifi: { ssid: 'test-net', password: 'test-pass' },
    operationalStatus: 'AVAILABLE',
    housekeepingStatus: 'CLEAN',
    maintenanceStatus: 'OK',
    maintenanceNote: '',
    isActive: true,
    createdAt: '2026-01-01T00:00:00.000Z',
    createdBy: 'test',
    updatedAt: '2026-01-01T00:00:00.000Z',
    updatedBy: 'test',
    ...overrides,
  };
}

export const TEST_GUEST_TOKEN = '11111111-1111-4111-8111-111111111111';

export function stayFixture(overrides: Partial<StayAggregate> = {}): StayAggregate {
  const stay = buildNewStay(
    {
      guestName: 'Test Guest',
      villaId: 'villa-a',
      checkIn: '2026-12-01',
      checkOut: '2026-12-05',
      guestsCount: 2,
    },
    villaFixture(),
    {
      stayId: 'stay-test-1',
      guestTokenUuid: TEST_GUEST_TOKEN,
      magicLinkUrl: `https://guest.test/?guestId=${TEST_GUEST_TOKEN}`,
      now: '2026-11-01T00:00:00.000Z',
    },
  );
  return { ...stay, ...overrides };
}

const AT = '2026-12-02T10:00:00.000Z';

function bookingFixture(stay: StayAggregate): ExperienceBooking {
  return {
    bookingId: 'bk-test-1', stayId: stay.stayId, villaId: stay.villaId, villaName: stay.villaName,
    guestNames: stay.guestProfile.name, serviceId: 'svc-1', itemId: null, section: 'EXPERIENCES',
    usageType: 'BOOKING', category: null, title: 'Test service', scheduledDate: '2026-12-03',
    scheduledTimeSlot: '10:00', partySize: 2, isIncludedWithStay: false, originalValuationUSD: 20,
    priceChargedUSD: 20, metadata: {}, status: 'REQUESTED', cancellationReason: '',
    assignedStaffId: 'staff-internal', assignedStaffName: 'Internal Name', assignedDepartment: 'CONCIERGE',
    assignedAt: null, notifiedAt: null, adminNotes: 'internal note', createdAt: AT,
    snapshot: {
      serviceId: 'svc-1', serviceName: { en: 'Test service', es: 'Servicio de prueba' }, section: 'EXPERIENCES',
      usageType: 'BOOKING', pricingMode: 'PER_PERSON', chargeToFolio: true, currency: 'USD',
      lines: [{ itemId: null, name: { en: 'Test service', es: 'Servicio de prueba' }, unitPriceUSD: 10, quantity: 1, lineTotalUSD: 20 }],
      totalUSD: 20, capturedAt: AT,
    },
  };
}

function conciergeFixture(stay: StayAggregate): ConciergeRequest {
  return {
    requestId: 'req-test-1', stayId: stay.stayId, villaId: stay.villaId, villaName: stay.villaName,
    guestNames: stay.guestProfile.name, type: 'request', category: 'Concierge', priority: 'NORMAL',
    title: 'Extra towels', timeLabel: '', location: '', status: 'Requested', currentStep: 1,
    assignedStaffId: 'staff-internal', assignedTo: '', assignedDepartment: 'CONCIERGE', assignedAt: null,
    notifiedAt: null, details: 'Two towels', notes: 'internal note', photoStoragePath: null, isCompleted: false,
    messages: [{ sender: 'GUEST', senderName: stay.guestProfile.name, text: 'Two towels', sentAt: AT }],
    createdAt: AT, updatedAt: AT,
  };
}

function larderFixture(stay: StayAggregate): LarderOrderItem {
  return {
    orderItemId: 'larder-test-1', stayId: stay.stayId, villaId: stay.villaId, villaName: stay.villaName,
    guestNames: stay.guestProfile.name, serviceId: 'svc-stock', catalogItemId: 'item-1', name: 'Test item',
    itemName: { en: 'Test item', es: 'Artículo de prueba' }, category: '', unitPriceUSD: 5, quantity: 2,
    lineTotalUSD: 10, storageType: '', provisioningStatus: 'Pending', assignedStaffId: null,
    assignedStaffName: null, assignedDepartment: null, assignedAt: null, updatedAt: AT,
  };
}

function feedbackFixture(stay: StayAggregate): MidStayFeedback {
  return {
    feedbackId: 'fb-test-1', stayId: stay.stayId, villaId: stay.villaId, villaName: stay.villaName,
    guestNames: stay.guestProfile.name, dayOfStay: 2, rating: 5, selectedSentiment: 'serene',
    selectedAspects: [], housekeepingPreferences: [], note: '', status: 'SUBMITTED',
    handledByStaffId: null, createdAt: AT,
  };
}

function folioFixture(): FolioItem {
  return {
    folioItemId: 'folio-test-1', displayOrder: 1, title: 'Test service', subtitle: '', category: 'SERVICE',
    badgeLabel: null, isComplimentary: false, originalValuationUSD: 20, chargedAmountUSD: 20,
    status: 'PRE_AUTHORIZED', sourceRefId: 'bk-test-1', createdAt: AT,
  };
}

/** An in-house stay holding one entry in every embedded list (neutral test data). */
export function populatedStayFixture(overrides: Partial<StayAggregate> = {}): StayAggregate {
  const stay = stayFixture({ status: 'ACTIVE_STAY' });
  return {
    ...stay,
    experienceBookings: [bookingFixture(stay)],
    conciergeRequests: [conciergeFixture(stay)],
    larderOrders: [larderFixture(stay)],
    midstayFeedback: [feedbackFixture(stay)],
    folioItems: [folioFixture()],
    ...overrides,
  };
}
