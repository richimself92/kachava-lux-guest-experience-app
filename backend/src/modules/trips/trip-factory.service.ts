import { Inject, Injectable } from '@nestjs/common';
import * as crypto from 'crypto';
import { buildServiceSnapshot, resolveOrderLines, ResolvedLine } from '../../domain/catalog/catalog-rules';
import { CatalogService } from '../../domain/catalog/catalog.models';
import { BusinessRuleError, EntityNotFoundError } from '../../domain/domain-errors';
import { StayRecord } from '../../domain/models/domain.models';
import { ResortSettings } from '../../domain/models/resort-config.models';
import {
  SERVICE_ITEM_REPOSITORY_PORT,
  SERVICE_REPOSITORY_PORT,
  ServiceItemRepositoryPort,
  ServiceRepositoryPort,
} from '../../domain/ports/repository.ports';
import {
  assembleNewTrip,
  resolveSchedule,
  TripDetailsInput,
  TripScheduleInput,
} from '../../domain/trips/trip-assembly';
import { Trip, TripCreator, TripServiceSnapshot } from '../../domain/trips/trip.models';

export type TripRequestFields = TripScheduleInput & TripDetailsInput & { serviceId: string; itemId?: string };

export interface TripBuildRequest {
  fields: TripRequestFields;
  stay: StayRecord;
  settings: ResortSettings;
  createdBy: TripCreator;
  actor: string;
  now: Date;
}

export interface BuiltTrip {
  trip: Trip;
  service: CatalogService;
}

/**
 * Turns a trip request into a validated REQUESTED trip: an ACTIVE TRANSPORT service from the
 * catalog, an optional ACTIVE vehicle item of that service, the schedule from Settings and the
 * name/price/capacity snapshot. Nothing is persisted here.
 */
@Injectable()
export class TripFactory {
  constructor(
    @Inject(SERVICE_REPOSITORY_PORT) private readonly services: ServiceRepositoryPort,
    @Inject(SERVICE_ITEM_REPOSITORY_PORT) private readonly items: ServiceItemRepositoryPort,
  ) {}

  async build(request: TripBuildRequest): Promise<BuiltTrip> {
    const { fields, stay, now } = request;
    const service = await this.requireTransportService(fields.serviceId);
    const line = await this.resolveVehicle(service, fields.itemId);
    const schedule = resolveSchedule(fields, request.settings, service);
    const capturedAt = now.toISOString();
    const snapshot: TripServiceSnapshot = {
      ...buildServiceSnapshot(service, [line], fields.passengers, capturedAt),
      vehicleCapacity: line.item?.capacity ?? null,
    };
    const trip = assembleNewTrip({
      tripId: `trip_${crypto.randomUUID()}`,
      stay: { stayId: stay.stayId, villaId: stay.villaId, villaName: stay.villaName, guestName: stay.guestProfile.name },
      type: fields.type,
      schedule,
      details: fields,
      serviceId: service.serviceId,
      itemId: line.item?.itemId ?? null,
      snapshot,
      createdBy: request.createdBy,
      actor: request.actor,
      at: capturedAt,
    });
    return { trip, service };
  }

  private async requireTransportService(serviceId: string): Promise<CatalogService> {
    const service = await this.services.findById(serviceId);
    if (!service) throw new EntityNotFoundError('Service', serviceId);
    if (service.kind !== 'TRANSPORT') throw new BusinessRuleError(`Service ${serviceId} is not a transport service`);
    if (service.status !== 'ACTIVE') throw new BusinessRuleError(`Service ${serviceId} is not available`);
    return service;
  }

  /** The chosen vehicle must be an ACTIVE item of this service. */
  private async resolveVehicle(service: CatalogService, itemId: string | undefined): Promise<ResolvedLine> {
    if (!itemId) return { item: null, quantity: 1 };
    const item = await this.items.findById(itemId);
    if (!item || item.serviceId !== service.serviceId) throw new EntityNotFoundError('Item', itemId);
    return resolveOrderLines(service, [item], [{ itemId, quantity: 1 }])[0];
  }
}
