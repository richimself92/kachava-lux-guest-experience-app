import {
  Body,
  Controller,
  Get,
  Param,
  Patch,
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
import { AdminSyncService } from './admin-sync.service';
import { AdminService } from './admin.service';
import {
  AdminLoginDto,
  AlertListQueryDto,
  ApproveCheckoutDto,
  AssignBookingDto,
  AssignTransferDto,
  BookingListQueryDto,
  ConciergeListQueryDto,
  CreateReservationDto,
  LarderOrderListQueryDto,
  StaffListQueryDto,
  StayListQueryDto,
  UpdateAdminConciergeDto,
  UpdateLarderStatusDto,
  UpdateStayStatusDto,
  UpdateStayWifiDto,
} from './dto/admin.dto';

/** Every list endpoint takes `?q=&page=&pageSize=&sort=field:asc|desc&<filters>`. */
@Controller('admin')
export class AdminController {
  constructor(
    private readonly adminService: AdminService,
    private readonly fulfillment: AdminFulfillmentService,
    private readonly adminSyncService: AdminSyncService,
  ) {}

  /** Silent login of the environment-configured admin identity (ADMIN_SERVICE_EMAIL). */
  @Post('auth/login')
  login(@Body() dto: AdminLoginDto) {
    return this.adminService.loginStaff(dto);
  }

  @Get('sync')
  @UseGuards(AdminAuthGuard, RolesGuard)
  @Roles('HOST_ADMIN', 'CONCIERGE_STAFF')
  sync() {
    return this.adminSyncService.snapshot();
  }

  @Get('alerts')
  @UseGuards(AdminAuthGuard, RolesGuard)
  @Roles('HOST_ADMIN', 'CONCIERGE_STAFF', 'DEPARTMENT_COORDINATOR')
  listAlerts(@Query() query: AlertListQueryDto) {
    return this.adminService.listAlerts(query);
  }

  @Patch('alerts/:alertId/acknowledge')
  @UseGuards(AdminAuthGuard, RolesGuard)
  @Roles('HOST_ADMIN', 'CONCIERGE_STAFF', 'DEPARTMENT_COORDINATOR')
  acknowledgeAlert(@Param('alertId') alertId: string, @CurrentStaff() staff: StaffMember) {
    return this.adminService.acknowledgeAlert(alertId, staff);
  }

  @Get('stays')
  @UseGuards(AdminAuthGuard, RolesGuard)
  @Roles('HOST_ADMIN', 'CONCIERGE_STAFF')
  listStays(@Query() query: StayListQueryDto) {
    return this.adminService.listStays(query);
  }

  @Post('stays')
  @UseGuards(AdminAuthGuard, RolesGuard)
  @Roles('HOST_ADMIN')
  createStay(@Body() dto: CreateReservationDto) {
    return this.adminService.createReservation(dto);
  }

  @Post('stays/:stayId/regenerate-token')
  @UseGuards(AdminAuthGuard, RolesGuard)
  @Roles('HOST_ADMIN')
  regenerateStayToken(@Param('stayId') stayId: string) {
    return this.adminService.regenerateStayToken(stayId);
  }

  @Patch('stays/:stayId/status')
  @UseGuards(AdminAuthGuard, RolesGuard)
  @Roles('HOST_ADMIN', 'CONCIERGE_STAFF', 'DEPARTMENT_COORDINATOR')
  updateStayStatus(@Param('stayId') stayId: string, @Body() dto: UpdateStayStatusDto) {
    return this.adminService.updateStayStatus(stayId, dto.status);
  }

  @Patch('stays/:stayId/wifi')
  @UseGuards(AdminAuthGuard, RolesGuard)
  @Roles('HOST_ADMIN', 'CONCIERGE_STAFF', 'DEPARTMENT_COORDINATOR')
  updateStayWifi(@Param('stayId') stayId: string, @Body() dto: UpdateStayWifiDto) {
    return this.adminService.updateStayWifi(stayId, dto);
  }

  @Patch('stays/:stayId/transfer')
  @UseGuards(AdminAuthGuard, RolesGuard)
  @Roles('HOST_ADMIN', 'CONCIERGE_STAFF', 'DEPARTMENT_COORDINATOR')
  updateStayTransfer(@Param('stayId') stayId: string, @Body() dto: AssignTransferDto) {
    return this.adminService.updateStayTransfer(stayId, dto);
  }

  @Get('bookings')
  @UseGuards(AdminAuthGuard, RolesGuard)
  @Roles('HOST_ADMIN', 'CONCIERGE_STAFF', 'DEPARTMENT_COORDINATOR')
  listBookings(@Query() query: BookingListQueryDto) {
    return this.fulfillment.listBookings(query);
  }

  @Patch('bookings/:bookingId/assign')
  @UseGuards(AdminAuthGuard, RolesGuard)
  @Roles('HOST_ADMIN', 'CONCIERGE_STAFF', 'DEPARTMENT_COORDINATOR')
  assignBooking(@Param('bookingId') bookingId: string, @Body() dto: AssignBookingDto) {
    return this.fulfillment.assignBooking(bookingId, dto);
  }

  @Get('larder-orders')
  @UseGuards(AdminAuthGuard, RolesGuard)
  @Roles('HOST_ADMIN', 'CONCIERGE_STAFF', 'DEPARTMENT_COORDINATOR')
  listLarderOrders(@Query() query: LarderOrderListQueryDto) {
    return this.fulfillment.listLarderOrders(query);
  }

  @Patch('larder-orders/:orderId/status')
  @UseGuards(AdminAuthGuard, RolesGuard)
  @Roles('HOST_ADMIN', 'CONCIERGE_STAFF', 'DEPARTMENT_COORDINATOR')
  updateLarderStatus(@Param('orderId') orderId: string, @Body() dto: UpdateLarderStatusDto) {
    return this.fulfillment.updateLarderOrderStatus(orderId, dto);
  }

  @Get('concierge-requests')
  @UseGuards(AdminAuthGuard, RolesGuard)
  @Roles('HOST_ADMIN', 'CONCIERGE_STAFF', 'DEPARTMENT_COORDINATOR')
  listConciergeRequests(@Query() query: ConciergeListQueryDto) {
    return this.fulfillment.listConciergeRequests(query);
  }

  @Patch('concierge-requests/:requestId')
  @UseGuards(AdminAuthGuard, RolesGuard)
  @Roles('HOST_ADMIN', 'CONCIERGE_STAFF', 'DEPARTMENT_COORDINATOR')
  updateConciergeRequest(
    @Param('requestId') requestId: string,
    @Body() dto: UpdateAdminConciergeDto,
    @CurrentStaff() staff: StaffMember,
  ) {
    return this.fulfillment.updateConciergeRequest(requestId, dto, staff);
  }

  @Get('concierge-requests/:requestId/photo-url')
  @UseGuards(AdminAuthGuard, RolesGuard)
  @Roles('HOST_ADMIN', 'CONCIERGE_STAFF', 'DEPARTMENT_COORDINATOR')
  getConciergePhotoUrl(@Param('requestId') requestId: string) {
    return this.fulfillment.generateConciergePhotoGetUrl(requestId);
  }

  @Get('midstay-feedback')
  @UseGuards(AdminAuthGuard, RolesGuard)
  @Roles('HOST_ADMIN', 'CONCIERGE_STAFF')
  listMidStayFeedback(@Query() query: ListQueryDto) {
    return this.fulfillment.listMidStayFeedback(query);
  }

  @Patch('stays/:stayId/folio/approve-checkout')
  @UseGuards(AdminAuthGuard, RolesGuard)
  @Roles('HOST_ADMIN', 'CONCIERGE_STAFF')
  approveCheckout(
    @Param('stayId') stayId: string,
    @Body() dto: ApproveCheckoutDto,
    @CurrentStaff() staff: StaffMember,
  ) {
    return this.fulfillment.approveCheckout(stayId, dto, staff);
  }

  @Get('staff')
  @UseGuards(AdminAuthGuard, RolesGuard)
  @Roles('HOST_ADMIN', 'CONCIERGE_STAFF', 'DEPARTMENT_COORDINATOR')
  listStaff(@Query() query: StaffListQueryDto) {
    return this.adminService.listStaff(query);
  }
}
