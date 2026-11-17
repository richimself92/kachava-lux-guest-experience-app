import { Body, Controller, Get, Patch, UseGuards } from '@nestjs/common';
import {
  ANY_STAFF_ROLE,
  auditActorOf,
  CurrentStaff,
  Roles,
} from '../../common/decorators/auth.decorators';
import { AdminAuthGuard } from '../../common/guards/admin-auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import { StaffMember } from '../../domain/models/domain.models';
import { UpdateSettingsDto } from './settings.dto';
import { SettingsService } from './settings.service';

@Controller('admin/settings')
@UseGuards(AdminAuthGuard, RolesGuard)
export class SettingsController {
  constructor(private readonly settings: SettingsService) {}

  @Get()
  @Roles(...ANY_STAFF_ROLE)
  get() {
    return this.settings.get();
  }

  @Patch()
  @Roles('HOST_ADMIN')
  update(@Body() dto: UpdateSettingsDto, @CurrentStaff() staff: StaffMember) {
    return this.settings.update(dto, auditActorOf(staff));
  }
}
