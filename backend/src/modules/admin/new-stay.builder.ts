import {
  FlightTransfer,
  FolioSummary,
  GuestProfile,
  HostInfo,
  Personalization,
  StayAggregate,
  VillaAccess,
} from '../../domain/models/domain.models';
import { Villa } from '../../domain/models/resort-config.models';
import { CreateReservationDto } from './dto/admin.dto';

export interface NewStayIdentity {
  stayId: string;
  guestTokenUuid: string;
  magicLinkUrl: string;
  now: string;
}

/** Unified operations role label shown to guests until a specific host is assigned. */
const UNIFIED_HOST_ROLE = 'HOST ADMIN';
const MS_PER_DAY = 86_400_000;

/**
 * Builds a brand-new, empty stay aggregate from the reservation request and its villa.
 * Nothing is copied from templates: unknown values stay empty, zero or "not requested".
 * Dates are ISO calendar dates (validated by the DTO; checkOut after checkIn by the service).
 */
export function buildNewStay(dto: CreateReservationDto, villa: Villa, identity: NewStayIdentity): StayAggregate {
  const celebration = dto.occasion || dto.celebration || '';
  const guestsCount = dto.guestsCount ?? 0;
  return {
    stayId: identity.stayId, guestTokenUuid: identity.guestTokenUuid,
    magicLinkUrl: identity.magicLinkUrl, status: 'PRE_ARRIVAL',
    villaId: villa.villaId, villaName: villa.name, suiteName: villa.category, sqft: '',
    stayDatesLabel: `${dto.checkIn} – ${dto.checkOut}`,
    checkInDate: dto.checkIn, checkOutDate: dto.checkOut,
    checkInTimestamp: toIsoTimestamp(dto.checkIn), checkOutTimestamp: toIsoTimestamp(dto.checkOut),
    nights: nightsBetween(dto.checkIn, dto.checkOut), guestsCount, selectedSignaturePrivilege: 'massage',
    guestProfile: buildGuestProfile(dto, celebration), hostInfo: emptyHostInfo(),
    villaAccess: buildVillaAccess(dto, villa), flightTransfer: emptyTransfer(guestsCount),
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

function buildVillaAccess(dto: CreateReservationDto, villa: Villa): VillaAccess {
  return {
    digitalKeyStatus: 'INACTIVE', wifiSsid: dto.wifiSsid?.trim() || villa.wifi.ssid,
    wifiPasscode: dto.wifiPasscode?.trim() || villa.wifi.password, climateTempF: 0, plungePoolTempF: 0,
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

function toIsoTimestamp(isoDate: string): string {
  return new Date(`${isoDate}T00:00:00.000Z`).toISOString();
}

export function nightsBetween(checkIn: string, checkOut: string): number {
  const diff = Date.parse(`${checkOut}T00:00:00Z`) - Date.parse(`${checkIn}T00:00:00Z`);
  return Number.isFinite(diff) ? Math.round(diff / MS_PER_DAY) : 0;
}
