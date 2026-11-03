import { Type } from 'class-transformer';
import {
  ArrayMaxSize,
  IsArray,
  IsBoolean,
  IsInt,
  IsNotEmpty,
  IsNumber,
  IsObject,
  IsOptional,
  IsString,
  Matches,
  Max,
  MaxLength,
  Min,
  ValidateNested,
} from 'class-validator';
import {
  ISO_DATE_PATTERN,
  LARDER_LINES_MAX,
  LONG_TEXT_MAX,
  MaxJsonBytes,
  METADATA_MAX_BYTES,
  SHORT_TEXT_MAX,
  STRING_LIST_MAX,
  TIME_OF_DAY_PATTERN,
  URL_MAX,
} from '../../../common/validation/field-limits';

export class VerifyStepUpDto {
  @IsOptional()
  @IsString()
  @MaxLength(SHORT_TEXT_MAX)
  villaNumber?: string;

  @IsOptional()
  @IsString()
  @MaxLength(SHORT_TEXT_MAX)
  lastName?: string;
}

export class UpdateTransferDto {
  @IsOptional()
  @IsString()
  @MaxLength(SHORT_TEXT_MAX)
  arrivalDate?: string;

  @IsOptional()
  @IsString()
  @MaxLength(SHORT_TEXT_MAX)
  arrivalAirport?: string;

  @IsOptional()
  @IsString()
  @MaxLength(SHORT_TEXT_MAX)
  airline?: string;

  @IsOptional()
  @IsString()
  @MaxLength(SHORT_TEXT_MAX)
  flightNumber?: string;

  @IsOptional()
  @IsString()
  @MaxLength(SHORT_TEXT_MAX)
  arrivalTime?: string;

  @IsOptional()
  @IsString()
  @MaxLength(SHORT_TEXT_MAX)
  estimatedLanding?: string;

  @IsOptional()
  @IsString()
  @MaxLength(SHORT_TEXT_MAX)
  terminal?: string;

  @IsOptional()
  @IsInt()
  @Min(1)
  @Max(12)
  partySize?: number;

  @IsOptional()
  @IsInt()
  @Min(0)
  @Max(30)
  luggageCount?: number;

  @IsOptional()
  @IsInt()
  @Min(0)
  @Max(20)
  luggageChecked?: number;

  @IsOptional()
  @IsInt()
  @Min(0)
  @Max(20)
  luggageCarryOn?: number;

  @IsOptional()
  @IsString()
  @MaxLength(LONG_TEXT_MAX)
  notes?: string;

  @IsOptional()
  @IsString()
  @MaxLength(SHORT_TEXT_MAX)
  status?: string;
}

export class UpdatePersonalizationDto {
  @IsOptional()
  @IsString()
  @MaxLength(SHORT_TEXT_MAX)
  tripPurpose?: string;

  @IsOptional()
  @IsString()
  @MaxLength(LONG_TEXT_MAX)
  occasionDetails?: string;

  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  @ArrayMaxSize(STRING_LIST_MAX)
  @MaxLength(SHORT_TEXT_MAX, { each: true })
  selectedInterests?: string[];

  @IsOptional()
  @IsString()
  @MaxLength(SHORT_TEXT_MAX)
  dietary?: string;

  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  @ArrayMaxSize(STRING_LIST_MAX)
  @MaxLength(SHORT_TEXT_MAX, { each: true })
  dietaryAllergies?: string[];

  @IsOptional()
  @IsString()
  @MaxLength(SHORT_TEXT_MAX)
  allergies?: string;

  @IsOptional()
  @IsString()
  @MaxLength(SHORT_TEXT_MAX)
  villaScent?: string;

  @IsOptional()
  @IsString()
  @MaxLength(SHORT_TEXT_MAX)
  scentProfile?: string;

  @IsOptional()
  @IsString()
  @MaxLength(SHORT_TEXT_MAX)
  pillowType?: string;

  @IsOptional()
  @IsString()
  @MaxLength(SHORT_TEXT_MAX)
  pillowSelection?: string;

  @IsOptional()
  @IsString()
  @MaxLength(SHORT_TEXT_MAX)
  temperatureCurve?: string;

  @IsOptional()
  @IsString()
  @MaxLength(SHORT_TEXT_MAX)
  lightingRhythm?: string;

  @IsOptional()
  @IsString()
  @MaxLength(SHORT_TEXT_MAX)
  housekeepingCadence?: string;

  @IsOptional()
  @IsString()
  @MaxLength(SHORT_TEXT_MAX)
  commChannel?: string;
}

export class LarderCartLineDto {
  @IsString()
  @IsNotEmpty()
  @MaxLength(SHORT_TEXT_MAX)
  itemId!: string;

  @IsInt()
  @Min(0)
  @Max(20)
  quantity!: number;
}

/** Replaces the stay's villa-stocking order with lines of one ORDER service. */
export class UpdateLarderOrderDto {
  @IsString()
  @IsNotEmpty()
  @MaxLength(SHORT_TEXT_MAX)
  serviceId!: string;

  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => LarderCartLineDto)
  @ArrayMaxSize(LARDER_LINES_MAX)
  items!: LarderCartLineDto[];
}

/** Books a catalog service (optionally one of its items); price comes from the catalog only. */
export class CreateBookingDto {
  @IsString()
  @IsNotEmpty()
  @MaxLength(SHORT_TEXT_MAX)
  serviceId!: string;

  @IsOptional()
  @IsString()
  @IsNotEmpty()
  @MaxLength(SHORT_TEXT_MAX)
  itemId?: string;

  @Matches(ISO_DATE_PATTERN, { message: 'scheduledDate must be an ISO date (YYYY-MM-DD)' })
  scheduledDate!: string;

  @IsOptional()
  @Matches(TIME_OF_DAY_PATTERN, { message: 'scheduledTimeSlot must be HH:mm' })
  scheduledTimeSlot?: string;

  @IsOptional()
  @IsInt()
  @Min(1)
  @Max(50)
  partySize?: number;

  @IsOptional()
  @IsObject()
  @MaxJsonBytes(METADATA_MAX_BYTES)
  metadata?: Record<string, unknown>;
}

export class CreateConciergeRequestDto {
  @IsOptional()
  @IsString()
  @MaxLength(SHORT_TEXT_MAX)
  type?: 'issue' | 'request' | 'ask' | 'reservation';

  @IsOptional()
  @IsString()
  @MaxLength(SHORT_TEXT_MAX)
  category?: string;

  @IsString()
  @IsNotEmpty()
  @MaxLength(SHORT_TEXT_MAX)
  title!: string;

  @IsOptional()
  @IsString()
  @MaxLength(LONG_TEXT_MAX)
  details?: string;

  @IsOptional()
  @IsString()
  @MaxLength(SHORT_TEXT_MAX)
  location?: string;

  @IsOptional()
  @IsString()
  @MaxLength(URL_MAX)
  photoStoragePath?: string;
}

export class CreateConciergeMessageDto {
  @IsString()
  @IsNotEmpty()
  @MaxLength(LONG_TEXT_MAX)
  text!: string;

  @IsOptional()
  @IsString()
  @MaxLength(SHORT_TEXT_MAX)
  senderName?: string;
}

export class GenerateUploadUrlDto {
  @IsOptional()
  @IsString()
  @MaxLength(SHORT_TEXT_MAX)
  requestId?: string;

  @IsString()
  @IsNotEmpty()
  @MaxLength(SHORT_TEXT_MAX)
  fileName!: string;

  @IsString()
  @IsNotEmpty()
  @MaxLength(SHORT_TEXT_MAX)
  contentType!: string;

  @IsNumber()
  fileSizeBytes!: number;
}

export class CreateMidStayCheckInDto {
  @IsOptional()
  @IsInt()
  @Min(1)
  @Max(5)
  rating?: number;

  @IsOptional()
  @IsInt()
  @Min(1)
  @Max(30)
  dayOfStay?: number;

  @IsOptional()
  @IsString()
  @MaxLength(SHORT_TEXT_MAX)
  selectedSentiment?: 'transcendent' | 'serene' | 'tuned' | 'direct';

  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  @ArrayMaxSize(STRING_LIST_MAX)
  @MaxLength(SHORT_TEXT_MAX, { each: true })
  selectedAspects?: string[];

  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  @ArrayMaxSize(STRING_LIST_MAX)
  @MaxLength(SHORT_TEXT_MAX, { each: true })
  housekeepingPreferences?: string[];

  @IsOptional()
  @IsString()
  @MaxLength(LONG_TEXT_MAX)
  note?: string;
}

export class ExpressCheckoutDto {
  @IsOptional()
  @IsBoolean()
  lateCheckoutRequested?: boolean;

  @IsOptional()
  @IsString()
  @MaxLength(SHORT_TEXT_MAX)
  requestedCheckoutTime?: string;
}
