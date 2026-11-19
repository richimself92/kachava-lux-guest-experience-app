import { BusinessRuleError } from '../domain-errors';
import { CatalogService } from './catalog.models';
import { withServiceDefaults } from './service-defaults';

export interface OrderConsentAnswers {
  substitutionsAllowed?: boolean;
  termsAccepted?: boolean;
}

/** What is stored with an order: null when the service did not ask. */
export interface OrderConsent {
  substitutionsAllowed: boolean | null;
  termsAcceptedAt: string | null;
}

export function hasTerms(service: CatalogService): boolean {
  const { terms } = withServiceDefaults(service).guestInfo;
  return Boolean(terms.en.trim() || terms.es.trim());
}

/** Substitution answer required when the service asks; terms with text must be accepted (422). */
export function resolveOrderConsent(service: CatalogService, answers: OrderConsentAnswers, at: string): OrderConsent {
  const asksSubstitutions = withServiceDefaults(service).stocking?.askSubstitutions === true;
  if (asksSubstitutions && typeof answers.substitutionsAllowed !== 'boolean') {
    throw new BusinessRuleError('substitutionsAllowed is required: say whether comparable substitutes may be bought');
  }
  const termsRequired = hasTerms(service);
  if (termsRequired && answers.termsAccepted !== true) {
    throw new BusinessRuleError('The terms & conditions of this service must be accepted (termsAccepted: true)');
  }
  return {
    substitutionsAllowed: asksSubstitutions ? (answers.substitutionsAllowed as boolean) : null,
    termsAcceptedAt: termsRequired ? at : null,
  };
}
