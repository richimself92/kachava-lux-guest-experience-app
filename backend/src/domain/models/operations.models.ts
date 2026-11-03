import {
  LocalizedText,
  ServiceSection,
  ServiceSnapshot,
  UsageType,
} from '../catalog/catalog.models';
import {
  AlertCategory,
  AlertSeverity,
  Department,
  RbacRole,
  StayRecord,
} from './stay.models';

/** One line of a villa-stocking order; name and price are a snapshot taken when ordering. */
export interface LarderOrderItem {
  orderItemId: string;
  stayId: string;
  villaId: string;
  villaName: string;
  guestNames: string;
  serviceId: string;
  catalogItemId: string;
  name: string;
  itemName: LocalizedText;
  category: string;
  unitPriceUSD: number;
  quantity: number;
  lineTotalUSD: number;
  storageType: string;
  provisioningStatus: string;
  assignedStaffId: string | null;
  assignedStaffName: string | null;
  assignedDepartment: Department | null;
  assignedAt: string | null;
  updatedAt: string;
}

export interface ExperienceBooking {
  bookingId: string;
  stayId: string;
  villaId: string;
  villaName: string;
  guestNames: string;
  /** Catalog references plus the snapshot (name, price, items) captured when booking. */
  serviceId: string;
  itemId: string | null;
  section: ServiceSection;
  usageType: UsageType;
  category: string | null;
  snapshot: ServiceSnapshot;
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
  assignedDepartment: Department | null;
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
    | 'SERVICE'
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

/** Records an alert/notification can open ("Open record"). */
export type AlertTargetType =
  | 'STAY'
  | 'TRIP'
  | 'TASK'
  | 'BOOKING'
  | 'ORDER'
  | 'REQUEST'
  | 'FEEDBACK'
  | 'CONVERSATION';

/** The record an alert opens; when absent it is derived from `sourceDocumentPath`. */
export interface AlertTargetRef {
  type: AlertTargetType;
  id: string;
}

/** Operational events the Notifications screen distinguishes (plan v2, "Notifications"). */
export type NotificationEvent =
  | 'NEW_RESERVATION'
  | 'ARRIVAL_DAY'
  | 'GUEST_REQUEST'
  | 'ITINERARY_CHANGE'
  | 'TASK_OVERDUE'
  | 'GUEST_MESSAGE'
  | 'TRIP_UNCONFIRMED';

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
  assignedDepartment: Department | null;
  isAcknowledged: boolean;
  acknowledgedByStaffId: string | null;
  acknowledgedAt: string | null;
  createdAt: string;
  targetRef?: AlertTargetRef;
  /** Set by the writer; older alerts derive it from `category`. */
  event?: NotificationEvent;
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
