import {
  IsBoolean,
  IsEmail,
  IsIn,
  IsNotEmpty,
  IsOptional,
  IsString,
  MaxLength,
} from 'class-validator';
import { ListQueryDto } from '../../common/listing/list-query';
import { QueryBoolean } from '../../common/listing/query-transforms';
import { EMAIL_MAX, SHORT_TEXT_MAX } from '../../common/validation/field-limits';
import { Department, DEPARTMENTS, RBAC_ROLES, RbacRole } from '../../domain/models/domain.models';

export class CreateStaffDto {
  @IsString()
  @IsNotEmpty()
  @MaxLength(SHORT_TEXT_MAX)
  fullName!: string;

  @IsIn(RBAC_ROLES)
  rbacRole!: RbacRole;

  @IsIn(DEPARTMENTS)
  department!: Department;

  @IsEmail()
  @MaxLength(EMAIL_MAX)
  email!: string;

  @IsOptional()
  @IsString()
  @MaxLength(SHORT_TEXT_MAX)
  phone?: string;

  /** Job title shown to colleagues (e.g. "Head chef"). */
  @IsOptional()
  @IsString()
  @MaxLength(SHORT_TEXT_MAX)
  role?: string;
}

export class UpdateStaffDto {
  @IsOptional()
  @IsString()
  @IsNotEmpty()
  @MaxLength(SHORT_TEXT_MAX)
  fullName?: string;

  @IsOptional()
  @IsIn(RBAC_ROLES)
  rbacRole?: RbacRole;

  @IsOptional()
  @IsIn(DEPARTMENTS)
  department?: Department;

  @IsOptional()
  @IsEmail()
  @MaxLength(EMAIL_MAX)
  email?: string;

  @IsOptional()
  @IsString()
  @MaxLength(SHORT_TEXT_MAX)
  phone?: string;

  @IsOptional()
  @IsString()
  @MaxLength(SHORT_TEXT_MAX)
  role?: string;

  @IsOptional()
  @IsBoolean()
  isActive?: boolean;
}

/** `?isActive=&rbacRole=&department=&q=&page=&pageSize=&sort=`; no `isActive` lists everyone. */
export class StaffListQueryDto extends ListQueryDto {
  @IsOptional()
  @QueryBoolean()
  @IsBoolean()
  isActive?: boolean;

  @IsOptional()
  @IsIn(RBAC_ROLES)
  rbacRole?: RbacRole;

  @IsOptional()
  @IsIn(DEPARTMENTS)
  department?: Department;
}
