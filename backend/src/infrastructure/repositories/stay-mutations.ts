import {
  ConciergeMessage,
  ConciergeRequest,
  ExperienceBooking,
  FolioItem,
  FolioSummary,
  LarderOrderItem,
  StayAggregate,
  StayLifecycleStatus,
} from '../../domain/models/domain.models';
import {
  BookingFilterCriteria,
  ConciergeFilterCriteria,
  LarderFilterCriteria,
  StayFilterCriteria,
} from '../../domain/ports/repository.ports';

export function matchesStayFilter(
  stay: StayAggregate,
  filter?: StayFilterCriteria,
): boolean {
  if (!filter) return true;
  if (filter.status && stay.status !== filter.status) return false;
  if (filter.villaId && stay.villaId !== filter.villaId) return false;
  if (filter.search) {
    const q = filter.search.toLowerCase();
    const target = `${stay.guestProfile.name} ${stay.villaName} ${stay.suiteName}`.toLowerCase();
    if (!target.includes(q)) return false;
  }
  return true;
}

export function matchesBookingFilter(
  b: ExperienceBooking,
  filter?: BookingFilterCriteria,
): boolean {
  if (!filter) return true;
  if (
    filter.category &&
    !b.bookingType.includes(filter.category.toUpperCase()) &&
    b.category !== filter.category.toUpperCase()
  ) {
    return false;
  }
  if (filter.bookingType && b.bookingType !== filter.bookingType) return false;
  if (filter.status && b.status !== filter.status) return false;
  if (filter.assignedDepartment && b.assignedDepartment !== filter.assignedDepartment) {
    return false;
  }
  if (filter.scheduledDate && b.scheduledDate !== filter.scheduledDate) return false;
  return true;
}

export function matchesLarderFilter(
  item: LarderOrderItem,
  filter?: LarderFilterCriteria,
): boolean {
  if (!filter) return true;
  if (
    filter.provisioningStatus &&
    item.provisioningStatus !== filter.provisioningStatus
  ) {
    return false;
  }
  if (filter.category && item.category !== filter.category) return false;
  if (filter.villaId && item.villaId !== filter.villaId) return false;
  return true;
}

export function matchesConciergeFilter(
  r: ConciergeRequest,
  filter?: ConciergeFilterCriteria,
): boolean {
  if (!filter) return true;
  if (filter.status && r.status !== filter.status) return false;
  if (filter.priority && r.priority !== filter.priority) return false;
  if (filter.assignedDepartment && r.assignedDepartment !== filter.assignedDepartment) {
    return false;
  }
  if (filter.category && r.category !== filter.category) return false;
  if (filter.villaId && r.villaId !== filter.villaId) return false;
  return true;
}

export function applyConciergeAdminUpdate(
  stays: Iterable<StayAggregate>,
  requestId: string,
  patch: Partial<ConciergeRequest>,
  newMessage?: ConciergeMessage,
): ConciergeRequest | null {
  for (const stay of stays) {
    const target = stay.conciergeRequests.find((r) => r.requestId === requestId);
    if (target) {
      Object.assign(target, patch, { updatedAt: new Date().toISOString() });
      if (newMessage) target.messages.push(structuredClone(newMessage));
      return structuredClone(target);
    }
  }
  return null;
}

export function applyLarderOrderStatusUpdate(
  stays: Iterable<StayAggregate>,
  orderItemId: string,
  patch: Partial<LarderOrderItem>,
): LarderOrderItem | null {
  const now = new Date().toISOString();
  for (const stay of stays) {
    const matchesStayOrder =
      stay.larderOrders.some((o) => o.orderItemId === orderItemId) ||
      stay.stayId === orderItemId ||
      orderItemId === `larder_${stay.stayId}`;
    if (matchesStayOrder && stay.larderOrders.length > 0) {
      for (const item of stay.larderOrders) {
        Object.assign(item, patch, { updatedAt: now });
      }
      return structuredClone(stay.larderOrders[0]);
    }
  }
  return null;
}

export function applyBookingAssignmentUpdate(
  stays: Iterable<StayAggregate>,
  bookingId: string,
  patch: Partial<ExperienceBooking>,
): ExperienceBooking | null {
  for (const stay of stays) {
    const target = stay.experienceBookings.find((b) => b.bookingId === bookingId);
    if (target) {
      Object.assign(target, patch);
      return structuredClone(target);
    }
  }
  return null;
}

export function findConciergeRequestAcrossStays(
  stays: Iterable<StayAggregate>,
  requestId: string,
): ConciergeRequest | null {
  for (const stay of stays) {
    const found = stay.conciergeRequests.find((r) => r.requestId === requestId);
    if (found) return structuredClone(found);
  }
  return null;
}

export function appendMessageToStayRequest(
  stay: StayAggregate,
  requestId: string,
  message: ConciergeMessage,
): ConciergeRequest | null {
  const req = stay.conciergeRequests.find((r) => r.requestId === requestId);
  if (!req) return null;
  req.messages.push(structuredClone(message));
  req.updatedAt = message.sentAt;
  return structuredClone(req);
}

export function applyFolioAndStatusUpdate(
  stay: StayAggregate,
  folioSummary: FolioSummary,
  folioItems: FolioItem[],
  newStatus?: StayLifecycleStatus,
  lateCheckoutRequested?: boolean,
): { folioSummary: FolioSummary; folioItems: FolioItem[]; status: StayLifecycleStatus } {
  stay.folioSummary = structuredClone(folioSummary);
  stay.folioItems = structuredClone(folioItems);
  if (newStatus) stay.status = newStatus;
  if (lateCheckoutRequested !== undefined) {
    stay.flightTransfer.lateCheckoutRequested = lateCheckoutRequested;
  }
  stay.updatedAt = new Date().toISOString();
  return {
    folioSummary: structuredClone(stay.folioSummary),
    folioItems: structuredClone(stay.folioItems),
    status: stay.status,
  };
}


