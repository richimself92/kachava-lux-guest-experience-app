export type StayLifecycleStatus =
  | 'PRE_ARRIVAL'
  | 'ACTIVE_STAY'
  | 'CHECKED_OUT'
  | 'EXPIRED'
  | 'CANCELLED';

export type RbacRole =
  | 'HOST_ADMIN'
  | 'CONCIERGE_STAFF'
  | 'DEPARTMENT_COORDINATOR';

export type Department =
  | 'CONCIERGE'
  | 'CULINARY'
  | 'MARINE'
  | 'TRANSPORT'
  | 'HOUSEKEEPING'
  | 'ENGINEERING'
  | 'WELLNESS';

export type AlertCategory =
  | 'CONCIERGE'
  | 'BOOKING'
  | 'LARDER'
  | 'TRANSFER'
  | 'MIDSTAY'
  | 'CHECKOUT'
  | 'DIETARY';

export type AlertSeverity = 'NORMAL' | 'HIGH' | 'URGENT';

export interface GuestProfile {
  name: string;
  lastNameNormalized: string;
  partner: string;
  celebration: string;
  folioCard: string;
  dietaryProfile: string;
  allergies: string;
  inVillaBar: string;
  communicationPref: string;
  phone: string;
  email: string;
  avatarUrl: string;
}

export interface HostInfo {
  staffId: string;
  name: string;
  shortName: string;
  role: string;
  avatarUrl: string;
  whatsappPhone: string;
  isOnline: boolean;
}

export interface VillaAccess {
  digitalKeyStatus: 'ACTIVE' | 'INACTIVE';
  wifiSsid: string;
  wifiPasscode: string;
  climateTempF: number;
  plungePoolTempF: number;
  humidityPercent: number;
  emergencyContact: string;
}

export interface FlightTransfer {
  arrivalDate?: string;
  arrivalAirport: string;
  airline: string;
  flightNumber: string;
  arrivalTime?: string;
  terminal?: string;
  estimatedLanding: string;
  partySize: number;
  luggageCount?: number;
  luggageChecked: number;
  luggageCarryOn: number;
  notes?: string;
  status: string;
  assignedStaffId: string;
  assignedStaffName?: string;
  assignedDriver: string;
  assignedDepartment: Department;
  notifiedAt: string | null;
  driverRole: string;
  driverPhone: string;
  driverAvatarUrl: string;
  vehicleModel: string;
  fleetNumber: string;
  meetingPoint?: string;
  departureFlightNumber: string;
  departureRoute: string;
  departureTimeLabel: string;
  lateCheckoutRequested: boolean;
  adminDispatchNotes: string;
}

export interface Personalization {
  currentStep: number;
  tripPurpose: string;
  occasionDetails: string;
  selectedInterests: string[];
  dietary: string;
  dietaryAllergies?: string[];
  allergies: string;
  villaScent: string;
  scentProfile?: string;
  pillowType: string;
  pillowSelection?: string;
  temperatureCurve?: string;
  lightingRhythm?: string;
  housekeepingCadence?: string;
  commChannel: string;
  updatedAt: string;
}

export interface FolioSummary {
  complimentarySavingsUSD: number;
  incidentalsSubtotalUSD: number;
  ecologicalLevyUSD: number;
  finalSettledTotalUSD: number;
  paymentStatus: 'PRE_AUTHORIZED' | 'SETTLED' | 'WAIVED';
  isCheckedOut: boolean;
  checkedOutAt: string | null;
  approvedByStaffId: string | null;
}

export interface StayRecord {
  stayId: string;
  guestTokenUuid: string;
  magicLinkUrl?: string;
  status: StayLifecycleStatus;
  villaId: string;
  villaName: string;
  suiteName: string;
  sqft: string;
  stayDatesLabel: string;
  checkInDate?: string;
  checkOutDate?: string;
  checkInTimestamp: string;
  checkOutTimestamp: string;
  nights: number;
  guestsCount: number;
  selectedSignaturePrivilege: 'massage' | 'golf';
  guestProfile: GuestProfile;
  hostInfo: HostInfo;
  villaAccess: VillaAccess;
  flightTransfer: FlightTransfer;
  personalization: Personalization;
  folioSummary: FolioSummary;
  createdAt: string;
  updatedAt: string;
}
