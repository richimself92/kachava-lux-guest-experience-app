import { Body, Controller, Get, HttpCode, HttpStatus, Param, Post, Query, UseGuards } from '@nestjs/common';
import { ANY_STAFF_ROLE, Roles } from '../../common/decorators/auth.decorators';
import { AdminAuthGuard } from '../../common/guards/admin-auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import { RequestListQueryDto, TransitionRequestDto } from './request.dto';
import { RequestsService } from './requests.service';

/** Section request queues (Experiences, Dining, Wellness): `{ data, meta }` pages. */
@Controller('admin/requests')
@UseGuards(AdminAuthGuard, RolesGuard)
export class RequestsController {
  constructor(private readonly requests: RequestsService) {}

  @Get()
  @Roles(...ANY_STAFF_ROLE)
  list(@Query() query: RequestListQueryDto) {
    return this.requests.list(query);
  }

  @Get(':requestId')
  @Roles(...ANY_STAFF_ROLE)
  get(@Param('requestId') requestId: string) {
    return this.requests.get(requestId);
  }

  @Post(':requestId/transition')
  @HttpCode(HttpStatus.OK)
  @Roles(...ANY_STAFF_ROLE)
  transition(@Param('requestId') requestId: string, @Body() dto: TransitionRequestDto) {
    return this.requests.transition(requestId, dto);
  }
}
