import {
  AlertCategory,
  AlertSeverity,
  ConciergeMessage,
  ConciergeRequest,
  Department,
  ExperienceBooking,
  FlightTransfer,
  FolioItem,
  FolioSummary,
  LarderOrderItem,
  MidStayFeedback,
  OperationalAlert,
  Personalization,
  StaffMember,
  StayAggregate,
  StayLifecycleStatus,
  StayRecord,
} from '../models/domain.models';
import { FolioSettlement, LarderCharge, SettledFolio } from '../folio-ledger';
import { BookingChange, JourneyMarks } from '../stays/guest-request-rules';
import { PaginatedResult, SortDirection } from '../../common/listing/list-query';
import { CatalogItem, CatalogService } from '../catalog/catalog.models';
import { ResortSettings, TransportProvider, Villa } from '../models/resort-config.models';
import { Trip, TripStatus } from '../trips/trip.models';
import { Task, TaskPriority, TaskStatus } from '../tasks/task.models';

export const STAY_REPOSITORY_PORT = Symbol('STAY_REPOSITORY_PORT');
export const VILLA_REPOSITORY_PORT = Symbol('VILLA_REPOSITORY_PORT');
export const TRANSPORT_PROVIDER_REPOSITORY_PORT = Symbol('TRANSPORT_PROVIDER_REPOSITORY_PORT');
export const SERVICE_REPOSITORY_PORT = Symbol('SERVICE_REPOSITORY_PORT');
export const SERVICE_ITEM_REPOSITORY_PORT = Symbol('SERVICE_ITEM_REPOSITORY_PORT');
export const SETTINGS_REPOSITORY_PORT = Symbol('SETTINGS_REPOSITORY_PORT');
export const CATALOG_IMAGE_STORAGE_PORT = Symbol('CATALOG_IMAGE_STORAGE_PORT');
export const ALERT_REPOSITORY_PORT = Symbol('ALERT_REPOSITORY_PORT');
export const STAFF_REPOSITORY_PORT = Symbol('STAFF_REPOSITORY_PORT');
export const STORAGE_SIGNER_PORT = Symbol('STORAGE_SIGNER_PORT');
export const TRIP_REPOSITORY_PORT = Symbol('TRIP_REPOSITORY_PORT');
export const TASK_REPOSITORY_PORT = Symbol('TASK_REPOSITORY_PORT');
export const NOTIFICATION_READ_REPOSITORY_PORT = Symbol('NOTIFICATION_READ_REPOSITORY_PORT');

/** Calendar fields a stays page can be ordered and ranged by. */
export type StayDateField = 'checkInDate' | 'checkOutDate';

/** Stays page request: equality filters, a date range on `dateField` (ISO dates) and guest-name search. */
export interface StayPageQuery {
  /** Order and range field; arrival (`checkInDate`) when omitted. */
  dateField?: StayDateField;
  status?: StayLifecycleStatus;
  villaId?: string;
  from?: string;
  to?: string;
  q?: string;
  page: number;
  pageSize: number;
  direction: SortDirection;
}

/** Messages inbox page: stays with at least one message, newest conversation first by default. */
export interface ConversationPageQuery {
  unread?: boolean;
  awaitingReply?: boolean;
  q?: string;
  page: number;
  pageSize: number;
  direction: SortDirection;
}

/** Equality filters pushed down to the store (`undefined` entries are ignored). */
export type EntityFilter = Record<string, string | number | boolean | undefined>;

/**
 * Admin-managed configuration collections (villas, providers, services, items). They are small
 * by nature, so `list` returns every match up to a hard scan limit and callers page in memory.
 */
export interface EntityRepositoryPort<T> {
  list(filter?: EntityFilter): Promise<T[]>;
  findById(id: string): Promise<T | null>;
  create(entity: T): Promise<T>;
  /** Read-modify-write in one transaction; throws EntityNotFoundError when absent. */
  update(id: string, mutate: (current: T) => T): Promise<T>;
  delete(id: string): Promise<void>;
}

export type VillaRepositoryPort = EntityRepositoryPort<Villa>;
export type TransportProviderRepositoryPort = EntityRepositoryPort<TransportProvider>;
export type ServiceRepositoryPort = EntityRepositoryPort<CatalogService>;
export type ServiceItemRepositoryPort = EntityRepositoryPort<CatalogItem>;

export interface SettingsRepositoryPort {
  get(): Promise<ResortSettings>;
  update(mutate: (current: ResortSettings) => ResortSettings): Promise<ResortSettings>;
}

export interface SignedUpload {
  uploadUrl: string;
  method: 'PUT' | 'POST';
  headers: Record<string, string>;
  expiresAt: string;
}

export interface CatalogImageStoragePort {
  signUpload(params: { path: string; contentType: string; maxBytes: number }): Promise<SignedUpload>;
  publicUrl(path: string): string;
}

export interface BookingFilterCriteria {
  section?: string;
  usageType?: string;
  status?: string;
  assignedDepartment?: string;
  scheduledDate?: string;
}

export interface LarderFilterCriteria {
  provisioningStatus?: string;
  category?: string;
  villaId?: string;
}

export interface ConciergeFilterCriteria {
  status?: string;
  priority?: string;
  assignedDepartment?: string;
  category?: string;
  villaId?: string;
}

export interface AlertFilterCriteria {
  isAcknowledged?: boolean;
  category?: AlertCategory;
  severity?: AlertSeverity;
  assignedDepartment?: Department;
}

/**
 * Builds the operational alert for a stay mutation from its result. The repository writes the
 * alert in the same transaction as the stay, so a failed request persists neither and a client
 * retry cannot duplicate the mutation. Returning null writes no alert.
 */
export type StayAlertFactory<T> = (result: T) => OperationalAlert | null;

export interface StayRepositoryPort {
  findByGuestTokenUuid(guestTokenUuid: string): Promise<StayAggregate | null>;
  findByStayId(stayId: string): Promise<StayAggregate | null>;
  pageStays(query: StayPageQuery): Promise<PaginatedResult<StayAggregate>>;
  /** Stays the admin dashboard follows live (pre-arrival and in-house), at most `limit`. */
  listOpenStays(limit: number): Promise<StayAggregate[]>;
  /** Every stay in `statuses` (bounded read: ListScanLimitError beyond the scan limit). */
  listStaysByStatuses(statuses: readonly StayLifecycleStatus[]): Promise<StayAggregate[]>;
  /** Stays with messages, filtered and ordered by the derived conversation summary in Firestore. */
  pageConversations(query: ConversationPageQuery): Promise<PaginatedResult<StayAggregate>>;
  /** Stays whose conversation has unread guest messages (bounded read). */
  listUnreadConversations(): Promise<StayAggregate[]>;
  /** Stays whose check-in date is `date` (bounded read). */
  listStaysCheckingInOn(date: string): Promise<StayAggregate[]>;
  hasStaysForVilla(villaId: string): Promise<boolean>;
  /** Creates the stay and, in the same transaction, its alert. */
  createStay(stay: StayAggregate, alert?: OperationalAlert | null): Promise<StayAggregate>;
  /** Read-modify-write of one stay in a transaction (StayNotFoundError when absent). */
  updateStay(stayId: string, change: (current: StayAggregate) => StayAggregate): Promise<StayAggregate>;
  updateStayToken(stayId: string, newUuid: string): Promise<StayRecord>;
  updateStayStatus(stayId: string, status: StayLifecycleStatus): Promise<StayRecord>;
  updateStayWifi(
    stayId: string,
    wifiPatch: { wifiSsid?: string; wifiPasscode?: string },
  ): Promise<StayRecord>;
  updateTransfer(
    stayId: string,
    transferPatch: Partial<FlightTransfer>,
    alertOf?: StayAlertFactory<FlightTransfer>,
  ): Promise<FlightTransfer>;
  updatePersonalization(
    stayId: string,
    personalizationPatch: Partial<Personalization>,
    allergiesLabel?: string,
    alertOf?: StayAlertFactory<Personalization>,
  ): Promise<Personalization>;
  updateSignaturePrivilege(
    stayId: string,
    privilege: 'massage' | 'golf',
  ): Promise<StayRecord>;
  /** Replaces the lines of ONE order service (others untouched) and re-prices its folio line. */
  replaceServiceOrder(
    stayId: string,
    serviceId: string,
    lines: LarderOrderItem[],
    charge: LarderCharge,
    alertOf?: StayAlertFactory<{ orders: LarderOrderItem[]; folioSummary: FolioSummary }>,
  ): Promise<{ orders: LarderOrderItem[]; folioSummary: FolioSummary }>;
  /** Guest cancel of a REQUESTED booking (404 unknown, 422 later status); drops its folio line. */
  cancelGuestBooking(
    stayId: string,
    bookingId: string,
    alertOf?: StayAlertFactory<ExperienceBooking>,
  ): Promise<ExperienceBooking>;
  /** Guest change of a REQUESTED booking's date, time or party; re-prices its folio line. */
  changeGuestBooking(
    stayId: string,
    bookingId: string,
    change: BookingChange,
    alertOf?: StayAlertFactory<ExperienceBooking>,
  ): Promise<ExperienceBooking>;
  /** Replaces the guest's skipped / self-completed journey task lists that are given. */
  setJourneyMarks(stayId: string, marks: Partial<JourneyMarks>): Promise<JourneyMarks>;
  listLarderOrdersAcrossStays(
    filter?: LarderFilterCriteria,
  ): Promise<LarderOrderItem[]>;
  updateLarderOrderStatus(
    orderItemId: string,
    patch: Partial<LarderOrderItem>,
  ): Promise<LarderOrderItem | null>;
  /** Stores the booking and, when paid, appends its folio line to the stored folio. */
  createBooking(
    stayId: string,
    booking: ExperienceBooking,
    alertOf?: StayAlertFactory<ExperienceBooking>,
  ): Promise<ExperienceBooking>;
  listBookingsForStay(stayId: string): Promise<ExperienceBooking[]>;
  listBookingsAcrossStays(
    filter?: BookingFilterCriteria,
  ): Promise<ExperienceBooking[]>;
  updateBookingAssignment(
    bookingId: string,
    patch: Partial<ExperienceBooking>,
  ): Promise<ExperienceBooking | null>;
  listConciergeRequestsForStay(stayId: string): Promise<ConciergeRequest[]>;
  listConciergeRequestsAcrossStays(
    filter?: ConciergeFilterCriteria,
  ): Promise<ConciergeRequest[]>;
  findConciergeRequestById(requestId: string): Promise<ConciergeRequest | null>;
  createConciergeRequest(
    stayId: string,
    request: ConciergeRequest,
    alertOf?: StayAlertFactory<ConciergeRequest>,
  ): Promise<ConciergeRequest>;
  appendConciergeMessage(
    stayId: string,
    requestId: string,
    message: ConciergeMessage,
    alertOf?: StayAlertFactory<ConciergeRequest | null>,
  ): Promise<ConciergeRequest | null>;
  updateConciergeRequestAdmin(
    requestId: string,
    patch: Partial<ConciergeRequest>,
    newMessage?: ConciergeMessage,
  ): Promise<ConciergeRequest | null>;
  createMidStayFeedback(
    stayId: string,
    feedback: MidStayFeedback,
    alertOf?: StayAlertFactory<MidStayFeedback>,
  ): Promise<MidStayFeedback>;
  listMidStayFeedbackAcrossStays(): Promise<MidStayFeedback[]>;
  getFolioForStay(
    stayId: string,
  ): Promise<{ folioSummary: FolioSummary; folioItems: FolioItem[] }>;
  /** Settles every folio line stored at commit time (no caller-supplied folio snapshot). */
  settleFolio(
    stayId: string,
    settlement: FolioSettlement,
    alertOf?: StayAlertFactory<SettledFolio>,
  ): Promise<SettledFolio>;
}

export interface AlertRepositoryPort {
  createAlert(alert: OperationalAlert): Promise<OperationalAlert>;
  listAlerts(
    filter?: AlertFilterCriteria,
  ): Promise<{ alerts: OperationalAlert[]; unreadCount: number }>;
  acknowledgeAlert(
    alertId: string,
    staffId: string,
  ): Promise<OperationalAlert | null>;
  /** Newest-first alerts created in the window (both bounds optional), at most `limit`. */
  listRecent(window: { fromIso?: string; toIsoExclusive?: string }, limit: number): Promise<OperationalAlert[]>;
  /** Acknowledges every listed alert that is still unread; returns how many changed. */
  acknowledgeMany(alertIds: readonly string[], staffId: string, at: string): Promise<number>;
}

export interface StaffRepositoryPort {
  listStaff(department?: string): Promise<StaffMember[]>;
  findByStaffId(staffId: string): Promise<StaffMember | null>;
  findByEmail(email: string): Promise<StaffMember | null>;
  findByFirebaseUid(firebaseUid: string): Promise<StaffMember | null>;
}

export interface SignedUrlResult {
  uploadUrl?: string;
  downloadUrl?: string;
  storagePath: string;
  expiresAt: string;
  contentType?: string;
}

/** A direct-to-Storage upload: send the bytes with `method` and exactly these `headers`. */
export interface SignedPhotoUpload extends SignedUpload {
  storagePath: string;
  maxBytes: number;
}

export interface StorageSignerPort {
  generateSignedPutUrl(params: {
    stayId: string;
    requestId: string;
    fileName: string;
    contentType: string;
    fileSizeBytes: number;
  }): Promise<SignedPhotoUpload>;
  generateSignedGetUrl(storagePath: string): Promise<SignedUrlResult>;
}

/** Trip instants that can bound a list: the pickup or the flight time. */
export type TripDateField = 'pickupAt' | 'flight.scheduledAt';

export interface TripWindowQuery {
  field: TripDateField;
  /** Inclusive lower bound (UTC ISO). */
  fromIso?: string;
  /** Exclusive upper bound (UTC ISO). */
  toIsoExclusive?: string;
}

/** Builds the alert that commits with a trip update (null writes none). */
export type TripAlertFactory = (updated: Trip, previous: Trip) => OperationalAlert | null;

/**
 * Top-level `trips` collection. Every list is a bounded read (ListScanLimitError beyond the
 * limit); alerts passed to `create`/`update` commit in the same transaction as the trip.
 */
export interface TripRepositoryPort {
  create(trip: Trip, alert?: OperationalAlert | null): Promise<Trip>;
  findById(tripId: string): Promise<Trip | null>;
  /** Read-modify-write in one transaction; throws EntityNotFoundError when absent. */
  update(tripId: string, mutate: (current: Trip) => Trip, alertOf?: TripAlertFactory): Promise<Trip>;
  /** Trips whose `field` lies in the window (every trip when no bound is given), ordered by it. */
  listInWindow(query: TripWindowQuery): Promise<Trip[]>;
  listForStay(stayId: string): Promise<Trip[]>;
  /** REQUESTED / SENT_TO_PROVIDER trips with `pickupAt <= cutoffIso`, earliest pickup first. */
  listUnconfirmedUntil(cutoffIso: string): Promise<Trip[]>;
  /** Trips of any of `stayIds` (bounded read). */
  listForStays(stayIds: readonly string[]): Promise<Trip[]>;
  /** Number of trips whose status is one of `statuses` (aggregate count, no document reads). */
  countByStatuses(statuses: readonly TripStatus[]): Promise<number>;
}

/** Tasks page request; every filter runs in Firestore (ordered by `dueAt`). */
export interface TaskPageQuery {
  status?: TaskStatus;
  priority?: TaskPriority;
  ownerStaffId?: string;
  villaId?: string;
  /** Only open tasks whose `dueAt` is before this instant (UTC ISO). */
  overdueBefore?: string;
  /** Normalised search text (title, guest or villa word prefix). */
  q?: string;
  page: number;
  pageSize: number;
  direction: SortDirection;
}

/** Top-level `tasks` collection (ADR-011). */
export interface TaskRepositoryPort {
  /** EntityConflictError when the id exists. */
  create(task: Task): Promise<Task>;
  /** Idempotent create keyed by `taskId`: an existing task is returned untouched. */
  createIfAbsent(task: Task): Promise<{ task: Task; created: boolean }>;
  findById(taskId: string): Promise<Task | null>;
  /** Read-modify-write in one transaction; EntityNotFoundError when absent. */
  update(taskId: string, mutate: (current: Task) => Task): Promise<Task>;
  page(query: TaskPageQuery): Promise<PaginatedResult<Task>>;
  /** Open tasks with `dueAt < nowIso`, earliest first (bounded read). */
  listOverdue(nowIso: string): Promise<Task[]>;
  countByStatuses(statuses: readonly TaskStatus[]): Promise<number>;
}

/** Read markers of computed notifications (stored alerts keep their own acknowledgement). */
export interface NotificationReadRepositoryPort {
  /** notificationId -> readAt for the ids that were marked read. */
  readAtOf(ids: readonly string[]): Promise<Map<string, string>>;
  markRead(ids: readonly string[], staffId: string, at: string): Promise<void>;
}
