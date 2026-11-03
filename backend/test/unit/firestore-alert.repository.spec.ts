import { OperationalAlert } from '../../src/domain/models/domain.models';
import { FirestoreAlertRepository } from '../../src/infrastructure/repositories/firestore-alert.repository';
import { FakeFirestore } from '../support/fake-firestore';

function alertFixture(alertId: string, createdAt: string): OperationalAlert {
  return {
    alertId, stayId: 'stay_a', villaId: 'villa-a', villaName: 'Test Villa', guestNames: 'Guest',
    category: 'CONCIERGE', severity: 'NORMAL', title: 'Title', summary: 'Summary',
    sourceDocumentPath: 'stays/stay_a', assignedDepartment: 'CONCIERGE', isAcknowledged: false,
    acknowledgedByStaffId: null, acknowledgedAt: null, createdAt,
  };
}

describe('FirestoreAlertRepository', () => {
  let fake: FakeFirestore;
  let instanceA: FirestoreAlertRepository;
  let instanceB: FirestoreAlertRepository;

  beforeEach(() => {
    fake = new FakeFirestore();
    instanceA = new FirestoreAlertRepository(fake.asFirestore());
    instanceB = new FirestoreAlertRepository(fake.asFirestore());
  });

  it('test_firestoreAlertRepository_newInstance_doesNotSeedDemoAlerts', async () => {
    expect(await instanceA.listAlerts()).toEqual({ alerts: [], unreadCount: 0 });
  });

  it('test_firestoreAlertRepository_alertCreatedOnOneInstance_isListedNewestFirstByAnother', async () => {
    await instanceA.createAlert(alertFixture('alt_old', '2026-11-12T10:00:00.000Z'));
    await instanceA.createAlert(alertFixture('alt_new', '2026-11-13T10:00:00.000Z'));

    const acked = await instanceB.acknowledgeAlert('alt_old', 'staff-test');
    const listed = await instanceA.listAlerts({ isAcknowledged: false });

    expect(acked?.acknowledgedByStaffId).toBe('staff-test');
    expect(listed.alerts.map((a) => a.alertId)).toEqual(['alt_new']);
    expect(listed.unreadCount).toBe(1);
    expect((await instanceB.listAlerts()).alerts.map((a) => a.alertId)).toEqual(['alt_new', 'alt_old']);
  });

  it('test_firestoreAlertRepository_acknowledgeUnknownAlert_returnsNull', async () => {
    expect(await instanceA.acknowledgeAlert('missing', 'staff-test')).toBeNull();
  });

  it('test_firestoreAlertRepository_writeFailure_surfacesAsError', async () => {
    fake.failWritesWith(new Error('UNAVAILABLE'));

    await expect(
      instanceA.createAlert(alertFixture('alt_x', '2026-11-13T10:00:00.000Z')),
    ).rejects.toThrow('UNAVAILABLE');
  });
});
