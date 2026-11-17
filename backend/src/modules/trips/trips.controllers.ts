import { Body, Controller, Get, HttpCode, HttpStatus, Param, Patch, Post, Query, UseGuards } from '@nestjs/common';
import {
  ANY_STAFF_ROLE,
  auditActorOf,
  CurrentStaff,
  CurrentStay,
  Roles,
} from '../../common/decorators/auth.decorators';
import { AdminAuthGuard } from '../../common/guards/admin-auth.guard';
import { GuestTokenGuard } from '../../common/guards/guest-token.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import { ListQueryDto } from '../../common/listing/list-query';
import { StaffMember, StayAggregate } from '../../domain/models/domain.models';
import { GuestTripsService } from './guest-trips.service';
import {
  CreateAdminTripDto,
  CreateGuestTripDto,
  TransitionTripDto,
  TripListQueryDto,
  UpdateTripDto,
} from './trip.dto';
import { TripsAdminService } from './trips-admin.service';

/** Trips are day-to-day operations: every staff role may read and operate them. */
@Controller('admin/trips')
@UseGuards(AdminAuthGuard, RolesGuard)
@Roles(...ANY_STAFF_ROLE)
export class TripsAdminController {
  constructor(private readonly trips: TripsAdminService) {}

  @Get()
  list(@Query() query: TripListQueryDto) {
    return this.trips.list(query);
  }

  /** Declared before `:tripId` so the literal path wins. */
  @Get('unconfirmed-due')
  listUnconfirmedDue(@Query() query: ListQueryDto) {
    return this.trips.listUnconfirmedDue(query);
  }

  @Get(':tripId')
  get(@Param('tripId') tripId: string) {
    return this.trips.get(tripId);
  }

  @Post()
  create(@Body() dto: CreateAdminTripDto, @CurrentStaff() staff: StaffMember) {
    return this.trips.create(dto, auditActorOf(staff));
  }

  @Patch(':tripId')
  update(@Param('tripId') tripId: string, @Body() dto: UpdateTripDto, @CurrentStaff() staff: StaffMember) {
    return this.trips.update(tripId, dto, auditActorOf(staff));
  }

  @Post(':tripId/transition')
  @HttpCode(HttpStatus.OK)
  transition(@Param('tripId') tripId: string, @Body() dto: TransitionTripDto, @CurrentStaff() staff: StaffMember) {
    return this.trips.transition(tripId, dto, auditActorOf(staff));
  }
}

/** Guest capability routes; responses are the guest-safe trip projection only. */
@Controller('stays/:guestUuid/trips')
@UseGuards(GuestTokenGuard)
export class GuestTripsController {
  constructor(private readonly trips: GuestTripsService) {}

  @Get()
  list(@CurrentStay() stay: StayAggregate) {
    return this.trips.list(stay);
  }

  @Post()
  create(@CurrentStay() stay: StayAggregate, @Body() dto: CreateGuestTripDto) {
    return this.trips.create(stay, dto);
  }

  @Post(':tripId/cancel')
  @HttpCode(HttpStatus.OK)
  cancel(@CurrentStay() stay: StayAggregate, @Param('tripId') tripId: string) {
    return this.trips.cancel(stay, tripId);
  }
}
