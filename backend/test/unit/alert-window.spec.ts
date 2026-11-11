import { OperationalAlert } from '../../src/domain/models/domain.models';
import { FirestoreAlertRepository } from '../../src/infrastructure/repositories/firestore-alert.repository';
import { FakeFirestore } from '../support/fake-firestore';

function alert(alertId: string, createdAt: string, isAcknowledged = false): OperationalAlert {
  return {
    alertId, stayId: 's1', villaId: 'v1', villaName: 'Villa', guestNames: 'Guest', category: 'CONCIERGE',
    severity: 'NORMAL', title: 't', summary: 's', sourceDocumentPath: 'stays/s1', assignedDepartment: null,
    isAcknowledged, acknowledgedByStaffId: null, acknowledgedAt: null, createdAt,
  };
}

describe('FirestoreAlertRepository windows and bulk acknowledgement', () => {
  let repo: FirestoreAlertRepository;

  beforeEach(async () => {
    repo = new FirestoreAlertRepository(new FakeFirestore().asFirestore());
    await repo.createAlert(alert('a1', '2026-11-20T10:00:00.000Z'));
    await repo.createAlert(alert('a2', '2026-11-21T10:00:00.000Z', true));
    await repo.createAlert(alert('a3', '2026-11-22T10:00:00.000Z'));
  });

  it('test_listRecent_isNewestFirst_windowedAndLimited', async () => {
    const ids = async (window: { fromIso?: string; toIsoExclusive?: string }, limit = 10) =>
      (await repo.listRecent(window, limit)).map((a) => a.alertId);

    expect(await ids({})).toEqual(['a3', 'a2', 'a1']);
    expect(await ids({}, 2)).toEqual(['a3', 'a2']);
    expect(await ids({ fromIso: '2026-11-21T00:00:00.000Z', toIsoExclusive: '2026-11-22T00:00:00.000Z' })).toEqual(['a2']);
  });

  it('test_acknowledgeMany_marksOnlyUnreadAlerts_withActorAndTime', async () => {
    const at = '2026-11-23T00:00:00.000Z';

    const changed = await repo.acknowledgeMany(['a1', 'a2', 'a3', 'missing'], 'staff-1', at);

    const all = await repo.listRecent({}, 10);
    expect(changed).toBe(2);
    expect(all.every((a) => a.isAcknowledged)).toBe(true);
    expect(all.find((a) => a.alertId === 'a1')).toMatchObject({ acknowledgedByStaffId: 'staff-1', acknowledgedAt: at });
    expect(all.find((a) => a.alertId === 'a2')?.acknowledgedAt).toBeNull();
  });
});
