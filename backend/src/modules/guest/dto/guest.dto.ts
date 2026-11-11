import { Type } from 'class-transformer';
import {
  ArrayMaxSize,
  IsArray,
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

/** `PUT /stays/:guestUuid/orders/:serviceId`: the guest's whole order for that ORDER service. */
export class UpdateServiceOrderDto {
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => LarderCartLineDto)
  @ArrayMaxSize(LARDER_LINES_MAX)
  items!: LarderCartLineDto[];
}

/** Journey task ids such as `1:core:flight` or `2:section:DINING`. */
export const JOURNEY_TASK_ID_PATTERN = /^[A-Za-z0-9:_.-]{1,100}$/;
export const JOURNEY_MARKS_MAX = 60;

/** Replaces the lists that are sent (an absent list is kept). */
export class UpdateJourneyDto {
  @IsOptional()
  @IsArray()
  @ArrayMaxSize(JOURNEY_MARKS_MAX)
  @Matches(JOURNEY_TASK_ID_PATTERN, { each: true, message: 'skippedTaskIds must be journey task ids' })
  skippedTaskIds?: string[];

  @IsOptional()
  @IsArray()
  @ArrayMaxSize(JOURNEY_MARKS_MAX)
  @Matches(JOURNEY_TASK_ID_PATTERN, { each: true, message: 'completedTaskIds must be journey task ids' })
  completedTaskIds?: string[];
}

/** Guest change of a REQUESTED booking; at least one field is required. */
export class ChangeBookingDto {
  @IsOptional()
  @Matches(ISO_DATE_PATTERN, { message: 'scheduledDate must be an ISO date (YYYY-MM-DD)' })
  scheduledDate?: string;

  @IsOptional()
  @Matches(TIME_OF_DAY_PATTERN, { message: 'scheduledTimeSlot must be HH:mm' })
  scheduledTimeSlot?: string;

  @IsOptional()
  @IsInt()
  @Min(1)
  @Max(50)
  partySize?: number;
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

/** A message needs text, a photo (from the upload-url `storagePath`) or both (checked by the service). */
export class CreateConciergeMessageDto {
  @IsOptional()
  @IsString()
  @MaxLength(LONG_TEXT_MAX)
  text?: string;

  @IsOptional()
  @IsString()
  @MaxLength(SHORT_TEXT_MAX)
  senderName?: string;

  @IsOptional()
  @IsString()
  @IsNotEmpty()
  @MaxLength(URL_MAX)
  photoStoragePath?: string;
}

/** Upload folders become storage path segments: letters, digits, `_` and `-` only. */
const UPLOAD_REQUEST_ID_PATTERN = /^[A-Za-z0-9_-]{1,100}$/;

export class GenerateUploadUrlDto {
  @IsOptional()
  @Matches(UPLOAD_REQUEST_ID_PATTERN, { message: 'requestId may only contain letters, digits, _ and -' })
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
