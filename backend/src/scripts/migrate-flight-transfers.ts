import type { Firestore } from 'firebase-admin/firestore';
import { assertFirestoreTarget } from '../common/config/runtime-flags';
import { StayAggregate } from '../domain/models/domain.models';
import { planLegacyArrival } from '../domain/trips/legacy-transfer-migration';
import { createFirestore } from '../infrastructure/firebase/firebase-admin.module';
import { FirestoreSettingsRepository } from '../infrastructure/repositories/firestore-settings.repository';
import { STAYS_COLLECTION } from '../infrastructure/repositories/firestore-stay.repository';
import { FirestoreTripRepository } from '../infrastructure/repositories/firestore-trip.repository';

/**
 * One-off, idempotent migration: each stay's legacy `flightTransfer` becomes an ARRIVAL trip in
 * `trips` (deterministic id, so re-runs skip it). Stays are never modified.
 *
 *   npm run migrate:flight-transfers -- --dry-run
 *
 * Same live-guard as the runtime (emulators outside production). Production additionally needs
 * `--allow-production`, which is only passed with the owner's explicit approval.
 */
export interface MigrationArgs {
  dryRun: boolean;
  allowProduction: boolean;
}

export interface MigrationReport {
  dryRun: boolean;
  scanned: number;
  /** Trip ids written (on --dry-run: the ids that would be written). */
  created: string[];
  alreadyMigrated: string[];
  skipped: Array<{ stayId: string; reason: string }>;
}

const FLAGS: Record<string, keyof MigrationArgs> = { '--dry-run': 'dryRun', '--allow-production': 'allowProduction' };

/** Unknown arguments fail, so a typo such as `--dryrun` can never run a real write. */
export function parseMigrationArgs(argv: string[]): MigrationArgs {
  const args: MigrationArgs = { dryRun: false, allowProduction: false };
  for (const arg of argv) {
    const flag = FLAGS[arg];
    if (!flag) throw new Error(`Unknown argument ${arg}. Use --dry-run and/or --allow-production.`);
    args[flag] = true;
  }
  return args;
}

export function assertMigrationTarget(env: Readonly<Record<string, string | undefined>>, args: MigrationArgs): void {
  assertFirestoreTarget(env);
  if (env.NODE_ENV === 'production' && !args.allowProduction) {
    throw new Error('Refusing to touch the live database without --allow-production (owner approval required).');
  }
}

export async function migrateFlightTransfers(
  db: Firestore,
  options: { dryRun: boolean; at: string },
): Promise<MigrationReport> {
  const settings = await new FirestoreSettingsRepository(db).get();
  const trips = new FirestoreTripRepository(db);
  const snapshot = await db.collection(STAYS_COLLECTION).get();
  const report: MigrationReport = { dryRun: options.dryRun, scanned: snapshot.docs.length, created: [], alreadyMigrated: [], skipped: [] };
  for (const doc of snapshot.docs) {
    const stay = { ...(doc.data() as StayAggregate), stayId: doc.id };
    const plan = planLegacyArrival(stay, settings, options.at);
    if ('skip' in plan) {
      report.skipped.push({ stayId: stay.stayId, reason: plan.skip });
    } else if (await trips.findById(plan.trip.tripId)) {
      report.alreadyMigrated.push(plan.trip.tripId);
    } else {
      if (!options.dryRun) await trips.create(plan.trip);
      report.created.push(plan.trip.tripId);
    }
  }
  return report;
}

async function main(): Promise<void> {
  const args = parseMigrationArgs(process.argv.slice(2));
  assertMigrationTarget(process.env, args);
  const report = await migrateFlightTransfers(createFirestore(), { dryRun: args.dryRun, at: new Date().toISOString() });
  process.stdout.write(`${JSON.stringify(report, null, 2)}\n`);
}

if (require.main === module) {
  main().catch((error: unknown) => {
    process.stderr.write(`[migrate-flight-transfers] ${error instanceof Error ? error.message : String(error)}\n`);
    process.exit(1);
  });
}
