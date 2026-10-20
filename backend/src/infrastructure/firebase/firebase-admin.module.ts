import { Global, Module, OnModuleInit } from '@nestjs/common';
import * as admin from 'firebase-admin';
import { Firestore, getFirestore } from 'firebase-admin/firestore';
import {
  ALERT_REPOSITORY_PORT,
  CATALOG_REPOSITORY_PORT,
  STAFF_REPOSITORY_PORT,
  STAY_REPOSITORY_PORT,
  STORAGE_SIGNER_PORT,
} from '../../domain/ports/repository.ports';
import { FirestoreStayRepositoryAdapter } from '../repositories/firestore-stay.repository';
import { InMemorySeededAlertRepository } from '../repositories/in-memory-alert.repository';
import { InMemorySeededCatalogRepository } from '../repositories/in-memory-catalog.repository';
import { InMemorySeededStaffRepository } from '../repositories/in-memory-staff.repository';
import { InMemorySeededStayRepository } from '../repositories/in-memory-stay.repository';
import { FirebaseStorageSignerAdapter } from '../storage/storage-signer.adapter';

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

export function getNamedFirestoreDb(): Firestore | null {
  const isFirestoreEnabled =
    process.env.NODE_ENV !== 'test' &&
    (process.env.USE_FIRESTORE === 'true' ||
      process.env.USE_GCP_FIRESTORE === 'true');

  if (!isFirestoreEnabled) {
    return null;
  }
  const app = ensureFirebaseAdminApp();
  const databaseId =
    process.env.FIRESTORE_DATABASE_ID || DEFAULT_FIRESTORE_DATABASE_ID;
  return getFirestore(app, databaseId);
}

@Global()
@Module({
  providers: [
    InMemorySeededStayRepository,
    FirestoreStayRepositoryAdapter,
    InMemorySeededCatalogRepository,
    InMemorySeededAlertRepository,
    InMemorySeededStaffRepository,
    FirebaseStorageSignerAdapter,
    {
      provide: STAY_REPOSITORY_PORT,
      useExisting: FirestoreStayRepositoryAdapter,
    },
    {
      provide: CATALOG_REPOSITORY_PORT,
      useExisting: InMemorySeededCatalogRepository,
    },
    {
      provide: ALERT_REPOSITORY_PORT,
      useExisting: InMemorySeededAlertRepository,
    },
    {
      provide: STAFF_REPOSITORY_PORT,
      useExisting: InMemorySeededStaffRepository,
    },
    {
      provide: STORAGE_SIGNER_PORT,
      useExisting: FirebaseStorageSignerAdapter,
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
    if (
      process.env.NODE_ENV !== 'test' &&
      (process.env.USE_FIRESTORE === 'true' ||
        process.env.USE_GCP_FIRESTORE === 'true')
    ) {
      ensureFirebaseAdminApp();
    }
  }
}
