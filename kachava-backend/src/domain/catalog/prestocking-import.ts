import { BusinessRuleError } from '../domain-errors';
import { assembleNewItem, assembleUpdatedItem, assembleUpdatedService } from './catalog-assembly';
import { assertValidService } from './catalog-rules';
import { AuditTrail, CatalogItem, CatalogService, LocalizedText, PricingUnit } from './catalog.models';
import { withServiceDefaults } from './service-defaults';
import { assertValidItem, withItemDefaults } from './item-rules';

/** One product of the pre-stocking catalog file (`{ items: PrestockingRow[] }`). */
export interface PrestockingRow {
  sku: string;
  category: string;
  name: LocalizedText;
  priceUSD: number;
  netCostMXN: number | null;
  sourceUrl: string | null;
  pricingUnit: PricingUnit;
  portionOzOptions: number[];
  order: number;
}

export interface PrestockingPlanContext {
  serviceId: string;
  actor: string;
  at: string;
  newId: () => string;
}

export interface PrestockingPlan {
  creates: CatalogItem[];
  updates: CatalogItem[];
  disables: CatalogItem[];
  counts: { created: number; updated: number; disabled: number; unchanged: number };
}

/** Fields the import owns; any difference in them makes an existing item an update. */
const IMPORTED_FIELDS = [
  'sku', 'category', 'name', 'priceUSD', 'netCostMXN', 'sourceUrl', 'pricingUnit', 'portionOzOptions', 'order', 'status',
] as const satisfies ReadonlyArray<keyof CatalogItem>;

function rowPatch(row: PrestockingRow): Partial<CatalogItem> {
  return { ...structuredClone(row), status: 'ACTIVE' };
}

function sameImportedFields(a: CatalogItem, b: CatalogItem): boolean {
  return IMPORTED_FIELDS.every((field) => JSON.stringify(a[field]) === JSON.stringify(b[field]));
}

function assertUniqueSkus(rows: PrestockingRow[]): void {
  const seen = new Set<string>();
  const duplicates = rows.map((r) => r.sku).filter((sku) => (seen.has(sku) ? true : (seen.add(sku), false)));
  if (duplicates.length > 0) throw new BusinessRuleError('Duplicate SKUs in the import file', duplicates);
}

function validated(item: CatalogItem): CatalogItem {
  try {
    assertValidItem(item);
  } catch (error) {
    throw new BusinessRuleError(`Invalid row ${item.sku}`, [error instanceof Error ? error.message : String(error)]);
  }
  return item;
}

function planRows(existing: CatalogItem[], rows: PrestockingRow[], ctx: PrestockingPlanContext) {
  const bySku = new Map(existing.filter((i) => i.sku).map((i) => [i.sku as string, i]));
  const audit = { updatedAt: ctx.at, updatedBy: ctx.actor };
  const creates: CatalogItem[] = [];
  const updates: CatalogItem[] = [];
  for (const row of rows) {
    const current = bySku.get(row.sku);
    if (!current) {
      const fullAudit = { ...audit, createdAt: ctx.at, createdBy: ctx.actor };
      creates.push(validated(assembleNewItem(rowPatch(row), ctx.serviceId, ctx.newId(), fullAudit)));
      continue;
    }
    const next = validated(assembleUpdatedItem(current, rowPatch(row), audit));
    if (!sameImportedFields(withItemDefaults(current), next)) updates.push(next);
  }
  return { creates, updates };
}

/** Items left out of the file become DISABLED and sort after the last file row. */
function planDisables(
  existing: CatalogItem[],
  fileSkus: Set<string>,
  lastOrder: number,
  ctx: PrestockingPlanContext,
): CatalogItem[] {
  return existing
    .filter((item) => !(item.sku && fileSkus.has(item.sku)))
    .filter((item) => item.status !== 'DISABLED' || item.order <= lastOrder)
    .map((item, index) => assembleUpdatedItem(
      item,
      { status: 'DISABLED', order: lastOrder + 1 + index },
      { updatedAt: ctx.at, updatedBy: ctx.actor },
    ));
}

/**
 * Pure diff of the pre-stocking file against the service's items: upsert by SKU (ACTIVE), and
 * every other item (no SKU, or a SKU not in the file) becomes DISABLED. Throws before any write
 * when a row is invalid, so the import is all-or-nothing.
 */
export function planPrestockingImport(
  existing: CatalogItem[],
  rows: PrestockingRow[],
  ctx: PrestockingPlanContext,
): PrestockingPlan {
  assertUniqueSkus(rows);
  const { creates, updates } = planRows(existing, rows, ctx);
  const fileSkus = new Set(rows.map((r) => r.sku));
  const disables = planDisables(existing, fileSkus, Math.max(0, ...rows.map((r) => r.order)), ctx);
  const unchanged = existing.length - updates.length - disables.length;
  return {
    creates,
    updates,
    disables,
    counts: { created: creates.length, updated: updates.length, disabled: disables.length, unchanged },
  };
}

/** Optional `service` block of the file: settings of the VILLA_STOCKING service itself. */
export interface PrestockingServiceBlock {
  terms?: LocalizedText;
  askSubstitutions?: boolean;
}

const EMPTY_STOCKING = { maxPerItem: null, orderDeadlineHoursBeforeCheckIn: null, askSubstitutions: false };

/** The service patched with the block through the normal update rules; null when nothing changes. */
export function planStockingServicePatch(
  stored: CatalogService,
  block: PrestockingServiceBlock | null,
  audit: Pick<AuditTrail, 'updatedAt' | 'updatedBy'>,
): CatalogService | null {
  if (!block) return null;
  const current = withServiceDefaults(stored);
  const next = assembleUpdatedService(current, {
    ...(block.terms ? { guestInfo: { terms: { ...current.guestInfo.terms, ...block.terms } } } : {}),
    ...(block.askSubstitutions === undefined
      ? {}
      : { stocking: { ...(current.stocking ?? EMPTY_STOCKING), askSubstitutions: block.askSubstitutions } }),
  }, audit);
  assertValidService(next);
  const changed = JSON.stringify([current.guestInfo, current.stocking]) !== JSON.stringify([next.guestInfo, next.stocking]);
  return changed ? next : null;
}
