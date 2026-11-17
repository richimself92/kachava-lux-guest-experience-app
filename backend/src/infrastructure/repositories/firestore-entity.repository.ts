import type { CollectionReference, Firestore, Query } from 'firebase-admin/firestore';
import { EntityNotFoundError, ListScanLimitError } from '../../domain/domain-errors';
import { EntityFilter, EntityRepositoryPort } from '../../domain/ports/repository.ports';
import { toFirestoreDocument } from './firestore-document.mapper';

/** Upper bound of documents one admin list request may read from a configuration collection. */
export const CONFIG_SCAN_LIMIT = 1000;

/**
 * One document per entity in `collection/{id}`. Reads hit Firestore on every call (no process
 * cache), writes are awaited, updates run in a transaction and errors propagate to the caller.
 */
export class FirestoreEntityRepository<T extends object> implements EntityRepositoryPort<T> {
  constructor(
    private readonly db: Firestore,
    private readonly collectionName: string,
    private readonly idField: keyof T & string,
    private readonly entityLabel: string,
    private readonly scanLimit = CONFIG_SCAN_LIMIT,
  ) {}

  async list(filter: EntityFilter = {}): Promise<T[]> {
    let query: Query = this.collection();
    for (const [field, value] of Object.entries(filter)) {
      if (value !== undefined) query = query.where(field, '==', value);
    }
    const snapshot = await query.limit(this.scanLimit + 1).get();
    if (snapshot.docs.length > this.scanLimit) {
      throw new ListScanLimitError(this.collectionName, this.scanLimit);
    }
    return snapshot.docs.map((doc) => doc.data() as T);
  }

  async findById(id: string): Promise<T | null> {
    const snapshot = await this.collection().doc(id).get();
    return snapshot.exists ? (snapshot.data() as T) : null;
  }

  async create(entity: T): Promise<T> {
    const id = String(entity[this.idField]);
    await this.collection().doc(id).create(toFirestoreDocument(entity));
    return structuredClone(entity);
  }

  update(id: string, mutate: (current: T) => T): Promise<T> {
    return this.db.runTransaction(async (tx) => {
      const ref = this.collection().doc(id);
      const snapshot = await tx.get(ref);
      if (!snapshot.exists) throw new EntityNotFoundError(this.entityLabel, id);
      const next = { ...mutate(snapshot.data() as T), [this.idField]: id } as T;
      tx.set(ref, toFirestoreDocument(next));
      return structuredClone(next);
    });
  }

  async delete(id: string): Promise<void> {
    await this.collection().doc(id).delete();
  }

  private collection(): CollectionReference {
    return this.db.collection(this.collectionName);
  }
}
