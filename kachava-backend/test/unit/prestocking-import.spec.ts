import { CatalogItem } from '../../src/domain/catalog/catalog.models';
import { planPrestockingImport, planStockingServicePatch, PrestockingRow } from '../../src/domain/catalog/prestocking-import';
import { BusinessRuleError } from '../../src/domain/domain-errors';
import {
  CATALOG_ITEMS_COLLECTION,
  CATALOG_SERVICES_COLLECTION,
} from '../../src/infrastructure/firebase/firebase-admin.module';
import { importPrestocking, parseImportArgs, parsePrestockingFile } from '../../src/scripts/import-prestocking';
import { itemFixture, serviceFixture } from '../support/catalog-fixtures';
import { FakeFirestore } from '../support/fake-firestore';

const AT = '2026-11-18T12:00:00.000Z';
const ACTOR = 'script:import-prestocking';
const SERVICE = 'svc-stock';

function row(overrides: Partial<PrestockingRow> = {}): PrestockingRow {
  return {
    sku: 'PRE-001', category: 'Dairy', name: { en: 'Whole milk', es: 'Leche entera' }, priceUSD: 2.5,
    netCostMXN: 38.5, sourceUrl: null, pricingUnit: 'ITEM', portionOzOptions: [], order: 1, ...overrides,
  };
}

const steakRow = row({
  sku: 'PRE-104', category: 'Proteins', name: { en: 'New York steak', es: 'Corte New York' }, priceUSD: 3.3114,
  netCostMXN: 30.9577, sourceUrl: 'https://supplier.example/steak', pricingUnit: 'OZ', portionOzOptions: [6, 8, 10, 12, 14], order: 104,
});

function plan(existing: CatalogItem[], rows: PrestockingRow[]) {
  let next = 0;
  return planPrestockingImport(existing, rows, { serviceId: SERVICE, actor: ACTOR, at: AT, newId: () => `new-${++next}` });
}

function applied(existing: CatalogItem[], result: ReturnType<typeof plan>): CatalogItem[] {
  const byId = new Map(existing.map((item) => [item.itemId, item]));
  [...result.creates, ...result.updates, ...result.disables].forEach((item) => byId.set(item.itemId, item));
  return [...byId.values()];
}

describe('planPrestockingImport', () => {
  const stock = (overrides: Partial<CatalogItem>) => itemFixture({ serviceId: SERVICE, ...overrides });

  it('test_plan_createsUpdatesDisablesAndCountsUnchanged', () => {
    const existing = [
      stock({ itemId: 'milk', sku: 'PRE-001', priceUSD: 2, category: 'Old' }),
      stock({ itemId: 'legacy', sku: null }),
      stock({ itemId: 'gone', sku: 'PRE-999' }),
      stock({ itemId: 'off', sku: null, status: 'DISABLED', order: 500 }),
    ];

    const result = plan(existing, [row(), steakRow]);

    expect(result.counts).toEqual({ created: 1, updated: 1, disabled: 2, unchanged: 1 });
    expect(result.creates[0]).toMatchObject({
      itemId: 'new-1', serviceId: SERVICE, sku: 'PRE-104', status: 'ACTIVE', pricingUnit: 'OZ', priceUSD: 3.3114,
      createdBy: ACTOR, createdAt: AT, updatedBy: ACTOR,
    });
    expect(result.updates[0]).toMatchObject({
      itemId: 'milk', priceUSD: 2.5, category: 'Dairy', netCostMXN: 38.5, name: { en: 'Whole milk', es: 'Leche entera' },
      status: 'ACTIVE', updatedBy: ACTOR, updatedAt: AT, createdBy: 'test',
    });
    expect(result.disables.map((i) => [i.itemId, i.status, i.updatedBy])).toEqual([
      ['legacy', 'DISABLED', ACTOR], ['gone', 'DISABLED', ACTOR],
    ]);
  });

  it('test_plan_secondRun_isIdempotent', () => {
    const existing = [itemFixture({ itemId: 'legacy', serviceId: SERVICE })];
    const first = plan(existing, [row(), steakRow]);

    const second = plan(applied(existing, first), [row(), steakRow]);

    expect(second.counts).toEqual({ created: 0, updated: 0, disabled: 0, unchanged: 3 });
  });

  it('test_plan_itemsLeftOut_moveAfterTheLastFileRow', () => {
    const existing = [
      stock({ itemId: 'legacy', sku: null, order: 1 }),
      stock({ itemId: 'off', sku: null, status: 'DISABLED', order: 2 }),
    ];

    const result = plan(existing, [row(), steakRow]);

    expect(result.disables.map((i) => [i.itemId, i.status, i.order])).toEqual([
      ['legacy', 'DISABLED', 105], ['off', 'DISABLED', 106],
    ]);
    expect(plan(applied(existing, result), [row(), steakRow]).disables).toEqual([]);
  });

  it('test_plan_disabledItemInTheFile_isReactivated', () => {
    const result = plan([stock({ itemId: 'milk', sku: 'PRE-001', status: 'DISABLED' })], [row()]);

    expect(result.updates[0].status).toBe('ACTIVE');
  });

  it('test_plan_duplicateSkuInFile_isRejected', () => {
    expect(() => plan([], [row(), row({ order: 2 })])).toThrow(BusinessRuleError);
  });

  it('test_plan_invalidRow_isRejectedBeforeAnyWrite', () => {
    expect(() => plan([], [row({ sku: 'PRE-104', pricingUnit: 'OZ', priceUSD: 0 })])).toThrow(/PRE-104/);
  });
});

describe('parsePrestockingFile', () => {
  it('test_parse_acceptsFourDecimalPerOunceValues', () => {
    expect(parsePrestockingFile({ items: [steakRow, row()] })).toEqual({ service: null, rows: [steakRow, row()] });
  });

  it('test_parse_optionalServiceBlock', () => {
    const service = { terms: { en: 'Paid in advance.\nNo refunds.', es: 'Pago previo.' }, askSubstitutions: true };

    expect(parsePrestockingFile({ source: 'x.xlsx', service, items: [row()] }).service).toEqual(service);
  });

  it.each([
    [{ terms: { en: 'x'.repeat(3001) } }],
    [{ askSubstitutions: 'yes' }],
  ])('test_parse_invalidServiceBlock_%j_isRejected', (service) => {
    expect(() => parsePrestockingFile({ service, items: [row()] })).toThrow();
  });

  it.each([
    [{}],
    [{ items: [{ ...row(), sku: '' }] }],
    [{ items: [{ ...row(), priceUSD: '2.5' }] }],
    [{ items: [{ ...row(), pricingUnit: 'KG' }] }],
    [{ items: [{ ...row(), sourceUrl: 'not a url' }] }],
    [{ items: [{ ...row(), name: { en: 'Milk' } }] }],
  ])('test_parse_invalidShape_%j_isRejected', (json) => {
    expect(() => parsePrestockingFile(json)).toThrow();
  });
});

describe('planStockingServicePatch', () => {
  const stockingService = () => serviceFixture({
    serviceId: SERVICE, kind: 'VILLA_STOCKING', experience: null,
    stocking: { maxPerItem: 4, orderDeadlineHoursBeforeCheckIn: null, askSubstitutions: false },
  });
  const block = { terms: { en: 'Paid in advance.', es: 'Pago previo.' }, askSubstitutions: true };

  it('test_patch_setsTermsAndSubstitutionQuestion_keepingOtherFields', () => {
    const next = planStockingServicePatch(stockingService(), block, { updatedAt: AT, updatedBy: ACTOR });

    expect(next).toMatchObject({
      guestInfo: { terms: block.terms, includes: { en: '', es: '' } },
      stocking: { askSubstitutions: true, maxPerItem: 4 }, updatedBy: ACTOR, updatedAt: AT, createdBy: 'test',
    });
  });

  it('test_patch_withoutChanges_isNull', () => {
    const current = planStockingServicePatch(stockingService(), block, { updatedAt: AT, updatedBy: ACTOR });

    expect(planStockingServicePatch(current!, block, { updatedAt: AT, updatedBy: ACTOR })).toBeNull();
    expect(planStockingServicePatch(stockingService(), null, { updatedAt: AT, updatedBy: ACTOR })).toBeNull();
  });
});

describe('parseImportArgs', () => {
  it('test_args_fileProjectAndDryRun', () => {
    expect(parseImportArgs(['--file', 'a.json', '--project', 'demo-p', '--dry-run'])).toEqual({
      file: 'a.json', project: 'demo-p', dryRun: true, allowProduction: false,
    });
  });

  it.each([
    [['--file', 'a.json']],
    [['--project', 'demo-p']],
    [['--file', 'a.json', '--project']],
    [['--file', 'a.json', '--project', 'demo-p', '--dryrun']],
  ])('test_args_%j_areRejected', (argv) => {
    expect(() => parseImportArgs(argv)).toThrow();
  });
});

describe('importPrestocking (Firestore adapters over the fake)', () => {
  function seeded(services = [serviceFixture({ serviceId: SERVICE, kind: 'VILLA_STOCKING', experience: null })]): FakeFirestore {
    const fake = new FakeFirestore();
    services.forEach((s) => fake.store(CATALOG_SERVICES_COLLECTION).set(s.serviceId, JSON.parse(JSON.stringify(s))));
    const legacy = itemFixture({ itemId: 'legacy', serviceId: SERVICE });
    fake.store(CATALOG_ITEMS_COLLECTION).set(legacy.itemId, JSON.parse(JSON.stringify(legacy)));
    return fake;
  }
  const options = (dryRun: boolean) => ({ dryRun, actor: ACTOR, at: AT });
  const BLOCK = { terms: { en: 'Paid in advance.', es: 'Pago previo.' }, askSubstitutions: true };

  it('test_dryRun_reportsCountsAndWritesNothing', async () => {
    const fake = seeded();

    const report = await importPrestocking(fake.asFirestore(), { service: BLOCK, rows: [row(), steakRow] }, options(true));

    expect(report).toEqual({
      dryRun: true, serviceId: SERVICE, serviceUpdated: true, created: 2, updated: 0, disabled: 1, unchanged: 0,
    });
    expect(fake.store(CATALOG_SERVICES_COLLECTION).get(SERVICE)).toMatchObject({ guestInfo: { terms: { en: '', es: '' } } });
    expect(fake.store(CATALOG_ITEMS_COLLECTION).size).toBe(1);
    expect(fake.store(CATALOG_ITEMS_COLLECTION).get('legacy')).toMatchObject({ status: 'ACTIVE' });
  });

  it('test_run_writesItems_andSecondRunChangesNothing', async () => {
    const fake = seeded();

    const first = await importPrestocking(fake.asFirestore(), { service: BLOCK, rows: [row(), steakRow] }, options(false));
    const second = await importPrestocking(fake.asFirestore(), { service: BLOCK, rows: [row(), steakRow] }, options(false));

    const stored = [...fake.store(CATALOG_ITEMS_COLLECTION).values()] as unknown as CatalogItem[];
    expect(stored.find((i) => i.sku === 'PRE-104')).toMatchObject({ status: 'ACTIVE', netCostMXN: 30.9577, createdBy: ACTOR });
    expect(stored.find((i) => i.itemId === 'legacy')).toMatchObject({ status: 'DISABLED' });
    expect(first.serviceUpdated).toBe(true);
    expect(fake.store(CATALOG_SERVICES_COLLECTION).get(SERVICE)).toMatchObject({
      guestInfo: { terms: BLOCK.terms }, stocking: { askSubstitutions: true }, updatedBy: ACTOR,
    });
    expect(second).toMatchObject({ serviceUpdated: false, created: 0, updated: 0, disabled: 0, unchanged: 3 });
  });

  it.each([
    [[]],
    [[
      serviceFixture({ serviceId: 'a', kind: 'VILLA_STOCKING', experience: null }),
      serviceFixture({ serviceId: 'b', kind: 'VILLA_STOCKING', experience: null }),
    ]],
  ])('test_zeroOrSeveralStockingServices_isAnError', async (services) => {
    await expect(importPrestocking(seeded(services).asFirestore(), { service: null, rows: [row()] }, options(true))).rejects.toThrow(/VILLA_STOCKING/);
  });
});
