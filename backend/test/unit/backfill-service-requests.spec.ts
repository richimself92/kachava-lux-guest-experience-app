import { SERVICE_REQUESTS_COLLECTION } from '../../src/infrastructure/repositories/firestore-service-request.repository';
import { STAYS_COLLECTION } from '../../src/infrastructure/repositories/firestore-stay.repository';
import { backfillServiceRequests } from '../../src/scripts/backfill-service-requests';
import { FakeFirestore } from '../support/fake-firestore';
import { populatedStayFixture, stayFixture } from '../support/stay-fixtures';

function storeWithStays(): FakeFirestore {
  const fake = new FakeFirestore();
  const populated = populatedStayFixture();
  const empty = stayFixture({ stayId: 'stay-empty' });
  fake.store(STAYS_COLLECTION).set(populated.stayId, JSON.parse(JSON.stringify(populated)));
  fake.store(STAYS_COLLECTION).set(empty.stayId, JSON.parse(JSON.stringify(empty)));
  return fake;
}

describe('backfill of the request queues', () => {
  it('test_dryRun_reportsTheEntriesWithoutWriting', async () => {
    const fake = storeWithStays();

    const report = await backfillServiceRequests(fake.asFirestore(), { dryRun: true });

    expect(report).toMatchObject({ dryRun: true, scanned: 2 });
    expect(report.written.sort()).toEqual(['bk-test-1', 'stay-test-1_svc-stock']);
    expect(fake.store(SERVICE_REQUESTS_COLLECTION).size).toBe(0);
  });

  it('test_run_writesOneEntryPerBookingAndOrder_andIsIdempotent', async () => {
    const fake = storeWithStays();

    await backfillServiceRequests(fake.asFirestore(), { dryRun: false });
    await backfillServiceRequests(fake.asFirestore(), { dryRun: false });

    const stored = fake.store(SERVICE_REQUESTS_COLLECTION);
    expect([...stored.keys()].sort()).toEqual(['bk-test-1', 'stay-test-1_svc-stock']);
    expect(stored.get('bk-test-1')).toMatchObject({ section: 'EXPERIENCES', status: 'RECEIVED' });
  });
});
