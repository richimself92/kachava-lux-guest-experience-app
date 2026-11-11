import { Type } from 'class-transformer';
import {
  ArrayMaxSize,
  IsArray,
  IsBoolean,
  IsInt,
  IsNotEmpty,
  IsNumber,
  IsOptional,
  IsString,
  IsTimeZone,
  Matches,
  Max,
  MaxLength,
  Min,
  ValidateIf,
  ValidateNested,
} from 'class-validator';
import { SHORT_TEXT_MAX, TIME_OF_DAY_PATTERN } from '../../common/validation/field-limits';

export const AIRPORTS_MAX = 20;
const IATA_CODE = /^[A-Z]{3}$/;
const notNull = (_: object, value: unknown) => value !== null;

export class AirportSettingDto {
  @Matches(IATA_CODE, { message: 'code must be a 3-letter uppercase IATA code' })
  code!: string;

  @IsString()
  @IsNotEmpty()
  @MaxLength(SHORT_TEXT_MAX)
  name!: string;

  @IsNumber()
  @Min(0)
  @Max(24)
  departureBufferHours!: number;

  @IsOptional()
  @IsBoolean()
  isActive?: boolean;
}

/** Partial update; `null` clears a value back to "not configured". */
export class UpdateSettingsDto {
  @IsOptional()
  @ValidateIf(notNull)
  @Matches(TIME_OF_DAY_PATTERN, { message: 'checkInTime must be HH:mm' })
  checkInTime?: string | null;

  @IsOptional()
  @ValidateIf(notNull)
  @Matches(TIME_OF_DAY_PATTERN, { message: 'checkOutTime must be HH:mm' })
  checkOutTime?: string | null;

  @IsOptional()
  @ValidateIf(notNull)
  @IsTimeZone()
  timeZone?: string | null;

  @IsOptional()
  @IsArray()
  @ArrayMaxSize(AIRPORTS_MAX)
  @ValidateNested({ each: true })
  @Type(() => AirportSettingDto)
  airports?: AirportSettingDto[];

  @IsOptional()
  @ValidateIf(notNull)
  @IsInt()
  @Min(1)
  @Max(168)
  transportAlertLeadHours?: number | null;
}
