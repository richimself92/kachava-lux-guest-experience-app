import { isAdminResetAllowed, isFirestoreFlagEnabled } from '../../src/common/config/runtime-flags';

describe('isFirestoreFlagEnabled', () => {
  it.each([
    [{ USE_FIRESTORE: 'true' }, true],
    [{ USE_GCP_FIRESTORE: 'true' }, true],
    [{ USE_FIRESTORE: 'false', USE_GCP_FIRESTORE: 'false' }, false],
    [{}, false],
  ])('test_isFirestoreFlagEnabled_env%j_returns%s', (env, expected) => {
    expect(isFirestoreFlagEnabled(env)).toBe(expected);
  });
});

describe('isAdminResetAllowed', () => {
  it.each([
    [{ NODE_ENV: 'test' }, true],
    [{ NODE_ENV: 'development' }, true],
    [{ NODE_ENV: 'production' }, false],
    [{ NODE_ENV: 'test', USE_FIRESTORE: 'true' }, false],
    [{ USE_GCP_FIRESTORE: 'true' }, false],
  ])('test_isAdminResetAllowed_env%j_returns%s', (env, expected) => {
    expect(isAdminResetAllowed(env)).toBe(expected);
  });
});
