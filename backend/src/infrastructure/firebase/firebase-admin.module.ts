import { Global, Module, Provider } from '@nestjs/common';
import * as admin from 'firebase-admin';
import { Firestore, getFirestore } from 'firebase-admin/firestore';
import { getStorage } from 'firebase-admin/storage';
import { assertFirestoreTarget, isFirestoreFlagEnabled } from '../../common/config/runtime-flags';
import { REALTIME_SIGNAL_WRITER_PORT, RealtimeSignalWriterPort } from '../../domain/ports/realtime-signal.port';
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
  TASK_REPOSITORY_PORT,
  NOTIFICATION_READ_REPOSITORY_PORT,
  SERVICE_REQUEST_REPOSITORY_PORT,
  STAFF_ROSTER_REPOSITORY_PORT,
  TRIP_REPOSITORY_PORT,
  VILLA_REPOSITORY_PORT,
} from '../../domain/ports/repository.ports';
import { FirestoreNotificationReadRepository } from '../repositories/firestore-notification-read.repository';
import { FirestoreTaskRepository } from '../repositories/firestore-task.repository';
import { FirestoreAlertRepository } from '../repositories/firestore-alert.repository';
import { FirestoreEntityRepository } from '../repositories/firestore-entity.repository';
import { FirestoreSettingsRepository } from '../repositories/firestore-settings.repository';
import { FirestoreServiceRequestRepository } from '../repositories/firestore-service-request.repository';
import { FirestoreStaffRepository, STAFF_COLLECTION } from '../repositories/firestore-staff.repository';
import { FirestoreStayRepository, STAY_SCAN_LIMIT } from '../repositories/firestore-stay.repository';
import { FirestoreTripRepository } from '../repositories/firestore-trip.repository';
import { FirestoreRealtimeSignalWriter } from '../realtime/firestore-realtime-signal.writer';
import { RecordingRealtimeSignalWriter } from '../realtime/recording-realtime-signal.writer';
import { CatalogImageStorageAdapter } from '../storage/catalog-image-storage.adapter';
import {
  EmulatorObjectUrlSigner,
  GcsObjectUrlSigner,
  ObjectUrlSigner,
  SignableBucket,
} from '../storage/object-url-signer';
import { FirebaseStorageSignerAdapter } from '../storage/storage-signer.adapter';

export const DEFAULT_GCP_PROJECT_ID = 'kavacha-app';
export const DEFAULT_FIRESTORE_DATABASE_ID = 'kavacha-db';
export const DEFAULT_STORAGE_BUCKET = 'kavacha-store';

/** Injection tokens for the two external handles; tests replace exactly these with fakes. */
export const FIRESTORE_DB = Symbol('FIRESTORE_DB');
export const OBJECT_URL_SIGNER = Symbol('OBJECT_URL_SIGNER');

export const VILLAS_COLLECTION = 'villas';
export const TRANSPORT_PROVIDERS_COLLECTION = 'transport_providers';
export const CATALOG_SERVICES_COLLECTION = 'catalog_services';
export const CATALOG_ITEMS_COLLECTION = 'catalog_items';

function storageBucketName(): string {
  return process.env.FIREBASE_STORAGE_BUCKET || DEFAULT_STORAGE_BUCKET;
}

export function ensureFirebaseAdminApp(): admin.app.App {
  if (admin.apps.length > 0 && admin.apps[0]) return admin.apps[0];
  return admin.initializeApp({
    projectId: process.env.FIREBASE_PROJECT_ID || process.env.GOOGLE_CLOUD_PROJECT || DEFAULT_GCP_PROJECT_ID,
    storageBucket: storageBucketName(),
  });
}

/** Always Firestore: production services, or the emulators everywhere else (see assertFirestoreTarget). */
export function createFirestore(): Firestore {
  assertFirestoreTarget();
  return getFirestore(ensureFirebaseAdminApp(), process.env.FIRESTORE_DATABASE_ID || DEFAULT_FIRESTORE_DATABASE_ID);
}

export function createObjectUrlSigner(): ObjectUrlSigner {
  assertFirestoreTarget();
  const bucketName = storageBucketName();
  const emulatorHost = process.env.FIREBASE_STORAGE_EMULATOR_HOST;
  if (emulatorHost) return new EmulatorObjectUrlSigner(emulatorHost, bucketName);
  const bucket = getStorage(ensureFirebaseAdminApp()).bucket(bucketName) as unknown as SignableBucket;
  return new GcsObjectUrlSigner(bucket, bucketName);
}

/** ADR-012 signal documents in Firestore; an in-memory recorder when Firestore is off (tests). */
export function createRealtimeSignalWriter(db: Firestore): RealtimeSignalWriterPort {
  return isFirestoreFlagEnabled() ? new FirestoreRealtimeSignalWriter(db) : new RecordingRealtimeSignalWriter();
}

function firestoreBacked<T>(token: symbol, build: (db: Firestore) => T): Provider {
  return { provide: token, useFactory: build, inject: [FIRESTORE_DB] };
}

const providers: Provider[] = [
  { provide: FIRESTORE_DB, useFactory: createFirestore },
  { provide: OBJECT_URL_SIGNER, useFactory: createObjectUrlSigner },
  firestoreBacked(
    STAY_REPOSITORY_PORT,
    (db) => new FirestoreStayRepository(db, STAY_SCAN_LIMIT, async () => (await new FirestoreSettingsRepository(db).get()).timeZone),
  ),
  firestoreBacked(REALTIME_SIGNAL_WRITER_PORT, createRealtimeSignalWriter),
  firestoreBacked(SERVICE_REQUEST_REPOSITORY_PORT, (db) => new FirestoreServiceRequestRepository(db)),
  firestoreBacked(
    STAFF_ROSTER_REPOSITORY_PORT,
    (db) => new FirestoreEntityRepository(db, STAFF_COLLECTION, 'staffId', 'Staff member'),
  ),
  firestoreBacked(ALERT_REPOSITORY_PORT, (db) => new FirestoreAlertRepository(db)),
  firestoreBacked(STAFF_REPOSITORY_PORT, (db) => new FirestoreStaffRepository(db)),
  firestoreBacked(SETTINGS_REPOSITORY_PORT, (db) => new FirestoreSettingsRepository(db)),
  firestoreBacked(TRIP_REPOSITORY_PORT, (db) => new FirestoreTripRepository(db)),
  firestoreBacked(TASK_REPOSITORY_PORT, (db) => new FirestoreTaskRepository(db)),
  firestoreBacked(NOTIFICATION_READ_REPOSITORY_PORT, (db) => new FirestoreNotificationReadRepository(db)),
  firestoreBacked(VILLA_REPOSITORY_PORT, (db) => new FirestoreEntityRepository(db, VILLAS_COLLECTION, 'villaId', 'Villa')),
  firestoreBacked(
    TRANSPORT_PROVIDER_REPOSITORY_PORT,
    (db) => new FirestoreEntityRepository(db, TRANSPORT_PROVIDERS_COLLECTION, 'providerId', 'Transport provider'),
  ),
  firestoreBacked(
    SERVICE_REPOSITORY_PORT,
    (db) => new FirestoreEntityRepository(db, CATALOG_SERVICES_COLLECTION, 'serviceId', 'Service'),
  ),
  firestoreBacked(
    SERVICE_ITEM_REPOSITORY_PORT,
    (db) => new FirestoreEntityRepository(db, CATALOG_ITEMS_COLLECTION, 'itemId', 'Item'),
  ),
  {
    provide: STORAGE_SIGNER_PORT,
    useFactory: (signer: ObjectUrlSigner) => new FirebaseStorageSignerAdapter(signer),
    inject: [OBJECT_URL_SIGNER],
  },
  {
    provide: CATALOG_IMAGE_STORAGE_PORT,
    useFactory: (signer: ObjectUrlSigner) => new CatalogImageStorageAdapter(signer),
    inject: [OBJECT_URL_SIGNER],
  },
];

/** The only persistence wiring of the runtime: every repository is a Firestore adapter. */
@Global()
@Module({
  providers,
  exports: providers.map((p) => (p as { provide: symbol }).provide),
})
export class FirebaseInfrastructureModule {}
