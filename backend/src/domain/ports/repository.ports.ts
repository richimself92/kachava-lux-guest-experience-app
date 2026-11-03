import {
  AlertCategory,
  AlertSeverity,
  ConciergeMessage,
  ConciergeRequest,
  Department,
  ExperienceBooking,
  ExperienceCatalogItem,
  FlightTransfer,
  FolioItem,
  FolioSummary,
  LarderCatalogItem,
  LarderOrderItem,
  MidStayFeedback,
  OperationalAlert,
  Personalization,
  StaffMember,
  StayAggregate,
  StayLifecycleStatus,
  StayRecord,
  YachtCatalog,
} from '../models/domain.models';
import { FolioSettlement, SettledFolio } from '../folio-ledger';

export const STAY_REPOSITORY_PORT = Symbol('STAY_REPOSITORY_PORT');
export const CATALOG_REPOSITORY_PORT = Symbol('CATALOG_REPOSITORY_PORT');
export const ALERT_REPOSITORY_PORT = Symbol('ALERT_REPOSITORY_PORT');
export const STAFF_REPOSITORY_PORT = Symbol('STAFF_REPOSITORY_PORT');
export const STORAGE_SIGNER_PORT = Symbol('STORAGE_SIGNER_PORT');

export interface StayFilterCriteria {
  status?: StayLifecycleStatus;
  villaId?: string;
  search?: string;
}

export interface BookingFilterCriteria {
  category?: string;
  bookingType?: string;
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
  listStays(filter?: StayFilterCriteria): Promise<StayAggregate[]>;
  createStay(stay: StayAggregate): Promise<StayAggregate>;
  updateStayToken(stayId: string, newUuid: string): Promise<StayRecord>;
  updateStayStatus(stayId: string, status: StayLifecycleStatus): Promise<StayRecord>;
  updateStayWifi(
    stayId: string,
    wifiPatch: { wifiSsid?: string; wifiPasscode?: string },
  ): Promise<StayRecord>;
  resetAllStays(): Promise<void>;
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

export interface CatalogRepositoryPort {
  getLarderCatalog(): Promise<LarderCatalogItem[]>;
  createLarderCatalogItem(item: Partial<LarderCatalogItem>): Promise<LarderCatalogItem>;
  deleteLarderCatalogItem(id: string): Promise<{ deleted: boolean; id: string }>;
  getExperiencesCatalog(): Promise<ExperienceCatalogItem[]>;
  createExperienceCatalogItem(
    item: Partial<ExperienceCatalogItem>,
  ): Promise<ExperienceCatalogItem>;
  deleteExperienceCatalogItem(id: string): Promise<{ deleted: boolean; id: string }>;
  getYachtCatalog(): Promise<YachtCatalog>;
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
  resetAllAlerts(): Promise<void>;
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
