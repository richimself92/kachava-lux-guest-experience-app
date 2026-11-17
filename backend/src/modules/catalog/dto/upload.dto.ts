import { IsIn, IsInt, IsOptional, IsString, Matches, Max, MaxLength, Min } from 'class-validator';
import { SHORT_TEXT_MAX } from '../../../common/validation/field-limits';

/** Catalog images: JPEG, PNG or WebP up to 5 MB. */
export const CATALOG_IMAGE_TYPES = {
  'image/jpeg': 'jpg',
  'image/png': 'png',
  'image/webp': 'webp',
} as const;
export type CatalogImageType = keyof typeof CATALOG_IMAGE_TYPES;
export const CATALOG_IMAGE_MAX_BYTES = 5 * 1024 * 1024;

/** 1-3 path segments of letters, digits, `_` or `-` (e.g. `services`, `services/items`). */
export const UPLOAD_FOLDER_PATTERN = /^[A-Za-z0-9_-]{1,64}(\/[A-Za-z0-9_-]{1,64}){0,2}$/;

export class SignCatalogUploadDto {
  /** Folder under `catalog/` where the object is stored. */
  @Matches(UPLOAD_FOLDER_PATTERN, { message: 'folder must be 1-3 segments of letters, digits, _ or -' })
  folder!: string;

  /** Original file name (informational; the stored name is generated). */
  @IsOptional()
  @IsString()
  @MaxLength(SHORT_TEXT_MAX)
  fileName?: string;

  @IsIn(Object.keys(CATALOG_IMAGE_TYPES), { message: 'contentType must be image/jpeg, image/png or image/webp' })
  contentType!: CatalogImageType;

  @IsInt()
  @Min(1)
  @Max(CATALOG_IMAGE_MAX_BYTES, { message: 'sizeBytes must be at most 5 MB (5242880 bytes)' })
  sizeBytes!: number;
}
