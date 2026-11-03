import {
  AlertCategory,
  AlertSeverity,
  AlertTargetRef,
  NotificationEvent,
  OperationalAlert,
  StayRecord,
} from '../models/domain.models';
import { Task } from '../tasks/task.models';
import { Trip } from '../trips/trip.models';

/**
 * Notifications (plan v2): stored operational alerts plus events computed on read (arrival day,
 * overdue task, unconfirmed trip). Levels map from alert severities; only URGENT plays a sound.
 */
export const NOTIFICATION_LEVELS = ['INFO', 'ACTION', 'URGENT'] as const;
export type NotificationLevel = (typeof NOTIFICATION_LEVELS)[number];

export type NotificationCategory = AlertCategory | 'ARRIVAL' | 'TASK';
export const NOTIFICATION_CATEGORIES: readonly NotificationCategory[] = [
  'CONCIERGE', 'BOOKING', 'LARDER', 'TRANSFER', 'MIDSTAY', 'CHECKOUT', 'DIETARY', 'RESERVATION', 'ARRIVAL', 'TASK',
];

export interface NotificationTarget extends AlertTargetRef {
  stayId: string | null;
}

export interface Notification {
  id: string;
  event: NotificationEvent;
  level: NotificationLevel;
  category: NotificationCategory;
  title: string;
  summary: string;
  stayId: string | null;
  villaId: string | null;
  villaName: string | null;
  guestName: string | null;
  createdAt: string;
  read: boolean;
  readAt: string | null;
  playSound: boolean;
  targetRef: NotificationTarget;
}

export interface NotificationFilter {
  level?: NotificationLevel;
  read?: boolean;
  category?: NotificationCategory;
  fromIso?: string;
  toIsoExclusive?: string;
}

const LEVEL_BY_SEVERITY: Record<AlertSeverity, NotificationLevel> = { NORMAL: 'INFO', HIGH: 'ACTION', URGENT: 'URGENT' };
const MS_PER_HOUR = 3_600_000;

export const COMPUTED_ID_PREFIXES = { arrival: 'arrival_', taskOverdue: 'task-overdue_', tripUnconfirmed: 'trip-unconfirmed_' };

export function levelOf(severity: AlertSeverity): NotificationLevel {
  return LEVEL_BY_SEVERITY[severity];
}

function eventOf(alert: OperationalAlert): NotificationEvent {
  if (alert.event) return alert.event;
  if (alert.category === 'TRANSFER') return 'ITINERARY_CHANGE';
  if (alert.category === 'RESERVATION') return 'NEW_RESERVATION';
  return 'GUEST_REQUEST';
}

/** `trips/{id}`, `stays/{id}/concierge_requests/{id}`, `stays/{id}/midstay_feedback/{id}` or `stays/{id}`. */
function targetFromPath(path: string, stayId: string): AlertTargetRef {
  const [root, rootId, child, childId] = path.split('/');
  if (root === 'trips' && rootId) return { type: 'TRIP', id: rootId };
  if (child === 'concierge_requests' && childId) return { type: 'REQUEST', id: childId };
  if (child === 'midstay_feedback' && childId) return { type: 'FEEDBACK', id: childId };
  return { type: 'STAY', id: rootId || stayId };
}

function build(fields: Omit<Notification, 'playSound' | 'read' | 'readAt'> & { readAt?: string | null }): Notification {
  const readAt = fields.readAt ?? null;
  return { ...fields, read: readAt !== null, readAt, playSound: fields.level === 'URGENT' };
}

export function notificationFromAlert(alert: OperationalAlert): Notification {
  const target = alert.targetRef ?? targetFromPath(alert.sourceDocumentPath ?? '', alert.stayId);
  const notification = build({
    id: alert.alertId,
    event: eventOf(alert),
    level: levelOf(alert.severity),
    category: alert.category,
    title: alert.title,
    summary: alert.summary,
    stayId: alert.stayId || null,
    villaId: alert.villaId || null,
    villaName: alert.villaName || null,
    guestName: alert.guestNames || null,
    createdAt: alert.createdAt,
    readAt: alert.acknowledgedAt,
    targetRef: { type: target.type, id: target.id, stayId: alert.stayId || null },
  });
  return { ...notification, read: alert.isAcknowledged };
}

/** The guest arrives today (`dayStartIso` = start of the resort day). */
export function arrivalNotification(stay: StayRecord, dayStartIso: string): Notification {
  return build({
    id: `${COMPUTED_ID_PREFIXES.arrival}${stay.stayId}_${stay.checkInDate}`,
    event: 'ARRIVAL_DAY',
    level: 'INFO',
    category: 'ARRIVAL',
    title: `${stay.villaName}: arrival today`,
    summary: stay.guestProfile?.name ?? '',
    stayId: stay.stayId,
    villaId: stay.villaId,
    villaName: stay.villaName,
    guestName: stay.guestProfile?.name ?? null,
    createdAt: dayStartIso,
    targetRef: { type: 'STAY', id: stay.stayId, stayId: stay.stayId },
  });
}

/** An open task past its deadline; urgent tasks are urgent notifications. */
export function taskOverdueNotification(task: Task): Notification {
  return build({
    id: `${COMPUTED_ID_PREFIXES.taskOverdue}${task.taskId}`,
    event: 'TASK_OVERDUE',
    level: task.priority === 'URGENT' ? 'URGENT' : 'ACTION',
    category: 'TASK',
    title: `Task overdue: ${task.title}`,
    summary: [task.villaName, task.guestName, task.ownerName].filter(Boolean).join(' · '),
    stayId: task.source.stayId,
    villaId: task.villaId,
    villaName: task.villaName,
    guestName: task.guestName,
    createdAt: task.dueAt ?? task.createdAt,
    targetRef: { type: 'TASK', id: task.taskId, stayId: task.source.stayId },
  });
}

/** A trip still unconfirmed within `leadHours` of its pickup (dated when it became due). */
export function tripUnconfirmedNotification(trip: Trip, leadHours: number): Notification {
  return build({
    id: `${COMPUTED_ID_PREFIXES.tripUnconfirmed}${trip.tripId}`,
    event: 'TRIP_UNCONFIRMED',
    level: 'URGENT',
    category: 'TRANSFER',
    title: `${trip.villaName}: ${trip.type} trip not confirmed`,
    summary: `${trip.guestName} · pickup ${trip.pickupAt}`,
    stayId: trip.stayId,
    villaId: trip.villaId,
    villaName: trip.villaName,
    guestName: trip.guestName,
    createdAt: new Date(Date.parse(trip.pickupAt) - leadHours * MS_PER_HOUR).toISOString(),
    targetRef: { type: 'TRIP', id: trip.tripId, stayId: trip.stayId },
  });
}

/** Applies read markers (id -> readAt) to computed notifications. */
export function withReadMarker(notification: Notification, readAt: string | undefined): Notification {
  return readAt ? { ...notification, read: true, readAt } : notification;
}

export function isComputedNotificationId(id: string): boolean {
  return Object.values(COMPUTED_ID_PREFIXES).some((prefix) => id.startsWith(prefix));
}

export function filterNotifications(list: readonly Notification[], filter: NotificationFilter): Notification[] {
  return list.filter(
    (n) =>
      (!filter.level || n.level === filter.level) &&
      (filter.read === undefined || n.read === filter.read) &&
      (!filter.category || n.category === filter.category) &&
      (!filter.fromIso || n.createdAt >= filter.fromIso) &&
      (!filter.toIsoExclusive || n.createdAt < filter.toIsoExclusive),
  );
}
