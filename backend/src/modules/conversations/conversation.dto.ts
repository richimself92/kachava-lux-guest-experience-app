import { IsBoolean, IsNotEmpty, IsOptional, IsString, MaxLength } from 'class-validator';
import { ListQueryDto } from '../../common/listing/list-query';
import { QueryBoolean } from '../../common/listing/query-transforms';
import { LONG_TEXT_MAX } from '../../common/validation/field-limits';

/** `GET /admin/conversations?q&unread&awaitingReply&page&pageSize&sort=lastMessageAt:desc`. */
export class ConversationListQueryDto extends ListQueryDto {
  @IsOptional() @QueryBoolean() @IsBoolean()
  unread?: boolean;

  @IsOptional() @QueryBoolean() @IsBoolean()
  awaitingReply?: boolean;
}

/** `GET /admin/conversations/:stayId/messages?page&pageSize` (page 1 = newest messages). */
export class ConversationMessagesQueryDto extends ListQueryDto {}

export class ReplyMessageDto {
  @IsString() @IsNotEmpty() @MaxLength(LONG_TEXT_MAX)
  text!: string;
}
