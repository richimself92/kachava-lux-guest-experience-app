import { Type } from 'class-transformer';
import {
  ArrayMaxSize,
  IsArray,
  IsBoolean,
  IsDefined,
  IsIn,
  IsInt,
  IsOptional,
  IsString,
  Max,
  MaxLength,
  Min,
  ValidateIf,
  ValidateNested,
} from 'class-validator';
import { ListQueryDto } from '../../../common/listing/list-query';
import { QueryBoolean } from '../../../common/listing/query-transforms';
import { SHORT_TEXT_MAX } from '../../../common/validation/field-limits';
import {
  CATALOG_STATUSES,
  CatalogStatus,
  GALLERY_MAX_IMAGES,
  SERVICE_KINDS,
  SERVICE_SECTIONS,
  ServiceKind,
  ServiceSection,
  USAGE_TYPES,
  UsageType,
} from '../../../domain/catalog/catalog.models';
import { CatalogImageDto, LongTextDto, notNull, ShortTextDto, TAGS_MAX } from './catalog-common.dto';
import {
  AvailabilityDto,
  BarDetailsDto,
  CreatePricingDto,
  DiningDetailsDto,
  ExperienceDetailsDto,
  GuestFormDto,
  GuestInfoDto,
  OperationDto,
  PreferenceDetailsDto,
  StockingDetailsDto,
  TransportDetailsDto,
  UpdatePricingDto,
  WellnessDetailsDto,
} from './service-blocks.dto';

/** Fields shared by create and update; nested blocks merge one level deep on PATCH. */
class ServiceFieldsDto {
  @IsOptional() @ValidateIf(notNull) @IsString() @MaxLength(SHORT_TEXT_MAX)
  category?: string | null;

  @IsOptional() @ValidateNested() @Type(() => ShortTextDto)
  shortDescription?: ShortTextDto;

  @IsOptional() @ValidateNested() @Type(() => LongTextDto)
  description?: LongTextDto;

  @IsOptional() @IsArray() @ArrayMaxSize(TAGS_MAX) @IsString({ each: true }) @MaxLength(SHORT_TEXT_MAX, { each: true })
  tags?: string[];

  @IsOptional() @IsInt() @Min(0) @Max(10_000)
  order?: number;

  @IsOptional() @IsBoolean()
  featured?: boolean;

  @IsOptional() @ValidateIf(notNull) @ValidateNested() @Type(() => CatalogImageDto)
  cover?: CatalogImageDto | null;

  @IsOptional() @IsArray() @ArrayMaxSize(GALLERY_MAX_IMAGES) @ValidateNested({ each: true }) @Type(() => CatalogImageDto)
  gallery?: CatalogImageDto[];

  @IsOptional() @ValidateNested() @Type(() => AvailabilityDto)
  availability?: AvailabilityDto;

  @IsOptional() @ValidateNested() @Type(() => GuestInfoDto)
  guestInfo?: GuestInfoDto;

  @IsOptional() @ValidateNested() @Type(() => GuestFormDto)
  guestForm?: GuestFormDto;

  @IsOptional() @ValidateNested() @Type(() => OperationDto)
  operation?: OperationDto;

  @IsOptional() @ValidateNested() @Type(() => BarDetailsDto)
  bar?: BarDetailsDto;

  @IsOptional() @ValidateNested() @Type(() => DiningDetailsDto)
  dining?: DiningDetailsDto;

  @IsOptional() @ValidateNested() @Type(() => StockingDetailsDto)
  stocking?: StockingDetailsDto;

  @IsOptional() @ValidateNested() @Type(() => ExperienceDetailsDto)
  experience?: ExperienceDetailsDto;

  @IsOptional() @ValidateNested() @Type(() => WellnessDetailsDto)
  wellness?: WellnessDetailsDto;

  @IsOptional() @ValidateNested() @Type(() => PreferenceDetailsDto)
  preference?: PreferenceDetailsDto;

  @IsOptional() @ValidateNested() @Type(() => TransportDetailsDto)
  transport?: TransportDetailsDto;

  @IsOptional() @IsIn(CATALOG_STATUSES)
  status?: CatalogStatus;
}

export class CreateServiceDto extends ServiceFieldsDto {
  @IsIn(SERVICE_KINDS)
  kind!: ServiceKind;

  @IsIn(SERVICE_SECTIONS)
  section!: ServiceSection;

  @IsIn(USAGE_TYPES)
  usageType!: UsageType;

  @IsDefined() @ValidateNested() @Type(() => ShortTextDto)
  name!: ShortTextDto;

  @IsDefined() @ValidateNested() @Type(() => CreatePricingDto)
  pricing!: CreatePricingDto;
}

export class UpdateServiceDto extends ServiceFieldsDto {
  /** Accepted only to reject a change explicitly: the kind of a service is immutable. */
  @IsOptional() @IsIn(SERVICE_KINDS)
  kind?: ServiceKind;

  @IsOptional() @IsIn(SERVICE_SECTIONS)
  section?: ServiceSection;

  @IsOptional() @IsIn(USAGE_TYPES)
  usageType?: UsageType;

  @IsOptional() @ValidateNested() @Type(() => ShortTextDto)
  name?: ShortTextDto;

  @IsOptional() @ValidateNested() @Type(() => UpdatePricingDto)
  pricing?: UpdatePricingDto;
}

export class ServiceListQueryDto extends ListQueryDto {
  @IsOptional() @IsIn(SERVICE_SECTIONS)
  section?: ServiceSection;

  @IsOptional() @IsIn(CATALOG_STATUSES)
  status?: CatalogStatus;

  @IsOptional() @IsIn(USAGE_TYPES)
  usageType?: UsageType;

  @IsOptional() @IsIn(SERVICE_KINDS)
  kind?: ServiceKind;

  @IsOptional() @QueryBoolean() @IsBoolean()
  featured?: boolean;
}

export class GuestCatalogQueryDto extends ListQueryDto {
  @IsOptional() @IsIn(SERVICE_SECTIONS)
  section?: ServiceSection;
}
