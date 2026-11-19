import { CatalogService } from './catalog.models';

/** Services stored before terms/substitutions read with empty terms and no substitution question. */
export function withServiceDefaults(service: CatalogService): CatalogService {
  return {
    ...service,
    guestInfo: { ...service.guestInfo, terms: service.guestInfo?.terms ?? { en: '', es: '' } },
    stocking: service.stocking ? { ...service.stocking, askSubstitutions: service.stocking.askSubstitutions ?? false } : null,
  };
}
