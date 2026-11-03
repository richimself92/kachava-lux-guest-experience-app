import { Inject, Injectable } from '@nestjs/common';
import {
  buildActivity,
  computeDashboardKpis,
  DashboardActivity,
  DashboardKpis,
} from '../../domain/dashboard/dashboard-rules';
import { CLOCK_PORT, ClockPort } from '../../domain/ports/clock.port';
import {
  SETTINGS_REPOSITORY_PORT,
  SettingsRepositoryPort,
  STAY_REPOSITORY_PORT,
  StayRepositoryPort,
  TASK_REPOSITORY_PORT,
  TaskRepositoryPort,
  TRIP_REPOSITORY_PORT,
  TripRepositoryPort,
  VILLA_REPOSITORY_PORT,
  VillaRepositoryPort,
} from '../../domain/ports/repository.ports';
import { OPEN_STAY_STATUSES } from '../../domain/stays/open-requests';
import { OPEN_TASK_STATUSES } from '../../domain/tasks/task.models';
import { resortDate } from '../../domain/time/zoned-time';
import { isFinalTripStatus, TRIP_STATUSES } from '../../domain/trips/trip.models';

/** "Today's activity" shows at most this many rows; `total` feeds "View all". */
export const DASHBOARD_ACTIVITY_ROWS = 8;
const OPEN_TRIP_STATUSES = TRIP_STATUSES.filter((status) => !isFinalTripStatus(status));

export interface DashboardView {
  /** Today at the resort (Settings time zone), YYYY-MM-DD. */
  resortDate: string;
  kpis: DashboardKpis;
  activity: DashboardActivity;
}

/**
 * Real-data dashboard: one bounded query of open stays, the active villas and two aggregate
 * counts (open trips, open tasks). A missing Settings time zone is SETTINGS_REQUIRED (422).
 */
@Injectable()
export class DashboardService {
  constructor(
    @Inject(SETTINGS_REPOSITORY_PORT) private readonly settings: SettingsRepositoryPort,
    @Inject(VILLA_REPOSITORY_PORT) private readonly villas: VillaRepositoryPort,
    @Inject(STAY_REPOSITORY_PORT) private readonly stays: StayRepositoryPort,
    @Inject(TRIP_REPOSITORY_PORT) private readonly trips: TripRepositoryPort,
    @Inject(TASK_REPOSITORY_PORT) private readonly tasks: TaskRepositoryPort,
    @Inject(CLOCK_PORT) private readonly clock: ClockPort,
  ) {}

  async get(): Promise<DashboardView> {
    const { timeZone } = await this.settings.get();
    const today = resortDate(this.clock.now(), timeZone);
    const [villas, stays, openTrips, openTasks] = await Promise.all([
      this.villas.list({ isActive: true }),
      this.stays.listStaysByStatuses(OPEN_STAY_STATUSES),
      this.trips.countByStatuses(OPEN_TRIP_STATUSES),
      this.tasks.countByStatuses(OPEN_TASK_STATUSES),
    ]);
    return {
      resortDate: today,
      kpis: computeDashboardKpis({ villas, stays, today, openTrips, openTasks }),
      activity: buildActivity(stays, today, DASHBOARD_ACTIVITY_ROWS),
    };
  }
}
