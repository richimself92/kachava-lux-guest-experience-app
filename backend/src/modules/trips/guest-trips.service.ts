import { Inject, Injectable } from '@nestjs/common';
import { BusinessRuleError, EntityNotFoundError } from '../../domain/domain-errors';
import { GUEST_CANCELLATION_REASON } from '../../domain/stays/guest-request-rules';
import { StayAggregate } from '../../domain/models/domain.models';
import { CLOCK_PORT, ClockPort } from '../../domain/ports/clock.port';
import {
  SETTINGS_REPOSITORY_PORT,
  SettingsRepositoryPort,
  TRIP_REPOSITORY_PORT,
  TripRepositoryPort,
} from '../../domain/ports/repository.ports';
import { StayLimitExceededError } from '../../domain/stay-errors';
import { MAX_GUEST_TRIPS_PER_STAY } from '../../domain/stay-limits';
import { newAlertId, tripAlert } from '../../domain/trips/trip-alerts';
import { assertGuestLeadTime } from '../../domain/trips/trip-rules';
import { transitionTrip } from '../../domain/trips/trip-transitions';
import { GuestTripView, toGuestTripView } from '../../domain/trips/trip-views';
import { isAirportTrip, Trip } from '../../domain/trips/trip.models';
import { TaskAutomation } from '../tasks/task-automation.service';
import { TripFactory } from './trip-factory.service';
import { CreateGuestTripDto } from './trip.dto';

/**
 * Guest self-service trips. Requests must use an ACTIVE transport service and respect its
 * `minLeadHours`; airport pickups are always computed by the resort. Every request commits a
 * TRANSFER/HIGH alert with the trip. Responses are the guest-safe projection only.
 */
@Injectable()
export class GuestTripsService {
  constructor(
    @Inject(TRIP_REPOSITORY_PORT) private readonly trips: TripRepositoryPort,
    @Inject(SETTINGS_REPOSITORY_PORT) private readonly settings: SettingsRepositoryPort,
    @Inject(CLOCK_PORT) private readonly clock: ClockPort,
    private readonly factory: TripFactory,
    private readonly taskAutomation: TaskAutomation,
  ) {}

  async create(stay: StayAggregate, dto: CreateGuestTripDto): Promise<GuestTripView> {
    if (isAirportTrip(dto.type) && dto.pickupAt) {
      throw new BusinessRuleError('Invalid trip', ['pickupAt is set by the resort for airport trips']);
    }
    const existing = await this.trips.listForStay(stay.stayId);
    if (existing.length >= MAX_GUEST_TRIPS_PER_STAY) throw new StayLimitExceededError('trips', MAX_GUEST_TRIPS_PER_STAY);
    const now = this.clock.now();
    const { trip, service } = await this.factory.build({
      fields: dto, stay, settings: await this.settings.get(), createdBy: 'GUEST', actor: `guest:${stay.stayId}`, now,
    });
    assertGuestLeadTime(trip.pickupAt, now, service.availability.minLeadHours);
    const created = await this.trips.create(trip, tripAlert(trip, 'REQUESTED', newAlertId(), now.toISOString()));
    await this.taskAutomation.forTrip(created, created.createdByActor);
    return toGuestTripView(created);
  }

  /** Guest cancel while REQUESTED (422 once sent to the provider; 404 for another stay's trip). */
  async cancel(stay: StayAggregate, tripId: string): Promise<GuestTripView> {
    const trip = await this.trips.findById(tripId);
    if (!trip || trip.stayId !== stay.stayId) throw new EntityNotFoundError('Trip', tripId);
    const actor = `guest:${stay.stayId}`;
    const at = this.clock.now().toISOString();
    const cancelled = await this.trips.update(
      tripId,
      (current) => this.cancelRequested(current, actor, at),
      (next) => tripAlert(next, 'GUEST_CANCELLED', newAlertId(), at),
    );
    await this.taskAutomation.cancelForSource('TRIP', tripId, GUEST_CANCELLATION_REASON, actor);
    return toGuestTripView(cancelled);
  }

  private cancelRequested(trip: Trip, actor: string, at: string): Trip {
    if (trip.status !== 'REQUESTED') {
      throw new BusinessRuleError(`Trip is ${trip.status}; only a REQUESTED trip can be cancelled by the guest`);
    }
    return transitionTrip(trip, { to: 'CANCELLED', reason: GUEST_CANCELLATION_REASON }, actor, at);
  }

  async list(stay: StayAggregate): Promise<GuestTripView[]> {
    const trips = await this.trips.listForStay(stay.stayId);
    return trips.sort((a, b) => a.pickupAt.localeCompare(b.pickupAt)).map(toGuestTripView);
  }
}
