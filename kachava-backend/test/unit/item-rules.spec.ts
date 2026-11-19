import {
  assertSkuAvailable,
  assertValidItem,
  distinctCategories,
  DEFAULT_PORTION_OZ_OPTIONS,
  itemPricingProblems,
  withItemDefaults,
} from '../../src/domain/catalog/item-rules';
import { linePriceUSD } from '../../src/domain/catalog/item-pricing';
import { CatalogItem } from '../../src/domain/catalog/catalog.models';
import { BusinessRuleError, EntityConflictError } from '../../src/domain/domain-errors';
import { itemFixture } from '../support/catalog-fixtures';

function legacyItem(): CatalogItem {
  const item = itemFixture() as Partial<CatalogItem>;
  delete item.sku;
  delete item.netCostMXN;
  delete item.sourceUrl;
  delete item.pricingUnit;
  delete item.portionOzOptions;
  return item as CatalogItem;
}

describe('withItemDefaults', () => {
  it('test_withItemDefaults_legacyItem_readsAsItemWithNulls', () => {
    expect(withItemDefaults(legacyItem())).toMatchObject({
      sku: null, netCostMXN: null, sourceUrl: null, pricingUnit: 'ITEM', portionOzOptions: [],
    });
  });

  it('test_withItemDefaults_ozWithoutOptions_getsDefaultPortions', () => {
    const item = withItemDefaults(itemFixture({ pricingUnit: 'OZ', portionOzOptions: [] }));

    expect(item.portionOzOptions).toEqual([6, 8, 10, 12, 14]);
    expect(DEFAULT_PORTION_OZ_OPTIONS).toEqual([6, 8, 10, 12, 14]);
  });

  it('test_withItemDefaults_ozOptions_areSortedAndUnique', () => {
    const item = withItemDefaults(itemFixture({ pricingUnit: 'OZ', portionOzOptions: [12, 6, 12] }));

    expect(item.portionOzOptions).toEqual([6, 12]);
  });

  it('test_withItemDefaults_itemUnit_dropsPortionOptions', () => {
    expect(withItemDefaults(itemFixture({ pricingUnit: 'ITEM', portionOzOptions: [6] })).portionOzOptions).toEqual([]);
  });
});

describe('itemPricingProblems', () => {
  it('test_ozItem_withoutPositivePrice_isAProblem', () => {
    expect(itemPricingProblems(itemFixture({ pricingUnit: 'OZ', priceUSD: 0, portionOzOptions: [6] }))).toEqual([
      'priceUSD must be greater than 0 when pricingUnit is OZ',
    ]);
    expect(itemPricingProblems(itemFixture({ pricingUnit: 'OZ', priceUSD: null, portionOzOptions: [6] }))).toHaveLength(1);
  });

  it('test_ozItem_acceptsFourDecimalPriceAndCost', () => {
    const item = itemFixture({ pricingUnit: 'OZ', priceUSD: 3.3114, netCostMXN: 30.9577, portionOzOptions: [6, 12] });

    expect(itemPricingProblems(item)).toEqual([]);
  });

  it('test_itemUnit_rejectsMoreThanTwoDecimals', () => {
    const item = itemFixture({ pricingUnit: 'ITEM', priceUSD: 3.3114, netCostMXN: 30.9577 });

    expect(itemPricingProblems(item)).toEqual([
      'priceUSD allows at most 2 decimals when pricingUnit is ITEM',
      'netCostMXN allows at most 2 decimals when pricingUnit is ITEM',
    ]);
  });

  it('test_ozItem_rejectsInvalidPortionOptions', () => {
    const item = itemFixture({ pricingUnit: 'OZ', priceUSD: 1, portionOzOptions: [0, 65, 1.5] });

    expect(itemPricingProblems(item)).toEqual(['portionOzOptions must be 1 to 10 whole ounces between 1 and 64']);
  });

  it('test_assertValidItem_invalidPricing_isBusinessRuleError', () => {
    expect(() => assertValidItem(itemFixture({ pricingUnit: 'OZ', priceUSD: 0, portionOzOptions: [6] }))).toThrow(
      BusinessRuleError,
    );
  });
});

describe('linePriceUSD', () => {
  it('test_ozLine_isQuantityTimesOuncesTimesPrice_roundedToCents', () => {
    expect(linePriceUSD(3.3114, 5, 12)).toBe(198.68);
  });

  it('test_itemLine_ignoresOunces', () => {
    expect(linePriceUSD(4.25, 3, null)).toBe(12.75);
  });

  it('test_multiplier_isApplied', () => {
    expect(linePriceUSD(10, 1, null, 3)).toBe(30);
  });
});

describe('assertSkuAvailable', () => {
  const existing = [itemFixture({ itemId: 'a', sku: 'PRE-001' }), itemFixture({ itemId: 'b', sku: null })];

  it('test_skuUsedByAnotherItem_isConflict', () => {
    expect(() => assertSkuAvailable(existing, itemFixture({ itemId: 'c', sku: 'PRE-001' }))).toThrow(EntityConflictError);
  });

  it('test_sameItemOrNullSku_isAccepted', () => {
    expect(() => assertSkuAvailable(existing, itemFixture({ itemId: 'a', sku: 'PRE-001' }))).not.toThrow();
    expect(() => assertSkuAvailable(existing, itemFixture({ itemId: 'c', sku: null }))).not.toThrow();
  });
});

describe('distinctCategories', () => {
  it('test_distinctCategories_followCatalogOrder_withoutNulls', () => {
    const items = [
      itemFixture({ itemId: 'a', category: 'Dairy', order: 3 }),
      itemFixture({ itemId: 'b', category: 'Produce', order: 1 }),
      itemFixture({ itemId: 'c', category: null, order: 0 }),
      itemFixture({ itemId: 'd', category: 'Produce', order: 4 }),
      itemFixture({ itemId: 'e', category: 'Bakery', order: 2 }),
    ];

    expect(distinctCategories(items)).toEqual(['Produce', 'Bakery', 'Dairy']);
  });
});
