import { Inject, Injectable } from '@nestjs/common';
import { AlertListing } from '../../domain/alert-projections';
import {
  ConciergeRequest,
  ExperienceBooking,
  LarderOrderItem,
  MidStayFeedback,
  StayAggregate,
} from '../../domain/models/domain.models';
import {
  ALERT_REPOSITORY_PORT,
  AlertRepositoryPort,
  STAY_REPOSITORY_PORT,
  StayRepositoryPort,
} from '../../domain/ports/repository.ports';
import {
  collectBookings,
  collectConciergeRequests,
  collectLarderOrders,
  collectMidStayFeedback,
} from '../../domain/stay-projections';

/** Upper bound of open stays (pre-arrival + in-house) one sync payload carries. */
export const SYNC_STAY_LIMIT = 200;

/** Keys consumed by the admin dashboard polling loop. */
export interface AdminSyncSnapshot {
  stays: StayAggregate[];
  alerts: AlertListing;
  bookings: ExperienceBooking[];
  larderOrders: LarderOrderItem[];
  conciergeRequests: ConciergeRequest[];
  midstayFeedback: MidStayFeedback[];
}

/**
 * Bounded admin polling payload: at most SYNC_STAY_LIMIT open stays (ordered by arrival) and the
 * newest alerts; cross-stay lists are derived from those stays only. Catalog data is not part
 * of the sync: it is read through `/admin/services`.
 */
@Injectable()
export class AdminSyncService {
  constructor(
    @Inject(STAY_REPOSITORY_PORT) private readonly stayRepo: StayRepositoryPort,
    @Inject(ALERT_REPOSITORY_PORT) private readonly alertRepo: AlertRepositoryPort,
  ) {}

  async snapshot(): Promise<AdminSyncSnapshot> {
    const [stays, alerts] = await Promise.all([
      this.stayRepo.listOpenStays(SYNC_STAY_LIMIT),
      this.alertRepo.listAlerts(),
    ]);
    return {
      stays,
      alerts,
      bookings: collectBookings(stays),
      larderOrders: collectLarderOrders(stays),
      conciergeRequests: collectConciergeRequests(stays),
      midstayFeedback: collectMidStayFeedback(stays),
    };
  }
}
