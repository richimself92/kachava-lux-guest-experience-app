import { Injectable } from '@nestjs/common';
import { StayAggregate } from '../../domain/models/domain.models';
import { StayAlertFactory } from '../../domain/ports/repository.ports';
import { createSeededStayAggregate } from '../seed/sanctuary-seed.data';
import {
  AggregateStayRepository,
  StayMutator,
  StayNotFoundError,
} from './aggregate-stay.repository';
import { InMemorySeededAlertRepository } from './in-memory-alert.repository';

const CANONICAL_VILLA_102_STAY_ID = 'stay_2026_11_villa102_miller';
const VILLA_102_STAY_ALIASES = new Set([CANONICAL_VILLA_102_STAY_ID, 'stay_villa_102_2026_10']);

/**
 * Process-local stay store for local development (`USE_FIRESTORE` unset) and tests. Seeded with
 * the Villa 102 demo stay. Never used in Firestore mode. Mutation alerts go to `alerts`, the
 * application's in-memory alert store, in the same synchronous step as the stay write.
 */
@Injectable()
export class InMemorySeededStayRepository extends AggregateStayRepository {
  private readonly stays = new Map<string, StayAggregate>();

  constructor(private readonly alerts = new InMemorySeededAlertRepository()) {
    super();
    const initial = createSeededStayAggregate();
    this.stays.set(initial.stayId, initial);
  }

  protected async findStayByToken(normalizedToken: string): Promise<StayAggregate | null> {
    const found = Array.from(this.stays.values()).find(
      (stay) => stay.guestTokenUuid.toLowerCase() === normalizedToken,
    );
    return found ? structuredClone(found) : null;
  }

  protected async findStay(stayId: string): Promise<StayAggregate | null> {
    const stay = this.stays.get(this.resolveCanonicalStayId(stayId));
    return stay ? structuredClone(stay) : null;
  }

  protected async listAllStays(): Promise<StayAggregate[]> {
    return Array.from(this.stays.values()).map((s) => structuredClone(s));
  }

  protected async insertStay(stay: StayAggregate): Promise<void> {
    this.stays.set(stay.stayId, structuredClone(stay));
  }

  protected async transactStay<T>(
    stayId: string,
    mutator: StayMutator<T>,
    alertOf?: StayAlertFactory<T>,
  ): Promise<T> {
    const key = this.resolveCanonicalStayId(stayId);
    const current = this.stays.get(key);
    if (!current) throw new StayNotFoundError(stayId);
    const draft = structuredClone(current);
    const result = mutator(draft);
    const alert = alertOf?.(result);
    this.stays.set(key, draft);
    if (alert) this.alerts.insertNow(alert);
    return result;
  }

  protected async deleteAllStays(): Promise<void> {
    this.stays.clear();
  }

  private resolveCanonicalStayId(stayId: string): string {
    if (VILLA_102_STAY_ALIASES.has(stayId) && !this.stays.has(stayId)) {
      return CANONICAL_VILLA_102_STAY_ID;
    }
    return stayId;
  }
}
