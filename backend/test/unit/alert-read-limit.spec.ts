import { ALERT_READ_LIMIT } from '../../src/domain/alert-projections';
import { OperationalAlert } from '../../src/domain/models/domain.models';
import { AlertRepositoryPort } from '../../src/domain/ports/repository.ports';
import { FirestoreAlertRepository } from '../../src/infrastructure/repositories/firestore-alert.repository';
import { InMemorySeededAlertRepository } from '../../src/infrastructure/repositories/in-memory-alert.repository';
import { InMemorySeededCatalogRepository } from '../../src/infrastructure/repositories/in-memory-catalog.repository';
import { InMemorySeededStayRepository } from '../../src/infrastructure/repositories/in-memory-stay.repository';
import { AdminSyncService } from '../../src/modules/admin/admin-sync.service';
import { FakeFirestore } from '../support/fake-firestore';

const TOTAL = 250;

function alertAt(index: number): OperationalAlert {
  return {
    alertId: `alt_${String(index).padStart(4, '0')}`,
    stayId: 'stay_a', villaId: 'villa-102', villaName: 'Villa 102', guestNames: 'Guest',
    category: 'CONCIERGE', severity: 'NORMAL', title: `Alert ${index}`, summary: '',
    sourceDocumentPath: 'stays/stay_a', assignedDepartment: 'CONCIERGE', isAcknowledged: false,
    acknowledgedByStaffId: null, acknowledgedAt: null,
    createdAt: new Date(Date.UTC(2027, 0, 1, 0, 0, index)).toISOString(),
  };
}

async function fill(repo: AlertRepositoryPort): Promise<void> {
  for (let i = 0; i < TOTAL; i += 1) await repo.createAlert(alertAt(i));
}

describe('Alert reads are bounded to the newest ALERT_READ_LIMIT (ADV-07)', () => {
  it.each([
    ['firestore', () => new FirestoreAlertRepository(new FakeFirestore().asFirestore())],
    ['in-memory', () => new InMemorySeededAlertRepository()],
  ])('test_listAlerts_%s_returnsOnlyNewestAlerts', async (_name, build) => {
    const repo = build();
    await fill(repo);

    const { alerts } = await repo.listAlerts();

    expect(ALERT_READ_LIMIT).toBe(200);
    expect(alerts).toHaveLength(ALERT_READ_LIMIT);
    expect(alerts[0].alertId).toBe(`alt_0${TOTAL - 1}`);
  });

  it('test_adminSyncSnapshot_alertsAreBounded', async () => {
    const alerts = new InMemorySeededAlertRepository();
    await fill(alerts);
    const sync = new AdminSyncService(new InMemorySeededStayRepository(alerts), alerts, new InMemorySeededCatalogRepository());

    const snapshot = await sync.snapshot();

    expect(snapshot.alerts.alerts.length).toBeLessThanOrEqual(ALERT_READ_LIMIT);
  });
});
