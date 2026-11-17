import { AuditTrail } from '../catalog/catalog.models';

/** Configuration entities created from the admin. Nothing here has a value preloaded in code. */
export const VILLA_OPERATIONAL_STATUSES = ['AVAILABLE', 'OCCUPIED', 'CLEANING', 'MAINTENANCE', 'BLOCKED'] as const;
export const VILLA_HOUSEKEEPING_STATUSES = ['CLEAN', 'DIRTY', 'IN_PROGRESS'] as const;
export const VILLA_MAINTENANCE_STATUSES = ['OK', 'ISSUE_REPORTED', 'IN_MAINTENANCE'] as const;

export type VillaOperationalStatus = (typeof VILLA_OPERATIONAL_STATUSES)[number];
export type VillaHousekeepingStatus = (typeof VILLA_HOUSEKEEPING_STATUSES)[number];
export type VillaMaintenanceStatus = (typeof VILLA_MAINTENANCE_STATUSES)[number];

export interface Villa extends AuditTrail {
  villaId: string;
  name: string;
  category: string;
  /** Maximum number of guests. */
  capacity: number;
  wifi: { ssid: string; password: string };
  operationalStatus: VillaOperationalStatus;
  housekeepingStatus: VillaHousekeepingStatus;
  maintenanceStatus: VillaMaintenanceStatus;
  maintenanceNote: string;
  isActive: boolean;
}

export interface TransportProvider extends AuditTrail {
  providerId: string;
  name: string;
  phone: string;
  email: string;
  isActive: boolean;
}

export interface AirportSetting {
  code: string;
  name: string;
  departureBufferHours: number;
  isActive: boolean;
}

/** Resort settings. A null/empty value means "not configured yet"; there are no code defaults. */
export interface ResortSettings {
  checkInTime: string | null;
  checkOutTime: string | null;
  timeZone: string | null;
  airports: AirportSetting[];
  transportAlertLeadHours: number | null;
  updatedAt: string | null;
  updatedBy: string | null;
}

export function unconfiguredSettings(): ResortSettings {
  return {
    checkInTime: null,
    checkOutTime: null,
    timeZone: null,
    airports: [],
    transportAlertLeadHours: null,
    updatedAt: null,
    updatedBy: null,
  };
}
