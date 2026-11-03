import { OperationalAlert } from './models/domain.models';
import { AlertFilterCriteria } from './ports/repository.ports';

/**
 * Alert reads (including `/admin/sync`) return at most the newest 200 alerts, so the payload and
 * the read cost stay bounded as the collection grows; `unreadCount` counts within that window.
 */
export const ALERT_READ_LIMIT = 200;

export interface AlertListing {
  alerts: OperationalAlert[];
  unreadCount: number;
}

function matchesAlertFilter(alert: OperationalAlert, filter?: AlertFilterCriteria): boolean {
  if (filter?.isAcknowledged !== undefined && alert.isAcknowledged !== filter.isAcknowledged) {
    return false;
  }
  if (filter?.category && alert.category !== filter.category) return false;
  if (filter?.severity && alert.severity !== filter.severity) return false;
  if (filter?.assignedDepartment && alert.assignedDepartment !== filter.assignedDepartment) {
    return false;
  }
  return true;
}

/** Filters newest-first alerts; `unreadCount` always counts every unacknowledged alert. */
export function summarizeAlerts(
  newestFirst: OperationalAlert[],
  filter?: AlertFilterCriteria,
): AlertListing {
  return {
    alerts: structuredClone(newestFirst.filter((a) => matchesAlertFilter(a, filter))),
    unreadCount: newestFirst.filter((a) => !a.isAcknowledged).length,
  };
}

/** The newest `ALERT_READ_LIMIT` alerts, newest first. */
export function newestAlerts(alerts: OperationalAlert[]): OperationalAlert[] {
  return [...alerts]
    .sort((a, b) => b.createdAt.localeCompare(a.createdAt))
    .slice(0, ALERT_READ_LIMIT);
}

export function acknowledge(alert: OperationalAlert, staffId: string): OperationalAlert {
  alert.isAcknowledged = true;
  alert.acknowledgedByStaffId = staffId;
  alert.acknowledgedAt = new Date().toISOString();
  return structuredClone(alert);
}
