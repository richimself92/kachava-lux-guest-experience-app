import { Type } from 'class-transformer';
import { IsBoolean, IsOptional, IsString, MaxLength, ValidateNested } from 'class-validator';
import { LONG_TEXT_MAX, SHORT_TEXT_MAX, URL_MAX } from '../../../common/validation/field-limits';

export const TAGS_MAX = 30;
export const notNull = (_: object, value: unknown) => value !== null;

/** Short bilingual text (names, labels). A missing translation is sent as an empty string. */
export class ShortTextDto {
  @IsOptional()
  @IsString()
  @MaxLength(SHORT_TEXT_MAX)
  en?: string;

  @IsOptional()
  @IsString()
  @MaxLength(SHORT_TEXT_MAX)
  es?: string;
}

/** Long bilingual text (descriptions, policies). */
export class LongTextDto {
  @IsOptional()
  @IsString()
  @MaxLength(LONG_TEXT_MAX)
  en?: string;

  @IsOptional()
  @IsString()
  @MaxLength(LONG_TEXT_MAX)
  es?: string;
}

/** An uploaded image: the `storagePath` returned by `POST /admin/uploads/sign` plus alt text. */
export class CatalogImageDto {
  @IsString()
  @MaxLength(URL_MAX)
  storagePath!: string;

  @IsOptional()
  @ValidateNested()
  @Type(() => ShortTextDto)
  alt?: ShortTextDto;

  @IsOptional()
  @IsBoolean()
  usageRightsConfirmed?: boolean;
}
