import { Inject, Injectable } from '@nestjs/common';
import { EntityConflictError } from '../../domain/domain-errors';
import { Villa } from '../../domain/models/resort-config.models';
import { CLOCK_PORT, ClockPort } from '../../domain/ports/clock.port';
import {
  SETTINGS_REPOSITORY_PORT,
  SettingsRepositoryPort,
  STAY_REPOSITORY_PORT,
  StayRepositoryPort,
  VILLA_REPOSITORY_PORT,
  VillaRepositoryPort,
} from '../../domain/ports/repository.ports';
import {
  assertBookableRange,
  isVillaInService,
  stayBlocksRange,
  StayNights,
} from '../../domain/stays/villa-availability';
import { resortDate } from '../../domain/time/zoned-time';

/** Wire shape of a bookable villa: the villa plus `id` (same as the villa list rows). */
export type AvailableVillaView = Villa & { id: string };

/**
 * Which villas can take a reservation for a night range. Reads only open stays that leave after
 * the arrival day (indexed status + [villaId +] checkOutDate query), never the whole collection.
 */
@Injectable()
export class VillaAvailabilityService {
  constructor(
    @Inject(SETTINGS_REPOSITORY_PORT) private readonly settings: SettingsRepositoryPort,
    @Inject(VILLA_REPOSITORY_PORT) private readonly villas: VillaRepositoryPort,
    @Inject(STAY_REPOSITORY_PORT) private readonly stays: StayRepositoryPort,
    @Inject(CLOCK_PORT) private readonly clock: ClockPort,
  ) {}

  /** In-service villas with no open stay on any of the requested nights, ordered by name. */
  async listAvailable(range: StayNights): Promise<AvailableVillaView[]> {
    const today = await this.assertRange(range);
    const [villas, open] = await Promise.all([
      this.villas.list({ isActive: true }),
      this.candidateStays(range),
    ]);
    const booked = new Set(open.filter((s) => stayBlocksRange(s, range, today)).map((s) => s.villaId));
    return villas
      .filter((v) => isVillaInService(v) && !booked.has(v.villaId))
      .sort((a, b) => a.name.localeCompare(b.name))
      .map((v) => ({ id: v.villaId, ...v }));
  }

  /** 422 for a past or empty range, 409 when another open stay holds one of the nights. */
  async assertVillaFree(villa: Villa, range: StayNights): Promise<void> {
    const today = await this.assertRange(range);
    const open = (await this.candidateStays(range)).filter((s) => s.villaId === villa.villaId);
    if (open.some((s) => stayBlocksRange(s, range, today))) {
      throw new EntityConflictError(`Villa ${villa.name} is already booked for these dates`);
    }
  }

  /** Resort today, once the range is valid. */
  private async assertRange(range: StayNights): Promise<string> {
    const { timeZone } = await this.settings.get();
    const today = resortDate(this.clock.now(), timeZone);
    assertBookableRange(range, today);
    return today;
  }

  /**
   * Open stays leaving after the arrival day, plus every in-house stay: an overstaying guest
   * (departure already past, not checked out) still holds the villa. In-house stays are at most
   * one per villa, so the extra read stays small.
   */
  private async candidateStays(range: StayNights) {
    const [leavingLater, inHouse] = await Promise.all([
      this.stays.listOpenStaysEndingAfter(range.checkIn),
      this.stays.listStaysByStatuses(['ACTIVE_STAY']),
    ]);
    const byId = new Map([...leavingLater, ...inHouse].map((s) => [s.stayId, s]));
    return [...byId.values()];
  }
}
