import {
  IsArray,
  IsBoolean,
  IsEmail,
  IsInt,
  IsNotEmpty,
  IsNumber,
  IsOptional,
  IsString,
  Max,
  Min,
} from 'class-validator';
import {
  Department,
  StayLifecycleStatus,
} from '../../../domain/models/domain.models';

export class AdminLoginDto {
  @IsEmail()
  email!: string;

  @IsOptional()
  @IsString()
  passcode?: string;

  @IsOptional()
  @IsString()
  password?: string;
}

export class CreateReservationDto {
  @IsString()
  @IsNotEmpty()
  guestName!: string;

  @IsOptional()
  @IsString()
  partnerName?: string;

  @IsOptional()
  @IsString()
  villaId?: string;

  @IsOptional()
  @IsString()
  villaName?: string;

  @IsOptional()
  @IsString()
  suiteName?: string;

  @IsOptional()
  @IsString()
  checkIn?: string;

  @IsOptional()
  @IsString()
  checkOut?: string;

  @IsOptional()
  @IsString()
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
  celebration?: string;

  @IsOptional()
  @IsString()
  occasion?: string;

  @IsOptional()
  @IsString()
  email?: string;

  @IsOptional()
  @IsString()
  phone?: string;

  @IsOptional()
  @IsString()
  wifiSsid?: string;

  @IsOptional()
  @IsString()
  wifiPasscode?: string;
}

export class CreateStayDto extends CreateReservationDto {}

export class CreateVillaDto {
  @IsOptional() @IsString() villaId?: string;
  @IsOptional() @IsString() villaName?: string;
  @IsOptional() @IsString() suiteType?: string;
  @IsOptional() @IsString() maxGuests?: string;
  @IsOptional() @IsString() wifiSsid?: string;
  @IsOptional() @IsString() wifiPasscode?: string;
}

export class UpdateStayWifiDto {
  @IsOptional()
  @IsString()
  wifiSsid?: string;

  @IsOptional()
  @IsString()
  wifiPasscode?: string;
}

export class AssignTransferDto {
  @IsOptional()
  @IsString()
  assignedStaffId?: string;

  @IsOptional()
  @IsString()
  assignedStaffName?: string;

  @IsOptional()
  @IsString()
  assignedDriver?: string;

  @IsOptional()
  @IsString()
  vehicleModel?: string;

  @IsOptional()
  @IsString()
  meetingPoint?: string;

  @IsOptional()
  @IsString()
  status?: string;

  @IsOptional()
  @IsString()
  adminDispatchNotes?: string;
}

export class AssignBookingDto {
  @IsOptional()
  @IsString()
  assignedStaffId?: string;

  @IsOptional()
  @IsString()
  assignedStaffName?: string;

  @IsOptional()
  @IsString()
  assignedDepartment?: Department;

  @IsOptional()
  @IsString()
  status?:
    | 'REQUESTED'
    | 'CONFIRMED'
    | 'IN_PREPARATION'
    | 'MODIFICATION_REQUESTED'
    | 'COMPLETED'
    | 'CANCELLED';

  @IsOptional()
  @IsString()
  adminNotes?: string;

  @IsOptional()
  @IsString()
  cancellationReason?: string;
}

export class UpdateLarderStatusDto {
  @IsOptional()
  @IsString()
  assignedStaffId?: string;

  @IsOptional()
  @IsString()
  assignedStaffName?: string;

  @IsOptional()
  @IsString()
  provisioningStatus?: string;

  @IsOptional()
  @IsString()
  status?: string;
}

export class UpdateAdminConciergeDto {
  @IsOptional()
  @IsString()
  status?: 'Requested' | 'Assigned' | 'In Progress' | 'Completed';

  @IsOptional()
  @IsInt()
  @Min(1)
  @Max(4)
  currentStep?: 1 | 2 | 3 | 4;

  @IsOptional()
  @IsString()
  assignedStaffId?: string;

  @IsOptional()
  @IsString()
  assignedTo?: string;

  @IsOptional()
  @IsString()
  assignedDepartment?: Department;

  @IsOptional()
  @IsString()
  notes?: string;

  @IsOptional()
  @IsString()
  replyMessage?: string;

  @IsOptional()
  @IsString()
  message?: string;
}

export class ApproveCheckoutDto {
  @IsOptional()
  @IsBoolean()
  approveLateCheckout?: boolean;

  @IsOptional()
  @IsString()
  adminNotes?: string;
}

export class UpdateStayStatusDto {
  @IsString()
  @IsNotEmpty()
  status!: StayLifecycleStatus;
}

export class CreateExperienceCatalogDto {
  @IsOptional() @IsString() id?: string;
  @IsString() @IsNotEmpty() title!: string;
  @IsOptional() @IsString() subtitle?: string;
  @IsOptional() @IsString() duration?: string;
  @IsOptional() @IsString() location?: string;
  @IsOptional() @IsString() vehicleOrDetail?: string;
  @IsOptional() @IsString() priceText?: string;
  @IsOptional() @IsNumber() basePriceUSD?: number;
  @IsOptional() @IsBoolean() isIncluded?: boolean;
  @IsOptional() @IsString() inclusionLabel?: string;
  @IsOptional() @IsString() image?: string;
  @IsOptional() @IsString() category?: string;
  @IsOptional() @IsString() description?: string;
  @IsOptional() @IsArray() @IsString({ each: true }) amenities?: string[];
  @IsOptional() @IsString() actionLabel?: string;
  @IsOptional() @IsString() actionScreen?: string;
}

export class CreateLarderCatalogDto {
  @IsOptional() @IsString() id?: string;
  @IsString() @IsNotEmpty() name!: string;
  @IsOptional() @IsString() origin?: string;
  @IsOptional() @IsString() description?: string;
  @IsOptional() @IsNumber() price?: number;
  @IsOptional() @IsString() category?: string;
  @IsOptional() @IsInt() quantity?: number;
  @IsOptional() @IsString() image?: string;
  @IsOptional() @IsString() tag?: string;
  @IsOptional() @IsString() dietary?: string;
  @IsOptional() @IsString() storageType?: string;
  @IsOptional() @IsBoolean() isActive?: boolean;
}

