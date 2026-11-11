import { Body, Controller, Get, Param, Patch, Post, Query, UseGuards } from '@nestjs/common';
import {
  ANY_STAFF_ROLE,
  auditActorOf,
  CurrentStaff,
  Roles,
} from '../../common/decorators/auth.decorators';
import { AdminAuthGuard } from '../../common/guards/admin-auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import { StaffMember } from '../../domain/models/domain.models';
import {
  CreateTransportProviderDto,
  TransportProviderListQueryDto,
  UpdateTransportProviderDto,
} from './transport-provider.dto';
import { TransportProvidersService } from './transport-providers.service';

@Controller('admin/transport-providers')
@UseGuards(AdminAuthGuard, RolesGuard)
export class TransportProvidersController {
  constructor(private readonly providers: TransportProvidersService) {}

  @Get()
  @Roles(...ANY_STAFF_ROLE)
  list(@Query() query: TransportProviderListQueryDto) {
    return this.providers.list(query);
  }

  @Get(':providerId')
  @Roles(...ANY_STAFF_ROLE)
  get(@Param('providerId') providerId: string) {
    return this.providers.get(providerId);
  }

  @Post()
  @Roles('HOST_ADMIN')
  create(@Body() dto: CreateTransportProviderDto, @CurrentStaff() staff: StaffMember) {
    return this.providers.create(dto, auditActorOf(staff));
  }

  @Patch(':providerId')
  @Roles('HOST_ADMIN')
  update(
    @Param('providerId') providerId: string,
    @Body() dto: UpdateTransportProviderDto,
    @CurrentStaff() staff: StaffMember,
  ) {
    return this.providers.update(providerId, dto, auditActorOf(staff));
  }
}
