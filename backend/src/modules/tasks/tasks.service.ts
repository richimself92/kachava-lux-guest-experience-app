import { Inject, Injectable } from '@nestjs/common';
import * as crypto from 'crypto';
import { PaginatedResult, toListQuery } from '../../common/listing/list-query';
import { definedFields } from '../../common/validation/patch';
import { EntityNotFoundError } from '../../domain/domain-errors';
import { CLOCK_PORT, ClockPort } from '../../domain/ports/clock.port';
import {
  SETTINGS_REPOSITORY_PORT,
  SettingsRepositoryPort,
  STAY_REPOSITORY_PORT,
  StayRepositoryPort,
  TASK_REPOSITORY_PORT,
  TaskRepositoryPort,
  VILLA_REPOSITORY_PORT,
  VillaRepositoryPort,
} from '../../domain/ports/repository.ports';
import { applyTaskPatch, TaskPatch, transitionTask, TaskTransitionCommand } from '../../domain/tasks/task-transitions';
import { isTaskOverdue, OPEN_TASK_STATUSES, Task } from '../../domain/tasks/task.models';
import { toInstantIso } from '../../domain/time/zoned-time';
import { CreateTaskDto, TaskListQueryDto, TransitionTaskDto, UpdateTaskDto } from './task.dto';

/** Wire shape: the task plus `id` and `overdue` (derived on read, never stored). */
export type TaskView = Task & { id: string; overdue: boolean };

export const TASK_LIST_SPEC = {
  sortable: ['dueAt'],
  defaultSort: { field: 'dueAt', direction: 'asc' as const },
};

interface TaskParty {
  stayId: string | null;
  villaId: string | null;
  villaName: string | null;
  guestName: string | null;
}

@Injectable()
export class TasksService {
  constructor(
    @Inject(TASK_REPOSITORY_PORT) private readonly tasks: TaskRepositoryPort,
    @Inject(STAY_REPOSITORY_PORT) private readonly stays: StayRepositoryPort,
    @Inject(VILLA_REPOSITORY_PORT) private readonly villas: VillaRepositoryPort,
    @Inject(SETTINGS_REPOSITORY_PORT) private readonly settings: SettingsRepositoryPort,
    @Inject(CLOCK_PORT) private readonly clock: ClockPort,
  ) {}

  async list(dto: TaskListQueryDto): Promise<PaginatedResult<TaskView>> {
    const query = toListQuery(dto, TASK_LIST_SPEC);
    const now = this.clock.now();
    const page = await this.tasks.page({
      status: dto.status,
      priority: dto.priority,
      ownerStaffId: dto.owner,
      villaId: dto.villaId,
      overdueBefore: dto.overdue ? now.toISOString() : undefined,
      q: query.q,
      page: query.page,
      pageSize: query.pageSize,
      direction: query.sort.direction,
    });
    return new PaginatedResult(page.data.map((task) => this.view(task, now)), page.meta);
  }

  async get(taskId: string): Promise<TaskView> {
    const task = await this.tasks.findById(taskId);
    if (!task) throw new EntityNotFoundError('Task', taskId);
    return this.view(task, this.clock.now());
  }

  async create(dto: CreateTaskDto, actor: string): Promise<TaskView> {
    const at = this.clock.now().toISOString();
    const party = await this.partyOf(dto);
    const owner = dto.ownerStaffId?.trim() || null;
    const status = owner ? 'ASSIGNED' : 'PENDING';
    const task: Task = {
      taskId: `task_${crypto.randomUUID()}`,
      title: dto.title.trim(),
      source: { type: 'MANUAL', refId: null, stayId: party.stayId },
      villaId: party.villaId,
      villaName: party.villaName,
      guestName: party.guestName,
      category: dto.category.trim(),
      ownerStaffId: owner,
      ownerName: dto.ownerName?.trim() || null,
      priority: dto.priority ?? 'NORMAL',
      dueAt: dto.dueAt ? await this.instant(dto.dueAt) : null,
      status,
      completion: null,
      cancellationReason: null,
      statusHistory: [{ from: null, to: status, at, by: actor }],
      createdAt: at,
      createdBy: actor,
      updatedAt: at,
      updatedBy: actor,
    };
    return this.view(await this.tasks.create(task), this.clock.now());
  }

  async update(taskId: string, dto: UpdateTaskDto, actor: string): Promise<TaskView> {
    const patch = definedFields(dto) as TaskPatch;
    if (typeof patch.dueAt === 'string') patch.dueAt = await this.instant(patch.dueAt);
    const at = this.clock.now().toISOString();
    const updated = await this.tasks.update(taskId, (current) => applyTaskPatch(current, patch, actor, at));
    return this.view(updated, this.clock.now());
  }

  async transition(taskId: string, dto: TransitionTaskDto, actor: string): Promise<TaskView> {
    const command = definedFields(dto) as TaskTransitionCommand;
    const at = this.clock.now().toISOString();
    const updated = await this.tasks.update(taskId, (current) => transitionTask(current, command, actor, at));
    return this.view(updated, this.clock.now());
  }

  countOpen(): Promise<number> {
    return this.tasks.countByStatuses(OPEN_TASK_STATUSES);
  }

  private view(task: Task, now: Date): TaskView {
    return { id: task.taskId, ...task, overdue: isTaskOverdue(task, now) };
  }

  /** Resort wall times need the Settings time zone (SETTINGS_REQUIRED otherwise). */
  private async instant(value: string): Promise<string> {
    return toInstantIso(value, (await this.settings.get()).timeZone);
  }

  private async partyOf(dto: CreateTaskDto): Promise<TaskParty> {
    if (dto.stayId) {
      const stay = await this.stays.findByStayId(dto.stayId);
      if (!stay) throw new EntityNotFoundError('Stay', dto.stayId);
      return { stayId: stay.stayId, villaId: stay.villaId, villaName: stay.villaName, guestName: stay.guestProfile.name };
    }
    if (dto.villaId) {
      const villa = await this.villas.findById(dto.villaId);
      if (!villa) throw new EntityNotFoundError('Villa', dto.villaId);
      return { stayId: null, villaId: villa.villaId, villaName: villa.name, guestName: null };
    }
    return { stayId: null, villaId: null, villaName: null, guestName: null };
  }
}
