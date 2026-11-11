import {
  IsBoolean,
  IsEmail,
  IsNotEmpty,
  IsOptional,
  IsString,
  MaxLength,
  ValidateIf,
} from 'class-validator';
import { ListQueryDto } from '../../common/listing/list-query';
import { QueryBoolean } from '../../common/listing/query-transforms';
import { EMAIL_MAX, SHORT_TEXT_MAX } from '../../common/validation/field-limits';

const nonEmpty = (_: object, value: unknown) => value !== '';

export class CreateTransportProviderDto {
  @IsString()
  @IsNotEmpty()
  @MaxLength(SHORT_TEXT_MAX)
  name!: string;

  @IsOptional()
  @IsString()
  @MaxLength(SHORT_TEXT_MAX)
  phone?: string;

  @IsOptional()
  @ValidateIf(nonEmpty)
  @IsEmail()
  @MaxLength(EMAIL_MAX)
  email?: string;

  @IsOptional()
  @IsBoolean()
  isActive?: boolean;
}

export class UpdateTransportProviderDto {
  @IsOptional()
  @IsString()
  @IsNotEmpty()
  @MaxLength(SHORT_TEXT_MAX)
  name?: string;

  @IsOptional()
  @IsString()
  @MaxLength(SHORT_TEXT_MAX)
  phone?: string;

  @IsOptional()
  @ValidateIf(nonEmpty)
  @IsEmail()
  @MaxLength(EMAIL_MAX)
  email?: string;

  @IsOptional()
  @IsBoolean()
  isActive?: boolean;
}

export class TransportProviderListQueryDto extends ListQueryDto {
  @IsOptional()
  @QueryBoolean()
  @IsBoolean()
  isActive?: boolean;
}
