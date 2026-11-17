import 'package:flutter_test/flutter_test.dart';
import 'package:kachava_admin_dashboard/domain/list_query.dart';
import 'package:kachava_admin_dashboard/domain/paged_result.dart';

void main() {
  group('ListQuery serialization', () {
    test('defaults to page 1, pageSize 25, no search, no sort', () {
      const query = ListQuery();
      expect(query.toQueryParameters(), {'page': '1', 'pageSize': '25'});
      expect(ListQuery.pageSizes, [10, 25, 50]);
    });

    test('serializes q, sort field:dir and filters (sorted keys)', () {
      final query = const ListQuery()
          .withSearch('  ocean ')
          .withFilter('villa', 'v-2')
          .withFilter('status', 'ACTIVE')
          .withSort(const ListSort('name', SortDirection.desc))
          .withPage(3);
      expect(query.toQueryString(),
          'q=ocean&page=3&pageSize=25&sort=name%3Adesc&status=ACTIVE&villa=v-2');
    });

    test('round-trips through query parameters', () {
      final query = const ListQuery(pageSize: 50)
          .withSearch('ana')
          .withFilter('status', 'IN_HOUSE')
          .withSort(const ListSort('arrival'))
          .withPage(2);
      expect(ListQuery.fromQueryParameters(query.toQueryParameters()), query);
    });

    test('parsing rejects unknown page sizes and bad pages', () {
      final query = ListQuery.fromQueryParameters(
          {'page': '-4', 'pageSize': '1000', 'sort': 'name:sideways'});
      expect(query.page, 1);
      expect(query.pageSize, 25);
      expect(query.sort, isNull);
    });

    test('empty filter value removes the filter', () {
      final query = const ListQuery().withFilter('status', 'A');
      expect(query.withFilter('status', '').filters, isEmpty);
      expect(query.withFilter('status', null).filters, isEmpty);
    });

    test('reserved keys cannot be used as filters', () {
      expect(
          () => const ListQuery().withFilter('page', '2'), throwsArgumentError);
    });
  });

  group('ListQuery page reset', () {
    const onPage4 = ListQuery(page: 4);

    test('search, filter, sort and pageSize changes reset page to 1', () {
      expect(onPage4.withSearch('x').page, 1);
      expect(onPage4.withFilter('status', 'A').page, 1);
      expect(onPage4.withSort(const ListSort('name')).page, 1);
      expect(onPage4.withPageSize(10).page, 1);
      expect(onPage4.withFilter('status', 'A').clearFilters().page, 1);
    });

    test('withPageSize only accepts 10/25/50', () {
      expect(() => onPage4.withPageSize(30), throwsArgumentError);
    });

    test('toggleSort cycles asc, desc, none; another field starts asc', () {
      final asc = const ListQuery().toggleSort('name');
      expect(asc.sort, const ListSort('name'));
      final desc = asc.toggleSort('name');
      expect(desc.sort, const ListSort('name', SortDirection.desc));
      expect(desc.toggleSort('name').sort, isNull);
      expect(desc.toggleSort('status').sort, const ListSort('status'));
    });

    test('clearFilters keeps sort and pageSize', () {
      final query = const ListQuery(pageSize: 10)
          .withSort(const ListSort('name'))
          .withSearch('a')
          .withFilter('status', 'A')
          .clearFilters();
      expect(query.hasActiveFilters, isFalse);
      expect(query.sort, const ListSort('name'));
      expect(query.pageSize, 10);
    });
  });

  group('PagedResult envelope', () {
    Map<String, dynamic> envelope(int page, int size, int total, int n) => {
          'data': [
            for (var i = 0; i < n; i++) {'id': 'r$i'}
          ],
          'meta': {'page': page, 'pageSize': size, 'total': total},
        };

    test('parses { data, meta } and computes the visible range', () {
      final result = PagedResult.fromEnvelope(
          envelope(2, 25, 132, 25), (m) => m['id'] as String);
      expect(result.items.first, 'r0');
      expect(result.rangeStart, 26);
      expect(result.rangeEnd, 50);
      expect(result.pageCount, 6);
      expect(result.hasPrevious, isTrue);
      expect(result.hasNext, isTrue);
    });

    test('last partial page', () {
      final result = PagedResult.fromEnvelope(
          envelope(6, 25, 132, 7), (m) => m['id'] as String);
      expect(result.rangeStart, 126);
      expect(result.rangeEnd, 132);
      expect(result.hasNext, isFalse);
    });

    test('empty result has a 0-0 range', () {
      final result = PagedResult.fromEnvelope(
          envelope(1, 25, 0, 0), (m) => m['id'] as String);
      expect(result.isEmpty, isTrue);
      expect(result.rangeStart, 0);
      expect(result.rangeEnd, 0);
      expect(result.pageCount, 1);
    });

    test('a missing meta block is a FormatException, never invented', () {
      expect(() => PagedResult.fromEnvelope({'data': []}, (m) => m),
          throwsFormatException);
      expect(
          () => PagedResult.fromEnvelope({
                'meta': {'page': 1, 'pageSize': 25, 'total': 0}
              }, (m) => m),
          throwsFormatException);
    });
  });
}
