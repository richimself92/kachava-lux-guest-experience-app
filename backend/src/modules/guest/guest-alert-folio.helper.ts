import { Injectable } from '@nestjs/common';
import * as crypto from 'crypto';
import {
  AlertCategory,
  AlertSeverity,
  Department,
  OperationalAlert,
  StayAggregate,
} from '../../domain/models/domain.models';

export interface GuestAlertParams {
  category: AlertCategory;
  severity: AlertSeverity;
  title: string;
  summary: string;
  sourceDocumentPath: string;
  assignedDepartment: Department;
}

/**
 * Builds the operational alert that accompanies a guest mutation. It does not persist anything:
 * the stay repository commits the alert in the same transaction as the stay change (ADV-09).
 * Folio arithmetic lives in `domain/folio-ledger.ts`.
 */
@Injectable()
export class GuestAlertFolioHelper {
  buildAlert(stay: StayAggregate, params: GuestAlertParams): OperationalAlert {
    return {
      alertId: `alt_${crypto.randomUUID()}`,
      stayId: stay.stayId,
      villaId: stay.villaId,
      villaName: stay.villaName,
      guestNames: stay.guestProfile.name,
      category: params.category,
      severity: params.severity,
      title: params.title,
      summary: params.summary,
      sourceDocumentPath: params.sourceDocumentPath,
      assignedDepartment: params.assignedDepartment,
      isAcknowledged: false,
      acknowledgedByStaffId: null,
      acknowledgedAt: null,
      createdAt: new Date().toISOString(),
    };
  }
}
