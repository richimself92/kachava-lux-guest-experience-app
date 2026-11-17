import { Inject, Injectable } from '@nestjs/common';
import {
  ListQuery,
  ListQueryDto,
  paginateInMemory,
  PaginatedResult,
  toListQuery,
} from '../../common/listing/list-query';
import { definedFields } from '../../common/validation/patch';
import { BusinessRuleError, EntityNotFoundError } from '../../domain/domain-errors';
import { StayAggregate } from '../../domain/models/domain.models';
import { ResortSettings } from '../../domain/models/resort-config.models';
import { CLOCK_PORT, ClockPort } from '../../domain/ports/clock.port';
import {
  SETTINGS_REPOSITORY_PORT,
  SettingsRepositoryPort,
  STAY_REPOSITORY_PORT,
  StayRepositoryPort,
  TRANSPORT_PROVIDER_REPOSITORY_PORT,
  TransportProviderRepositoryPort,
  TRIP_REPOSITORY_PORT,
  TripDateField,
  TripRepositoryPort,
} from '../../domain/ports/repository.ports';
import { zonedDayWindow } from '../../domain/time/zoned-time';
import { newAlertId, tripAlert } from '../../domain/trips/trip-alerts';
import { applyTripPatch, TripPatch } from '../../domain/trips/trip-assembly';
import { filterTrips } from '../../domain/trips/trip-listing';
import { flightChanged, requireLeadHours, unconfirmedDueCutoff } from '../../domain/trips/trip-rules';
import { transitionTrip, TripTransitionCommand } from '../../domain/trips/trip-transitions';
import { AdminTripView, toAdminTripView } from '../../domain/trips/trip-views';
import { Trip } from '../../domain/trips/trip.models';
import { TaskAutomation } from '../tasks/task-automation.service';
import { TripFactory } from './trip-factory.service';
import {
  CreateAdminTripDto,
  TransitionTripDto,
  TripListDateField,
  TripListQueryDto,
  UpdateTripDto,
} from './trip.dto';

export const TRIP_LIST_SPEC = {
  sortable: ['pickupAt'],
  defaultSort: { field: 'pickupAt', direction: 'asc' as const },
};
const DATE_FIELDS: Record<TripListDateField, TripDateField> = { pickupAt: 'pickupAt', flightAt: 'flight.scheduledAt' };
const OPEN_STAY_STATUSES = ['PRE_ARRIVAL', 'ACTIVE_STAY'];

/** Staff trip operations: list, create on behalf of a guest, edit and move through statuses. */
@Injectable()
export class TripsAdminService {
  constructor(
    @Inject(TRIP_REPOSITORY_PORT) private readonly trips: TripRepositoryPort,
    @Inject(STAY_REPOSITORY_PORT) private readonly stays: StayRepositoryPort,
    @Inject(SETTINGS_REPOSITORY_PORT) private readonly settings: SettingsRepositoryPort,
    @Inject(TRANSPORT_PROVIDER_REPOSITORY_PORT) private readonly providers: TransportProviderRepositoryPort,
    @Inject(CLOCK_PORT) private readonly clock: ClockPort,
    private readonly factory: TripFactory,
    private readonly taskAutomation: TaskAutomation,
  ) {}

  async list(dto: TripListQueryDto): Promise<PaginatedResult<AdminTripView>> {
    const query = toListQuery(dto, TRIP_LIST_SPEC);
    const settings = await this.settings.get();
    const window = zonedDayWindow({ from: dto.from, to: dto.to }, settings.timeZone);
    const trips = await this.trips.listInWindow({ field: DATE_FIELDS[dto.dateField ?? 'pickupAt'], ...window });
    const { status, type, providerId, villaId } = dto;
    return this.page(filterTrips(trips, { status, type, providerId, villaId, q: query.q }), query, settings);
  }

  /** Not confirmed and picking up within `transportAlertLeadHours` (computed on read). */
  async listUnconfirmedDue(dto: ListQueryDto): Promise<PaginatedResult<AdminTripView>> {
    const query = toListQuery(dto, TRIP_LIST_SPEC);
    const settings = await this.settings.get();
    const cutoff = unconfirmedDueCutoff(this.clock.now(), requireLeadHours(settings));
    const trips = await this.trips.listUnconfirmedUntil(cutoff);
    return this.page(filterTrips(trips, { q: query.q }), query, settings);
  }

  async get(tripId: string): Promise<AdminTripView> {
    const trip = await this.trips.findById(tripId);
    if (!trip) throw new EntityNotFoundError('Trip', tripId);
    return this.view(trip, await this.settings.get());
  }

  async create(dto: CreateAdminTripDto, actor: string): Promise<AdminTripView> {
    const stay = await this.requireOpenStay(dto.stayId);
    if (dto.providerId) await this.assertProviderUsable(dto.providerId);
    const settings = await this.settings.get();
    const { trip } = await this.factory.build({ fields: dto, stay, settings, createdBy: 'STAFF', actor, now: this.clock.now() });
    const created = await this.trips.create(trip);
    await this.taskAutomation.forTrip(created, actor);
    return this.view(created, settings);
  }

  /** A flight change commits a TRANSFER/HIGH alert together with the trip. */
  async update(tripId: string, dto: UpdateTripDto, actor: string): Promise<AdminTripView> {
    const patch = definedFields(dto) as TripPatch;
    if (patch.providerId) await this.assertProviderUsable(patch.providerId);
    const settings = await this.settings.get();
    const at = this.clock.now().toISOString();
    const updated = await this.trips.update(
      tripId,
      (current) => applyTripPatch(current, patch, settings, actor, at),
      (next, previous) => (flightChanged(previous, next) ? tripAlert(next, 'FLIGHT_CHANGED', newAlertId(), at) : null),
    );
    return this.view(updated, settings);
  }

  async transition(tripId: string, dto: TransitionTripDto, actor: string): Promise<AdminTripView> {
    if (dto.providerId) await this.assertProviderUsable(dto.providerId);
    const command = definedFields(dto) as TripTransitionCommand;
    const at = this.clock.now().toISOString();
    const updated = await this.trips.update(tripId, (current) => transitionTrip(current, command, actor, at));
    return this.view(updated, await this.settings.get());
  }

  private page(trips: Trip[], query: ListQuery, settings: ResortSettings): PaginatedResult<AdminTripView> {
    const page = paginateInMemory(trips, { ...query, q: undefined }, {
      searchText: () => '',
      sortValue: (trip) => trip.pickupAt,
    });
    return new PaginatedResult(page.data.map((trip) => this.view(trip, settings)), page.meta);
  }

  private view(trip: Trip, settings: ResortSettings): AdminTripView {
    return toAdminTripView(trip, this.clock.now(), settings.transportAlertLeadHours);
  }

  private async requireOpenStay(stayId: string): Promise<StayAggregate> {
    const stay = await this.stays.findByStayId(stayId);
    if (!stay) throw new EntityNotFoundError('Stay', stayId);
    if (!OPEN_STAY_STATUSES.includes(stay.status)) {
      throw new BusinessRuleError(`Stay ${stayId} is ${stay.status}; trips need an upcoming or in-house stay`);
    }
    return stay;
  }

  private async assertProviderUsable(providerId: string): Promise<void> {
    const provider = await this.providers.findById(providerId);
    if (!provider) throw new BusinessRuleError(`Transport provider ${providerId} does not exist`);
    if (!provider.isActive) throw new BusinessRuleError(`Transport provider ${providerId} is not active`);
  }
}
