import {
  FlightTransfer,
  FolioSummary,
  GuestProfile,
  HostInfo,
  Personalization,
  StayAggregate,
  VillaAccess,
} from '../../domain/models/domain.models';
import { CreateReservationDto } from './dto/admin.dto';

export interface NewStayIdentity {
  stayId: string;
  guestTokenUuid: string;
  magicLinkUrl: string;
  now: string;
}

/** Unified operations role label shown to guests until a specific host is assigned. */
const UNIFIED_HOST_ROLE = 'HOST ADMIN';
const ISO_DATE_PREFIX = /^\d{4}-\d{2}-\d{2}/;
const MS_PER_DAY = 86_400_000;

/**
 * Builds a brand-new, empty stay aggregate exclusively from the reservation request.
 * Nothing is copied from demo templates: unknown values stay empty, zero or "not requested".
 */
export function buildNewStay(dto: CreateReservationDto, identity: NewStayIdentity): StayAggregate {
  const villaId = dto.villaId?.trim() || '';
  const celebration = dto.occasion || dto.celebration || '';
  const guestsCount = dto.guestsCount ?? 0;
  return {
    stayId: identity.stayId, guestTokenUuid: identity.guestTokenUuid,
    magicLinkUrl: identity.magicLinkUrl, status: 'PRE_ARRIVAL',
    villaId, villaName: dto.villaName?.trim() || villaId,
    suiteName: extractSuiteName(dto.villaName, dto.suiteName), sqft: '',
    stayDatesLabel: resolveStayDatesLabel(dto),
    checkInDate: dto.checkIn || '', checkOutDate: dto.checkOut || '',
    checkInTimestamp: toIsoTimestamp(dto.checkIn), checkOutTimestamp: toIsoTimestamp(dto.checkOut),
    nights: calculateNights(dto), guestsCount, selectedSignaturePrivilege: 'massage',
    guestProfile: buildGuestProfile(dto, celebration), hostInfo: emptyHostInfo(),
    villaAccess: buildVillaAccess(dto), flightTransfer: emptyTransfer(guestsCount),
    personalization: emptyPersonalization(celebration, identity.now),
    folioSummary: emptyFolioSummary(),
    folioItems: [], larderOrders: [], experienceBookings: [], conciergeRequests: [], midstayFeedback: [],
    createdAt: identity.now, updatedAt: identity.now,
  };
}

function buildGuestProfile(dto: CreateReservationDto, celebration: string): GuestProfile {
  const lastName = dto.guestName.trim().split(/\s+/).pop()?.toLowerCase() || '';
  return {
    name: dto.guestName, lastNameNormalized: lastName, partner: dto.partnerName || '',
    celebration, folioCard: '', dietaryProfile: '', allergies: '', inVillaBar: '',
    communicationPref: '', phone: dto.phone || '', email: dto.email || '', avatarUrl: '',
  };
}

function emptyHostInfo(): HostInfo {
  return {
    staffId: '', name: UNIFIED_HOST_ROLE, shortName: UNIFIED_HOST_ROLE, role: UNIFIED_HOST_ROLE,
    avatarUrl: '', whatsappPhone: '', isOnline: false,
  };
}

function buildVillaAccess(dto: CreateReservationDto): VillaAccess {
  return {
    digitalKeyStatus: 'INACTIVE', wifiSsid: dto.wifiSsid?.trim() || '',
    wifiPasscode: dto.wifiPasscode?.trim() || '', climateTempF: 0, plungePoolTempF: 0,
    humidityPercent: 0, emergencyContact: '',
  };
}

function emptyTransfer(partySize: number): FlightTransfer {
  return {
    arrivalDate: '', arrivalAirport: '', airline: '', flightNumber: '', arrivalTime: '',
    terminal: '', estimatedLanding: '', partySize, luggageCount: 0, luggageChecked: 0,
    luggageCarryOn: 0, notes: '', status: 'Not Requested', assignedStaffId: '',
    assignedStaffName: '', assignedDriver: '', assignedDepartment: 'TRANSPORT', notifiedAt: null,
    driverRole: '', driverPhone: '', driverAvatarUrl: '', vehicleModel: '', fleetNumber: '',
    meetingPoint: '', departureFlightNumber: '', departureRoute: '', departureTimeLabel: '',
    lateCheckoutRequested: false, adminDispatchNotes: '',
  };
}

function emptyPersonalization(tripPurpose: string, now: string): Personalization {
  return {
    currentStep: 1, tripPurpose, occasionDetails: '', selectedInterests: [], dietary: '',
    dietaryAllergies: [], allergies: '', villaScent: '', scentProfile: '', pillowType: '',
    pillowSelection: '', temperatureCurve: '', lightingRhythm: '', housekeepingCadence: '',
    commChannel: '', updatedAt: now,
  };
}

function emptyFolioSummary(): FolioSummary {
  return {
    complimentarySavingsUSD: 0, incidentalsSubtotalUSD: 0, ecologicalLevyUSD: 0,
    finalSettledTotalUSD: 0, paymentStatus: 'PRE_AUTHORIZED', isCheckedOut: false,
    checkedOutAt: null, approvedByStaffId: null,
  };
}

function toIsoTimestamp(rawDate?: string): string {
  if (!rawDate || !ISO_DATE_PREFIX.test(rawDate.trim())) return '';
  const parsed = new Date(rawDate.trim());
  return Number.isNaN(parsed.getTime()) ? '' : parsed.toISOString();
}

/** Month-day inputs without a year ("Oct 19") are interpreted in the 2026 season. */
function calculateNights(dto: CreateReservationDto): number {
  if (typeof dto.nights === 'number' && dto.nights > 0) return dto.nights;
  if (!dto.checkIn || !dto.checkOut) return 0;
  const withYear = (raw: string) => (/\b\d{4}\b/.test(raw) ? raw.trim() : `${raw.trim()}, 2026`);
  const inDate = new Date(withYear(dto.checkIn));
  const outDate = new Date(withYear(dto.checkOut));
  const diffDays = Math.round((outDate.getTime() - inDate.getTime()) / MS_PER_DAY);
  return Number.isFinite(diffDays) && diffDays > 0 ? diffDays : 0;
}

function resolveStayDatesLabel(dto: CreateReservationDto): string {
  if (dto.checkIn && dto.checkOut) return `${dto.checkIn} – ${dto.checkOut}`;
  return dto.stayDatesLabel || '';
}

function extractSuiteName(villaName?: string, suiteName?: string): string {
  if (suiteName?.trim()) return suiteName.trim();
  if (villaName && (villaName.includes('—') || villaName.includes('-'))) {
    return villaName.split(/—|-/).slice(1).join('-').trim();
  }
  return '';
}
