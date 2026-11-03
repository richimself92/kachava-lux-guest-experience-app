import {
  Body,
  Controller,
  Get,
  Param,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import { CurrentStaff, Roles } from '../../common/decorators/auth.decorators';
import { AdminAuthGuard } from '../../common/guards/admin-auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import { ListQueryDto } from '../../common/listing/list-query';
import { StaffMember } from '../../domain/models/domain.models';
import { AdminFulfillmentService } from './admin-fulfillment.service';
import { AdminService } from './admin.service';
import { AdminLoginDto, CreateReservationDto } from './dto/admin.dto';

/** Every list endpoint takes `?q=&page=&pageSize=&sort=field:asc|desc&<filters>`. */
@Controller('admin')
export class AdminController {
  constructor(
    private readonly adminService: AdminService,
    private readonly fulfillment: AdminFulfillmentService,
  ) {}

  /** Silent login of the environment-configured admin identity (ADMIN_SERVICE_EMAIL). */
  @Post('auth/login')
  login(@Body() dto: AdminLoginDto) {
    return this.adminService.loginStaff(dto);
  }

  @Post('stays')
  @UseGuards(AdminAuthGuard, RolesGuard)
  @Roles('HOST_ADMIN')
  createStay(@Body() dto: CreateReservationDto, @CurrentStaff() staff: StaffMember) {
    return this.adminService.createReservation(dto, staff);
  }

  @Post('stays/:stayId/regenerate-token')
  @UseGuards(AdminAuthGuard, RolesGuard)
  @Roles('HOST_ADMIN')
  regenerateStayToken(@Param('stayId') stayId: string) {
    return this.adminService.regenerateStayToken(stayId);
  }

  @Get('midstay-feedback')
  @UseGuards(AdminAuthGuard, RolesGuard)
  @Roles('HOST_ADMIN', 'CONCIERGE_STAFF')
  listMidStayFeedback(@Query() query: ListQueryDto) {
    return this.fulfillment.listMidStayFeedback(query);
  }
}
