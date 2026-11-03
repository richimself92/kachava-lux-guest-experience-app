import {
  IsBoolean,
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
import { QueryBoolean } from '../../../common/listing/query-transforms';
import {
  EMAIL_MAX,
  ISO_DATE_PATTERN,
  LONG_TEXT_MAX,
  SHORT_TEXT_MAX,
  VILLA_ID_PATTERN,
} from '../../../common/validation/field-limits';
import {
  AlertCategory,
  AlertSeverity,
  Department,
  StayLifecycleStatus,
} from '../../../domain/models/domain.models';

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

export class BookingListQueryDto extends ListQueryDto {
  @IsOptional() @IsString() @MaxLength(SHORT_TEXT_MAX) section?: string;
  @IsOptional() @IsString() @MaxLength(SHORT_TEXT_MAX) usageType?: string;
  @IsOptional() @IsString() @MaxLength(SHORT_TEXT_MAX) status?: string;
  @IsOptional() @IsString() @MaxLength(SHORT_TEXT_MAX) assignedDepartment?: string;
  @IsOptional() @Matches(ISO_DATE_PATTERN) scheduledDate?: string;
}

export class LarderOrderListQueryDto extends ListQueryDto {
  @IsOptional() @IsString() @MaxLength(SHORT_TEXT_MAX) provisioningStatus?: string;
  @IsOptional() @IsString() @MaxLength(SHORT_TEXT_MAX) category?: string;
  @IsOptional() @IsString() @MaxLength(SHORT_TEXT_MAX) villaId?: string;
}

export class ConciergeListQueryDto extends ListQueryDto {
  @IsOptional() @IsString() @MaxLength(SHORT_TEXT_MAX) status?: string;
  @IsOptional() @IsString() @MaxLength(SHORT_TEXT_MAX) priority?: string;
  @IsOptional() @IsString() @MaxLength(SHORT_TEXT_MAX) assignedDepartment?: string;
  @IsOptional() @IsString() @MaxLength(SHORT_TEXT_MAX) category?: string;
  @IsOptional() @IsString() @MaxLength(SHORT_TEXT_MAX) villaId?: string;
}

export class AlertListQueryDto extends ListQueryDto {
  @IsOptional() @QueryBoolean() @IsBoolean() isAcknowledged?: boolean;
  @IsOptional() @IsString() @MaxLength(SHORT_TEXT_MAX) category?: AlertCategory;
  @IsOptional() @IsString() @MaxLength(SHORT_TEXT_MAX) severity?: AlertSeverity;
  @IsOptional() @IsString() @MaxLength(SHORT_TEXT_MAX) assignedDepartment?: Department;
}

export class StaffListQueryDto extends ListQueryDto {
  @IsOptional() @IsString() @MaxLength(SHORT_TEXT_MAX) department?: string;
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
  @IsIn(STAY_STATUSES)
  status!: StayLifecycleStatus;
}
