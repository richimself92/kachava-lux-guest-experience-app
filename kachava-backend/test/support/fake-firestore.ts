import type { Firestore } from 'firebase-admin/firestore';

type DocumentData = Record<string, unknown>;
type CollectionStore = Map<string, DocumentData>;

type FilterOp = '==' | '>=' | '<=' | '>' | '<' | 'array-contains' | 'in';
const SUPPORTED_OPS: ReadonlySet<string> = new Set(['==', '>=', '<=', '>', '<', 'array-contains', 'in']);

interface QueryState {
  filters: Array<{ field: string; op: FilterOp; value: unknown }>;
  orders?: Array<{ field: string; direction: 'asc' | 'desc' }>;
  max?: number;
  skip?: number;
}

/** Firestore rejects documents above 1 MiB (1,048,576 bytes). */
export const FAKE_MAX_DOCUMENT_BYTES = 1_048_576;
/** The Admin SDK retries a contended transaction up to 5 attempts before failing with ABORTED. */
export const FAKE_TRANSACTION_MAX_ATTEMPTS = 5;
const GRPC_ABORTED = 10;
const GRPC_INVALID_ARGUMENT = 3;

/**
 * In-memory Firestore double for unit tests. Supports the subset of the Admin SDK used by the
 * repositories (doc get/set/create/delete, where with ==/range/in/array-contains on top-level or dotted map fields, orderBy,
 * offset, limit, count(), transactions, recursiveDelete) and lets tests inject read/write failures. Never touches the network.
 *
 * Transactions are optimistic: every document read through `tx.get` is version-checked at
 * commit; a conflicting commit is discarded and the transaction body re-runs (after a
 * deterministic backoff) up to `maxTransactionAttempts`, then fails with gRPC code 10 ABORTED,
 * so lost updates in repository code surface in tests. Writes above 1 MiB fail like the SDK.
 */
export class FakeFirestore {
  readonly collections = new Map<string, CollectionStore>();
  readonly versions = new Map<string, number>();
  queryCount = 0;
  transactionConflicts = 0;
  maxTransactionAttempts = FAKE_TRANSACTION_MAX_ATTEMPTS;
  private readFailure: Error | null = null;
  private writeFailure: Error | null = null;
  private writeFailureCollection: string | null = null;

  failReadsWith(error: Error | null): void {
    this.readFailure = error;
  }

  /** Fails every write, or only writes to `collection` when given. */
  failWritesWith(error: Error | null, collection: string | null = null): void {
    this.writeFailure = error;
    this.writeFailureCollection = collection;
  }

  asFirestore(): Firestore {
    return this as unknown as Firestore;
  }

  collection(name: string): FakeCollectionRef {
    return new FakeCollectionRef(this, name, { filters: [] });
  }

  async runTransaction<T>(work: (tx: FakeTransaction) => Promise<T>): Promise<T> {
    for (let attempt = 1; attempt <= this.maxTransactionAttempts; attempt += 1) {
      const tx = new FakeTransaction(this);
      const result = await work(tx);
      if (!tx.hasConflicts()) {
        tx.commit();
        return result;
      }
      this.transactionConflicts += 1;
      await yieldMacrotasks(this.transactionConflicts);
    }
    throw Object.assign(new Error('10 ABORTED: Too much contention on these documents.'), {
      code: GRPC_ABORTED,
    });
  }

  async recursiveDelete(ref: FakeCollectionRef): Promise<void> {
    this.assertWritable(ref.id);
    this.collections.delete(ref.id);
  }

  store(name: string): CollectionStore {
    const existing = this.collections.get(name);
    if (existing) return existing;
    const created: CollectionStore = new Map();
    this.collections.set(name, created);
    return created;
  }

  assertReadable(): void {
    if (this.readFailure) throw this.readFailure;
  }

  assertWritable(collection: string): void {
    if (!this.writeFailure) return;
    const scoped = this.writeFailureCollection;
    if (!scoped || scoped === collection) throw this.writeFailure;
  }

  versionOf(path: string): number {
    return this.versions.get(path) ?? 0;
  }

  bumpVersion(path: string): void {
    this.versions.set(path, this.versionOf(path) + 1);
  }
}

/** Deterministic, per-conflict-distinct backoff so retried transactions stop colliding. */
async function yieldMacrotasks(count: number): Promise<void> {
  for (let i = 0; i < count; i += 1) {
    await new Promise<void>((resolve) => setImmediate(resolve));
  }
}

class FakeTransaction {
  private readonly pending: Array<{ ref: FakeDocumentRef; write: () => void }> = [];
  private readonly readVersions = new Map<string, number>();

  constructor(private readonly db: FakeFirestore) {}

  async get(ref: FakeDocumentRef): Promise<FakeDocumentSnapshot> {
    this.readVersions.set(ref.path, this.db.versionOf(ref.path));
    return ref.get();
  }

  hasConflicts(): boolean {
    return Array.from(this.readVersions).some(([path, v]) => this.db.versionOf(path) !== v);
  }

  set(ref: FakeDocumentRef, data: DocumentData): this {
    assertWithinDocumentLimit(data);
    const copy = structuredClone(data);
    this.pending.push({ ref, write: () => ref.writeNow(copy) });
    return this;
  }

  delete(ref: FakeDocumentRef): this {
    this.pending.push({ ref, write: () => ref.deleteNow() });
    return this;
  }

  /** Atomic: every write is validated before any is applied. */
  commit(): void {
    this.pending.forEach(({ ref }) => this.db.assertWritable(ref.collectionId));
    this.pending.forEach(({ write }) => write());
  }
}

class FakeCollectionRef {
  constructor(
    private readonly db: FakeFirestore,
    readonly id: string,
    private readonly state: QueryState,
  ) {}

  doc(id: string): FakeDocumentRef {
    return new FakeDocumentRef(this.db, this.id, id);
  }

  where(field: string, op: string, value: unknown): FakeCollectionRef {
    if (!SUPPORTED_OPS.has(op)) throw new Error(`FakeFirestore does not support '${op}'`);
    const filters = [...this.state.filters, { field, op: op as FilterOp, value }];
    return new FakeCollectionRef(this.db, this.id, { ...this.state, filters });
  }

  offset(skip: number): FakeCollectionRef {
    return new FakeCollectionRef(this.db, this.id, { ...this.state, skip });
  }

  /** Aggregate count over the filters (ignores offset and limit, like the SDK's count()). */
  count(): { get(): Promise<{ data(): { count: number } }> } {
    return {
      get: async () => {
        this.db.assertReadable();
        this.db.queryCount += 1;
        const count = this.sorted(this.matchingEntries()).length;
        return { data: () => ({ count }) };
      },
    };
  }

  orderBy(field: string, direction: 'asc' | 'desc' = 'asc'): FakeCollectionRef {
    const orders = [...(this.state.orders ?? []), { field, direction }];
    return new FakeCollectionRef(this.db, this.id, { ...this.state, orders });
  }

  limit(max: number): FakeCollectionRef {
    return new FakeCollectionRef(this.db, this.id, { ...this.state, max });
  }

  async get(): Promise<{ empty: boolean; docs: FakeDocumentSnapshot[] }> {
    this.db.assertReadable();
    this.db.queryCount += 1;
    const docs = this.sorted(this.matchingEntries()).map(
      ([id, data]) => new FakeDocumentSnapshot(id, structuredClone(data)),
    );
    const skipped = docs.slice(this.state.skip ?? 0);
    const limited = this.state.max === undefined ? skipped : skipped.slice(0, this.state.max);
    return { empty: limited.length === 0, docs: limited };
  }

  private matchingEntries(): Array<[string, DocumentData]> {
    return Array.from(this.db.store(this.id).entries())
      .sort(([a], [b]) => a.localeCompare(b))
      .filter(([, data]) => this.state.filters.every((f) => matchesFilter(fieldValue(data, f.field), f.op, f.value)));
  }

  private sorted(entries: Array<[string, DocumentData]>): Array<[string, DocumentData]> {
    const orders = this.state.orders ?? [];
    if (orders.length === 0) return entries;
    // Like Firestore, documents missing an order-by field are excluded from the result.
    return entries
      .filter(([, data]) => orders.every((o) => fieldValue(data, o.field) !== undefined))
      .sort(([, a], [, b]) => {
        for (const o of orders) {
          const sign = o.direction === 'desc' ? -1 : 1;
          const diff = compareFieldValues(fieldValue(a, o.field), fieldValue(b, o.field));
          if (diff !== 0) return sign * diff;
        }
        return 0;
      });
  }

}

class FakeDocumentRef {
  constructor(
    private readonly db: FakeFirestore,
    readonly collectionId: string,
    readonly id: string,
  ) {}

  get path(): string {
    return `${this.collectionId}/${this.id}`;
  }

  async get(): Promise<FakeDocumentSnapshot> {
    this.db.assertReadable();
    const data = this.db.store(this.collectionId).get(this.id);
    return new FakeDocumentSnapshot(this.id, data ? structuredClone(data) : undefined);
  }

  async set(data: DocumentData): Promise<void> {
    this.db.assertWritable(this.collectionId);
    this.writeNow(data);
  }

  async create(data: DocumentData): Promise<void> {
    this.db.assertWritable(this.collectionId);
    if (this.db.store(this.collectionId).has(this.id)) {
      throw new Error(`ALREADY_EXISTS: ${this.collectionId}/${this.id}`);
    }
    this.writeNow(data);
  }

  async delete(): Promise<void> {
    this.db.assertWritable(this.collectionId);
    this.deleteNow();
  }

  writeNow(data: DocumentData): void {
    assertNoUndefinedValues(data);
    assertWithinDocumentLimit(data);
    this.db.store(this.collectionId).set(this.id, structuredClone(data));
    this.db.bumpVersion(this.path);
  }

  deleteNow(): void {
    this.db.store(this.collectionId).delete(this.id);
    this.db.bumpVersion(this.path);
  }
}

class FakeDocumentSnapshot {
  constructor(
    readonly id: string,
    private readonly payload: DocumentData | undefined,
  ) {}

  get exists(): boolean {
    return this.payload !== undefined;
  }

  data(): DocumentData | undefined {
    return this.payload ? structuredClone(this.payload) : undefined;
  }
}

/** Resolves a dotted field path (`flight.scheduledAt`) like Firestore does for map fields. */
function fieldValue(data: DocumentData, path: string): unknown {
  return path.split('.').reduce<unknown>(
    (value, key) => (value !== null && typeof value === 'object' ? (value as DocumentData)[key] : undefined),
    data,
  );
}

function compareFieldValues(a: unknown, b: unknown): number {
  if (typeof a === 'number' && typeof b === 'number') return a - b;
  const left = String(a);
  const right = String(b);
  if (left === right) return 0;
  return left < right ? -1 : 1;
}

function matchesFilter(actual: unknown, op: FilterOp, expected: unknown): boolean {
  switch (op) {
    case '==':
      return actual === expected;
    case 'in':
      return Array.isArray(expected) && expected.includes(actual);
    case 'array-contains':
      return Array.isArray(actual) && actual.includes(expected);
    default:
      if (actual === undefined || actual === null) return false;
      return compareRange(compareFieldValues(actual, expected), op);
  }
}

function compareRange(cmp: number, op: '>=' | '<=' | '>' | '<'): boolean {
  if (op === '>=') return cmp >= 0;
  if (op === '<=') return cmp <= 0;
  if (op === '>') return cmp > 0;
  return cmp < 0;
}

/** Mirrors the server, which rejects documents above 1 MiB with INVALID_ARGUMENT. */
function assertWithinDocumentLimit(data: DocumentData): void {
  const bytes = Buffer.byteLength(JSON.stringify(data));
  if (bytes <= FAKE_MAX_DOCUMENT_BYTES) return;
  throw Object.assign(
    new Error(
      `3 INVALID_ARGUMENT: Document cannot be written because its size (${bytes} bytes) exceeds the maximum allowed size of 1,048,576 bytes.`,
    ),
    { code: GRPC_INVALID_ARGUMENT },
  );
}

/** Mirrors the real SDK, which rejects `undefined` field values. */
function assertNoUndefinedValues(value: unknown, path = 'document'): void {
  if (value === undefined) {
    throw new Error(`Cannot use "undefined" as a Firestore value (found in field "${path}").`);
  }
  if (value === null || typeof value !== 'object') return;
  for (const [key, child] of Object.entries(value)) {
    assertNoUndefinedValues(child, `${path}.${key}`);
  }
}
