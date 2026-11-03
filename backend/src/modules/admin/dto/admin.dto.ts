import {
  ArrayMaxSize,
  IsArray,
  IsBoolean,
  IsEmail,
  IsInt,
  IsNotEmpty,
  IsNumber,
  IsOptional,
  IsString,
  Matches,
  Max,
  MaxLength,
  Min,
} from 'class-validator';
import {
  EMAIL_MAX,
  LONG_TEXT_MAX,
  SHORT_TEXT_MAX,
  STRING_LIST_MAX,
  URL_MAX,
  VILLA_ID_PATTERN,
} from '../../../common/validation/field-limits';
import {
  Department,
  StayLifecycleStatus,
} from '../../../domain/models/domain.models';

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

export class CreateReservationDto {
  @IsString()
  @IsNotEmpty()
  @MaxLength(SHORT_TEXT_MAX)
  guestName!: string;

  @IsOptional()
  @IsString()
  @MaxLength(SHORT_TEXT_MAX)
  partnerName?: string;

  @IsOptional()
  @IsString()
  @MaxLength(SHORT_TEXT_MAX)
  @Matches(VILLA_ID_PATTERN)
  villaId?: string;

  @IsOptional()
  @IsString()
  @MaxLength(SHORT_TEXT_MAX)
  villaName?: string;

  @IsOptional()
  @IsString()
  @MaxLength(SHORT_TEXT_MAX)
  suiteName?: string;

  @IsOptional()
  @IsString()
  @MaxLength(SHORT_TEXT_MAX)
  checkIn?: string;

  @IsOptional()
  @IsString()
  @MaxLength(SHORT_TEXT_MAX)
  checkOut?: string;

  @IsOptional()
  @IsString()
  @MaxLength(SHORT_TEXT_MAX)
  stayDatesLabel?: string;

  @IsOptional()
  @IsInt()
  @Min(1)
  @Max(30)
  nights?: number;

  @IsOptional()
  @IsInt()
  @Min(1)
  @Max(12)
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
  @IsString()
  @MaxLength(SHORT_TEXT_MAX)
  wifiSsid?: string;

  @IsOptional()
  @IsString()
  @MaxLength(SHORT_TEXT_MAX)
  wifiPasscode?: string;
}

export class CreateStayDto extends CreateReservationDto {}

export class CreateVillaDto {
  @IsOptional() @IsString() @MaxLength(SHORT_TEXT_MAX) @Matches(VILLA_ID_PATTERN) villaId?: string;
  @IsOptional() @IsString() @MaxLength(SHORT_TEXT_MAX) villaName?: string;
  @IsOptional() @IsString() @MaxLength(SHORT_TEXT_MAX) suiteType?: string;
  @IsOptional() @IsString() @MaxLength(SHORT_TEXT_MAX) maxGuests?: string;
  @IsOptional() @IsString() @MaxLength(SHORT_TEXT_MAX) wifiSsid?: string;
  @IsOptional() @IsString() @MaxLength(SHORT_TEXT_MAX) wifiPasscode?: string;
}

export class UpdateStayWifiDto {
  @IsOptional()
  @IsString()
  @MaxLength(SHORT_TEXT_MAX)
  wifiSsid?: string;

  @IsOptional()
  @IsString()
  @MaxLength(SHORT_TEXT_MAX)
  wifiPasscode?: string;
}

export class AssignTransferDto {
  @IsOptional()
  @IsString()
  @MaxLength(SHORT_TEXT_MAX)
  assignedStaffId?: string;

  @IsOptional()
  @IsString()
  @MaxLength(SHORT_TEXT_MAX)
  assignedStaffName?: string;

  @IsOptional()
  @IsString()
  @MaxLength(SHORT_TEXT_MAX)
  assignedDriver?: string;

  @IsOptional()
  @IsString()
  @MaxLength(SHORT_TEXT_MAX)
  vehicleModel?: string;

  @IsOptional()
  @IsString()
  @MaxLength(SHORT_TEXT_MAX)
  meetingPoint?: string;

  @IsOptional()
  @IsString()
  @MaxLength(SHORT_TEXT_MAX)
  status?: string;

  @IsOptional()
  @IsString()
  @MaxLength(LONG_TEXT_MAX)
  adminDispatchNotes?: string;
}

export class AssignBookingDto {
  @IsOptional()
  @IsString()
  @MaxLength(SHORT_TEXT_MAX)
  assignedStaffId?: string;

  @IsOptional()
  @IsString()
  @MaxLength(SHORT_TEXT_MAX)
  assignedStaffName?: string;

  @IsOptional()
  @IsString()
  @MaxLength(SHORT_TEXT_MAX)
  assignedDepartment?: Department;

  @IsOptional()
  @IsString()
  @MaxLength(SHORT_TEXT_MAX)
  status?:
    | 'REQUESTED'
    | 'CONFIRMED'
    | 'IN_PREPARATION'
    | 'MODIFICATION_REQUESTED'
    | 'COMPLETED'
    | 'CANCELLED';

  @IsOptional()
  @IsString()
  @MaxLength(LONG_TEXT_MAX)
  adminNotes?: string;

  @IsOptional()
  @IsString()
  @MaxLength(LONG_TEXT_MAX)
  cancellationReason?: string;
}

export class UpdateLarderStatusDto {
  @IsOptional()
  @IsString()
  @MaxLength(SHORT_TEXT_MAX)
  assignedStaffId?: string;

  @IsOptional()
  @IsString()
  @MaxLength(SHORT_TEXT_MAX)
  assignedStaffName?: string;

  @IsOptional()
  @IsString()
  @MaxLength(SHORT_TEXT_MAX)
  provisioningStatus?: string;

  @IsOptional()
  @IsString()
  @MaxLength(SHORT_TEXT_MAX)
  status?: string;
}

export class UpdateAdminConciergeDto {
  @IsOptional()
  @IsString()
  @MaxLength(SHORT_TEXT_MAX)
  status?: 'Requested' | 'Assigned' | 'In Progress' | 'Completed';

  @IsOptional()
  @IsInt()
  @Min(1)
  @Max(4)
  currentStep?: 1 | 2 | 3 | 4;

  @IsOptional()
  @IsString()
  @MaxLength(SHORT_TEXT_MAX)
  assignedStaffId?: string;

  @IsOptional()
  @IsString()
  @MaxLength(SHORT_TEXT_MAX)
  assignedTo?: string;

  @IsOptional()
  @IsString()
  @MaxLength(SHORT_TEXT_MAX)
  assignedDepartment?: Department;

  @IsOptional()
  @IsString()
  @MaxLength(LONG_TEXT_MAX)
  notes?: string;

  @IsOptional()
  @IsString()
  @MaxLength(LONG_TEXT_MAX)
  replyMessage?: string;

  @IsOptional()
  @IsString()
  @MaxLength(LONG_TEXT_MAX)
  message?: string;
}

export class ApproveCheckoutDto {
  @IsOptional()
  @IsBoolean()
  approveLateCheckout?: boolean;

  @IsOptional()
  @IsString()
  @MaxLength(LONG_TEXT_MAX)
  adminNotes?: string;
}

export class UpdateStayStatusDto {
  @IsString()
  @IsNotEmpty()
  @MaxLength(SHORT_TEXT_MAX)
  status!: StayLifecycleStatus;
}

export class CreateExperienceCatalogDto {
  @IsOptional() @IsString() @MaxLength(SHORT_TEXT_MAX) id?: string;
  @IsString() @IsNotEmpty() @MaxLength(SHORT_TEXT_MAX) title!: string;
  @IsOptional() @IsString() @MaxLength(SHORT_TEXT_MAX) subtitle?: string;
  @IsOptional() @IsString() @MaxLength(SHORT_TEXT_MAX) duration?: string;
  @IsOptional() @IsString() @MaxLength(SHORT_TEXT_MAX) location?: string;
  @IsOptional() @IsString() @MaxLength(SHORT_TEXT_MAX) vehicleOrDetail?: string;
  @IsOptional() @IsString() @MaxLength(SHORT_TEXT_MAX) priceText?: string;
  @IsOptional() @IsNumber() @Min(0) basePriceUSD?: number;
  @IsOptional() @IsBoolean() isIncluded?: boolean;
  @IsOptional() @IsString() @MaxLength(SHORT_TEXT_MAX) inclusionLabel?: string;
  @IsOptional() @IsString() @MaxLength(URL_MAX) image?: string;
  @IsOptional() @IsString() @MaxLength(SHORT_TEXT_MAX) category?: string;
  @IsOptional() @IsString() @MaxLength(LONG_TEXT_MAX) description?: string;
  @IsOptional() @IsArray() @IsString({ each: true }) @ArrayMaxSize(STRING_LIST_MAX) @MaxLength(SHORT_TEXT_MAX, { each: true }) amenities?: string[];
  @IsOptional() @IsString() @MaxLength(SHORT_TEXT_MAX) actionLabel?: string;
  @IsOptional() @IsString() @MaxLength(SHORT_TEXT_MAX) actionScreen?: string;
}

export class CreateLarderCatalogDto {
  @IsOptional() @IsString() @MaxLength(SHORT_TEXT_MAX) id?: string;
  @IsString() @IsNotEmpty() @MaxLength(SHORT_TEXT_MAX) name!: string;
  @IsOptional() @IsString() @MaxLength(SHORT_TEXT_MAX) origin?: string;
  @IsOptional() @IsString() @MaxLength(LONG_TEXT_MAX) description?: string;
  @IsOptional() @IsNumber() @Min(0) price?: number;
  @IsOptional() @IsString() @MaxLength(SHORT_TEXT_MAX) category?: string;
  @IsOptional() @IsInt() @Min(0) quantity?: number;
  @IsOptional() @IsString() @MaxLength(URL_MAX) image?: string;
  @IsOptional() @IsString() @MaxLength(SHORT_TEXT_MAX) tag?: string;
  @IsOptional() @IsString() @MaxLength(SHORT_TEXT_MAX) dietary?: string;
  @IsOptional() @IsString() @MaxLength(SHORT_TEXT_MAX) storageType?: string;
  @IsOptional() @IsBoolean() isActive?: boolean;
}

