import { NestFactory } from '@nestjs/core';
import { Test } from '@nestjs/testing';
import { AppModule } from '../../src/app.module';
import {
  assertProductionSecrets,
  MIN_SECRET_LENGTH,
  resolveSecret,
} from '../../src/common/config/runtime-secrets';
import { bootstrap } from '../../src/main';

const STRONG = 'x'.repeat(MIN_SECRET_LENGTH);
const ALL_STRONG = {
  STAFF_JWT_SECRET: STRONG,
  STEPUP_HMAC_SECRET: STRONG,
  STORAGE_SIGNING_SECRET: STRONG,
};

describe('resolveSecret / assertProductionSecrets', () => {
  it.each([{ NODE_ENV: 'production' }, { USE_FIRESTORE: 'true' }, { USE_GCP_FIRESTORE: 'true' }])(
    'test_resolveSecret_strictEnv%j_missingSecret_throwsClearError',
    (env) => {
      expect(() => resolveSecret('STAFF_JWT_SECRET', env)).toThrow(/STAFF_JWT_SECRET.*32/);
    },
  );

  it('test_resolveSecret_production_weakSecret_throws', () => {
    const env = { NODE_ENV: 'production', STEPUP_HMAC_SECRET: 'short-secret' };

    expect(() => resolveSecret('STEPUP_HMAC_SECRET', env)).toThrow(/STEPUP_HMAC_SECRET/);
  });

  it('test_resolveSecret_production_strongSecret_returnsIt', () => {
    expect(resolveSecret('STAFF_JWT_SECRET', { NODE_ENV: 'production', ...ALL_STRONG })).toBe(STRONG);
  });

  it('test_resolveSecret_local_missingSecret_returnsStablePerProcessRandomSecret', () => {
    const first = resolveSecret('STAFF_JWT_SECRET', {});
    const again = resolveSecret('STAFF_JWT_SECRET', {});
    const other = resolveSecret('STEPUP_HMAC_SECRET', {});

    expect(first.length).toBeGreaterThanOrEqual(MIN_SECRET_LENGTH);
    expect(again).toBe(first);
    expect(other).not.toBe(first);
  });

  it('test_resolveSecret_local_configuredSecret_isUsed', () => {
    expect(resolveSecret('STORAGE_SIGNING_SECRET', { STORAGE_SIGNING_SECRET: 'dev' })).toBe('dev');
  });

  it('test_assertProductionSecrets_productionMissingStorageSecret_throws', () => {
    const env = { NODE_ENV: 'production', STAFF_JWT_SECRET: STRONG, STEPUP_HMAC_SECRET: STRONG };

    expect(() => assertProductionSecrets(env)).toThrow(/STORAGE_SIGNING_SECRET/);
  });

  it('test_assertProductionSecrets_allStrongOrLocal_passes', () => {
    expect(() => assertProductionSecrets({ NODE_ENV: 'production', ...ALL_STRONG })).not.toThrow();
    expect(() => assertProductionSecrets({ NODE_ENV: 'development' })).not.toThrow();
  });
});

describe('startup in production without secrets', () => {
  const saved = { ...process.env };

  beforeEach(() => {
    process.env.NODE_ENV = 'production';
    delete process.env.STAFF_JWT_SECRET;
    delete process.env.STEPUP_HMAC_SECRET;
    delete process.env.STORAGE_SIGNING_SECRET;
  });

  afterEach(() => {
    process.env = { ...saved };
    jest.restoreAllMocks();
  });

  it('test_bootstrap_productionMissingSecrets_failsBeforeCreatingApp', async () => {
    const create = jest.spyOn(NestFactory, 'create').mockResolvedValue({} as never);

    await expect(bootstrap()).rejects.toThrow(/STAFF_JWT_SECRET/);
    expect(create).not.toHaveBeenCalled();
  });

  it('test_appModule_productionMissingSecrets_failsDependencyInjection', async () => {
    await expect(Test.createTestingModule({ imports: [AppModule] }).compile()).rejects.toThrow(
      /_SECRET/,
    );
  });
});
