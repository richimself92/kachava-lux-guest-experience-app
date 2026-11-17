import type { DocumentReference, Firestore } from 'firebase-admin/firestore';
import { ResortSettings, unconfiguredSettings } from '../../domain/models/resort-config.models';
import { SettingsRepositoryPort } from '../../domain/ports/repository.ports';
import { toFirestoreDocument } from './firestore-document.mapper';

export const SETTINGS_COLLECTION = 'resort_settings';
export const SETTINGS_DOCUMENT_ID = 'current';

/** Single `resort_settings/current` document; absent fields read as "not configured" (null). */
export class FirestoreSettingsRepository implements SettingsRepositoryPort {
  constructor(private readonly db: Firestore) {}

  async get(): Promise<ResortSettings> {
    const snapshot = await this.ref().get();
    return withUnconfiguredFields(snapshot.exists ? snapshot.data() : undefined);
  }

  update(mutate: (current: ResortSettings) => ResortSettings): Promise<ResortSettings> {
    return this.db.runTransaction(async (tx) => {
      const snapshot = await tx.get(this.ref());
      const next = mutate(withUnconfiguredFields(snapshot.exists ? snapshot.data() : undefined));
      tx.set(this.ref(), toFirestoreDocument(next));
      return structuredClone(next);
    });
  }

  private ref(): DocumentReference {
    return this.db.collection(SETTINGS_COLLECTION).doc(SETTINGS_DOCUMENT_ID);
  }
}

function withUnconfiguredFields(stored: Record<string, unknown> | undefined): ResortSettings {
  return { ...unconfiguredSettings(), ...(stored as Partial<ResortSettings> | undefined) };
}
