import { Controller, Get, UseGuards } from '@nestjs/common';
import { ANY_STAFF_ROLE, Roles } from '../../common/decorators/auth.decorators';
import { AdminAuthGuard } from '../../common/guards/admin-auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import { DashboardService } from './dashboard.service';

@Controller('admin/dashboard')
@UseGuards(AdminAuthGuard, RolesGuard)
@Roles(...ANY_STAFF_ROLE)
export class DashboardController {
  constructor(private readonly dashboard: DashboardService) {}

  @Get()
  get() {
    return this.dashboard.get();
  }
}
