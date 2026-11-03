import { ExperienceCatalogItem, LarderCatalogItem } from './models/domain.models';

const DEFAULT_LARDER_IMAGE =
  'https://images.unsplash.com/photo-1540420773420-3366772f4999?auto=format&fit=crop&w=800&q=80';
const DEFAULT_EXPERIENCE_IMAGE =
  'https://images.unsplash.com/photo-1544551763-46a013bb70d5?auto=format&fit=crop&w=1200&q=80';

export function buildLarderCatalogItem(item: Partial<LarderCatalogItem>): LarderCatalogItem {
  return {
    id: item.id?.trim() || `larder_${Date.now()}`,
    name: item.name || 'Artisanal Provision',
    origin: item.origin || 'Kachava Culinary Lab',
    description: item.description || '',
    price: Number(item.price ?? 0),
    category: item.category?.trim() || 'Minibar',
    quantity: item.quantity ?? 0,
    image: item.image || DEFAULT_LARDER_IMAGE,
    tag: item.tag || 'CURATED SELECTION',
    ...(item.dietary ? { dietary: item.dietary } : {}),
    storageType: item.storageType || 'CHILLED IN LARDER',
    isActive: item.isActive ?? true,
  };
}

export function buildExperienceCatalogItem(
  item: Partial<ExperienceCatalogItem>,
): ExperienceCatalogItem {
  const basePriceUSD = Number(item.basePriceUSD ?? 0);
  const isIncluded = item.isIncluded ?? basePriceUSD === 0;
  return {
    id: item.id?.trim() || `exp_${Date.now()}`,
    title: item.title || 'Sanctuary Experience',
    subtitle: item.subtitle || item.location || 'Kachava Sanctuary',
    duration: item.duration || '2 Hours',
    location: item.location || 'Kachava Sanctuary',
    vehicleOrDetail: item.vehicleOrDetail || 'Private Curation',
    priceText: item.priceText || (isIncluded ? 'Complimentary' : `$${basePriceUSD} USD`),
    basePriceUSD,
    isIncluded,
    ...(item.inclusionLabel ? { inclusionLabel: item.inclusionLabel } : {}),
    image: item.image || DEFAULT_EXPERIENCE_IMAGE,
    category: item.category || 'Wellness & Spa',
    description: item.description || '',
    amenities: item.amenities || ['Private Host Curation'],
    actionLabel: item.actionLabel || 'Reserve Experience',
    ...(item.actionScreen ? { actionScreen: item.actionScreen } : {}),
  };
}
