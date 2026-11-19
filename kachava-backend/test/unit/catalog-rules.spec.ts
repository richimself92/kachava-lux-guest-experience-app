import {
  activationProblems,
  assertCatalogImages,
  assertKindDetailsMatch,
  buildServiceSnapshot,
  consistencyProblems,
  itemActivationProblems,
  resolveOrderLines,
  toGuestCatalogService,
} from '../../src/domain/catalog/catalog-rules';
import { CatalogItem } from '../../src/domain/catalog/catalog.models';
import { BusinessRuleError, EntityNotFoundError } from '../../src/domain/domain-errors';
import { itemFixture, serviceFixture } from '../support/catalog-fixtures';

const NOW = '2026-11-02T12:00:00.000Z';

describe('service activation rule', () => {
  it('test_activationProblems_completeService_isEmpty', () => {
    expect(activationProblems(serviceFixture())).toEqual([]);
  });

  it('test_activationProblems_missingCoverAndSpanishText_listsEachProblem', () => {
    const service = serviceFixture({
      cover: null,
      name: { en: 'Only English', es: '' },
      shortDescription: { en: '', es: 'Solo español' },
    });

    expect(activationProblems(service)).toEqual([
      'cover image is required',
      'name.es is required',
      'shortDescription.en is required',
    ]);
  });

  it('test_itemActivationProblems_missingEnglishName_isReported', () => {
    expect(itemActivationProblems(itemFixture({ name: { en: ' ', es: 'Nombre' } }))).toEqual([
      'name.en is required',
    ]);
  });
});

describe('service consistency', () => {
  it('test_consistencyProblems_validService_isEmpty', () => {
    expect(consistencyProblems(serviceFixture())).toEqual([]);
  });

  it('test_consistencyProblems_reportsEachInvalidCombination', () => {
    const base = serviceFixture();
    const service = serviceFixture({
      name: { en: ' ', es: '' },
      pricing: { ...base.pricing, mode: 'INCLUDED', amount: 20 },
      availability: {
        ...base.availability,
        minGuests: 5,
        maxGuests: 2,
        timeSlots: [{ start: '10:00', end: '09:00' }],
      },
    });

    expect(consistencyProblems(service)).toEqual([
      'name needs English or Spanish text',
      'pricing.amount must be empty when pricing is INCLUDED',
      'minGuests cannot exceed maxGuests',
      'time slot 10:00-09:00 must end after it starts',
    ]);
  });
});

describe('kind-specific details', () => {
  it('test_assertKindDetailsMatch_blockOfAnotherKind_isRejected', () => {
    expect(() =>
      assertKindDetailsMatch('EXPERIENCE', { bar: { ageConfirmationRequired: true } }),
    ).toThrow(BusinessRuleError);
  });

  it('test_assertKindDetailsMatch_matchingBlock_isAccepted', () => {
    expect(() =>
      assertKindDetailsMatch('BAR', { bar: { ageConfirmationRequired: true } }),
    ).not.toThrow();
  });
});

describe('image paths', () => {
  const image = (storagePath: string) => ({ storagePath, alt: { en: '', es: '' }, usageRightsConfirmed: true });

  it('test_assertCatalogImages_pathOutsideCatalog_isRejected', () => {
    expect(() => assertCatalogImages([image('private/stays/s1/a.jpg')])).toThrow(BusinessRuleError);
    expect(() => assertCatalogImages([image('https://example.com/a.jpg')])).toThrow(BusinessRuleError);
  });

  it('test_assertCatalogImages_traversal_isRejected', () => {
    expect(() => assertCatalogImages([image('catalog/services/../x.jpg')])).toThrow(BusinessRuleError);
  });

  it('test_assertCatalogImages_catalogUpload_isAccepted', () => {
    expect(() => assertCatalogImages([image('catalog/services/items/a.webp')])).not.toThrow();
  });
});

describe('resolveOrderLines', () => {
  it('test_resolveOrderLines_disabledService_isRejected', () => {
    expect(() => resolveOrderLines(serviceFixture({ status: 'DISABLED' }), [], [])).toThrow(BusinessRuleError);
  });

  it('test_resolveOrderLines_unknownItem_isNotFound', () => {
    expect(() =>
      resolveOrderLines(serviceFixture(), [itemFixture()], [{ itemId: 'missing', quantity: 1 }]),
    ).toThrow(EntityNotFoundError);
  });

  it('test_resolveOrderLines_disabledItem_isRejected', () => {
    expect(() =>
      resolveOrderLines(serviceFixture(), [itemFixture({ status: 'DISABLED' })], [{ itemId: 'item-1', quantity: 1 }]),
    ).toThrow(BusinessRuleError);
  });

  it('test_resolveOrderLines_aboveStockingMaxPerItem_isRejected', () => {
    const service = serviceFixture({
      kind: 'VILLA_STOCKING',
      experience: null,
      stocking: { maxPerItem: 2, orderDeadlineHoursBeforeCheckIn: null, askSubstitutions: false },
    });

    expect(() =>
      resolveOrderLines(service, [itemFixture()], [{ itemId: 'item-1', quantity: 3 }]),
    ).toThrow(BusinessRuleError);
  });
});

describe('buildServiceSnapshot pricing', () => {
  it('test_snapshot_perPersonService_multipliesByPartySize', () => {
    const snapshot = buildServiceSnapshot(serviceFixture(), [{ item: null, quantity: 1 }], 3, NOW);

    expect(snapshot.lines[0]).toMatchObject({ unitPriceUSD: 10, quantity: 1, lineTotalUSD: 30 });
    expect(snapshot.totalUSD).toBe(30);
    expect(snapshot.serviceName).toEqual({ en: 'Test service', es: 'Servicio de prueba' });
  });

  it('test_snapshot_itemPrice_overridesServiceAmount', () => {
    const service = serviceFixture({ pricing: { ...serviceFixture().pricing, mode: 'PER_UNIT', amount: null } });

    const snapshot = buildServiceSnapshot(service, [{ item: itemFixture({ priceUSD: 4 }), quantity: 3 }], 1, NOW);

    expect(snapshot.lines[0]).toMatchObject({ itemId: 'item-1', unitPriceUSD: 4, lineTotalUSD: 12 });
  });

  it('test_snapshot_included_isZero', () => {
    const service = serviceFixture({ pricing: { ...serviceFixture().pricing, mode: 'INCLUDED', amount: null } });

    expect(buildServiceSnapshot(service, [{ item: null, quantity: 1 }], 2, NOW).totalUSD).toBe(0);
  });

  it('test_snapshot_onRequest_hasNoPrice', () => {
    const service = serviceFixture({ pricing: { ...serviceFixture().pricing, mode: 'ON_REQUEST', amount: null } });

    const snapshot = buildServiceSnapshot(service, [{ item: null, quantity: 1 }], 2, NOW);

    expect(snapshot.totalUSD).toBeNull();
    expect(snapshot.lines[0].unitPriceUSD).toBeNull();
  });

  it('test_snapshot_perHour_usesDuration', () => {
    const base = serviceFixture();
    const service = serviceFixture({
      pricing: { ...base.pricing, mode: 'PER_HOUR', amount: 100 },
      availability: { ...base.availability, durationMinutes: 90 },
    });

    expect(buildServiceSnapshot(service, [{ item: null, quantity: 1 }], 1, NOW).totalUSD).toBe(150);
  });

  it('test_snapshot_pricedModeWithoutAmount_isRejected', () => {
    const service = serviceFixture({ pricing: { ...serviceFixture().pricing, mode: 'FIXED', amount: null } });

    expect(() => buildServiceSnapshot(service, [{ item: null, quantity: 1 }], 1, NOW)).toThrow(BusinessRuleError);
  });
});

describe('toGuestCatalogService', () => {
  it('test_guestView_hidesOperationAndAudit_andResolvesImageUrls', () => {
    const view = toGuestCatalogService(serviceFixture(), [itemFixture()], (path) => `https://img/${path}`);

    expect(view).not.toHaveProperty('operation');
    expect(view).not.toHaveProperty('createdBy');
    expect(view).not.toHaveProperty('updatedBy');
    expect(view.items[0]).not.toHaveProperty('createdBy');
    expect(view.id).toBe('svc-1');
    expect(view.cover).toEqual({
      storagePath: 'catalog/services/cover.jpg',
      url: 'https://img/catalog/services/cover.jpg',
      alt: { en: 'Cover', es: 'Portada' },
      usageRightsConfirmed: true,
    });
  });
});

describe('weight-priced (OZ) order lines', () => {
  const steak = itemFixture({ pricingUnit: 'OZ', priceUSD: 3.3114, portionOzOptions: [6, 8, 10, 12, 14] });
  const perUnit = serviceFixture({ pricing: { ...serviceFixture().pricing, mode: 'PER_UNIT', amount: null } });

  it('test_resolveOrderLines_ozItemWithoutOunces_isRejected', () => {
    expect(() => resolveOrderLines(perUnit, [steak], [{ itemId: 'item-1', quantity: 5 }])).toThrow(BusinessRuleError);
  });

  it('test_resolveOrderLines_ozNotOffered_isRejected', () => {
    expect(() =>
      resolveOrderLines(perUnit, [steak], [{ itemId: 'item-1', quantity: 5, ozPerPortion: 9 }]),
    ).toThrow(BusinessRuleError);
  });

  it('test_resolveOrderLines_itemWithOunces_isRejected', () => {
    expect(() =>
      resolveOrderLines(perUnit, [itemFixture()], [{ itemId: 'item-1', quantity: 1, ozPerPortion: 6 }]),
    ).toThrow(BusinessRuleError);
  });

  it('test_resolveOrderLines_legacyItemWithoutPricingUnit_readsAsItem', () => {
    const legacy = itemFixture() as Partial<CatalogItem>;
    delete legacy.pricingUnit;
    delete legacy.portionOzOptions;

    const [line] = resolveOrderLines(perUnit, [legacy as CatalogItem], [{ itemId: 'item-1', quantity: 2 }]);

    expect(line.ozPerPortion).toBeNull();
    expect(line.item?.pricingUnit).toBe('ITEM');
  });

  it('test_snapshot_ozLine_isPortionsTimesOuncesTimesPricePerOunce', () => {
    const lines = resolveOrderLines(perUnit, [steak], [{ itemId: 'item-1', quantity: 5, ozPerPortion: 12 }]);

    const snapshot = buildServiceSnapshot(perUnit, lines, 1, NOW);

    expect(snapshot.lines[0]).toEqual(expect.objectContaining({
      pricingUnit: 'OZ', ozPerPortion: 12, unitPriceUSD: 3.3114, quantity: 5, lineTotalUSD: 198.68,
    }));
    expect(snapshot.totalUSD).toBe(198.68);
  });

  it('test_snapshot_itemLine_carriesItemUnitAndNoOunces', () => {
    const lines = resolveOrderLines(perUnit, [itemFixture({ priceUSD: 4 })], [{ itemId: 'item-1', quantity: 3 }]);

    expect(buildServiceSnapshot(perUnit, lines, 1, NOW).lines[0]).toMatchObject({
      pricingUnit: 'ITEM', ozPerPortion: null, lineTotalUSD: 12,
    });
  });
});

describe('guest item projection', () => {
  it('test_guestItem_hasPricingUnitAndPortions_butNeverAdminOnlyFields', () => {
    const item = itemFixture({
      sku: 'PRE-104', netCostMXN: 30.9577, sourceUrl: 'https://supplier.example/steak',
      pricingUnit: 'OZ', priceUSD: 3.3114, portionOzOptions: [6, 8],
    });

    const [guestItem] = toGuestCatalogService(serviceFixture(), [item], (path) => path).items;

    expect(guestItem).toMatchObject({ pricingUnit: 'OZ', portionOzOptions: [6, 8], priceUSD: 3.3114 });
    expect(guestItem).not.toHaveProperty('sku');
    expect(guestItem).not.toHaveProperty('netCostMXN');
    expect(guestItem).not.toHaveProperty('sourceUrl');
  });
});
