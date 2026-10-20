import {
  Body,
  Controller,
  Delete,
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
import {
  StaffMember,
  StayLifecycleStatus,
} from '../../domain/models/domain.models';
import { AdminService } from './admin.service';
import {
  AdminLoginDto,
  ApproveCheckoutDto,
  AssignBookingDto,
  AssignTransferDto,
  CreateExperienceCatalogDto,
  CreateLarderCatalogDto,
  CreateReservationDto,
  UpdateAdminConciergeDto,
  UpdateLarderStatusDto,
  UpdateStayStatusDto,
  UpdateStayWifiDto,
} from './dto/admin.dto';

@Controller('admin')
export class AdminController {
  constructor(private readonly adminService: AdminService) {}

  @Post('auth/login')
  login(@Body() dto: AdminLoginDto) {
    return this.adminService.loginStaff(dto);
  }

  @Post('reset')
  @UseGuards(AdminAuthGuard)
  resetAllData() {
    return this.adminService.resetAllData();
  }

  @Get('alerts')
  @UseGuards(AdminAuthGuard, RolesGuard)
  @Roles('HOST_ADMIN', 'CONCIERGE_STAFF', 'DEPARTMENT_COORDINATOR')
  listAlerts(@Query() query: Record<string, string | undefined>) {
    return this.adminService.listAlerts(this.adminService.parseAlertQuery(query));
  }

  @Patch('alerts/:alertId/acknowledge')
  @UseGuards(AdminAuthGuard, RolesGuard)
  @Roles('HOST_ADMIN', 'CONCIERGE_STAFF', 'DEPARTMENT_COORDINATOR')
  acknowledgeAlert(
    @Param('alertId') alertId: string,
    @CurrentStaff() staff: StaffMember,
  ) {
    return this.adminService.acknowledgeAlert(alertId, staff);
  }

  @Get('stays')
  @UseGuards(AdminAuthGuard, RolesGuard)
  @Roles('HOST_ADMIN', 'CONCIERGE_STAFF')
  listStays(
    @Query('status') status?: StayLifecycleStatus,
    @Query('villaId') villaId?: string,
    @Query('search') search?: string,
  ) {
    return this.adminService.listStays({ status, villaId, search });
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
  updateStayStatus(
    @Param('stayId') stayId: string,
    @Body() dto: UpdateStayStatusDto,
  ) {
    return this.adminService.updateStayStatus(stayId, dto.status);
  }

  @Patch('stays/:stayId/wifi')
  @UseGuards(AdminAuthGuard, RolesGuard)
  @Roles('HOST_ADMIN', 'CONCIERGE_STAFF', 'DEPARTMENT_COORDINATOR')
  updateStayWifi(
    @Param('stayId') stayId: string,
    @Body() dto: UpdateStayWifiDto,
  ) {
    return this.adminService.updateStayWifi(stayId, dto);
  }

  @Patch('stays/:stayId/transfer')
  @UseGuards(AdminAuthGuard, RolesGuard)
  @Roles('HOST_ADMIN', 'CONCIERGE_STAFF', 'DEPARTMENT_COORDINATOR')
  updateStayTransfer(
    @Param('stayId') stayId: string,
    @Body() dto: AssignTransferDto,
  ) {
    return this.adminService.updateStayTransfer(stayId, dto);
  }

  @Get('catalog/experiences')
  @UseGuards(AdminAuthGuard)
  listCatalogExperiences() {
    return this.adminService.listCatalogExperiences();
  }

  @Post('catalog/experiences')
  @UseGuards(AdminAuthGuard)
  createCatalogExperience(@Body() dto: CreateExperienceCatalogDto) {
    return this.adminService.createCatalogExperience(dto);
  }

  @Delete('catalog/experiences/:id')
  @UseGuards(AdminAuthGuard)
  deleteCatalogExperience(@Param('id') id: string) {
    return this.adminService.deleteCatalogExperience(id);
  }

  @Get('catalog/larder')
  @UseGuards(AdminAuthGuard)
  listCatalogLarder() {
    return this.adminService.listCatalogLarder();
  }

  @Post('catalog/larder')
  @UseGuards(AdminAuthGuard)
  createCatalogLarder(@Body() dto: CreateLarderCatalogDto) {
    return this.adminService.createCatalogLarder(dto);
  }

  @Delete('catalog/larder/:id')
  @UseGuards(AdminAuthGuard)
  deleteCatalogLarder(@Param('id') id: string) {
    return this.adminService.deleteCatalogLarder(id);
  }

  @Get('bookings')
  @UseGuards(AdminAuthGuard, RolesGuard)
  @Roles('HOST_ADMIN', 'CONCIERGE_STAFF', 'DEPARTMENT_COORDINATOR')
  listBookings(
    @Query('category') category?: string,
    @Query('bookingType') bookingType?: string,
    @Query('status') status?: string,
    @Query('assignedDepartment') assignedDepartment?: string,
    @Query('scheduledDate') scheduledDate?: string,
  ) {
    return this.adminService.listBookings({
      category,
      bookingType,
      status,
      assignedDepartment,
      scheduledDate,
    });
  }

  @Patch('bookings/:bookingId/assign')
  @UseGuards(AdminAuthGuard, RolesGuard)
  @Roles('HOST_ADMIN', 'CONCIERGE_STAFF', 'DEPARTMENT_COORDINATOR')
  assignBooking(
    @Param('bookingId') bookingId: string,
    @Body() dto: AssignBookingDto,
  ) {
    return this.adminService.assignBooking(bookingId, dto);
  }

  @Get('larder-orders')
  @UseGuards(AdminAuthGuard, RolesGuard)
  @Roles('HOST_ADMIN', 'CONCIERGE_STAFF', 'DEPARTMENT_COORDINATOR')
  listLarderOrders(
    @Query('provisioningStatus') provisioningStatus?: string,
    @Query('category') category?: string,
    @Query('villaId') villaId?: string,
  ) {
    return this.adminService.listLarderOrders({
      provisioningStatus,
      category,
      villaId,
    });
  }

  @Patch('larder-orders/:orderId/status')
  @UseGuards(AdminAuthGuard, RolesGuard)
  @Roles('HOST_ADMIN', 'CONCIERGE_STAFF', 'DEPARTMENT_COORDINATOR')
  updateLarderStatus(
    @Param('orderId') orderId: string,
    @Body() dto: UpdateLarderStatusDto,
  ) {
    return this.adminService.updateLarderOrderStatus(orderId, dto);
  }

  @Get('concierge-requests')
  @UseGuards(AdminAuthGuard, RolesGuard)
  @Roles('HOST_ADMIN', 'CONCIERGE_STAFF', 'DEPARTMENT_COORDINATOR')
  listConciergeRequests(
    @Query('status') status?: string,
    @Query('priority') priority?: string,
    @Query('assignedDepartment') assignedDepartment?: string,
    @Query('category') category?: string,
    @Query('villaId') villaId?: string,
  ) {
    return this.adminService.listConciergeRequests({
      status,
      priority,
      assignedDepartment,
      category,
      villaId,
    });
  }

  @Patch('concierge-requests/:requestId')
  @UseGuards(AdminAuthGuard, RolesGuard)
  @Roles('HOST_ADMIN', 'CONCIERGE_STAFF', 'DEPARTMENT_COORDINATOR')
  updateConciergeRequest(
    @Param('requestId') requestId: string,
    @Body() dto: UpdateAdminConciergeDto,
    @CurrentStaff() staff: StaffMember,
  ) {
    return this.adminService.updateConciergeRequest(requestId, dto, staff);
  }

  @Get('concierge-requests/:requestId/photo-url')
  @UseGuards(AdminAuthGuard, RolesGuard)
  @Roles('HOST_ADMIN', 'CONCIERGE_STAFF', 'DEPARTMENT_COORDINATOR')
  getConciergePhotoUrl(@Param('requestId') requestId: string) {
    return this.adminService.generateConciergePhotoGetUrl(requestId);
  }

  @Get('midstay-feedback')
  @UseGuards(AdminAuthGuard, RolesGuard)
  @Roles('HOST_ADMIN', 'CONCIERGE_STAFF')
  listMidStayFeedback() {
    return this.adminService.listMidStayFeedback();
  }

  @Patch('stays/:stayId/folio/approve-checkout')
  @UseGuards(AdminAuthGuard, RolesGuard)
  @Roles('HOST_ADMIN', 'CONCIERGE_STAFF')
  approveCheckout(
    @Param('stayId') stayId: string,
    @Body() dto: ApproveCheckoutDto,
    @CurrentStaff() staff: StaffMember,
  ) {
    return this.adminService.approveCheckout(stayId, dto, staff);
  }

  @Get('staff')
  @UseGuards(AdminAuthGuard, RolesGuard)
  @Roles('HOST_ADMIN', 'CONCIERGE_STAFF', 'DEPARTMENT_COORDINATOR')
  listStaff(@Query('department') department?: string) {
    return this.adminService.listStaff(department);
  }
}
