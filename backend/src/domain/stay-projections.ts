import {
  ConciergeRequest,
  ExperienceBooking,
  LarderOrderItem,
  MidStayFeedback,
  StayAggregate,
} from './models/domain.models';
import {
  BookingFilterCriteria,
  ConciergeFilterCriteria,
  LarderFilterCriteria,
} from './ports/repository.ports';

/**
 * Pure read projections over stay aggregates. Every repository adapter and the admin sync
 * snapshot derive their cross-stay listings from these functions, so the same input always
 * produces the same output regardless of the storage backend.
 */
export function matchesBookingFilter(b: ExperienceBooking, filter?: BookingFilterCriteria): boolean {
  if (!filter) return true;
  if (filter.section && b.section !== filter.section) return false;
  if (filter.usageType && b.usageType !== filter.usageType) return false;
  if (filter.status && b.status !== filter.status) return false;
  if (filter.assignedDepartment && b.assignedDepartment !== filter.assignedDepartment) {
    return false;
  }
  if (filter.scheduledDate && b.scheduledDate !== filter.scheduledDate) return false;
  return true;
}

export function matchesLarderFilter(item: LarderOrderItem, filter?: LarderFilterCriteria): boolean {
  if (!filter) return true;
  if (filter.provisioningStatus && item.provisioningStatus !== filter.provisioningStatus) {
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

export function collectLarderOrders(
  stays: StayAggregate[],
  filter?: LarderFilterCriteria,
): LarderOrderItem[] {
  return structuredClone(
    stays.flatMap((s) => s.larderOrders).filter((item) => matchesLarderFilter(item, filter)),
  );
}

export function collectBookings(
  stays: StayAggregate[],
  filter?: BookingFilterCriteria,
): ExperienceBooking[] {
  return structuredClone(
    stays.flatMap((s) => s.experienceBookings).filter((b) => matchesBookingFilter(b, filter)),
  );
}

export function collectConciergeRequests(
  stays: StayAggregate[],
  filter?: ConciergeFilterCriteria,
): ConciergeRequest[] {
  return structuredClone(
    stays.flatMap((s) => s.conciergeRequests).filter((r) => matchesConciergeFilter(r, filter)),
  );
}

export function collectMidStayFeedback(stays: StayAggregate[]): MidStayFeedback[] {
  return structuredClone(stays.flatMap((s) => s.midstayFeedback));
}
