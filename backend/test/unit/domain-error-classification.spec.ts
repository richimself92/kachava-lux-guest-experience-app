import { classifyError } from '../../src/common/filters/error-classification';
import {
  BusinessRuleError,
  EntityConflictError,
  EntityNotFoundError,
  ListScanLimitError,
  SettingsRequiredError,
} from '../../src/domain/domain-errors';

describe('classifyError for catalog/configuration domain errors', () => {
  it('test_entityNotFound_mapsTo404WithMessage', () => {
    const result = classifyError(new EntityNotFoundError('Service', 'svc-1'));

    expect(result).toMatchObject({ status: 404, error: 'NotFound', message: 'Service svc-1 not found.' });
  });

  it('test_businessRule_mapsTo422WithDetails', () => {
    const result = classifyError(new BusinessRuleError('Cannot activate', ['cover image is required']));

    expect(result).toMatchObject({
      status: 422,
      error: 'UnprocessableEntity',
      message: 'Cannot activate: cover image is required',
    });
  });

  it('test_conflict_mapsTo409', () => {
    expect(classifyError(new EntityConflictError('Villa has stays')).status).toBe(409);
  });

  it('test_scanLimit_mapsTo422', () => {
    expect(classifyError(new ListScanLimitError('catalog_services', 1000)).status).toBe(422);
  });

  it('test_settingsRequired_mapsTo422WithStableCodeAndMissingSettings', () => {
    const result = classifyError(new SettingsRequiredError(['timeZone', 'airports.CUN']));

    expect(result).toMatchObject({
      status: 422,
      error: 'UnprocessableEntity',
      code: 'SETTINGS_REQUIRED',
      details: ['timeZone', 'airports.CUN'],
    });
    expect(result.message).toContain('timeZone');
  });

  it('test_plainBusinessRule_hasNoCode', () => {
    expect(classifyError(new BusinessRuleError('Nope')).code).toBeUndefined();
  });
});
