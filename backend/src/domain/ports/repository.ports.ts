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
import { PaginatedResult, SortDirection } from '../../common/listing/list-query';
import { CatalogItem, CatalogService } from '../catalog/catalog.models';
import { ResortSettings, TransportProvider, Villa } from '../models/resort-config.models';

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

/** Stays page request: equality filters, arrival range (ISO dates) and guest-name search. */
export interface StayPageQuery {
  status?: StayLifecycleStatus;
  villaId?: string;
  from?: string;
  to?: string;
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
  hasStaysForVilla(villaId: string): Promise<boolean>;
  createStay(stay: StayAggregate): Promise<StayAggregate>;
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
  /** Replaces the larder order; the larder folio line is re-priced from the stored folio. */
  replaceLarderOrders(
    stayId: string,
    orders: LarderOrderItem[],
    charge: LarderCharge,
    alertOf?: StayAlertFactory<{ orders: LarderOrderItem[]; folioSummary: FolioSummary }>,
  ): Promise<{ orders: LarderOrderItem[]; folioSummary: FolioSummary }>;
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

export interface StorageSignerPort {
  generateSignedPutUrl(params: {
    stayId: string;
    requestId: string;
    fileName: string;
    contentType: string;
    fileSizeBytes: number;
  }): Promise<SignedUrlResult>;
  generateSignedGetUrl(storagePath: string): Promise<SignedUrlResult>;
}
