import * as fs from 'fs';
import * as path from 'path';
import { Test } from '@nestjs/testing';
import { AppModule } from '../../src/app.module';
import {
  ALERT_REPOSITORY_PORT,
  CATALOG_IMAGE_STORAGE_PORT,
  SERVICE_ITEM_REPOSITORY_PORT,
  SERVICE_REPOSITORY_PORT,
  SETTINGS_REPOSITORY_PORT,
  STAFF_REPOSITORY_PORT,
  STAY_REPOSITORY_PORT,
  STORAGE_SIGNER_PORT,
  TRANSPORT_PROVIDER_REPOSITORY_PORT,
  TRIP_REPOSITORY_PORT,
  VILLA_REPOSITORY_PORT,
} from '../../src/domain/ports/repository.ports';
import { CLOCK_PORT } from '../../src/domain/ports/clock.port';
import { FIRESTORE_DB, OBJECT_URL_SIGNER } from '../../src/infrastructure/firebase/firebase-admin.module';

const SRC_ROOT = path.resolve(__dirname, '../../src');
const RUNTIME_TOKENS = {
  STAY_REPOSITORY_PORT, ALERT_REPOSITORY_PORT, STAFF_REPOSITORY_PORT, SETTINGS_REPOSITORY_PORT,
  VILLA_REPOSITORY_PORT, TRANSPORT_PROVIDER_REPOSITORY_PORT, SERVICE_REPOSITORY_PORT,
  SERVICE_ITEM_REPOSITORY_PORT, STORAGE_SIGNER_PORT, CATALOG_IMAGE_STORAGE_PORT, OBJECT_URL_SIGNER,
  TRIP_REPOSITORY_PORT, CLOCK_PORT,
};
const FORBIDDEN_RUNTIME_NAME = /in-?memory|seed|fake|demo|mock/i;

function sourceFiles(dir: string): string[] {
  return fs.readdirSync(dir, { withFileTypes: true }).flatMap((entry) => {
    const full = path.join(dir, entry.name);
    return entry.isDirectory() ? sourceFiles(full) : [full];
  });
}

describe('Runtime module graph has no in-memory, seed or demo providers', () => {
  const savedEnv = { ...process.env };

  afterEach(() => {
    process.env = { ...savedEnv };
  });

  it('test_appModule_withRealFactories_wiresOnlyFirestoreAndStorageAdapters', async () => {
    Object.assign(process.env, {
      USE_FIRESTORE: 'true',
      FIRESTORE_EMULATOR_HOST: '127.0.0.1:1',
      FIREBASE_STORAGE_EMULATOR_HOST: '127.0.0.1:2',
      FIREBASE_PROJECT_ID: 'demo-module-graph',
      STAFF_JWT_SECRET: 'x'.repeat(32),
      STEPUP_HMAC_SECRET: 'y'.repeat(32),
    });
    const moduleRef = await Test.createTestingModule({ imports: [AppModule] }).compile();

    const adapters = Object.entries(RUNTIME_TOKENS).map(([token, symbol]) => [
      token,
      (moduleRef.get(symbol) as object).constructor.name,
    ]);
    const db = moduleRef.get(FIRESTORE_DB) as object;
    await moduleRef.close();

    expect(db.constructor.name).toBe('Firestore');
    expect(adapters.filter(([, name]) => FORBIDDEN_RUNTIME_NAME.test(name))).toEqual([]);
    expect(Object.fromEntries(adapters)).toMatchObject({
      STAY_REPOSITORY_PORT: 'FirestoreStayRepository',
      VILLA_REPOSITORY_PORT: 'FirestoreEntityRepository',
      SERVICE_REPOSITORY_PORT: 'FirestoreEntityRepository',
      SETTINGS_REPOSITORY_PORT: 'FirestoreSettingsRepository',
      STAFF_REPOSITORY_PORT: 'FirestoreStaffRepository',
      TRIP_REPOSITORY_PORT: 'FirestoreTripRepository',
      CLOCK_PORT: 'SystemClock',
      OBJECT_URL_SIGNER: 'EmulatorObjectUrlSigner',
    });
  });

  it('test_appModule_withoutUseFirestore_refusesToBuild', async () => {
    delete process.env.USE_FIRESTORE;

    await expect(Test.createTestingModule({ imports: [AppModule] }).compile()).rejects.toThrow(/USE_FIRESTORE=true/);
  });

  it('test_sourceTree_hasNoSeedOrInMemoryFilesOrDemoFixtures', () => {
    const files = sourceFiles(SRC_ROOT);
    const offendingFiles = files.filter((file) => /seed|in-memory/i.test(path.relative(SRC_ROOT, file)));
    const offendingContent = files.filter((file) =>
      /InMemory\w*Repository|InMemorySeeded|createSeeded|550e8400-e29b|Villa 102|Miller|unsplash/.test(fs.readFileSync(file, 'utf8')),
    );

    expect(offendingFiles).toEqual([]);
    expect(offendingContent).toEqual([]);
  });
});
