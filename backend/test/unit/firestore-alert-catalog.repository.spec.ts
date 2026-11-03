import { OperationalAlert } from '../../src/domain/models/domain.models';
import {
  createAlertRepository,
  createCatalogRepository,
  createStayRepository,
} from '../../src/infrastructure/firebase/repository.providers';
import { FirestoreAlertRepository } from '../../src/infrastructure/repositories/firestore-alert.repository';
import { FirestoreCatalogRepository } from '../../src/infrastructure/repositories/firestore-catalog.repository';
import { FirestoreStayRepository } from '../../src/infrastructure/repositories/firestore-stay.repository';
import { InMemorySeededAlertRepository } from '../../src/infrastructure/repositories/in-memory-alert.repository';
import { InMemorySeededCatalogRepository } from '../../src/infrastructure/repositories/in-memory-catalog.repository';
import { InMemorySeededStayRepository } from '../../src/infrastructure/repositories/in-memory-stay.repository';
import { FakeFirestore } from '../support/fake-firestore';

function alertFixture(alertId: string, createdAt: string): OperationalAlert {
  return {
    alertId, stayId: 'stay_a', villaId: 'villa-201', villaName: 'Villa 201', guestNames: 'Guest',
    category: 'CONCIERGE', severity: 'NORMAL', title: 'Title', summary: 'Summary',
    sourceDocumentPath: 'stays/stay_a', assignedDepartment: 'CONCIERGE', isAcknowledged: false,
    acknowledgedByStaffId: null, acknowledgedAt: null, createdAt,
  };
}

describe('Repository provider factory', () => {
  it('test_repositoryFactories_withFirestore_selectFirestoreAdapters', () => {
    const db = new FakeFirestore().asFirestore();

    expect(createStayRepository(db)).toBeInstanceOf(FirestoreStayRepository);
    expect(createAlertRepository(db)).toBeInstanceOf(FirestoreAlertRepository);
    expect(createCatalogRepository(db)).toBeInstanceOf(FirestoreCatalogRepository);
  });

  it('test_repositoryFactories_withoutFirestore_selectInMemoryAdapters', () => {
    expect(createStayRepository(null)).toBeInstanceOf(InMemorySeededStayRepository);
    expect(createAlertRepository(null)).toBeInstanceOf(InMemorySeededAlertRepository);
    expect(createCatalogRepository(null)).toBeInstanceOf(InMemorySeededCatalogRepository);
  });
});

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

    const acked = await instanceB.acknowledgeAlert('alt_old', 'staff_eduardo');
    const listed = await instanceA.listAlerts({ isAcknowledged: false });

    expect(acked?.acknowledgedByStaffId).toBe('staff_eduardo');
    expect(listed.alerts.map((a) => a.alertId)).toEqual(['alt_new']);
    expect(listed.unreadCount).toBe(1);
    expect((await instanceB.listAlerts()).alerts.map((a) => a.alertId)).toEqual(['alt_new', 'alt_old']);
  });

  it('test_firestoreAlertRepository_acknowledgeUnknownAlert_returnsNull', async () => {
    expect(await instanceA.acknowledgeAlert('missing', 'staff_eduardo')).toBeNull();
  });

  it('test_firestoreAlertRepository_writeFailure_surfacesAsError', async () => {
    fake.failWritesWith(new Error('UNAVAILABLE'));

    await expect(
      instanceA.createAlert(alertFixture('alt_x', '2026-11-13T10:00:00.000Z')),
    ).rejects.toThrow('UNAVAILABLE');
  });

  it('test_firestoreAlertRepository_resetAllAlerts_deletesFromStore', async () => {
    await instanceA.createAlert(alertFixture('alt_x', '2026-11-13T10:00:00.000Z'));

    await instanceB.resetAllAlerts();

    expect((await instanceA.listAlerts()).alerts).toEqual([]);
  });
});

describe('FirestoreCatalogRepository', () => {
  let fake: FakeFirestore;
  let instanceA: FirestoreCatalogRepository;
  let instanceB: FirestoreCatalogRepository;

  beforeEach(() => {
    fake = new FakeFirestore();
    instanceA = new FirestoreCatalogRepository(fake.asFirestore());
    instanceB = new FirestoreCatalogRepository(fake.asFirestore());
  });

  it('test_firestoreCatalogRepository_emptyStore_returnsEmptyCatalogsWithoutSeeding', async () => {
    expect(await instanceA.getLarderCatalog()).toEqual([]);
    expect(await instanceA.getExperiencesCatalog()).toEqual([]);
    expect(fake.collections.get('catalog_larder')?.size ?? 0).toBe(0);
  });

  it('test_firestoreCatalogRepository_itemsCreatedOnOneInstance_areReadAndDeletedByAnother', async () => {
    await instanceA.createLarderCatalogItem({ id: 'larder_x', name: 'Mezcal', price: 40 });
    await instanceA.createExperienceCatalogItem({ id: 'exp_x', title: 'Stargazing' });

    expect((await instanceB.getLarderCatalog()).map((i) => i.id)).toEqual(['larder_x']);
    expect((await instanceB.getExperiencesCatalog())[0].title).toBe('Stargazing');
    expect(await instanceB.deleteLarderCatalogItem('larder_x')).toEqual({ deleted: true, id: 'larder_x' });
    expect(await instanceA.deleteLarderCatalogItem('larder_x')).toEqual({ deleted: false, id: 'larder_x' });
    expect(await instanceA.deleteExperienceCatalogItem('exp_x')).toEqual({ deleted: true, id: 'exp_x' });
  });

  it('test_firestoreCatalogRepository_writeFailure_surfacesAsError', async () => {
    fake.failWritesWith(new Error('PERMISSION_DENIED'));

    await expect(instanceA.createLarderCatalogItem({ name: 'Mezcal' })).rejects.toThrow(
      'PERMISSION_DENIED',
    );
  });
});
