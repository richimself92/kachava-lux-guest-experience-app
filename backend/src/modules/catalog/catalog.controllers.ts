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
import { CatalogAdminService } from './catalog-admin.service';
import { CatalogUploadsService } from './catalog-uploads.service';
import { CreateItemDto, ItemListQueryDto, UpdateItemDto } from './dto/item.dto';
import { CreateServiceDto, GuestCatalogQueryDto, ServiceListQueryDto, UpdateServiceDto } from './dto/service.dto';
import { SignCatalogUploadDto } from './dto/upload.dto';
import { GuestCatalogService } from './guest-catalog.service';

@Controller('admin/services')
@UseGuards(AdminAuthGuard, RolesGuard)
export class AdminServicesController {
  constructor(private readonly catalog: CatalogAdminService) {}

  @Get()
  @Roles(...ANY_STAFF_ROLE)
  list(@Query() query: ServiceListQueryDto) {
    return this.catalog.listServices(query);
  }

  @Get(':serviceId')
  @Roles(...ANY_STAFF_ROLE)
  get(@Param('serviceId') serviceId: string) {
    return this.catalog.getService(serviceId);
  }

  @Post()
  @Roles('HOST_ADMIN')
  create(@Body() dto: CreateServiceDto, @CurrentStaff() staff: StaffMember) {
    return this.catalog.createService(dto, auditActorOf(staff));
  }

  @Patch(':serviceId')
  @Roles('HOST_ADMIN')
  update(@Param('serviceId') serviceId: string, @Body() dto: UpdateServiceDto, @CurrentStaff() staff: StaffMember) {
    return this.catalog.updateService(serviceId, dto, auditActorOf(staff));
  }

  @Get(':serviceId/items')
  @Roles(...ANY_STAFF_ROLE)
  listItems(@Param('serviceId') serviceId: string, @Query() query: ItemListQueryDto) {
    return this.catalog.listItems(serviceId, query);
  }

  @Post(':serviceId/items')
  @Roles('HOST_ADMIN')
  createItem(@Param('serviceId') serviceId: string, @Body() dto: CreateItemDto, @CurrentStaff() staff: StaffMember) {
    return this.catalog.createItem(serviceId, dto, auditActorOf(staff));
  }

  @Patch(':serviceId/items/:itemId')
  @Roles('HOST_ADMIN')
  updateItem(
    @Param('serviceId') serviceId: string,
    @Param('itemId') itemId: string,
    @Body() dto: UpdateItemDto,
    @CurrentStaff() staff: StaffMember,
  ) {
    return this.catalog.updateItem(serviceId, itemId, dto, auditActorOf(staff));
  }
}

@Controller('admin/uploads')
@UseGuards(AdminAuthGuard, RolesGuard)
export class AdminUploadsController {
  constructor(private readonly uploads: CatalogUploadsService) {}

  @Post('sign')
  @Roles('HOST_ADMIN')
  sign(@Body() dto: SignCatalogUploadDto) {
    return this.uploads.sign(dto);
  }
}

/** Public guest catalog (no stay data): ACTIVE services and items only. */
@Controller('catalog')
export class GuestCatalogController {
  constructor(private readonly catalog: GuestCatalogService) {}

  @Get('services')
  list(@Query() query: GuestCatalogQueryDto) {
    return this.catalog.list(query);
  }
}
