import { Body, Controller, Get, HttpCode, HttpStatus, Param, Post, Query, UseGuards } from '@nestjs/common';
import { ANY_STAFF_ROLE, CurrentStaff, Roles } from '../../common/decorators/auth.decorators';
import { AdminAuthGuard } from '../../common/guards/admin-auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import { StaffMember } from '../../domain/models/domain.models';
import { ConversationListQueryDto, ConversationMessagesQueryDto, ReplyMessageDto } from './conversation.dto';
import { ConversationsService } from './conversations.service';

/** Guests → Messages inbox. */
@Controller('admin/conversations')
@UseGuards(AdminAuthGuard, RolesGuard)
@Roles(...ANY_STAFF_ROLE)
export class ConversationsController {
  constructor(private readonly conversations: ConversationsService) {}

  @Get()
  list(@Query() query: ConversationListQueryDto) {
    return this.conversations.list(query);
  }

  /** Declared before `:stayId` routes so the literal path wins. */
  @Get('unread-count')
  unreadCount() {
    return this.conversations.unreadCount();
  }

  @Get(':stayId/messages')
  messages(@Param('stayId') stayId: string, @Query() query: ConversationMessagesQueryDto) {
    return this.conversations.messages(stayId, query);
  }

  @Post(':stayId/messages')
  reply(@Param('stayId') stayId: string, @Body() dto: ReplyMessageDto, @CurrentStaff() staff: StaffMember) {
    return this.conversations.reply(stayId, dto.text, staff);
  }

  @Post(':stayId/read')
  @HttpCode(HttpStatus.OK)
  read(@Param('stayId') stayId: string) {
    return this.conversations.markRead(stayId);
  }
}
