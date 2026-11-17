import { Type } from 'class-transformer';
import {
  ArrayMaxSize,
  IsArray,
  IsDefined,
  IsIn,
  IsInt,
  IsNumber,
  IsOptional,
  IsString,
  Max,
  MaxLength,
  Min,
  ValidateIf,
  ValidateNested,
} from 'class-validator';
import { ListQueryDto } from '../../../common/listing/list-query';
import { SHORT_TEXT_MAX } from '../../../common/validation/field-limits';
import { CATALOG_STATUSES, CatalogStatus } from '../../../domain/catalog/catalog.models';
import { CatalogImageDto, LongTextDto, notNull, ShortTextDto, TAGS_MAX } from './catalog-common.dto';

export class VehicleCapacityDto {
  @IsInt() @Min(1) @Max(60)
  passengers!: number;

  @IsInt() @Min(0) @Max(100)
  luggage!: number;
}

class ItemFieldsDto {
  @IsOptional() @ValidateNested() @Type(() => LongTextDto)
  description?: LongTextDto;

  @IsOptional() @ValidateIf(notNull) @IsString() @MaxLength(SHORT_TEXT_MAX)
  category?: string | null;

  @IsOptional() @ValidateIf(notNull) @ValidateNested() @Type(() => CatalogImageDto)
  image?: CatalogImageDto | null;

  @IsOptional() @ValidateIf(notNull) @IsNumber({ maxDecimalPlaces: 2 }) @Min(0) @Max(1_000_000)
  priceUSD?: number | null;

  @IsOptional() @IsArray() @ArrayMaxSize(TAGS_MAX) @IsString({ each: true }) @MaxLength(SHORT_TEXT_MAX, { each: true })
  tags?: string[];

  @IsOptional() @IsArray() @ArrayMaxSize(TAGS_MAX) @IsString({ each: true }) @MaxLength(SHORT_TEXT_MAX, { each: true })
  dietaryTags?: string[];

  @IsOptional() @IsArray() @ArrayMaxSize(TAGS_MAX) @IsString({ each: true }) @MaxLength(SHORT_TEXT_MAX, { each: true })
  allergens?: string[];

  @IsOptional() @ValidateIf(notNull) @IsString() @MaxLength(SHORT_TEXT_MAX)
  origin?: string | null;

  @IsOptional() @ValidateIf(notNull) @IsString() @MaxLength(SHORT_TEXT_MAX)
  unit?: string | null;

  @IsOptional() @ValidateIf(notNull) @IsString() @MaxLength(SHORT_TEXT_MAX)
  storage?: string | null;

  @IsOptional() @ValidateIf(notNull) @ValidateNested() @Type(() => VehicleCapacityDto)
  capacity?: VehicleCapacityDto | null;

  @IsOptional() @IsInt() @Min(0) @Max(10_000)
  order?: number;

  @IsOptional() @IsIn(CATALOG_STATUSES)
  status?: CatalogStatus;
}

export class CreateItemDto extends ItemFieldsDto {
  @IsDefined() @ValidateNested() @Type(() => ShortTextDto)
  name!: ShortTextDto;
}

export class UpdateItemDto extends ItemFieldsDto {
  @IsOptional() @ValidateNested() @Type(() => ShortTextDto)
  name?: ShortTextDto;
}

export class ItemListQueryDto extends ListQueryDto {
  @IsOptional() @IsIn(CATALOG_STATUSES)
  status?: CatalogStatus;

  @IsOptional() @IsString() @MaxLength(SHORT_TEXT_MAX)
  category?: string;
}
