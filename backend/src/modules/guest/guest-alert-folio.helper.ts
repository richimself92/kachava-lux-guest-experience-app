import { Inject, Injectable } from '@nestjs/common';
import * as crypto from 'crypto';
import {
  AlertCategory,
  AlertSeverity,
  Department,
  FolioItem,
  FolioSummary,
  StayAggregate,
} from '../../domain/models/domain.models';
import {
  ALERT_REPOSITORY_PORT,
  AlertRepositoryPort,
} from '../../domain/ports/repository.ports';

@Injectable()
export class GuestAlertFolioHelper {
  constructor(
    @Inject(ALERT_REPOSITORY_PORT)
    private readonly alertRepo: AlertRepositoryPort,
  ) {}

  recalculateFolioSummary(
    current: FolioSummary,
    items: FolioItem[],
  ): FolioSummary {
    const complimentarySavingsUSD = items
      .filter((i) => i.isComplimentary)
      .reduce((sum, i) => sum + (i.originalValuationUSD || 0), 0);
    const incidentalsSubtotalUSD = items
      .filter((i) => !i.isComplimentary && i.category !== 'ECOLOGICAL_LEVY')
      .reduce((sum, i) => sum + i.chargedAmountUSD, 0);
    const ecologicalLevyUSD = items
      .filter((i) => i.category === 'ECOLOGICAL_LEVY')
      .reduce((sum, i) => sum + i.chargedAmountUSD, 0);

    return {
      ...current,
      complimentarySavingsUSD,
      incidentalsSubtotalUSD,
      ecologicalLevyUSD,
      finalSettledTotalUSD: incidentalsSubtotalUSD + ecologicalLevyUSD,
    };
  }

  async emitAlert(
    stay: StayAggregate,
    params: {
      category: AlertCategory;
      severity: AlertSeverity;
      title: string;
      summary: string;
      sourceDocumentPath: string;
      assignedDepartment: Department;
    },
  ): Promise<void> {
    await this.alertRepo.createAlert({
      alertId: `alt_${crypto.randomBytes(4).toString('hex')}`,
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
    });
  }
}
