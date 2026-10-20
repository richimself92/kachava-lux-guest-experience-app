import { Firestore, getFirestore } from 'firebase-admin/firestore';
import { StayAggregate } from '../domain/models/domain.models';
import {
  DEFAULT_FIRESTORE_DATABASE_ID,
  DEFAULT_GCP_PROJECT_ID,
  ensureFirebaseAdminApp,
} from '../infrastructure/firebase/firebase-admin.module';
import {
  SEEDED_EXPERIENCES_CATALOG,
  SEEDED_LARDER_CATALOG,
  SEEDED_STAFF_MEMBERS,
  SEEDED_YACHT_CATALOG,
} from '../infrastructure/seed/sanctuary-catalog.seed';
import {
  createSeededOperationalAlerts,
  createSeededStayAggregate,
} from '../infrastructure/seed/sanctuary-seed.data';

async function seedStayWithSubcollections(
  db: Firestore,
  stayDocId: string,
  stay: StayAggregate,
): Promise<void> {
  const {
    larderOrders,
    experienceBookings,
    conciergeRequests,
    midstayFeedback,
    folioItems,
    ...rootFields
  } = stay;

  const stayRef = db.collection('stays').doc(stayDocId);
  await stayRef.set({ ...rootFields, stayId: stayDocId }, { merge: true });

  const batch = db.batch();
  for (const item of larderOrders) {
    batch.set(stayRef.collection('larder_orders').doc(item.orderItemId), {
      ...item,
      stayId: stayDocId,
    });
  }
  for (const bk of experienceBookings) {
    batch.set(stayRef.collection('experience_bookings').doc(bk.bookingId), {
      ...bk,
      stayId: stayDocId,
    });
  }
  for (const req of conciergeRequests) {
    batch.set(stayRef.collection('concierge_requests').doc(req.requestId), {
      ...req,
      stayId: stayDocId,
    });
  }
  for (const fb of midstayFeedback) {
    batch.set(stayRef.collection('midstay_feedback').doc(fb.feedbackId), {
      ...fb,
      stayId: stayDocId,
    });
  }
  for (const fi of folioItems) {
    batch.set(stayRef.collection('folio_items').doc(fi.folioItemId), fi);
  }
  await batch.commit();
}

async function seedRootCollections(db: Firestore): Promise<void> {
  const batch = db.batch();

  for (const staff of SEEDED_STAFF_MEMBERS) {
    batch.set(db.collection('staff_members').doc(staff.staffId), staff);
  }
  for (const alert of createSeededOperationalAlerts()) {
    batch.set(db.collection('operational_alerts').doc(alert.alertId), alert);
  }
  for (const larder of SEEDED_LARDER_CATALOG) {
    batch.set(db.collection('catalog_larder').doc(larder.id), larder);
  }
  for (const exp of SEEDED_EXPERIENCES_CATALOG) {
    batch.set(db.collection('catalog_experiences').doc(exp.id), exp);
  }
  batch.set(
    db.collection('catalog_yacht').doc(SEEDED_YACHT_CATALOG.vesselId),
    SEEDED_YACHT_CATALOG,
  );
  batch.set(db.collection('catalog_villas').doc('villa-102'), {
    villaId: 'villa-102',
    villaName: 'Villa 102',
    suiteName: 'Ceiba Suite',
    sqft: '3,400 sq ft',
  });

  await batch.commit();
}

export async function runFirestoreSeed(): Promise<void> {
  const projectId =
    process.env.FIREBASE_PROJECT_ID ||
    process.env.GOOGLE_CLOUD_PROJECT ||
    DEFAULT_GCP_PROJECT_ID;
  const databaseId =
    process.env.FIRESTORE_DATABASE_ID || DEFAULT_FIRESTORE_DATABASE_ID;

  const app = ensureFirebaseAdminApp();
  const db = getFirestore(app, databaseId);

  const stayTemplate = createSeededStayAggregate();
  await seedStayWithSubcollections(db, 'stay_villa_102_2026_10', stayTemplate);
  await seedStayWithSubcollections(
    db,
    'stay_2026_11_villa102_miller',
    stayTemplate,
  );
  await seedRootCollections(db);

  process.stdout.write(
    `[Firestore Seed] Successfully seeded projects/${projectId}/databases/${databaseId} (stays, subcollections, staff_members, operational_alerts, catalogs).\n`,
  );
}

if (require.main === module) {
  runFirestoreSeed().catch((err: unknown) => {
    const message = err instanceof Error ? err.message : String(err);
    process.stderr.write(`[Firestore Seed Error] ${message}\n`);
    process.exit(1);
  });
}
