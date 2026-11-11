import { Type } from 'class-transformer';
import {
  IsBoolean,
  IsIn,
  IsInt,
  IsNotEmpty,
  IsObject,
  IsOptional,
  IsString,
  Matches,
  Max,
  MaxLength,
  Min,
  ValidateNested,
} from 'class-validator';
import { ListQueryDto } from '../../common/listing/list-query';
import { ISO_DATE_PATTERN, LONG_TEXT_MAX, SHORT_TEXT_MAX } from '../../common/validation/field-limits';
import { TRIP_STATUSES, TRIP_TYPES, TripStatus, TripType } from '../../domain/trips/trip.models';
import { DATE_TIME_INPUT_PATTERN } from '../../domain/time/zoned-time';

/** Technical input bounds only; the business limit is the chosen vehicle's capacity. */
export const TRIP_PASSENGERS_MAX = 100;
export const TRIP_LUGGAGE_MAX = 100;
export const TRIP_WAIT_MINUTES_MAX = 24 * 60;
const ID_MAX = 100;
const IATA_CODE = /^[A-Z]{3}$/;
const DATE_TIME_MESSAGE = 'must be YYYY-MM-DDTHH:mm in resort time, or an ISO date-time with offset';
/** `?dateField=` values: the instant `from`/`to` filter on. */
export const TRIP_LIST_DATE_FIELDS = ['pickupAt', 'flightAt'] as const;
export type TripListDateField = (typeof TRIP_LIST_DATE_FIELDS)[number];

export class TripFlightDto {
  @IsString() @IsNotEmpty() @MaxLength(SHORT_TEXT_MAX)
  airline!: string;

  @IsString() @IsNotEmpty() @MaxLength(SHORT_TEXT_MAX)
  number!: string;

  @Matches(DATE_TIME_INPUT_PATTERN, { message: `flight.scheduledAt ${DATE_TIME_MESSAGE}` })
  scheduledAt!: string;
}

export class TripDriverDto {
  @IsString() @MaxLength(SHORT_TEXT_MAX)
  name!: string;

  @IsString() @MaxLength(SHORT_TEXT_MAX)
  phone!: string;
}

export class TripVehicleDto {
  @IsString() @MaxLength(SHORT_TEXT_MAX)
  description!: string;

  @IsString() @MaxLength(SHORT_TEXT_MAX)
  plate!: string;
}

/** What a guest (or staff on their behalf) asks for. Cross-field rules are checked in the domain. */
export class CreateGuestTripDto {
  @IsString() @IsNotEmpty() @MaxLength(ID_MAX)
  serviceId!: string;

  @IsOptional() @IsString() @IsNotEmpty() @MaxLength(ID_MAX)
  itemId?: string;

  @IsIn(TRIP_TYPES)
  type!: TripType;

  @IsOptional() @Matches(IATA_CODE, { message: 'airportCode must be a 3-letter uppercase IATA code' })
  airportCode?: string;

  @IsOptional() @IsObject() @ValidateNested() @Type(() => TripFlightDto)
  flight?: TripFlightDto;

  @IsOptional() @Matches(DATE_TIME_INPUT_PATTERN, { message: `pickupAt ${DATE_TIME_MESSAGE}` })
  pickupAt?: string;

  @IsOptional() @IsString() @MaxLength(SHORT_TEXT_MAX)
  origin?: string;

  @IsOptional() @IsString() @MaxLength(SHORT_TEXT_MAX)
  destination?: string;

  @IsOptional() @IsBoolean()
  roundTrip?: boolean;

  @IsOptional() @IsInt() @Min(0) @Max(TRIP_WAIT_MINUTES_MAX)
  waitMinutes?: number;

  @IsInt() @Min(1) @Max(TRIP_PASSENGERS_MAX)
  passengers!: number;

  @IsOptional() @IsInt() @Min(0) @Max(TRIP_LUGGAGE_MAX)
  luggage?: number;

  @IsOptional() @IsString() @MaxLength(LONG_TEXT_MAX)
  guestNotes?: string;
}

export class CreateAdminTripDto extends CreateGuestTripDto {
  @IsString() @IsNotEmpty() @MaxLength(ID_MAX)
  stayId!: string;

  @IsOptional() @IsString() @MaxLength(LONG_TEXT_MAX)
  notes?: string;

  @IsOptional() @IsString() @IsNotEmpty() @MaxLength(ID_MAX)
  providerId?: string;
}

/** Partial staff edit; `null` clears nullable fields. Type, service and vehicle are fixed. */
export class UpdateTripDto {
  @IsOptional() @Matches(IATA_CODE, { message: 'airportCode must be a 3-letter uppercase IATA code' })
  airportCode?: string;

  @IsOptional() @IsObject() @ValidateNested() @Type(() => TripFlightDto)
  flight?: TripFlightDto;

  @IsOptional() @Matches(DATE_TIME_INPUT_PATTERN, { message: `pickupAt ${DATE_TIME_MESSAGE}` })
  pickupAt?: string;

  @IsOptional() @IsString() @MaxLength(SHORT_TEXT_MAX)
  origin?: string | null;

  @IsOptional() @IsString() @MaxLength(SHORT_TEXT_MAX)
  destination?: string | null;

  @IsOptional() @IsBoolean()
  roundTrip?: boolean;

  @IsOptional() @IsInt() @Min(0) @Max(TRIP_WAIT_MINUTES_MAX)
  waitMinutes?: number | null;

  @IsOptional() @IsInt() @Min(1) @Max(TRIP_PASSENGERS_MAX)
  passengers?: number;

  @IsOptional() @IsInt() @Min(0) @Max(TRIP_LUGGAGE_MAX)
  luggage?: number;

  @IsOptional() @IsString() @MaxLength(LONG_TEXT_MAX)
  guestNotes?: string;

  @IsOptional() @IsString() @MaxLength(LONG_TEXT_MAX)
  notes?: string;

  @IsOptional() @IsString() @IsNotEmpty() @MaxLength(ID_MAX)
  providerId?: string | null;

  @IsOptional() @IsObject() @ValidateNested() @Type(() => TripDriverDto)
  driver?: TripDriverDto | null;

  @IsOptional() @IsObject() @ValidateNested() @Type(() => TripVehicleDto)
  vehicle?: TripVehicleDto | null;
}

export class TransitionTripDto {
  @IsIn(TRIP_STATUSES)
  to!: TripStatus;

  @IsOptional() @IsString() @MaxLength(SHORT_TEXT_MAX)
  reason?: string;

  @IsOptional() @IsObject() @ValidateNested() @Type(() => TripDriverDto)
  driver?: TripDriverDto;

  @IsOptional() @IsObject() @ValidateNested() @Type(() => TripVehicleDto)
  vehicle?: TripVehicleDto;

  @IsOptional() @IsString() @IsNotEmpty() @MaxLength(ID_MAX)
  providerId?: string;
}

/** `from`/`to` are inclusive resort calendar days (Settings `timeZone`) on `dateField`. */
export class TripListQueryDto extends ListQueryDto {
  @IsOptional() @IsIn(TRIP_STATUSES)
  status?: TripStatus;

  @IsOptional() @IsIn(TRIP_TYPES)
  type?: TripType;

  @IsOptional() @Matches(ISO_DATE_PATTERN, { message: 'from must be YYYY-MM-DD' })
  from?: string;

  @IsOptional() @Matches(ISO_DATE_PATTERN, { message: 'to must be YYYY-MM-DD' })
  to?: string;

  @IsOptional() @IsIn(TRIP_LIST_DATE_FIELDS)
  dateField?: TripListDateField;

  @IsOptional() @IsString() @MaxLength(ID_MAX)
  providerId?: string;

  @IsOptional() @IsString() @MaxLength(ID_MAX)
  villaId?: string;
}
