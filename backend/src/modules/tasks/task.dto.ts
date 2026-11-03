import {
  IsIn,
  IsNotEmpty,
  IsOptional,
  IsString,
  Matches,
  MaxLength,
  ValidateIf,
} from 'class-validator';
import { ListQueryDto } from '../../common/listing/list-query';
import { QueryBoolean } from '../../common/listing/query-transforms';
import { LONG_TEXT_MAX, SHORT_TEXT_MAX } from '../../common/validation/field-limits';
import { DATE_TIME_INPUT_PATTERN } from '../../domain/time/zoned-time';
import { TASK_PRIORITIES, TASK_STATUSES, TaskPriority, TaskStatus } from '../../domain/tasks/task.models';

const ID_MAX = 100;
const DUE_MESSAGE = 'dueAt must be YYYY-MM-DDTHH:mm in resort time, or an ISO date-time with offset';

/** `GET /admin/tasks?status&priority&owner&villaId&overdue=true&q&page&pageSize&sort=dueAt:asc|desc`. */
export class TaskListQueryDto extends ListQueryDto {
  @IsOptional() @IsIn(TASK_STATUSES)
  status?: TaskStatus;

  @IsOptional() @IsIn(TASK_PRIORITIES)
  priority?: TaskPriority;

  /** Owner staff id. */
  @IsOptional() @IsString() @MaxLength(ID_MAX)
  owner?: string;

  @IsOptional() @IsString() @MaxLength(ID_MAX)
  villaId?: string;

  /** Only `true` is a filter (open and past due now). */
  @IsOptional() @QueryBoolean() @IsIn([true], { message: 'overdue only accepts true' })
  overdue?: boolean;
}

export class CreateTaskDto {
  @IsString() @IsNotEmpty() @MaxLength(SHORT_TEXT_MAX)
  title!: string;

  @IsString() @IsNotEmpty() @MaxLength(SHORT_TEXT_MAX)
  category!: string;

  @IsOptional() @IsIn(TASK_PRIORITIES)
  priority?: TaskPriority;

  @IsOptional() @Matches(DATE_TIME_INPUT_PATTERN, { message: DUE_MESSAGE })
  dueAt?: string;

  /** Links the task to a stay (villa and guest are copied from it). */
  @IsOptional() @IsString() @MaxLength(ID_MAX)
  stayId?: string;

  /** Villa without a stay (e.g. maintenance); ignored when `stayId` is given. */
  @IsOptional() @IsString() @MaxLength(ID_MAX)
  villaId?: string;

  /** With an owner the task starts ASSIGNED. */
  @IsOptional() @IsString() @IsNotEmpty() @MaxLength(ID_MAX)
  ownerStaffId?: string;

  @IsOptional() @IsString() @MaxLength(SHORT_TEXT_MAX)
  ownerName?: string;
}

/** Descriptive fields only; the status moves through `POST /admin/tasks/:id/transition`. */
export class UpdateTaskDto {
  @IsOptional() @IsString() @MaxLength(SHORT_TEXT_MAX)
  title?: string;

  @IsOptional() @IsString() @IsNotEmpty() @MaxLength(SHORT_TEXT_MAX)
  category?: string;

  @IsOptional() @IsIn(TASK_PRIORITIES)
  priority?: TaskPriority;

  /** `null` removes the deadline. */
  @IsOptional() @ValidateIf((_, value) => value !== null) @Matches(DATE_TIME_INPUT_PATTERN, { message: DUE_MESSAGE })
  dueAt?: string | null;

  @IsOptional() @ValidateIf((_, value) => value !== null) @IsString() @MaxLength(ID_MAX)
  ownerStaffId?: string | null;

  @IsOptional() @ValidateIf((_, value) => value !== null) @IsString() @MaxLength(SHORT_TEXT_MAX)
  ownerName?: string | null;
}

export class TransitionTaskDto {
  @IsIn(TASK_STATUSES)
  to!: TaskStatus;

  @IsOptional() @IsString() @MaxLength(ID_MAX)
  ownerStaffId?: string;

  @IsOptional() @IsString() @MaxLength(SHORT_TEXT_MAX)
  ownerName?: string;

  /** Completion confirmation (required for COMPLETED). */
  @IsOptional() @IsString() @MaxLength(LONG_TEXT_MAX)
  note?: string;

  @IsOptional() @IsString() @MaxLength(LONG_TEXT_MAX)
  reason?: string;
}
