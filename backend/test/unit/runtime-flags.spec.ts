import { assertFirestoreTarget, isFirestoreFlagEnabled } from '../../src/common/config/runtime-flags';

const EMULATORS = {
  FIRESTORE_EMULATOR_HOST: '127.0.0.1:8085',
  FIREBASE_STORAGE_EMULATOR_HOST: '127.0.0.1:9199',
};

describe('isFirestoreFlagEnabled', () => {
  it.each([
    [{ USE_FIRESTORE: 'true' }, true],
    [{ USE_FIRESTORE: 'false' }, false],
    [{ USE_GCP_FIRESTORE: 'true' }, false],
    [{}, false],
  ])('test_isFirestoreFlagEnabled_env%j_returns%s', (env, expected) => {
    expect(isFirestoreFlagEnabled(env)).toBe(expected);
  });
});

describe('assertFirestoreTarget (no in-memory mode, never the live database locally)', () => {
  it('test_withoutUseFirestore_refusesToStart', () => {
    expect(() => assertFirestoreTarget({ ...EMULATORS })).toThrow(/USE_FIRESTORE=true/);
  });

  it('test_localWithoutFirestoreEmulator_refusesLiveDatabase', () => {
    expect(() =>
      assertFirestoreTarget({ USE_FIRESTORE: 'true', FIREBASE_STORAGE_EMULATOR_HOST: '127.0.0.1:9199' }),
    ).toThrow(/FIRESTORE_EMULATOR_HOST/);
  });

  it('test_localWithoutStorageEmulator_refusesLiveBucket', () => {
    expect(() =>
      assertFirestoreTarget({ USE_FIRESTORE: 'true', FIRESTORE_EMULATOR_HOST: '127.0.0.1:8085' }),
    ).toThrow(/FIREBASE_STORAGE_EMULATOR_HOST/);
  });

  it('test_localWithEmulators_isAllowed', () => {
    expect(() => assertFirestoreTarget({ USE_FIRESTORE: 'true', ...EMULATORS })).not.toThrow();
  });

  it('test_production_usesManagedServices', () => {
    expect(() => assertFirestoreTarget({ USE_FIRESTORE: 'true', NODE_ENV: 'production' })).not.toThrow();
  });
});
