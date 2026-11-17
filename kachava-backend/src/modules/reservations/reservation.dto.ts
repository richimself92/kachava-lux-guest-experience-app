import { Type } from 'class-transformer';
import { IsIn, IsObject, IsOptional, IsString, Matches, MaxLength, ValidateIf, ValidateNested } from 'class-validator';
import { LANGUAGE_PATTERN, LONG_TEXT_MAX, SHORT_TEXT_MAX } from '../../common/validation/field-limits';
import { STAY_ACTIONS, StayAction } from '../../domain/stays/stay-transitions';
import { StayListQueryDto } from '../admin/dto/admin.dto';

const ID_MAX = 100;

/** `GET /admin/stays`: `status`, `villaId`, `from`/`to` (on the sort date), `q` guest name, `sort=checkIn|checkOut:asc|desc`. */
export class ReservationListQueryDto extends StayListQueryDto {}

/** `GET /admin/guests`: one row per stay; `q` searches the guest name. */
export class GuestListQueryDto extends StayListQueryDto {}

export class StayWifiDto {
  @IsOptional() @IsString() @MaxLength(SHORT_TEXT_MAX)
  ssid?: string;

  @IsOptional() @IsString() @MaxLength(SHORT_TEXT_MAX)
  password?: string;
}

/** Staff edits of a reservation; `action` moves the status (CANCEL needs `reason`). */
export class UpdateReservationDto {
  @IsOptional() @IsString() @MaxLength(SHORT_TEXT_MAX)
  resortHostName?: string;

  @IsOptional() @IsString() @MaxLength(ID_MAX)
  resortHostStaffId?: string;

  @IsOptional() @IsString() @MaxLength(LONG_TEXT_MAX)
  internalNotes?: string;

  /** `null` clears it. */
  @IsOptional() @ValidateIf((_, value) => value !== null)
  @Matches(LANGUAGE_PATTERN, { message: 'language must be a language code such as en or es' })
  language?: string | null;

  /** Overrides the villa Wi-Fi for this stay only. */
  @IsOptional() @IsObject() @ValidateNested() @Type(() => StayWifiDto)
  wifi?: StayWifiDto;

  @IsOptional() @IsIn(STAY_ACTIONS)
  action?: StayAction;

  @IsOptional() @IsString() @MaxLength(LONG_TEXT_MAX)
  reason?: string;
}
