import { Inject, Injectable } from '@nestjs/common';
import { AlertListing } from '../../domain/alert-projections';
import {
  ConciergeRequest,
  ExperienceBooking,
  ExperienceCatalogItem,
  LarderCatalogItem,
  LarderOrderItem,
  MidStayFeedback,
  StayAggregate,
} from '../../domain/models/domain.models';
import {
  ALERT_REPOSITORY_PORT,
  AlertRepositoryPort,
  CATALOG_REPOSITORY_PORT,
  CatalogRepositoryPort,
  STAY_REPOSITORY_PORT,
  StayRepositoryPort,
} from '../../domain/ports/repository.ports';
import {
  collectBookings,
  collectConciergeRequests,
  collectLarderOrders,
  collectMidStayFeedback,
} from '../../domain/stay-projections';

/** Keys consumed by the admin dashboard; each mirrors the matching admin GET with default filters. */
export interface AdminSyncSnapshot {
  stays: StayAggregate[];
  alerts: AlertListing;
  bookings: ExperienceBooking[];
  larderOrders: LarderOrderItem[];
  conciergeRequests: ConciergeRequest[];
  midstayFeedback: MidStayFeedback[];
  experiences: ExperienceCatalogItem[];
  larder: LarderCatalogItem[];
}

/**
 * Builds the admin polling payload from a single read of the stays collection; cross-stay
 * lists are derived with the same projections the per-resource endpoints use.
 */
@Injectable()
export class AdminSyncService {
  constructor(
    @Inject(STAY_REPOSITORY_PORT) private readonly stayRepo: StayRepositoryPort,
    @Inject(ALERT_REPOSITORY_PORT) private readonly alertRepo: AlertRepositoryPort,
    @Inject(CATALOG_REPOSITORY_PORT) private readonly catalogRepo: CatalogRepositoryPort,
  ) {}

  async snapshot(): Promise<AdminSyncSnapshot> {
    const [stays, alerts, experiences, larder] = await Promise.all([
      this.stayRepo.listStays(),
      this.alertRepo.listAlerts(),
      this.catalogRepo.getExperiencesCatalog(),
      this.catalogRepo.getLarderCatalog(),
    ]);
    return {
      stays,
      alerts,
      bookings: collectBookings(stays),
      larderOrders: collectLarderOrders(stays),
      conciergeRequests: collectConciergeRequests(stays),
      midstayFeedback: collectMidStayFeedback(stays),
      experiences,
      larder,
    };
  }
}
