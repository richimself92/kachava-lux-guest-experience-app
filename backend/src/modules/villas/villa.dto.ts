import { Type } from 'class-transformer';
import {
  IsBoolean,
  IsIn,
  IsInt,
  IsNotEmpty,
  IsOptional,
  IsString,
  Matches,
  Max,
  MaxLength,
  Min,
  ValidateNested,
} from 'class-validator';
import { ListQueryDto } from '../../common/listing/list-query';
import { QueryBoolean } from '../../common/listing/query-transforms';
import { ISO_DATE_PATTERN, LONG_TEXT_MAX, SHORT_TEXT_MAX } from '../../common/validation/field-limits';
import {
  VILLA_HOUSEKEEPING_STATUSES,
  VILLA_MAINTENANCE_STATUSES,
  VILLA_OPERATIONAL_STATUSES,
  VillaHousekeepingStatus,
  VillaMaintenanceStatus,
  VillaOperationalStatus,
} from '../../domain/models/resort-config.models';

export const VILLA_MAX_GUESTS_LIMIT = 50;

export class VillaWifiDto {
  @IsString()
  @MaxLength(SHORT_TEXT_MAX)
  ssid!: string;

  @IsString()
  @MaxLength(SHORT_TEXT_MAX)
  password!: string;
}

export class CreateVillaDto {
  @IsString()
  @IsNotEmpty()
  @MaxLength(SHORT_TEXT_MAX)
  name!: string;

  @IsString()
  @IsNotEmpty()
  @MaxLength(SHORT_TEXT_MAX)
  category!: string;

  @IsInt()
  @Min(1)
  @Max(VILLA_MAX_GUESTS_LIMIT)
  capacity!: number;

  @IsOptional()
  @ValidateNested()
  @Type(() => VillaWifiDto)
  wifi?: VillaWifiDto;

  @IsIn(VILLA_OPERATIONAL_STATUSES)
  operationalStatus!: VillaOperationalStatus;

  @IsIn(VILLA_HOUSEKEEPING_STATUSES)
  housekeepingStatus!: VillaHousekeepingStatus;

  @IsIn(VILLA_MAINTENANCE_STATUSES)
  maintenanceStatus!: VillaMaintenanceStatus;

  @IsOptional()
  @IsString()
  @MaxLength(LONG_TEXT_MAX)
  maintenanceNote?: string;

  @IsOptional()
  @IsBoolean()
  isActive?: boolean;
}

export class UpdateVillaDto {
  @IsOptional()
  @IsString()
  @IsNotEmpty()
  @MaxLength(SHORT_TEXT_MAX)
  name?: string;

  @IsOptional()
  @IsString()
  @IsNotEmpty()
  @MaxLength(SHORT_TEXT_MAX)
  category?: string;

  @IsOptional()
  @IsInt()
  @Min(1)
  @Max(VILLA_MAX_GUESTS_LIMIT)
  capacity?: number;

  @IsOptional()
  @ValidateNested()
  @Type(() => VillaWifiDto)
  wifi?: VillaWifiDto;

  @IsOptional()
  @IsIn(VILLA_OPERATIONAL_STATUSES)
  operationalStatus?: VillaOperationalStatus;

  @IsOptional()
  @IsIn(VILLA_HOUSEKEEPING_STATUSES)
  housekeepingStatus?: VillaHousekeepingStatus;

  @IsOptional()
  @IsIn(VILLA_MAINTENANCE_STATUSES)
  maintenanceStatus?: VillaMaintenanceStatus;

  @IsOptional()
  @IsString()
  @MaxLength(LONG_TEXT_MAX)
  maintenanceNote?: string;

  @IsOptional()
  @IsBoolean()
  isActive?: boolean;
}

export class VillaListQueryDto extends ListQueryDto {
  @IsOptional()
  @QueryBoolean()
  @IsBoolean()
  isActive?: boolean;

  @IsOptional()
  @IsIn(VILLA_OPERATIONAL_STATUSES)
  operationalStatus?: VillaOperationalStatus;

  @IsOptional()
  @IsString()
  @MaxLength(SHORT_TEXT_MAX)
  category?: string;
}

/** `GET /admin/villas/available`: the nights to book (ISO dates, checkOut exclusive). */
export class AvailableVillasQueryDto {
  @Matches(ISO_DATE_PATTERN, { message: 'checkIn must be an ISO date (YYYY-MM-DD)' })
  checkIn!: string;

  @Matches(ISO_DATE_PATTERN, { message: 'checkOut must be an ISO date (YYYY-MM-DD)' })
  checkOut!: string;
}
