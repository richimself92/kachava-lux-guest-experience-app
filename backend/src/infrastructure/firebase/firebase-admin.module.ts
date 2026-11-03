import { Global, Module, OnModuleInit } from '@nestjs/common';
import * as admin from 'firebase-admin';
import { Firestore, getFirestore } from 'firebase-admin/firestore';
import { getStorage } from 'firebase-admin/storage';
import { isFirestoreFlagEnabled } from '../../common/config/runtime-flags';
import {
  ALERT_REPOSITORY_PORT,
  AlertRepositoryPort,
  CATALOG_REPOSITORY_PORT,
  STAFF_REPOSITORY_PORT,
  STAY_REPOSITORY_PORT,
  STORAGE_SIGNER_PORT,
} from '../../domain/ports/repository.ports';
import { InMemorySeededStaffRepository } from '../repositories/in-memory-staff.repository';
import { FirebaseStorageSignerAdapter } from '../storage/storage-signer.adapter';
import {
  createAlertRepository,
  createCatalogRepository,
  createStayRepository,
} from './repository.providers';

export const DEFAULT_GCP_PROJECT_ID = 'kavacha-app';
export const DEFAULT_FIRESTORE_DATABASE_ID = 'kavacha-db';
export const DEFAULT_STORAGE_BUCKET = 'kavacha-store';

export function ensureFirebaseAdminApp(): admin.app.App {
  const projectId =
    process.env.FIREBASE_PROJECT_ID ||
    process.env.GOOGLE_CLOUD_PROJECT ||
    DEFAULT_GCP_PROJECT_ID;
  const storageBucket =
    process.env.FIREBASE_STORAGE_BUCKET || DEFAULT_STORAGE_BUCKET;

  if (admin.apps.length > 0 && admin.apps[0]) {
    return admin.apps[0];
  }
  return admin.initializeApp({
    projectId,
    storageBucket,
  });
}

function isFirestoreModeEnabled(): boolean {
  return process.env.NODE_ENV !== 'test' && isFirestoreFlagEnabled();
}

export function getNamedFirestoreDb(): Firestore | null {
  if (!isFirestoreModeEnabled()) {
    return null;
  }
  const app = ensureFirebaseAdminApp();
  const databaseId =
    process.env.FIRESTORE_DATABASE_ID || DEFAULT_FIRESTORE_DATABASE_ID;
  return getFirestore(app, databaseId);
}

/** Firestore mode signs with the real bucket; in-memory mode issues local-development URLs. */
export function createStorageSigner(): FirebaseStorageSignerAdapter {
  if (!isFirestoreModeEnabled()) {
    return new FirebaseStorageSignerAdapter(null);
  }
  const bucketName =
    process.env.FIREBASE_STORAGE_BUCKET || DEFAULT_STORAGE_BUCKET;
  return new FirebaseStorageSignerAdapter(
    getStorage(ensureFirebaseAdminApp()).bucket(bucketName),
  );
}

@Global()
@Module({
  providers: [
    InMemorySeededStaffRepository,
    {
      provide: STAY_REPOSITORY_PORT,
      useFactory: (alerts: AlertRepositoryPort) =>
        createStayRepository(getNamedFirestoreDb(), alerts),
      inject: [ALERT_REPOSITORY_PORT],
    },
    {
      provide: CATALOG_REPOSITORY_PORT,
      useFactory: () => createCatalogRepository(getNamedFirestoreDb()),
    },
    {
      provide: ALERT_REPOSITORY_PORT,
      useFactory: () => createAlertRepository(getNamedFirestoreDb()),
    },
    {
      provide: STAFF_REPOSITORY_PORT,
      useExisting: InMemorySeededStaffRepository,
    },
    {
      provide: STORAGE_SIGNER_PORT,
      useFactory: createStorageSigner,
    },
  ],
  exports: [
    STAY_REPOSITORY_PORT,
    CATALOG_REPOSITORY_PORT,
    ALERT_REPOSITORY_PORT,
    STAFF_REPOSITORY_PORT,
    STORAGE_SIGNER_PORT,
  ],
})
export class FirebaseInfrastructureModule implements OnModuleInit {
  onModuleInit(): void {
    if (isFirestoreModeEnabled()) {
      ensureFirebaseAdminApp();
    }
  }
}
