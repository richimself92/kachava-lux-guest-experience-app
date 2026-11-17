import { Body, Controller, Get, HttpCode, HttpStatus, Param, Patch, Post, Query, UseGuards } from '@nestjs/common';
import { ANY_STAFF_ROLE, auditActorOf, CurrentStaff, Roles } from '../../common/decorators/auth.decorators';
import { AdminAuthGuard } from '../../common/guards/admin-auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import { StaffMember } from '../../domain/models/domain.models';
import { CreateTaskDto, TaskListQueryDto, TransitionTaskDto, UpdateTaskDto } from './task.dto';
import { TasksService } from './tasks.service';

/** Operational tasks: every staff role works them. */
@Controller('admin/tasks')
@UseGuards(AdminAuthGuard, RolesGuard)
@Roles(...ANY_STAFF_ROLE)
export class TasksController {
  constructor(private readonly tasks: TasksService) {}

  @Get()
  list(@Query() query: TaskListQueryDto) {
    return this.tasks.list(query);
  }

  @Get(':taskId')
  get(@Param('taskId') taskId: string) {
    return this.tasks.get(taskId);
  }

  @Post()
  create(@Body() dto: CreateTaskDto, @CurrentStaff() staff: StaffMember) {
    return this.tasks.create(dto, auditActorOf(staff));
  }

  @Patch(':taskId')
  update(@Param('taskId') taskId: string, @Body() dto: UpdateTaskDto, @CurrentStaff() staff: StaffMember) {
    return this.tasks.update(taskId, dto, auditActorOf(staff));
  }

  @Post(':taskId/transition')
  @HttpCode(HttpStatus.OK)
  transition(@Param('taskId') taskId: string, @Body() dto: TransitionTaskDto, @CurrentStaff() staff: StaffMember) {
    return this.tasks.transition(taskId, dto, auditActorOf(staff));
  }
}
