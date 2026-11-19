import { BusinessRuleError, EntityConflictError } from '../domain-errors';
import { assertCatalogImages, assertItemCanBeActive } from './catalog-rules';
import { CatalogItem } from './catalog.models';

/** Portion sizes offered when an OZ item is saved without its own options. */
export const DEFAULT_PORTION_OZ_OPTIONS: readonly number[] = [6, 8, 10, 12, 14];
export const PORTION_OZ_MIN = 1;
export const PORTION_OZ_MAX = 64;
export const PORTION_OPTIONS_MAX = 10;
/** Per-ounce prices and costs carry 4 decimals; unit prices stay in cents. */
const DECIMALS = { ITEM: 2, OZ: 4 } as const;

function sortedUnique(values: number[]): number[] {
  return [...new Set(values)].sort((a, b) => a - b);
}

function portionOptionsOf(item: Partial<CatalogItem>): number[] {
  if (item.pricingUnit !== 'OZ') return [];
  const options = item.portionOzOptions ?? [];
  return options.length > 0 ? sortedUnique(options) : [...DEFAULT_PORTION_OZ_OPTIONS];
}

/** Items stored before weight pricing read as ITEM with no admin-only data. */
export function withItemDefaults(item: CatalogItem): CatalogItem {
  return {
    ...item,
    sku: item.sku ?? null,
    netCostMXN: item.netCostMXN ?? null,
    sourceUrl: item.sourceUrl ?? null,
    pricingUnit: item.pricingUnit ?? 'ITEM',
    portionOzOptions: portionOptionsOf(item),
  };
}

function hasAtMostDecimals(value: number | null, decimals: number): boolean {
  return value === null || Number(value.toFixed(decimals)) === value;
}

function isValidPortion(oz: number): boolean {
  return Number.isInteger(oz) && oz >= PORTION_OZ_MIN && oz <= PORTION_OZ_MAX;
}

function ozProblems(item: CatalogItem): string[] {
  if (item.pricingUnit !== 'OZ') return [];
  const options = item.portionOzOptions;
  const validOptions = options.length >= 1 && options.length <= PORTION_OPTIONS_MAX && options.every(isValidPortion);
  return [
    ...(item.priceUSD !== null && item.priceUSD > 0 ? [] : ['priceUSD must be greater than 0 when pricingUnit is OZ']),
    ...(validOptions ? [] : [`portionOzOptions must be 1 to ${PORTION_OPTIONS_MAX} whole ounces between 1 and 64`]),
  ];
}

/** Why the price fields of an item are invalid (OZ needs a per-ounce price and portion sizes). */
export function itemPricingProblems(item: CatalogItem): string[] {
  const decimals = DECIMALS[item.pricingUnit];
  const precision = (['priceUSD', 'netCostMXN'] as const)
    .filter((field) => !hasAtMostDecimals(item[field], decimals))
    .map((field) => `${field} allows at most ${decimals} decimals when pricingUnit is ${item.pricingUnit}`);
  return [...ozProblems(item), ...precision];
}

/** Invariants of every saved item, active or not. */
export function assertValidItem(item: CatalogItem): void {
  if (!item.name.en.trim() && !item.name.es.trim()) {
    throw new BusinessRuleError('Invalid item', ['name needs English or Spanish text']);
  }
  if (item.image) assertCatalogImages([item.image]);
  const problems = itemPricingProblems(item);
  if (problems.length > 0) throw new BusinessRuleError('Invalid item', problems);
  assertItemCanBeActive(item);
}

/** A SKU identifies one item of its service (409 when another item already uses it). */
export function assertSkuAvailable(serviceItems: CatalogItem[], candidate: CatalogItem): void {
  if (!candidate.sku) return;
  const owner = serviceItems.find((item) => item.sku === candidate.sku && item.itemId !== candidate.itemId);
  if (owner) throw new EntityConflictError(`SKU ${candidate.sku} is already used by item ${owner.itemId}`);
}

/** Distinct item categories, in the catalog order of their first item. */
export function distinctCategories(items: CatalogItem[]): string[] {
  const ordered = [...items].sort((a, b) => a.order - b.order);
  return [...new Set(ordered.map((item) => item.category).filter((c): c is string => Boolean(c)))];
}
