import { IsBoolean, IsIn, IsOptional, Matches } from 'class-validator';
import { ListQueryDto } from '../../common/listing/list-query';
import { QueryBoolean } from '../../common/listing/query-transforms';
import { ISO_DATE_PATTERN } from '../../common/validation/field-limits';
import {
  NOTIFICATION_CATEGORIES,
  NOTIFICATION_LEVELS,
  NotificationCategory,
  NotificationLevel,
} from '../../domain/notifications/notification-rules';

/** `GET /admin/notifications?level&read&category&from&to&q&page&pageSize&sort=createdAt:asc|desc`. */
export class NotificationListQueryDto extends ListQueryDto {
  @IsOptional() @IsIn(NOTIFICATION_LEVELS)
  level?: NotificationLevel;

  @IsOptional() @QueryBoolean() @IsBoolean()
  read?: boolean;

  @IsOptional() @IsIn(NOTIFICATION_CATEGORIES)
  category?: NotificationCategory;

  /** Inclusive resort days (Settings time zone) on `createdAt`. */
  @IsOptional() @Matches(ISO_DATE_PATTERN, { message: 'from must be an ISO date (YYYY-MM-DD)' })
  from?: string;

  @IsOptional() @Matches(ISO_DATE_PATTERN, { message: 'to must be an ISO date (YYYY-MM-DD)' })
  to?: string;
}
