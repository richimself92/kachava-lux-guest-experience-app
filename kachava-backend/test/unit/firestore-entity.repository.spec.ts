import { FirestoreEntityRepository } from '../../src/infrastructure/repositories/firestore-entity.repository';
import { EntityNotFoundError, ListScanLimitError } from '../../src/domain/domain-errors';
import { FakeFirestore } from '../support/fake-firestore';

interface Thing {
  thingId: string;
  name: string;
  active: boolean;
}

function repoOver(fake: FakeFirestore, scanLimit = 10) {
  return new FirestoreEntityRepository<Thing>(fake.asFirestore(), 'things', 'thingId', 'Thing', scanLimit);
}

describe('FirestoreEntityRepository', () => {
  it('test_create_thenFindById_returnsStoredEntity', async () => {
    const repo = repoOver(new FakeFirestore());

    await repo.create({ thingId: 't1', name: 'One', active: true });

    expect(await repo.findById('t1')).toEqual({ thingId: 't1', name: 'One', active: true });
    expect(await repo.findById('missing')).toBeNull();
  });

  it('test_twoInstances_shareTheStore_noProcessCache', async () => {
    const fake = new FakeFirestore();
    await repoOver(fake).create({ thingId: 't1', name: 'One', active: true });

    expect(await repoOver(fake).list()).toHaveLength(1);
  });

  it('test_list_appliesEqualityFilters_ignoringUndefined', async () => {
    const repo = repoOver(new FakeFirestore());
    await repo.create({ thingId: 't1', name: 'One', active: true });
    await repo.create({ thingId: 't2', name: 'Two', active: false });

    const active = await repo.list({ active: true, name: undefined });

    expect(active.map((t) => t.thingId)).toEqual(['t1']);
  });

  it('test_list_aboveScanLimit_failsLoudly', async () => {
    const fake = new FakeFirestore();
    const repo = repoOver(fake, 2);
    for (const id of ['a', 'b', 'c']) await repo.create({ thingId: id, name: id, active: true });

    await expect(repo.list()).rejects.toBeInstanceOf(ListScanLimitError);
  });

  it('test_update_missing_throwsNotFound', async () => {
    await expect(repoOver(new FakeFirestore()).update('x', (t) => t)).rejects.toBeInstanceOf(EntityNotFoundError);
  });

  it('test_update_persistsMutation_andKeepsId', async () => {
    const repo = repoOver(new FakeFirestore());
    await repo.create({ thingId: 't1', name: 'One', active: true });

    const updated = await repo.update('t1', (t) => ({ ...t, thingId: 'hijack', name: 'Uno' }));

    expect(updated).toEqual({ thingId: 't1', name: 'Uno', active: true });
    expect(await repo.findById('t1')).toEqual(updated);
  });

  it('test_create_existingId_isRejected', async () => {
    const repo = repoOver(new FakeFirestore());
    await repo.create({ thingId: 't1', name: 'One', active: true });

    await expect(repo.create({ thingId: 't1', name: 'Dup', active: true })).rejects.toThrow();
  });

  it('test_writeFailure_propagates', async () => {
    const fake = new FakeFirestore();
    fake.failWritesWith(new Error('UNAVAILABLE'));

    await expect(repoOver(fake).create({ thingId: 't1', name: 'One', active: true })).rejects.toThrow('UNAVAILABLE');
  });

  it('test_delete_removesDocument', async () => {
    const repo = repoOver(new FakeFirestore());
    await repo.create({ thingId: 't1', name: 'One', active: true });

    await repo.delete('t1');

    expect(await repo.findById('t1')).toBeNull();
  });
});
