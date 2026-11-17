import { Inject, Injectable } from '@nestjs/common';
import { paginateInMemory, PaginatedResult, toListQuery } from '../../common/listing/list-query';
import { EntityNotFoundError } from '../../domain/domain-errors';
import { StaffMember } from '../../domain/models/domain.models';
import { ResortSettings } from '../../domain/models/resort-config.models';
import {
  arrivalNotification,
  filterNotifications,
  isComputedNotificationId,
  Notification,
  notificationFromAlert,
  taskOverdueNotification,
  tripUnconfirmedNotification,
  withReadMarker,
} from '../../domain/notifications/notification-rules';
import { CLOCK_PORT, ClockPort } from '../../domain/ports/clock.port';
import {
  ALERT_REPOSITORY_PORT,
  AlertRepositoryPort,
  NOTIFICATION_READ_REPOSITORY_PORT,
  NotificationReadRepositoryPort,
  SETTINGS_REPOSITORY_PORT,
  SettingsRepositoryPort,
  STAY_REPOSITORY_PORT,
  StayRepositoryPort,
  TASK_REPOSITORY_PORT,
  TaskRepositoryPort,
  TRIP_REPOSITORY_PORT,
  TripRepositoryPort,
} from '../../domain/ports/repository.ports';
import { isOpenStay } from '../../domain/stays/open-requests';
import { InstantWindow, resortDate, zonedDayWindow, zonedLocalToUtc } from '../../domain/time/zoned-time';
import { unconfirmedDueCutoff } from '../../domain/trips/trip-rules';
import { NotificationListQueryDto } from './notification.dto';

/** Newest stored alerts one notifications read covers (clients send `from`/`to` for history). */
export const NOTIFICATION_ALERT_SCAN = 500;

export const NOTIFICATION_LIST_SPEC = {
  sortable: ['createdAt'],
  defaultSort: { field: 'createdAt', direction: 'desc' as const },
};

export interface UnreadCount {
  unreadCount: number;
  urgentUnreadCount: number;
}

/**
 * Notifications = stored operational alerts (new reservation, guest request, itinerary change,
 * guest message...) + events computed on read: arrival today, overdue task and trip unconfirmed
 * within the Settings lead time. Computed events whose settings are missing are not produced.
 */
@Injectable()
export class NotificationsService {
  constructor(
    @Inject(ALERT_REPOSITORY_PORT) private readonly alerts: AlertRepositoryPort,
    @Inject(NOTIFICATION_READ_REPOSITORY_PORT) private readonly reads: NotificationReadRepositoryPort,
    @Inject(STAY_REPOSITORY_PORT) private readonly stays: StayRepositoryPort,
    @Inject(TASK_REPOSITORY_PORT) private readonly tasks: TaskRepositoryPort,
    @Inject(TRIP_REPOSITORY_PORT) private readonly trips: TripRepositoryPort,
    @Inject(SETTINGS_REPOSITORY_PORT) private readonly settings: SettingsRepositoryPort,
    @Inject(CLOCK_PORT) private readonly clock: ClockPort,
  ) {}

  async list(dto: NotificationListQueryDto): Promise<PaginatedResult<Notification>> {
    const query = toListQuery(dto, NOTIFICATION_LIST_SPEC);
    const settings = await this.settings.get();
    const window = zonedDayWindow({ from: dto.from, to: dto.to }, settings.timeZone);
    const all = filterNotifications(await this.collect(settings, window), window);
    const matching = filterNotifications(all, { level: dto.level, read: dto.read, category: dto.category });
    const page = paginateInMemory(matching, query, {
      searchText: (n) => `${n.title} ${n.summary} ${n.villaName ?? ''} ${n.guestName ?? ''}`,
      sortValue: (n) => n.createdAt,
    });
    return new PaginatedResult(page.data, page.meta, { unreadCount: all.filter((n) => !n.read).length });
  }

  async unreadCount(): Promise<UnreadCount> {
    const unread = (await this.collect(await this.settings.get(), {})).filter((n) => !n.read);
    return { unreadCount: unread.length, urgentUnreadCount: unread.filter((n) => n.level === 'URGENT').length };
  }

  async markRead(id: string, staff: StaffMember): Promise<Notification> {
    const at = this.clock.now().toISOString();
    if (!isComputedNotificationId(id)) {
      const updated = await this.alerts.acknowledgeAlert(id, staff.staffId);
      if (!updated) throw new EntityNotFoundError('Notification', id);
      return notificationFromAlert(updated);
    }
    const current = (await this.computed(await this.settings.get())).find((n) => n.id === id);
    if (!current) throw new EntityNotFoundError('Notification', id);
    await this.reads.markRead([id], staff.staffId, at);
    return withReadMarker(current, at);
  }

  /** Marks every unread notification the bell currently counts. */
  async markAllRead(staff: StaffMember): Promise<{ marked: number }> {
    const at = this.clock.now().toISOString();
    const unread = (await this.collect(await this.settings.get(), {})).filter((n) => !n.read);
    const computedIds = unread.filter((n) => isComputedNotificationId(n.id)).map((n) => n.id);
    const storedIds = unread.filter((n) => !isComputedNotificationId(n.id)).map((n) => n.id);
    const [acknowledged] = await Promise.all([
      this.alerts.acknowledgeMany(storedIds, staff.staffId, at),
      this.reads.markRead(computedIds, staff.staffId, at),
    ]);
    return { marked: acknowledged + computedIds.length };
  }

  private async collect(settings: ResortSettings, window: InstantWindow): Promise<Notification[]> {
    const [stored, computed] = await Promise.all([
      this.alerts.listRecent(window, NOTIFICATION_ALERT_SCAN),
      this.computed(settings),
    ]);
    return [...stored.map(notificationFromAlert), ...computed];
  }

  private async computed(settings: ResortSettings): Promise<Notification[]> {
    const now = this.clock.now();
    const [arrivals, overdue, unconfirmed] = await Promise.all([
      this.arrivalsToday(settings, now),
      this.tasks.listOverdue(now.toISOString()).then((tasks) => tasks.map(taskOverdueNotification)),
      this.unconfirmedTrips(settings, now),
    ]);
    const computed = [...arrivals, ...overdue, ...unconfirmed];
    const readAt = await this.reads.readAtOf(computed.map((n) => n.id));
    return computed.map((n) => withReadMarker(n, readAt.get(n.id)));
  }

  private async arrivalsToday(settings: ResortSettings, now: Date): Promise<Notification[]> {
    if (!settings.timeZone) return [];
    const today = resortDate(now, settings.timeZone);
    const dayStart = zonedLocalToUtc(`${today}T00:00`, settings.timeZone).toISOString();
    const stays = await this.stays.listStaysCheckingInOn(today);
    return stays.filter(isOpenStay).map((stay) => arrivalNotification(stay, dayStart));
  }

  private async unconfirmedTrips(settings: ResortSettings, now: Date): Promise<Notification[]> {
    const lead = settings.transportAlertLeadHours;
    if (lead === null || lead === undefined) return [];
    const trips = await this.trips.listUnconfirmedUntil(unconfirmedDueCutoff(now, lead));
    return trips.map((trip) => tripUnconfirmedNotification(trip, lead));
  }
}
