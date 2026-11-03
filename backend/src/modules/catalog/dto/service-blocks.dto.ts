import { Type } from 'class-transformer';
import {
  ArrayMaxSize,
  IsArray,
  IsBoolean,
  IsDefined,
  IsIn,
  IsInt,
  IsNumber,
  IsOptional,
  IsString,
  Matches,
  Max,
  MaxLength,
  Min,
  ValidateIf,
  ValidateNested,
} from 'class-validator';
import {
  ISO_DATE_PATTERN,
  LONG_TEXT_MAX,
  SHORT_TEXT_MAX,
  TIME_OF_DAY_PATTERN,
} from '../../../common/validation/field-limits';
import {
  OFFERED_WHEN,
  OfferedWhen,
  PRICING_MODES,
  PricingMode,
  SELECTION_MODES,
  TRANSPORT_PRICE_BASIS,
  WEEKDAYS,
  Weekday,
  WELLNESS_LOCATIONS,
} from '../../../domain/catalog/catalog.models';
import { Department } from '../../../domain/models/domain.models';
import { LongTextDto, notNull, ShortTextDto } from './catalog-common.dto';

const DEPARTMENTS: Department[] = [
  'CONCIERGE', 'CULINARY', 'MARINE', 'TRANSPORT', 'HOUSEKEEPING', 'ENGINEERING', 'WELLNESS',
];
const MAX_AMOUNT_USD = 1_000_000;
const MAX_HOURS = 720;

class PricingFieldsDto {
  @IsOptional()
  @ValidateIf(notNull)
  @IsNumber({ maxDecimalPlaces: 2 })
  @Min(0)
  @Max(MAX_AMOUNT_USD)
  amount?: number | null;

  @IsOptional()
  @IsIn(['USD'])
  currency?: 'USD';

  @IsOptional()
  @IsBoolean()
  chargeToFolio?: boolean;

  @IsOptional()
  @ValidateNested()
  @Type(() => LongTextDto)
  note?: LongTextDto;
}

export class CreatePricingDto extends PricingFieldsDto {
  @IsIn(PRICING_MODES)
  mode!: PricingMode;
}

export class UpdatePricingDto extends PricingFieldsDto {
  @IsOptional()
  @IsIn(PRICING_MODES)
  mode?: PricingMode;
}

export class TimeSlotDto {
  @Matches(TIME_OF_DAY_PATTERN, { message: 'start must be HH:mm' })
  start!: string;

  @Matches(TIME_OF_DAY_PATTERN, { message: 'end must be HH:mm' })
  end!: string;
}

export class AvailabilityDto {
  @IsOptional()
  @IsArray()
  @ArrayMaxSize(WEEKDAYS.length)
  @IsIn(WEEKDAYS, { each: true })
  weekdays?: Weekday[];

  @IsOptional()
  @IsArray()
  @ArrayMaxSize(24)
  @ValidateNested({ each: true })
  @Type(() => TimeSlotDto)
  timeSlots?: TimeSlotDto[];

  @IsOptional()
  @IsArray()
  @ArrayMaxSize(366)
  @Matches(ISO_DATE_PATTERN, { each: true, message: 'blockedDates must be ISO dates (YYYY-MM-DD)' })
  blockedDates?: string[];

  @IsOptional() @ValidateIf(notNull) @IsInt() @Min(0) @Max(MAX_HOURS)
  minLeadHours?: number | null;

  @IsOptional() @ValidateIf(notNull) @IsInt() @Min(0) @Max(MAX_HOURS)
  cancellationHours?: number | null;

  @IsOptional() @ValidateIf(notNull) @IsInt() @Min(1) @Max(500)
  minGuests?: number | null;

  @IsOptional() @ValidateIf(notNull) @IsInt() @Min(1) @Max(500)
  maxGuests?: number | null;

  @IsOptional() @ValidateIf(notNull) @IsInt() @Min(1) @Max(1440)
  durationMinutes?: number | null;

  @IsOptional() @ValidateIf(notNull) @IsIn(OFFERED_WHEN)
  offeredWhen?: OfferedWhen | null;
}

export class GuestInfoDto {
  @IsOptional() @ValidateNested() @Type(() => LongTextDto) includes?: LongTextDto;
  @IsOptional() @ValidateNested() @Type(() => LongTextDto) excludes?: LongTextDto;
  @IsOptional() @ValidateNested() @Type(() => LongTextDto) whatToBring?: LongTextDto;
  @IsOptional() @ValidateNested() @Type(() => LongTextDto) location?: LongTextDto;
  @IsOptional() @ValidateNested() @Type(() => LongTextDto) restrictions?: LongTextDto;
  @IsOptional() @ValidateNested() @Type(() => LongTextDto) cancellationPolicy?: LongTextDto;
}

export class GuestFormDto {
  @IsOptional() @IsBoolean() date?: boolean;
  @IsOptional() @IsBoolean() time?: boolean;
  @IsOptional() @IsBoolean() guests?: boolean;
  @IsOptional() @IsBoolean() notes?: boolean;
  @IsOptional() @IsBoolean() dietary?: boolean;
  @IsOptional() @IsBoolean() health?: boolean;
}

/** Staff-only operation data. */
export class OperationDto {
  @IsOptional() @ValidateIf(notNull) @IsString() @MaxLength(SHORT_TEXT_MAX)
  providerId?: string | null;

  @IsOptional() @ValidateIf(notNull) @IsIn(DEPARTMENTS)
  responsibleDepartment?: Department | null;

  @IsOptional() @ValidateIf(notNull) @IsString() @MaxLength(SHORT_TEXT_MAX)
  responsibleStaffId?: string | null;

  @IsOptional() @IsBoolean()
  requiresConfirmation?: boolean;

  @IsOptional() @IsString() @MaxLength(LONG_TEXT_MAX)
  internalInstructions?: string;
}

export class BarDetailsDto {
  @IsOptional() @IsBoolean() ageConfirmationRequired?: boolean;
}

export class DiningDetailsDto {
  @IsOptional() @IsBoolean() pairingAvailable?: boolean;
}

export class StockingDetailsDto {
  @IsOptional() @ValidateIf(notNull) @IsInt() @Min(1) @Max(100)
  maxPerItem?: number | null;

  @IsOptional() @ValidateIf(notNull) @IsInt() @Min(0) @Max(MAX_HOURS)
  orderDeadlineHoursBeforeCheckIn?: number | null;
}

export class ItineraryStepDto {
  @IsDefined() @ValidateNested() @Type(() => ShortTextDto) title!: ShortTextDto;
  @IsOptional() @ValidateNested() @Type(() => LongTextDto) description?: LongTextDto;
  @IsOptional() @ValidateIf(notNull) @IsInt() @Min(1) @Max(1440) durationMinutes?: number | null;
}

export class ExperienceDetailsDto {
  @IsOptional() @IsArray() @ArrayMaxSize(20) @ValidateNested({ each: true }) @Type(() => ItineraryStepDto)
  itinerary?: ItineraryStepDto[];

  @IsOptional() @ValidateNested() @Type(() => ShortTextDto)
  meetingPoint?: ShortTextDto;

  @IsOptional() @IsArray() @ArrayMaxSize(10) @Matches(/^[a-z]{2}$/, { each: true, message: 'languages must be ISO 639-1 codes' })
  languages?: string[];

  @IsOptional() @ValidateIf(notNull) @IsInt() @Min(0) @Max(99)
  minAge?: number | null;
}

export class WellnessDetailsDto {
  @IsOptional() @ValidateIf(notNull) @IsIn(WELLNESS_LOCATIONS)
  location?: (typeof WELLNESS_LOCATIONS)[number] | null;

  @IsOptional() @IsArray() @ArrayMaxSize(20) @ValidateNested({ each: true }) @Type(() => ShortTextDto)
  healthQuestions?: ShortTextDto[];

  @IsOptional() @ValidateNested() @Type(() => LongTextDto)
  contraindications?: LongTextDto;
}

export class PreferenceDetailsDto {
  @IsOptional() @IsIn(SELECTION_MODES)
  selection?: (typeof SELECTION_MODES)[number];

  @IsOptional() @ValidateIf(notNull) @IsInt() @Min(0) @Max(MAX_HOURS)
  changeDeadlineHours?: number | null;
}

export class TransportDetailsDto {
  @IsOptional() @IsArray() @ArrayMaxSize(20) @Matches(/^[A-Z]{3}$/, { each: true, message: 'airportCodes must be IATA codes' })
  airportCodes?: string[];

  @IsOptional() @ValidateIf(notNull) @IsIn(TRANSPORT_PRICE_BASIS)
  priceBasis?: (typeof TRANSPORT_PRICE_BASIS)[number] | null;

  @IsOptional() @IsBoolean()
  flightDetailsRequired?: boolean;
}
