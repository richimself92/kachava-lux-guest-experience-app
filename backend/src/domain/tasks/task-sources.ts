import { CatalogService } from '../catalog/catalog.models';
import { ExperienceBooking, StayRecord } from '../models/domain.models';
import { orderRefId } from '../stays/open-requests';
import { zonedLocalToUtc } from '../time/zoned-time';
import { Trip } from '../trips/trip.models';
import { sourceTaskId, Task, TaskPriority, TaskSource } from './task.models';

/**
 * Builders of the tasks that guest/staff activity generates automatically. Each source maps to a
 * deterministic task id (`sourceTaskId`), so creating it twice is a no-op (idempotent per source).
 */
export interface TaskSchedule {
  timeZone: string | null;
  checkInTime: string | null;
}

interface SourceTaskFields {
  title: string;
  source: TaskSource & { refId: string };
  stay: Pick<StayRecord, 'villaId' | 'villaName'> & { guestName: string };
  category: string;
  priority: TaskPriority;
  dueAt: string | null;
  ownerStaffId: string | null;
}

const TIME_OF_DAY = /^([01]\d|2[0-3]):[0-5]\d$/;

/** A resort wall time as a UTC instant; null (no deadline) when the zone or date is unknown. */
export function resortWallTimeIso(
  date: string | undefined,
  time: string | null | undefined,
  timeZone: string | null,
): string | null {
  if (!date || !timeZone) return null;
  const clock = time && TIME_OF_DAY.test(time) ? time : '00:00';
  return zonedLocalToUtc(`${date}T${clock}`, timeZone).toISOString();
}

function checkInDeadline(stay: StayRecord, schedule: TaskSchedule): string | null {
  return resortWallTimeIso(stay.checkInDate, schedule.checkInTime, schedule.timeZone);
}

function stayParty(stay: StayRecord) {
  return { villaId: stay.villaId, villaName: stay.villaName, guestName: stay.guestProfile.name };
}

function newSourceTask(fields: SourceTaskFields, actor: string, at: string): Task {
  const owner = fields.ownerStaffId?.trim() || null;
  const status = owner ? 'ASSIGNED' : 'PENDING';
  return {
    taskId: sourceTaskId(fields.source.type, fields.source.refId),
    title: fields.title,
    source: { ...fields.source },
    villaId: fields.stay.villaId,
    villaName: fields.stay.villaName,
    guestName: fields.stay.guestName,
    category: fields.category,
    ownerStaffId: owner,
    ownerName: null,
    priority: fields.priority,
    dueAt: fields.dueAt,
    status,
    completion: null,
    cancellationReason: null,
    statusHistory: [{ from: null, to: status, at, by: actor }],
    createdAt: at,
    createdBy: actor,
    updatedAt: at,
    updatedBy: actor,
  };
}

export interface BookingTaskRequest {
  stay: StayRecord;
  booking: ExperienceBooking;
  service: CatalogService;
  schedule: TaskSchedule;
  actor: string;
  at: string;
}

/**
 * A preference choice becomes a preparation task due at check-in; a booking whose service
 * requires confirmation becomes a confirmation task due at its slot. Anything else: no task.
 */
export function bookingTaskFor(request: BookingTaskRequest): Task | null {
  const { stay, booking, service, schedule } = request;
  const owner = service.operation.responsibleStaffId;
  if (booking.usageType === 'PREFERENCE') {
    return newSourceTask({
      title: `Prepare: ${booking.title}`,
      source: { type: 'PREFERENCE', refId: booking.bookingId, stayId: stay.stayId },
      stay: stayParty(stay), category: service.section, priority: 'NORMAL',
      dueAt: checkInDeadline(stay, schedule), ownerStaffId: owner,
    }, request.actor, request.at);
  }
  if (booking.usageType !== 'BOOKING' || !service.operation.requiresConfirmation) return null;
  return newSourceTask({
    title: `Confirm: ${booking.title}`,
    source: { type: 'BOOKING', refId: booking.bookingId, stayId: stay.stayId },
    stay: stayParty(stay), category: service.section, priority: 'NORMAL',
    dueAt: resortWallTimeIso(booking.scheduledDate, booking.scheduledTimeSlot, schedule.timeZone),
    ownerStaffId: owner,
  }, request.actor, request.at);
}

export interface OrderTaskRequest {
  stay: StayRecord;
  service: CatalogService;
  lineCount: number;
  schedule: TaskSchedule;
  actor: string;
  at: string;
}

/** A villa-stocking order: one task per stay and service, due at check-in. */
export function orderTaskFor(request: OrderTaskRequest): Task {
  const { stay, service } = request;
  return newSourceTask({
    title: `Stock villa: ${service.name.en} (${request.lineCount} items)`,
    source: { type: 'ORDER', refId: orderRefId(stay.stayId, service.serviceId), stayId: stay.stayId },
    stay: stayParty(stay), category: service.section, priority: 'NORMAL',
    dueAt: checkInDeadline(stay, request.schedule), ownerStaffId: service.operation.responsibleStaffId,
  }, request.actor, request.at);
}

/** Every trip needs coordination with the provider before its pickup. */
export function tripTaskFor(trip: Trip, actor: string, at: string): Task {
  return newSourceTask({
    title: `Coordinate ${trip.type.toLowerCase()} trip`,
    source: { type: 'TRIP', refId: trip.tripId, stayId: trip.stayId },
    stay: { villaId: trip.villaId, villaName: trip.villaName, guestName: trip.guestName },
    category: 'TRANSPORTATION', priority: 'HIGH', dueAt: trip.pickupAt, ownerStaffId: null,
  }, actor, at);
}
