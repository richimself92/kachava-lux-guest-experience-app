import { OperationalAlert } from './models/domain.models';

export function acknowledge(alert: OperationalAlert, staffId: string): OperationalAlert {
  alert.isAcknowledged = true;
  alert.acknowledgedByStaffId = staffId;
  alert.acknowledgedAt = new Date().toISOString();
  return structuredClone(alert);
}
