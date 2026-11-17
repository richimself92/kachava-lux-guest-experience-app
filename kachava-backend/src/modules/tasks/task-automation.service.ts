import { Inject, Injectable } from '@nestjs/common';
import { CatalogService } from '../../domain/catalog/catalog.models';
import { ExperienceBooking, StayRecord } from '../../domain/models/domain.models';
import { CLOCK_PORT, ClockPort } from '../../domain/ports/clock.port';
import { EntityNotFoundError } from '../../domain/domain-errors';
import {
  SERVICE_REQUEST_REPOSITORY_PORT,
  ServiceRequestRepositoryPort,
  SETTINGS_REPOSITORY_PORT,
  SettingsRepositoryPort,
  STAY_REPOSITORY_PORT,
  StayRepositoryPort,
  TASK_REPOSITORY_PORT,
  TaskRepositoryPort,
} from '../../domain/ports/repository.ports';
import { RequestRef } from '../../domain/requests/request-transitions';
import { ServiceRequestEntry } from '../../domain/requests/service-requests';
import {
  bookingTaskFor,
  orderTaskFor,
  requestTaskFor,
  requestUsageType,
  resortWallTimeIso,
  TaskSchedule,
  tripTaskFor,
} from '../../domain/tasks/task-sources';
import { applyTaskPatch, transitionTask } from '../../domain/tasks/task-transitions';
import { isFinalTaskStatus, sourceTaskId, Task, TaskSourceType } from '../../domain/tasks/task.models';
import { Trip } from '../../domain/trips/trip.models';

/**
 * Creates the operational task a guest or staff action implies (preference choice, stocking
 * order, booking that needs confirmation, trip). Runs after the source record is committed and
 * is idempotent per source (deterministic task id), so a retried request never duplicates it.
 */
@Injectable()
export class TaskAutomation {
  constructor(
    @Inject(TASK_REPOSITORY_PORT) private readonly tasks: TaskRepositoryPort,
    @Inject(SETTINGS_REPOSITORY_PORT) private readonly settings: SettingsRepositoryPort,
    @Inject(CLOCK_PORT) private readonly clock: ClockPort,
    @Inject(SERVICE_REQUEST_REPOSITORY_PORT) private readonly requests: ServiceRequestRepositoryPort,
    @Inject(STAY_REPOSITORY_PORT) private readonly stays: StayRepositoryPort,
  ) {}

  /** "Create task" of an inbox request: its source task, created once (idempotent). */
  async ensureForRequest(requestId: string, actor: string): Promise<Task> {
    const entry = await this.requests.findById(requestId);
    if (!entry) throw new EntityNotFoundError('Request', requestId);
    const stay = await this.stays.findByStayId(entry.stayId);
    if (!stay) throw new EntityNotFoundError('Stay', entry.stayId);
    return this.ensure(requestTaskFor({ stay, entry, schedule: await this.schedule(), actor, at: this.now() }));
  }

  /** A request staff cancelled cancels its open task (no task or a closed one: no-op). */
  cancelForRequest(entry: Pick<ServiceRequestEntry, 'kind' | 'usageType' | 'requestId'>, reason: string, actor: string) {
    return this.cancelForSource(requestUsageType(entry), entry.requestId, reason, actor);
  }

  /**
   * A completed task of a guest request moves that request to done (confirming it first when it
   * is still new). Request moves never touch tasks, so this cannot loop; a closed request is left.
   */
  async completeRequestOf(task: Task): Promise<void> {
    const { type, refId, stayId } = task.source;
    if (!refId || !stayId || !['ORDER', 'BOOKING', 'PREFERENCE'].includes(type)) return;
    const entry = await this.requests.findById(refId);
    if (!entry || !entry.open) return;
    const ref: RequestRef = entry.kind === 'ORDER' ? { kind: 'ORDER', id: entry.serviceId } : { kind: 'BOOKING', id: refId };
    if (entry.status === 'RECEIVED') {
      await this.stays.transitionServiceRequest(stayId, ref, { action: 'CONFIRM', at: this.now() });
    }
    await this.stays.transitionServiceRequest(stayId, ref, { action: 'COMPLETE', at: this.now() });
  }

  async forBooking(stay: StayRecord, booking: ExperienceBooking, service: CatalogService, actor: string): Promise<Task | null> {
    const task = bookingTaskFor({ stay, booking, service, schedule: await this.schedule(), actor, at: this.now() });
    return task ? this.ensure(task) : null;
  }

  async forOrder(stay: StayRecord, service: CatalogService, lineCount: number, actor: string): Promise<Task | null> {
    if (lineCount === 0) return null;
    return this.ensure(orderTaskFor({ stay, service, lineCount, schedule: await this.schedule(), actor, at: this.now() }));
  }

  forTrip(trip: Trip, actor: string): Promise<Task> {
    return this.ensure(tripTaskFor(trip, actor, this.now()));
  }

  /** Cancels the open task of a source the guest cancelled (no task or a closed one: no-op). */
  async cancelForSource(type: TaskSourceType, refId: string, reason: string, actor: string): Promise<void> {
    const at = this.now();
    await this.updateOpen(sourceTaskId(type, refId), (task) => transitionTask(task, { to: 'CANCELLED', reason }, actor, at));
  }

  /** A changed booking moves the deadline of its open confirmation task to the new slot. */
  async rescheduleBooking(booking: ExperienceBooking, actor: string): Promise<void> {
    if (booking.usageType !== 'BOOKING') return;
    const { timeZone } = await this.schedule();
    const dueAt = resortWallTimeIso(booking.scheduledDate, booking.scheduledTimeSlot, timeZone);
    const at = this.now();
    await this.updateOpen(sourceTaskId('BOOKING', booking.bookingId), (task) => applyTaskPatch(task, { dueAt }, actor, at));
  }

  private async updateOpen(taskId: string, change: (task: Task) => Task): Promise<void> {
    const task = await this.tasks.findById(taskId);
    if (!task || isFinalTaskStatus(task.status)) return;
    await this.tasks.update(taskId, (current) => (isFinalTaskStatus(current.status) ? current : change(current)));
  }

  private async ensure(task: Task): Promise<Task> {
    return (await this.tasks.createIfAbsent(task)).task;
  }

  private async schedule(): Promise<TaskSchedule> {
    const { timeZone, checkInTime } = await this.settings.get();
    return { timeZone, checkInTime };
  }

  private now(): string {
    return this.clock.now().toISOString();
  }
}
