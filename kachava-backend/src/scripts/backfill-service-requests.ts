import type { Firestore } from 'firebase-admin/firestore';
import { StayAggregate } from '../domain/models/domain.models';
import { projectServiceRequests } from '../domain/requests/service-requests';
import { createFirestore } from '../infrastructure/firebase/firebase-admin.module';
import { ServiceRequestIndexWriter } from '../infrastructure/repositories/firestore-service-request.repository';
import { FirestoreSettingsRepository } from '../infrastructure/repositories/firestore-settings.repository';
import { STAYS_COLLECTION } from '../infrastructure/repositories/firestore-stay.repository';
import { assertMigrationTarget, parseMigrationArgs } from './migrate-flight-transfers';

/**
 * One-off, idempotent backfill of the section request queues (`service_requests`) from the
 * bookings and orders already stored in each stay. Stays are never modified.
 *
 *   npm run backfill:service-requests -- --dry-run
 *
 * Production additionally needs `--allow-production` (owner approval only).
 */
export interface BackfillReport {
  dryRun: boolean;
  scanned: number;
  /** Request ids written (on --dry-run: the ids that would be written). */
  written: string[];
}

function withLists(id: string, data: Record<string, unknown>): StayAggregate {
  return {
    larderOrders: [], experienceBookings: [], conciergeRequests: [], midstayFeedback: [], folioItems: [],
    ...(data as Partial<StayAggregate>),
    stayId: id,
  } as StayAggregate;
}

export async function backfillServiceRequests(db: Firestore, options: { dryRun: boolean }): Promise<BackfillReport> {
  const timeZone = (await new FirestoreSettingsRepository(db).get()).timeZone;
  const writer = new ServiceRequestIndexWriter(db, async () => timeZone);
  const snapshot = await db.collection(STAYS_COLLECTION).get();
  const report: BackfillReport = { dryRun: options.dryRun, scanned: snapshot.docs.length, written: [] };
  for (const doc of snapshot.docs) {
    const stay = withLists(doc.id, doc.data());
    const entries = projectServiceRequests(stay, timeZone);
    if (entries.length === 0) continue;
    if (!options.dryRun) {
      const write = await writer.prepare(null, stay);
      await db.runTransaction(async (tx) => write(tx));
    }
    report.written.push(...entries.map((e) => e.requestId));
  }
  return report;
}

async function main(): Promise<void> {
  const args = parseMigrationArgs(process.argv.slice(2));
  assertMigrationTarget(process.env, args);
  const report = await backfillServiceRequests(createFirestore(), { dryRun: args.dryRun });
  process.stdout.write(`${JSON.stringify(report, null, 2)}\n`);
}

if (require.main === module) {
  main().catch((error: unknown) => {
    process.stderr.write(`${error instanceof Error ? error.message : String(error)}\n`);
    process.exitCode = 1;
  });
}
