import { BusinessRuleError } from '../domain-errors';
import { CatalogItem } from './catalog.models';

export function roundCents(value: number): number {
  return Math.round(value * 100) / 100;
}

/** ITEM: quantity x price; OZ: portions x ounces per portion x price per ounce. Rounded to cents. */
export function linePriceUSD(unitPriceUSD: number, quantity: number, ozPerPortion: number | null, multiplier = 1): number {
  return roundCents(unitPriceUSD * quantity * (ozPerPortion ?? 1) * multiplier);
}

/** OZ items need one of their portion sizes; ITEM items take no ounces (422 otherwise). */
export function assertPortionFits(item: CatalogItem, ozPerPortion: number | undefined): void {
  if (item.pricingUnit === 'OZ') {
    if (ozPerPortion === undefined || !item.portionOzOptions.includes(ozPerPortion)) {
      throw new BusinessRuleError(
        `Item ${item.itemId} is sold by weight: ozPerPortion must be one of ${item.portionOzOptions.join(', ')}`,
      );
    }
  } else if (ozPerPortion !== undefined) {
    throw new BusinessRuleError(`Item ${item.itemId} is sold per unit: ozPerPortion is not allowed`);
  }
}
