import { Inject, Injectable } from '@nestjs/common';
import { CatalogService } from '../../domain/catalog/catalog.models';
import { ExperienceBooking, StayRecord } from '../../domain/models/domain.models';
import { CLOCK_PORT, ClockPort } from '../../domain/ports/clock.port';
import {
  SETTINGS_REPOSITORY_PORT,
  SettingsRepositoryPort,
  TASK_REPOSITORY_PORT,
  TaskRepositoryPort,
} from '../../domain/ports/repository.ports';
import { bookingTaskFor, orderTaskFor, TaskSchedule, tripTaskFor } from '../../domain/tasks/task-sources';
import { Task } from '../../domain/tasks/task.models';
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
  ) {}

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
