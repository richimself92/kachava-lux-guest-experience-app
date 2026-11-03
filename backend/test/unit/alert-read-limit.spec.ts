import { ALERT_READ_LIMIT } from '../../src/domain/alert-projections';
import { OperationalAlert } from '../../src/domain/models/domain.models';
import { AlertRepositoryPort } from '../../src/domain/ports/repository.ports';
import { FirestoreAlertRepository } from '../../src/infrastructure/repositories/firestore-alert.repository';
import { FirestoreStayRepository } from '../../src/infrastructure/repositories/firestore-stay.repository';
import { AdminSyncService, SYNC_STAY_LIMIT } from '../../src/modules/admin/admin-sync.service';
import { FakeFirestore } from '../support/fake-firestore';
import { stayFixture } from '../support/stay-fixtures';

const TOTAL = 250;

function alertAt(index: number): OperationalAlert {
  return {
    alertId: `alt_${String(index).padStart(4, '0')}`,
    stayId: 'stay_a', villaId: 'villa-a', villaName: 'Test Villa', guestNames: 'Guest',
    category: 'CONCIERGE', severity: 'NORMAL', title: `Alert ${index}`, summary: '',
    sourceDocumentPath: 'stays/stay_a', assignedDepartment: 'CONCIERGE', isAcknowledged: false,
    acknowledgedByStaffId: null, acknowledgedAt: null,
    createdAt: new Date(Date.UTC(2027, 0, 1, 0, 0, index)).toISOString(),
  };
}

async function fill(repo: AlertRepositoryPort): Promise<void> {
  for (let i = 0; i < TOTAL; i += 1) await repo.createAlert(alertAt(i));
}

describe('Admin reads are bounded (ADV-07)', () => {
  it('test_listAlerts_returnsOnlyNewestAlerts', async () => {
    const repo = new FirestoreAlertRepository(new FakeFirestore().asFirestore());
    await fill(repo);

    const { alerts } = await repo.listAlerts();

    expect(ALERT_READ_LIMIT).toBe(200);
    expect(alerts).toHaveLength(ALERT_READ_LIMIT);
    expect(alerts[0].alertId).toBe(`alt_0${TOTAL - 1}`);
  });

  it('test_adminSyncSnapshot_alertsAndStaysAreBounded_closedStaysExcluded', async () => {
    const fake = new FakeFirestore();
    const alerts = new FirestoreAlertRepository(fake.asFirestore());
    const stays = new FirestoreStayRepository(fake.asFirestore());
    await fill(alerts);
    await stays.createStay(stayFixture({ stayId: 'open', status: 'PRE_ARRIVAL' }));
    await stays.createStay(stayFixture({ stayId: 'closed', status: 'CHECKED_OUT', guestTokenUuid: '22222222-2222-4222-8222-222222222222' }));
    const sync = new AdminSyncService(stays, alerts);

    const snapshot = await sync.snapshot();

    expect(SYNC_STAY_LIMIT).toBe(200);
    expect(snapshot.alerts.alerts.length).toBeLessThanOrEqual(ALERT_READ_LIMIT);
    expect(snapshot.stays.map((s) => s.stayId)).toEqual(['open']);
    expect(Object.keys(snapshot).sort()).toEqual(
      ['alerts', 'bookings', 'conciergeRequests', 'larderOrders', 'midstayFeedback', 'stays'],
    );
  });
});
