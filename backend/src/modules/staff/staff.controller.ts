import { Body, Controller, Get, Param, Patch, Post, Query, UseGuards } from '@nestjs/common';
import { ANY_STAFF_ROLE, Roles } from '../../common/decorators/auth.decorators';
import { AdminAuthGuard } from '../../common/guards/admin-auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import { CreateStaffDto, StaffListQueryDto, UpdateStaffDto } from './staff.dto';
import { StaffService } from './staff.service';

/** Staff roster: any staff reads it (owner pickers); only HOST_ADMIN creates or edits it. */
@Controller('admin/staff')
@UseGuards(AdminAuthGuard, RolesGuard)
export class StaffController {
  constructor(private readonly staff: StaffService) {}

  @Get()
  @Roles(...ANY_STAFF_ROLE)
  list(@Query() query: StaffListQueryDto) {
    return this.staff.list(query);
  }

  @Get(':staffId')
  @Roles(...ANY_STAFF_ROLE)
  get(@Param('staffId') staffId: string) {
    return this.staff.get(staffId);
  }

  @Post()
  @Roles('HOST_ADMIN')
  create(@Body() dto: CreateStaffDto) {
    return this.staff.create(dto);
  }

  @Patch(':staffId')
  @Roles('HOST_ADMIN')
  update(@Param('staffId') staffId: string, @Body() dto: UpdateStaffDto) {
    return this.staff.update(staffId, dto);
  }
}
