import {
  AlertCategory,
  AlertSeverity,
  Department,
  RbacRole,
  StayRecord,
} from './stay.models';

export interface LarderOrderItem {
  orderItemId: string;
  stayId: string;
  villaId: string;
  villaName: string;
  guestNames: string;
  catalogItemId: string;
  name: string;
  category: string;
  unitPriceUSD: number;
  quantity: number;
  lineTotalUSD: number;
  storageType: string;
  provisioningStatus: string;
  assignedStaffId: string | null;
  assignedStaffName: string | null;
  assignedDepartment: Department;
  assignedAt: string | null;
  updatedAt: string;
}

export interface ExperienceBooking {
  bookingId: string;
  stayId: string;
  villaId: string;
  villaName: string;
  guestNames: string;
  bookingType:
    | 'EXCURSION'
    | 'YACHT_CHARTER'
    | 'PRIVATE_DINING'
    | 'INCLUDED_PRIVILEGE';
  category?: string;
  catalogRefId: string;
  title: string;
  scheduledDate: string;
  scheduledTimeSlot: string;
  partySize: number;
  isIncludedWithStay: boolean;
  originalValuationUSD: number;
  priceChargedUSD: number;
  metadata: Record<string, unknown>;
  status:
    | 'REQUESTED'
    | 'CONFIRMED'
    | 'IN_PREPARATION'
    | 'MODIFICATION_REQUESTED'
    | 'COMPLETED'
    | 'CANCELLED';
  cancellationReason?: string;
  assignedStaffId: string | null;
  assignedStaffName: string | null;
  assignedDepartment: Department;
  assignedAt: string | null;
  notifiedAt: string | null;
  adminNotes: string;
  createdAt: string;
}

export interface ConciergeMessage {
  sender: 'GUEST' | 'CONCIERGE';
  senderStaffId?: string;
  senderName: string;
  text: string;
  sentAt: string;
}

export interface ConciergeRequest {
  requestId: string;
  stayId: string;
  villaId: string;
  villaName: string;
  guestNames: string;
  type: 'issue' | 'request' | 'ask' | 'reservation';
  category: string;
  priority: AlertSeverity;
  title: string;
  timeLabel: string;
  location: string;
  status: 'Requested' | 'Assigned' | 'In Progress' | 'Completed';
  currentStep: 1 | 2 | 3 | 4;
  assignedStaffId: string | null;
  assignedTo: string;
  assignedDepartment: Department;
  assignedAt: string | null;
  notifiedAt: string | null;
  details: string;
  notes: string;
  photoStoragePath: string | null;
  isCompleted: boolean;
  messages: ConciergeMessage[];
  createdAt: string;
  updatedAt: string;
}

export interface MidStayFeedback {
  feedbackId: string;
  stayId: string;
  villaId: string;
  villaName: string;
  guestNames: string;
  dayOfStay: number;
  rating?: number;
  selectedSentiment: 'transcendent' | 'serene' | 'tuned' | 'direct';
  selectedAspects: string[];
  housekeepingPreferences?: string[];
  note: string;
  status: 'SUBMITTED' | 'DISPATCHED_TO_HOST' | 'RECALIBRATED';
  handledByStaffId: string | null;
  createdAt: string;
}

export interface FolioItem {
  folioItemId: string;
  displayOrder: number;
  title: string;
  subtitle: string;
  category:
    | 'STAY_PRIVILEGE'
    | 'VILLA_ENTITLEMENT'
    | 'EXCURSION'
    | 'LARDER'
    | 'SPA_APOTHECARY'
    | 'ECOLOGICAL_LEVY';
  badgeLabel: string | null;
  isComplimentary: boolean;
  originalValuationUSD: number | null;
  chargedAmountUSD: number;
  status: 'PRE_AUTHORIZED' | 'SETTLED' | 'WAIVED';
  sourceRefId: string | null;
  createdAt: string;
}

export interface StayAggregate extends StayRecord {
  larderOrders: LarderOrderItem[];
  experienceBookings: ExperienceBooking[];
  conciergeRequests: ConciergeRequest[];
  midstayFeedback: MidStayFeedback[];
  folioItems: FolioItem[];
}

export interface OperationalAlert {
  alertId: string;
  stayId: string;
  villaId: string;
  villaName: string;
  guestNames: string;
  category: AlertCategory;
  severity: AlertSeverity;
  title: string;
  summary: string;
  sourceDocumentPath: string;
  assignedDepartment: Department;
  isAcknowledged: boolean;
  acknowledgedByStaffId: string | null;
  acknowledgedAt: string | null;
  createdAt: string;
}

export interface StaffMember {
  staffId: string;
  firebaseUid: string;
  fullName: string;
  shortName: string;
  role: string;
  department: Department;
  rbacRole: RbacRole;
  email: string;
  phone: string;
  avatarUrl: string;
  isActive: boolean;
}

export interface LarderCatalogItem {
  id: string;
  name: string;
  origin: string;
  description: string;
  price: number;
  category: string;
  quantity: number;
  image: string;
  tag: string;
  dietary?: string;
  storageType: string;
  isActive: boolean;
}

export interface ExperienceCatalogItem {
  id: string;
  title: string;
  subtitle: string;
  duration: string;
  location: string;
  vehicleOrDetail: string;
  priceText: string;
  basePriceUSD: number;
  isIncluded: boolean;
  inclusionLabel?: string;
  image: string;
  category: string;
  description: string;
  amenities: string[];
  actionLabel: string;
  actionScreen?: string;
}

export interface YachtCatalog {
  vesselId: string;
  vesselSpecs: Record<string, string>;
  captainInfo: Record<string, string>;
  packages: Array<{
    id: string;
    title: string;
    tagline: string;
    durationHours: number;
    durationLabel: string;
    valuationUSD: number;
    upgradePriceUSD: number;
    isIncludedWithStay: boolean;
    priceLabel: string;
    description: string;
    highlights: string[];
    suggestedPaths: string;
    idealFor: string;
  }>;
  destinations: Array<{
    id: string;
    title: string;
    region: string;
    badge: string;
    image: string;
    subtitle: string;
    description: string;
    highlights: string[];
    duration: string;
  }>;
  gallery: Array<{
    src: string;
    caption: string;
    tag: string;
  }>;
}
