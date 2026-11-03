import { Body, Controller, Delete, Get, Param, Patch, Post, Query, UseGuards } from '@nestjs/common';
import {
  ANY_STAFF_ROLE,
  auditActorOf,
  CurrentStaff,
  Roles,
} from '../../common/decorators/auth.decorators';
import { AdminAuthGuard } from '../../common/guards/admin-auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import { StaffMember } from '../../domain/models/domain.models';
import { CreateVillaDto, UpdateVillaDto, VillaListQueryDto } from './villa.dto';
import { VillasService } from './villas.service';

@Controller('admin/villas')
@UseGuards(AdminAuthGuard, RolesGuard)
export class VillasController {
  constructor(private readonly villas: VillasService) {}

  @Get()
  @Roles(...ANY_STAFF_ROLE)
  list(@Query() query: VillaListQueryDto) {
    return this.villas.list(query);
  }

  @Get(':villaId')
  @Roles(...ANY_STAFF_ROLE)
  get(@Param('villaId') villaId: string) {
    return this.villas.get(villaId);
  }

  @Post()
  @Roles('HOST_ADMIN')
  create(@Body() dto: CreateVillaDto, @CurrentStaff() staff: StaffMember) {
    return this.villas.create(dto, auditActorOf(staff));
  }

  @Patch(':villaId')
  @Roles('HOST_ADMIN')
  update(@Param('villaId') villaId: string, @Body() dto: UpdateVillaDto, @CurrentStaff() staff: StaffMember) {
    return this.villas.update(villaId, dto, auditActorOf(staff));
  }

  @Delete(':villaId')
  @Roles('HOST_ADMIN')
  remove(@Param('villaId') villaId: string) {
    return this.villas.remove(villaId);
  }
}
