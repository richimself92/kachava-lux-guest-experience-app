import { CatalogService } from '../../src/domain/catalog/catalog.models';
import { resolveOrderConsent } from '../../src/domain/catalog/order-consent';
import { withServiceDefaults } from '../../src/domain/catalog/service-defaults';
import { BusinessRuleError } from '../../src/domain/domain-errors';
import { serviceFixture } from '../support/catalog-fixtures';

const AT = '2026-11-19T10:00:00.000Z';
const TERMS = { en: 'Paid in advance.', es: '' };

function stocking(askSubstitutions: boolean, terms = { en: '', es: '' }): CatalogService {
  const base = serviceFixture();
  return serviceFixture({
    kind: 'VILLA_STOCKING', experience: null, usageType: 'ORDER',
    stocking: { maxPerItem: null, orderDeadlineHoursBeforeCheckIn: null, askSubstitutions },
    guestInfo: { ...base.guestInfo, terms },
  });
}

describe('withServiceDefaults', () => {
  it('test_legacyService_readsWithEmptyTermsAndNoSubstitutionQuestion', () => {
    const legacy = JSON.parse(JSON.stringify(stocking(true)));
    delete legacy.guestInfo.terms;
    delete legacy.stocking.askSubstitutions;

    const service = withServiceDefaults(legacy as CatalogService);

    expect(service.guestInfo.terms).toEqual({ en: '', es: '' });
    expect(service.stocking?.askSubstitutions).toBe(false);
    expect(withServiceDefaults(serviceFixture()).stocking).toBeNull();
  });
});

describe('resolveOrderConsent', () => {
  it('test_nothingAsked_storesNulls_andIgnoresAnswers', () => {
    expect(resolveOrderConsent(stocking(false), { substitutionsAllowed: true, termsAccepted: true }, AT)).toEqual({
      substitutionsAllowed: null, termsAcceptedAt: null,
    });
  });

  it('test_askSubstitutions_requiresAnAnswer', () => {
    expect(() => resolveOrderConsent(stocking(true), {}, AT)).toThrow(BusinessRuleError);
    expect(resolveOrderConsent(stocking(true), { substitutionsAllowed: false }, AT).substitutionsAllowed).toBe(false);
  });

  it('test_termsWithText_mustBeAccepted', () => {
    expect(() => resolveOrderConsent(stocking(false, TERMS), {}, AT)).toThrow(/terms/);
    expect(() => resolveOrderConsent(stocking(false, { en: ' ', es: 'Pago previo.' }), { termsAccepted: false }, AT)).toThrow(
      BusinessRuleError,
    );
    expect(resolveOrderConsent(stocking(false, TERMS), { termsAccepted: true }, AT).termsAcceptedAt).toBe(AT);
  });

  it('test_legacyServiceWithoutNewFields_asksNothing', () => {
    const legacy = JSON.parse(JSON.stringify(serviceFixture()));
    delete legacy.guestInfo.terms;

    expect(resolveOrderConsent(legacy as CatalogService, {}, AT)).toEqual({ substitutionsAllowed: null, termsAcceptedAt: null });
  });
});
