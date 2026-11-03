import { Controller, Get, HttpCode, HttpStatus, Param, Post, Query, UseGuards } from '@nestjs/common';
import { ANY_STAFF_ROLE, CurrentStaff, Roles } from '../../common/decorators/auth.decorators';
import { AdminAuthGuard } from '../../common/guards/admin-auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import { StaffMember } from '../../domain/models/domain.models';
import { NotificationListQueryDto } from './notification.dto';
import { NotificationsService } from './notifications.service';

@Controller('admin/notifications')
@UseGuards(AdminAuthGuard, RolesGuard)
@Roles(...ANY_STAFF_ROLE)
export class NotificationsController {
  constructor(private readonly notifications: NotificationsService) {}

  @Get()
  list(@Query() query: NotificationListQueryDto) {
    return this.notifications.list(query);
  }

  /** Declared before `:id` routes so the literal paths win. */
  @Get('unread-count')
  unreadCount() {
    return this.notifications.unreadCount();
  }

  @Post('read-all')
  @HttpCode(HttpStatus.OK)
  readAll(@CurrentStaff() staff: StaffMember) {
    return this.notifications.markAllRead(staff);
  }

  @Post(':id/read')
  @HttpCode(HttpStatus.OK)
  read(@Param('id') id: string, @CurrentStaff() staff: StaffMember) {
    return this.notifications.markRead(id, staff);
  }
}
