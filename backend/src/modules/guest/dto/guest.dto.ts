import { Type } from 'class-transformer';
import {
  IsArray,
  IsBoolean,
  IsInt,
  IsNotEmpty,
  IsNumber,
  IsObject,
  IsOptional,
  IsString,
  Max,
  Min,
  ValidateNested,
} from 'class-validator';

export class VerifyStepUpDto {
  @IsOptional()
  @IsString()
  villaNumber?: string;

  @IsOptional()
  @IsString()
  lastName?: string;
}

export class UpdateTransferDto {
  @IsOptional()
  @IsString()
  arrivalDate?: string;

  @IsOptional()
  @IsString()
  arrivalAirport?: string;

  @IsOptional()
  @IsString()
  airline?: string;

  @IsOptional()
  @IsString()
  flightNumber?: string;

  @IsOptional()
  @IsString()
  arrivalTime?: string;

  @IsOptional()
  @IsString()
  estimatedLanding?: string;

  @IsOptional()
  @IsString()
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
  notes?: string;

  @IsOptional()
  @IsString()
  status?: string;
}

export class UpdatePersonalizationDto {
  @IsOptional()
  @IsString()
  tripPurpose?: string;

  @IsOptional()
  @IsString()
  occasionDetails?: string;

  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  selectedInterests?: string[];

  @IsOptional()
  @IsString()
  dietary?: string;

  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  dietaryAllergies?: string[];

  @IsOptional()
  @IsString()
  allergies?: string;

  @IsOptional()
  @IsString()
  villaScent?: string;

  @IsOptional()
  @IsString()
  scentProfile?: string;

  @IsOptional()
  @IsString()
  pillowType?: string;

  @IsOptional()
  @IsString()
  pillowSelection?: string;

  @IsOptional()
  @IsString()
  temperatureCurve?: string;

  @IsOptional()
  @IsString()
  lightingRhythm?: string;

  @IsOptional()
  @IsString()
  housekeepingCadence?: string;

  @IsOptional()
  @IsString()
  commChannel?: string;
}

export class LarderCartLineDto {
  @IsString()
  @IsNotEmpty()
  itemId!: string;

  @IsInt()
  @Min(0)
  @Max(20)
  quantity!: number;
}

export class UpdateLarderOrderDto {
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => LarderCartLineDto)
  items!: LarderCartLineDto[];
}

export class CreateBookingDto {
  @IsOptional()
  @IsString()
  category?: string;

  @IsOptional()
  @IsString()
  bookingType?: string;

  @IsString()
  @IsNotEmpty()
  catalogRefId!: string;

  @IsOptional()
  @IsString()
  title?: string;

  @IsString()
  @IsNotEmpty()
  scheduledDate!: string;

  @IsString()
  @IsNotEmpty()
  scheduledTimeSlot!: string;

  @IsOptional()
  @IsInt()
  @Min(1)
  @Max(20)
  partySize?: number;

  @IsOptional()
  @IsObject()
  metadata?: Record<string, unknown>;
}

export class CreateConciergeRequestDto {
  @IsOptional()
  @IsString()
  type?: 'issue' | 'request' | 'ask' | 'reservation';

  @IsOptional()
  @IsString()
  category?: string;

  @IsString()
  @IsNotEmpty()
  title!: string;

  @IsOptional()
  @IsString()
  details?: string;

  @IsOptional()
  @IsString()
  location?: string;

  @IsOptional()
  @IsString()
  photoStoragePath?: string;
}

export class CreateConciergeMessageDto {
  @IsString()
  @IsNotEmpty()
  text!: string;

  @IsOptional()
  @IsString()
  senderName?: string;
}

export class GenerateUploadUrlDto {
  @IsOptional()
  @IsString()
  requestId?: string;

  @IsString()
  @IsNotEmpty()
  fileName!: string;

  @IsString()
  @IsNotEmpty()
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
  selectedSentiment?: 'transcendent' | 'serene' | 'tuned' | 'direct';

  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  selectedAspects?: string[];

  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  housekeepingPreferences?: string[];

  @IsOptional()
  @IsString()
  note?: string;
}

export class ExpressCheckoutDto {
  @IsOptional()
  @IsBoolean()
  lateCheckoutRequested?: boolean;

  @IsOptional()
  @IsString()
  requestedCheckoutTime?: string;
}
