import { BadRequestException } from '@nestjs/common';
import { Type } from 'class-transformer';
import { IsInt, IsOptional, IsString, Matches, Max, MaxLength, Min } from 'class-validator';

export const DEFAULT_PAGE_SIZE = 25;
export const MAX_PAGE_SIZE = 100;
export const SEARCH_MAX_LENGTH = 100;
const SORT_MAX_LENGTH = 60;
const SORT_PATTERN = /^([A-Za-z][A-Za-z0-9]*):(asc|desc)$/;

export type SortDirection = 'asc' | 'desc';

export interface SortSpec {
  field: string;
  direction: SortDirection;
}

/** Normalised list request shared by every list endpoint. `q` is lower-cased and accent-free. */
export interface ListQuery {
  page: number;
  pageSize: number;
  sort: SortSpec;
  q?: string;
}

export interface ListSpec {
  sortable: readonly string[];
  defaultSort: SortSpec;
}

export interface PageMeta {
  page: number;
  pageSize: number;
  total: number;
}

/**
 * A page of results. The response interceptor emits it as `{ data, meta: { page, pageSize, total } }`
 * instead of wrapping it a second time; `extraMeta` adds endpoint counters (e.g. `unreadCount`).
 */
export class PaginatedResult<T> {
  constructor(
    readonly data: T[],
    readonly meta: PageMeta,
    readonly extraMeta: Record<string, number> = {},
  ) {}
}

/** Query-string contract: `?q=&page=&pageSize=&sort=field:asc|desc`. Endpoint filters extend it. */
export class ListQueryDto {
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  page?: number;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(MAX_PAGE_SIZE)
  pageSize?: number;

  @IsOptional()
  @IsString()
  @MaxLength(SORT_MAX_LENGTH)
  @Matches(SORT_PATTERN, { message: 'sort must look like field:asc or field:desc' })
  sort?: string;

  @IsOptional()
  @IsString()
  @MaxLength(SEARCH_MAX_LENGTH)
  q?: string;
}

/** Lower-cases, strips accents and collapses whitespace so searches match regardless of typing. */
export function normalizeSearchText(value: string): string {
  return value
    .normalize('NFD')
    .replace(/[̀-ͯ]/g, '')
    .toLowerCase()
    .replace(/\s+/g, ' ')
    .trim();
}

function parseSort(raw: string | undefined, spec: ListSpec): SortSpec {
  if (!raw) return { ...spec.defaultSort };
  const match = SORT_PATTERN.exec(raw);
  if (!match) throw new BadRequestException('sort must look like field:asc or field:desc');
  const [, field, direction] = match;
  if (!spec.sortable.includes(field)) {
    throw new BadRequestException(`sort field must be one of: ${spec.sortable.join(', ')}`);
  }
  return { field, direction: direction as SortDirection };
}

export function toListQuery(dto: ListQueryDto, spec: ListSpec): ListQuery {
  const pageSize = dto.pageSize ?? DEFAULT_PAGE_SIZE;
  if (!Number.isInteger(pageSize) || pageSize < 1 || pageSize > MAX_PAGE_SIZE) {
    throw new BadRequestException(`pageSize must be between 1 and ${MAX_PAGE_SIZE}`);
  }
  const page = dto.page ?? 1;
  if (!Number.isInteger(page) || page < 1) throw new BadRequestException('page must be >= 1');
  const q = dto.q ? normalizeSearchText(dto.q) : '';
  return { page, pageSize, sort: parseSort(dto.sort, spec), q: q || undefined };
}

export type SortValue = string | number | boolean | null | undefined;

export interface InMemoryAccessors<T> {
  searchText: (item: T) => string;
  sortValue: (item: T, field: string) => SortValue;
}

function compareValues(a: SortValue, b: SortValue): number {
  if (a === b) return 0;
  if (a === null || a === undefined) return 1;
  if (b === null || b === undefined) return -1;
  if (typeof a === 'number' && typeof b === 'number') return a - b;
  return String(a).localeCompare(String(b), 'en', { sensitivity: 'base', numeric: true });
}

export function sliceToPage<T>(sorted: T[], query: ListQuery): PaginatedResult<T> {
  const start = (query.page - 1) * query.pageSize;
  return new PaginatedResult(sorted.slice(start, start + query.pageSize), {
    page: query.page,
    pageSize: query.pageSize,
    total: sorted.length,
  });
}

/** Search, sort and page an already-bounded list held in memory. */
export function paginateInMemory<T>(
  items: readonly T[],
  query: ListQuery,
  accessors: InMemoryAccessors<T>,
): PaginatedResult<T> {
  const q = query.q;
  const matching = q
    ? items.filter((item) => normalizeSearchText(accessors.searchText(item)).includes(q))
    : [...items];
  const sign = query.sort.direction === 'desc' ? -1 : 1;
  const { field } = query.sort;
  matching.sort((a, b) => {
    const av = accessors.sortValue(a, field);
    const bv = accessors.sortValue(b, field);
    if (av === null || av === undefined || bv === null || bv === undefined) {
      return compareValues(av, bv);
    }
    return sign * compareValues(av, bv);
  });
  return sliceToPage(matching, query);
}
