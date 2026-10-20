import {
  DEFAULT_FIRESTORE_DATABASE_ID,
  DEFAULT_GCP_PROJECT_ID,
  DEFAULT_STORAGE_BUCKET,
} from '../../src/infrastructure/firebase/firebase-admin.module';
import { FirebaseStorageSignerAdapter } from '../../src/infrastructure/storage/storage-signer.adapter';
import { InMemorySeededStayRepository } from '../../src/infrastructure/repositories/in-memory-stay.repository';

describe('GCP & Firebase Live Resource Configuration (kavacha-app, kavacha-db, kavacha-store)', () => {
  it('test_firebaseDefaults_matchKavachaAppResources', () => {
    expect(DEFAULT_GCP_PROJECT_ID).toBe('kavacha-app');
    expect(DEFAULT_FIRESTORE_DATABASE_ID).toBe('kavacha-db');
    expect(DEFAULT_STORAGE_BUCKET).toBe('kavacha-store');
  });

  it('test_storageSignerAdapter_usesKavachaStoreBucketByDefault', async () => {
    const signer = new FirebaseStorageSignerAdapter();
    const putResult = await signer.generateSignedPutUrl({
      stayId: 'stay_villa_102_2026_10',
      requestId: 'req-towels',
      fileName: 'photo.jpg',
      contentType: 'image/jpeg',
      fileSizeBytes: 2048,
    });

    expect(putResult.uploadUrl).toContain('https://storage.googleapis.com/kavacha-store/');
  });

  it('test_stayRepository_supportsBothStayIdsForVilla102', async () => {
    const repo = new InMemorySeededStayRepository();
    const byCanonical = await repo.findByStayId('stay_2026_11_villa102_miller');
    const byOctId = await repo.findByStayId('stay_villa_102_2026_10');

    expect(byCanonical).not.toBeNull();
    expect(byOctId).not.toBeNull();
    expect(byOctId?.villaName).toBe('Villa 102');
  });
});
