import {
  IsEmail,
  IsIn,
  IsInt,
  IsNotEmpty,
  IsOptional,
  IsString,
  Matches,
  Max,
  MaxLength,
  Min,
} from 'class-validator';
import { ListQueryDto } from '../../../common/listing/list-query';
import {
  EMAIL_MAX,
  ISO_DATE_PATTERN,
  LANGUAGE_PATTERN,
  SHORT_TEXT_MAX,
  VILLA_ID_PATTERN,
} from '../../../common/validation/field-limits';
import { StayLifecycleStatus } from '../../../domain/models/domain.models';

const STAY_STATUSES: StayLifecycleStatus[] = ['PRE_ARRIVAL', 'ACTIVE_STAY', 'CHECKED_OUT', 'EXPIRED', 'CANCELLED'];

export class AdminLoginDto {
  @IsEmail()
  @MaxLength(EMAIL_MAX)
  email!: string;

  @IsOptional()
  @IsString()
  @MaxLength(SHORT_TEXT_MAX)
  passcode?: string;

  @IsOptional()
  @IsString()
  @MaxLength(SHORT_TEXT_MAX)
  password?: string;
}

/** A reservation references an existing villa and uses ISO calendar dates. */
export class CreateReservationDto {
  @IsString()
  @IsNotEmpty()
  @MaxLength(SHORT_TEXT_MAX)
  guestName!: string;

  @IsOptional()
  @IsString()
  @MaxLength(SHORT_TEXT_MAX)
  partnerName?: string;

  @IsString()
  @MaxLength(SHORT_TEXT_MAX)
  @Matches(VILLA_ID_PATTERN)
  villaId!: string;

  @Matches(ISO_DATE_PATTERN, { message: 'checkIn must be an ISO date (YYYY-MM-DD)' })
  checkIn!: string;

  @Matches(ISO_DATE_PATTERN, { message: 'checkOut must be an ISO date (YYYY-MM-DD)' })
  checkOut!: string;

  @IsOptional()
  @IsInt()
  @Min(1)
  @Max(50)
  guestsCount?: number;

  @IsOptional()
  @IsString()
  @MaxLength(SHORT_TEXT_MAX)
  celebration?: string;

  @IsOptional()
  @IsString()
  @MaxLength(SHORT_TEXT_MAX)
  occasion?: string;

  @IsOptional()
  @IsString()
  @MaxLength(EMAIL_MAX)
  email?: string;

  @IsOptional()
  @IsString()
  @MaxLength(SHORT_TEXT_MAX)
  phone?: string;

  @IsOptional()
  @Matches(LANGUAGE_PATTERN, { message: 'language must be a language code such as en or es' })
  language?: string;

  @IsOptional()
  @IsString()
  @MaxLength(SHORT_TEXT_MAX)
  wifiSsid?: string;

  @IsOptional()
  @IsString()
  @MaxLength(SHORT_TEXT_MAX)
  wifiPasscode?: string;
}

export class StayListQueryDto extends ListQueryDto {
  @IsOptional()
  @IsIn(STAY_STATUSES)
  status?: StayLifecycleStatus;

  @IsOptional()
  @IsString()
  @MaxLength(SHORT_TEXT_MAX)
  villaId?: string;

  @IsOptional()
  @Matches(ISO_DATE_PATTERN, { message: 'from must be an ISO date (YYYY-MM-DD)' })
  from?: string;

  @IsOptional()
  @Matches(ISO_DATE_PATTERN, { message: 'to must be an ISO date (YYYY-MM-DD)' })
  to?: string;
}
