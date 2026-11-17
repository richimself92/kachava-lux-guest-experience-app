import { BadRequestException } from '@nestjs/common';
import {
  DEFAULT_PAGE_SIZE,
  MAX_PAGE_SIZE,
  PaginatedResult,
  paginateInMemory,
  toListQuery,
} from '../../src/common/listing/list-query';

interface Row {
  name: string;
  order: number;
}

const rows: Row[] = [
  { name: 'Charlie', order: 3 },
  { name: 'alpha', order: 1 },
  { name: 'Bravo', order: 2 },
];

const spec = {
  sortable: ['name', 'order'] as const,
  defaultSort: { field: 'name', direction: 'asc' } as const,
};

const accessors = {
  searchText: (r: Row) => r.name,
  sortValue: (r: Row, field: string) => (field === 'order' ? r.order : r.name),
};

describe('toListQuery', () => {
  it('test_toListQuery_emptyInput_appliesDefaults', () => {
    const query = toListQuery({}, spec);

    expect(query).toEqual({
      page: 1,
      pageSize: DEFAULT_PAGE_SIZE,
      sort: { field: 'name', direction: 'asc' },
      q: undefined,
    });
  });

  it('test_toListQuery_validInput_parsesSortAndTrimsSearch', () => {
    const query = toListQuery({ page: 2, pageSize: 10, sort: 'order:desc', q: '  Bra ' }, spec);

    expect(query).toEqual({ page: 2, pageSize: 10, sort: { field: 'order', direction: 'desc' }, q: 'bra' });
  });

  it('test_toListQuery_unknownSortField_throwsBadRequest', () => {
    expect(() => toListQuery({ sort: 'secret:asc' }, spec)).toThrow(BadRequestException);
  });

  it('test_toListQuery_malformedSort_throwsBadRequest', () => {
    expect(() => toListQuery({ sort: 'name' }, spec)).toThrow(BadRequestException);
  });

  it('test_maxPageSize_isOneHundred', () => {
    expect(MAX_PAGE_SIZE).toBe(100);
    expect(DEFAULT_PAGE_SIZE).toBe(25);
  });
});

describe('paginateInMemory', () => {
  it('test_paginateInMemory_sortsCaseInsensitivelyAndReportsTotal', () => {
    const page = paginateInMemory(rows, toListQuery({ pageSize: 2 }, spec), accessors);

    expect(page).toBeInstanceOf(PaginatedResult);
    expect(page.data.map((r) => r.name)).toEqual(['alpha', 'Bravo']);
    expect(page.meta).toEqual({ page: 1, pageSize: 2, total: 3 });
  });

  it('test_paginateInMemory_secondPage_returnsRemainder', () => {
    const page = paginateInMemory(rows, toListQuery({ page: 2, pageSize: 2 }, spec), accessors);

    expect(page.data.map((r) => r.name)).toEqual(['Charlie']);
  });

  it('test_paginateInMemory_search_filtersBeforeCounting', () => {
    const page = paginateInMemory(rows, toListQuery({ q: 'ALP' }, spec), accessors);

    expect(page.data.map((r) => r.name)).toEqual(['alpha']);
    expect(page.meta.total).toBe(1);
  });

  it('test_paginateInMemory_numericDescendingSort', () => {
    const page = paginateInMemory(rows, toListQuery({ sort: 'order:desc' }, spec), accessors);

    expect(page.data.map((r) => r.order)).toEqual([3, 2, 1]);
  });

  it('test_paginateInMemory_searchIgnoresAccents', () => {
    const page = paginateInMemory(
      [{ name: 'Café Olé', order: 1 }],
      toListQuery({ q: 'cafe' }, spec),
      accessors,
    );

    expect(page.meta.total).toBe(1);
  });
});
