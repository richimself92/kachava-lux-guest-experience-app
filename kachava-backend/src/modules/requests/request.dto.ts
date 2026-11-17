import { IsIn, IsNotEmpty, IsOptional, IsString, Matches, MaxLength } from 'class-validator';
import { ListQueryDto } from '../../common/listing/list-query';
import { ISO_DATE_PATTERN, SHORT_TEXT_MAX } from '../../common/validation/field-limits';
import { SERVICE_SECTIONS, ServiceSection } from '../../domain/catalog/catalog.models';
import { REQUEST_ACTIONS, RequestAction } from '../../domain/requests/request-transitions';
import {
  REQUEST_STATUS_FILTERS,
  REQUEST_USAGE_TYPES,
  RequestStatusFilter,
  RequestUsageType,
} from '../../domain/requests/service-requests';

/** `?section=&status=&usageType=&from=&to=&q=&page=&pageSize=&sort=at|queue:asc|desc`; dates are resort days. */
export class RequestListQueryDto extends ListQueryDto {
  @IsOptional()
  @IsIn(SERVICE_SECTIONS)
  section?: ServiceSection;

  @IsOptional()
  @IsIn(REQUEST_STATUS_FILTERS)
  status?: RequestStatusFilter;

  @IsOptional()
  @IsIn(REQUEST_USAGE_TYPES)
  usageType?: RequestUsageType;

  @IsOptional()
  @Matches(ISO_DATE_PATTERN, { message: 'from must be an ISO date (YYYY-MM-DD)' })
  from?: string;

  @IsOptional()
  @Matches(ISO_DATE_PATTERN, { message: 'to must be an ISO date (YYYY-MM-DD)' })
  to?: string;
}

export class TransitionRequestDto {
  @IsIn(REQUEST_ACTIONS)
  action!: RequestAction;

  /** Required by CANCEL (checked by the domain rule). */
  @IsOptional()
  @IsString()
  @IsNotEmpty()
  @MaxLength(SHORT_TEXT_MAX)
  reason?: string;
}
