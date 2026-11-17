import { Body, Controller, Get, Param, Patch, Query, UseGuards } from '@nestjs/common';
import { auditActorOf, CurrentStaff, Roles } from '../../common/decorators/auth.decorators';
import { AdminAuthGuard } from '../../common/guards/admin-auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import { StaffMember } from '../../domain/models/domain.models';
import { GuestListQueryDto, ReservationListQueryDto, UpdateReservationDto } from './reservation.dto';
import { ReservationsService } from './reservations.service';

/**
 * Reservations (stay list, detail, edits, folio). Creation, token, Wi-Fi, transfer and checkout
 * approval stay on the existing `AdminController` routes under `admin/stays/:stayId/...`.
 */
@Controller('admin/stays')
@UseGuards(AdminAuthGuard, RolesGuard)
@Roles('HOST_ADMIN', 'CONCIERGE_STAFF')
export class ReservationsController {
  constructor(private readonly reservations: ReservationsService) {}

  @Get()
  list(@Query() query: ReservationListQueryDto) {
    return this.reservations.list(query);
  }

  @Get(':stayId')
  get(@Param('stayId') stayId: string) {
    return this.reservations.get(stayId);
  }

  @Patch(':stayId')
  update(@Param('stayId') stayId: string, @Body() dto: UpdateReservationDto, @CurrentStaff() staff: StaffMember) {
    return this.reservations.update(stayId, dto, auditActorOf(staff));
  }

  @Get(':stayId/folio')
  folio(@Param('stayId') stayId: string) {
    return this.reservations.folio(stayId);
  }
}

/** Guest profiles per stay: staff-only (preferences, allergies, notes). */
@Controller('admin/guests')
@UseGuards(AdminAuthGuard, RolesGuard)
@Roles('HOST_ADMIN', 'CONCIERGE_STAFF')
export class GuestsController {
  constructor(private readonly reservations: ReservationsService) {}

  @Get()
  list(@Query() query: GuestListQueryDto) {
    return this.reservations.listGuests(query);
  }

  @Get(':stayId')
  get(@Param('stayId') stayId: string) {
    return this.reservations.guestProfile(stayId);
  }
}
