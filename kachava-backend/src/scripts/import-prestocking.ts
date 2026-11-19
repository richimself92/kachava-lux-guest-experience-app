import { plainToInstance, Type } from 'class-transformer';
import { ArrayMaxSize, IsArray, IsBoolean, IsOptional, validateSync, ValidateNested } from 'class-validator';
import * as crypto from 'crypto';
import * as fs from 'fs';
import type { Firestore } from 'firebase-admin/firestore';
import { CatalogItem, CatalogService } from '../domain/catalog/catalog.models';
import {
  planPrestockingImport,
  planStockingServicePatch,
  PrestockingRow,
  PrestockingServiceBlock,
} from '../domain/catalog/prestocking-import';
import {
  CATALOG_ITEMS_COLLECTION,
  CATALOG_SERVICES_COLLECTION,
  createFirestore,
} from '../infrastructure/firebase/firebase-admin.module';
import { FirestoreEntityRepository } from '../infrastructure/repositories/firestore-entity.repository';
import { CreateItemDto } from '../modules/catalog/dto/item.dto';
import { TermsTextDto } from '../modules/catalog/dto/service-blocks.dto';
import { assertMigrationTarget } from './migrate-flight-transfers';

/**
 * Upserts the pre-stocking catalog file into the single VILLA_STOCKING service (by SKU); every
 * other item of that service is DISABLED; an optional `service` block sets its terms and
 * substitution question through the normal service rules. Idempotent; `--dry-run` only prints the counts.
 *
 *   npm run import:prestocking -- --project <id> --file ../doc/catalog/prestocking-2027.json [--dry-run]
 *
 * Same live-guard as the runtime (emulators outside production via FIRESTORE_EMULATOR_HOST).
 * Writing to production additionally needs `--allow-production` (owner approval only).
 */
export interface ImportArgs {
  file: string;
  project: string;
  dryRun: boolean;
  allowProduction: boolean;
}

export interface ImportReport {
  dryRun: boolean;
  serviceId: string;
  /** The file's `service` block changed the service's terms or substitution question. */
  serviceUpdated: boolean;
  created: number;
  updated: number;
  disabled: number;
  unchanged: number;
}

const ACTOR = 'script:import-prestocking';
const ROWS_MAX = 1000;

const BOOLEAN_FLAGS: Record<string, 'dryRun' | 'allowProduction'> = { '--dry-run': 'dryRun', '--allow-production': 'allowProduction' };
const VALUE_FLAGS: Record<string, 'file' | 'project'> = { '--file': 'file', '--project': 'project' };

/** Unknown arguments fail, so a typo such as `--dryrun` can never run a real write. */
export function parseImportArgs(argv: string[]): ImportArgs {
  const args: Partial<ImportArgs> = { dryRun: false, allowProduction: false };
  for (let i = 0; i < argv.length; i += 1) {
    const arg = argv[i];
    if (BOOLEAN_FLAGS[arg]) args[BOOLEAN_FLAGS[arg]] = true;
    else if (VALUE_FLAGS[arg] && argv[i + 1] && !argv[i + 1].startsWith('--')) args[VALUE_FLAGS[arg]] = argv[++i];
    else throw new Error(`Invalid argument ${arg}. Use --file <json> --project <id> [--dry-run] [--allow-production].`);
  }
  if (!args.file) throw new Error('--file <json> is required.');
  if (!args.project) throw new Error('--project <id> is required (refusing to guess the target project).');
  return args as ImportArgs;
}

class PrestockingServiceDto {
  @IsOptional() @ValidateNested() @Type(() => TermsTextDto)
  terms?: TermsTextDto;

  @IsOptional() @IsBoolean()
  askSubstitutions?: boolean;
}

export interface PrestockingFile {
  service: PrestockingServiceBlock | null;
  rows: PrestockingRow[];
}

class PrestockingFileDto {
  @IsOptional() @ValidateNested() @Type(() => PrestockingServiceDto)
  service?: PrestockingServiceDto;

  @IsArray() @ArrayMaxSize(ROWS_MAX) @ValidateNested({ each: true }) @Type(() => CreateItemDto)
  items!: CreateItemDto[];
}

/** Fields the admin API leaves optional but every import row must carry. */
function missingFields(dto: CreateItemDto): string[] {
  return [
    ...(dto.sku?.trim() ? [] : ['sku']),
    ...(dto.category?.trim() ? [] : ['category']),
    ...(dto.name.en?.trim() && dto.name.es?.trim() ? [] : ['name.en/name.es']),
    ...(typeof dto.priceUSD === 'number' ? [] : ['priceUSD']),
    ...(typeof dto.order === 'number' ? [] : ['order']),
  ];
}

function rowOf(dto: CreateItemDto, index: number): PrestockingRow {
  const missing = missingFields(dto);
  if (missing.length > 0) throw new Error(`Row ${index + 1} (${dto.sku ?? 'no sku'}) needs ${missing.join(', ')}`);
  return {
    sku: (dto.sku as string).trim(), category: dto.category as string, name: { en: dto.name.en as string, es: dto.name.es as string },
    priceUSD: dto.priceUSD as number, netCostMXN: dto.netCostMXN ?? null, sourceUrl: dto.sourceUrl ?? null,
    pricingUnit: dto.pricingUnit ?? 'ITEM', portionOzOptions: dto.portionOzOptions ?? [], order: dto.order as number,
  };
}

function serviceBlockOf(dto: PrestockingServiceDto | undefined): PrestockingServiceBlock | null {
  if (!dto) return null;
  return {
    ...(dto.terms ? { terms: { en: dto.terms.en ?? '', es: dto.terms.es ?? '' } } : {}),
    ...(dto.askSubstitutions === undefined ? {} : { askSubstitutions: dto.askSubstitutions }),
  };
}

/** Validates the file with the same rules as the admin item API (4 decimals for per-ounce values). */
export function parsePrestockingFile(json: unknown): PrestockingFile {
  const file = plainToInstance(PrestockingFileDto, json);
  const errors = validateSync(file, { whitelist: true });
  if (errors.length > 0) throw new Error(`Invalid import file: ${JSON.stringify(errors.map((e) => e.toString()))}`);
  return { service: serviceBlockOf(file.service), rows: file.items.map(rowOf) };
}

async function stockingService(services: FirestoreEntityRepository<CatalogService>): Promise<CatalogService> {
  const stocking = await services.list({ kind: 'VILLA_STOCKING' });
  if (stocking.length !== 1) {
    throw new Error(`Expected exactly one VILLA_STOCKING service, found ${stocking.length}.`);
  }
  return stocking[0];
}

export async function importPrestocking(
  db: Firestore,
  file: PrestockingFile,
  options: { dryRun: boolean; actor: string; at: string },
): Promise<ImportReport> {
  const services = new FirestoreEntityRepository<CatalogService>(db, CATALOG_SERVICES_COLLECTION, 'serviceId', 'Service');
  const items = new FirestoreEntityRepository<CatalogItem>(db, CATALOG_ITEMS_COLLECTION, 'itemId', 'Item');
  const service = await stockingService(services);
  const { serviceId } = service;
  const patched = planStockingServicePatch(service, file.service, { updatedAt: options.at, updatedBy: options.actor });
  const plan = planPrestockingImport(await items.list({ serviceId }), file.rows, {
    serviceId, actor: options.actor, at: options.at, newId: () => crypto.randomUUID(),
  });
  if (!options.dryRun) {
    if (patched) await services.update(serviceId, () => patched);
    for (const item of plan.creates) await items.create(item);
    for (const item of [...plan.updates, ...plan.disables]) await items.update(item.itemId, () => item);
  }
  return { dryRun: options.dryRun, serviceId, serviceUpdated: patched !== null, ...plan.counts };
}

async function main(): Promise<void> {
  const args = parseImportArgs(process.argv.slice(2));
  process.env.FIREBASE_PROJECT_ID = args.project;
  // A dry run only reads, so it may inspect production; real writes there need --allow-production.
  assertMigrationTarget(process.env, { dryRun: args.dryRun, allowProduction: args.allowProduction || args.dryRun });
  const file = parsePrestockingFile(JSON.parse(fs.readFileSync(args.file, 'utf8')));
  const report = await importPrestocking(createFirestore(), file, { dryRun: args.dryRun, actor: ACTOR, at: new Date().toISOString() });
  process.stdout.write(`${JSON.stringify(report, null, 2)}\n`);
}

if (require.main === module) {
  main().catch((error: unknown) => {
    process.stderr.write(`[import-prestocking] ${error instanceof Error ? error.message : String(error)}\n`);
    process.exit(1);
  });
}
