import 'package:kachava_admin_dashboard/domain/list_query.dart';
import 'package:kachava_admin_dashboard/domain/paged_result.dart';

/// Test-only paged source that applies a [ListQuery] the way the backend
/// does (search, equality filters, one sort, page window). Never used by the
/// app at runtime.
class InMemoryPagedSource<T> {
  InMemoryPagedSource({
    required List<T> items,
    required this.searchText,
    required this.sortValue,
    this.filterValue,
  }) : items = List.of(items);

  final List<T> items;
  final List<String> Function(T item) searchText;
  final Comparable<Object?>? Function(T item, String field) sortValue;
  final String? Function(T item, String key)? filterValue;

  PagedResult<T> page(ListQuery query) {
    final matching = items.where((item) => _matches(item, query)).toList();
    final sort = query.sort;
    if (sort != null) {
      matching.sort((a, b) {
        final va = sortValue(a, sort.field), vb = sortValue(b, sort.field);
        final cmp = va == null || vb == null ? 0 : va.compareTo(vb);
        return sort.direction == SortDirection.asc ? cmp : -cmp;
      });
    }
    final start = (query.page - 1) * query.pageSize;
    final rows = start >= matching.length
        ? <T>[]
        : matching.sublist(
            start, (start + query.pageSize).clamp(0, matching.length));
    return PagedResult(
        items: rows,
        page: query.page,
        pageSize: query.pageSize,
        total: matching.length);
  }

  bool _matches(T item, ListQuery query) {
    final q = query.q.toLowerCase();
    final matchesSearch =
        q.isEmpty || searchText(item).any((t) => t.toLowerCase().contains(q));
    return matchesSearch &&
        query.filters.entries
            .every((f) => filterValue?.call(item, f.key) == f.value);
  }
}
