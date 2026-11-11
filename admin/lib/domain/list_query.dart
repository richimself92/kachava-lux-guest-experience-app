/// Sort direction for a list column.
enum SortDirection { asc, desc }

/// One active sort: `field:asc|desc` on the wire.
class ListSort {
  const ListSort(this.field, [this.direction = SortDirection.asc]);

  final String field;
  final SortDirection direction;

  String get wireValue => '$field:${direction.name}';

  /// Parses `field:asc|desc`; anything else is `null`.
  static ListSort? tryParse(String? raw) {
    final parts = (raw ?? '').split(':');
    if (parts.length != 2 || parts.first.trim().isEmpty) return null;
    final direction =
        SortDirection.values.where((d) => d.name == parts.last).firstOrNull;
    return direction == null ? null : ListSort(parts.first.trim(), direction);
  }

  @override
  bool operator ==(Object other) =>
      other is ListSort && other.field == field && other.direction == direction;

  @override
  int get hashCode => Object.hash(field, direction);

  @override
  String toString() => wireValue;
}

/// Immutable list state shared by every admin list: search text, filters,
/// one sort and the page window.
///
/// Wire format: `?q=&page=&pageSize=&sort=field:asc|desc&<filter>=<value>`.
/// Any change other than the page itself resets [page] to 1.
class ListQuery {
  const ListQuery({
    this.q = '',
    this.filters = const {},
    this.sort,
    this.page = 1,
    this.pageSize = defaultPageSize,
  });

  static const List<int> pageSizes = [10, 25, 50];
  static const int defaultPageSize = 25;
  static const Set<String> reservedKeys = {'q', 'page', 'pageSize', 'sort'};

  final String q;
  final Map<String, String> filters;
  final ListSort? sort;
  final int page;
  final int pageSize;

  /// Rebuilds a query from URL/query parameters; invalid values fall back
  /// to defaults.
  factory ListQuery.fromQueryParameters(Map<String, String> params) {
    final size = int.tryParse(params['pageSize'] ?? '');
    final page = int.tryParse(params['page'] ?? '') ?? 1;
    return ListQuery(
      q: (params['q'] ?? '').trim(),
      filters: {
        for (final e in params.entries)
          if (!reservedKeys.contains(e.key) && e.value.isNotEmpty)
            e.key: e.value,
      },
      sort: ListSort.tryParse(params['sort']),
      page: page < 1 ? 1 : page,
      pageSize: pageSizes.contains(size) ? size! : defaultPageSize,
    );
  }

  bool get hasActiveFilters => q.trim().isNotEmpty || filters.isNotEmpty;

  Map<String, String> toQueryParameters() {
    final keys = filters.keys.toList()..sort();
    return {
      if (q.trim().isNotEmpty) 'q': q.trim(),
      'page': '$page',
      'pageSize': '$pageSize',
      if (sort != null) 'sort': sort!.wireValue,
      for (final k in keys) k: filters[k]!,
    };
  }

  String toQueryString() => Uri(queryParameters: toQueryParameters()).query;

  ListQuery withSearch(String text) => _copy(q: text.trim(), page: 1);

  /// Sets [key] to [value]; a `null` or empty value removes the filter.
  ListQuery withFilter(String key, String? value) {
    if (reservedKeys.contains(key)) {
      throw ArgumentError.value(key, 'key', 'Reserved query key');
    }
    final next = Map<String, String>.of(filters)..remove(key);
    if (value != null && value.isNotEmpty) next[key] = value;
    return _copy(filters: Map.unmodifiable(next), page: 1);
  }

  ListQuery withFilters(Map<String, String> next) =>
      _copy(filters: Map.unmodifiable(next), page: 1);

  ListQuery withSort(ListSort? next) =>
      ListQuery(q: q, filters: filters, sort: next, pageSize: pageSize);

  /// Cycles [field]: ascending, descending, none. Another field starts at
  /// ascending (one active sort only).
  ListQuery toggleSort(String field) {
    final current = sort;
    if (current == null || current.field != field) {
      return withSort(ListSort(field));
    }
    return withSort(current.direction == SortDirection.asc
        ? ListSort(field, SortDirection.desc)
        : null);
  }

  ListQuery withPage(int next) => _copy(page: next < 1 ? 1 : next);

  ListQuery withPageSize(int size) {
    if (!pageSizes.contains(size)) {
      throw ArgumentError.value(size, 'size', 'Allowed: $pageSizes');
    }
    return _copy(pageSize: size, page: 1);
  }

  /// Drops the search text and every filter; keeps sort and page size.
  ListQuery clearFilters() => _copy(q: '', filters: const {}, page: 1);

  ListQuery _copy({
    String? q,
    Map<String, String>? filters,
    int? page,
    int? pageSize,
  }) =>
      ListQuery(
        q: q ?? this.q,
        filters: filters ?? this.filters,
        sort: sort,
        page: page ?? this.page,
        pageSize: pageSize ?? this.pageSize,
      );

  @override
  bool operator ==(Object other) =>
      other is ListQuery &&
      other.q == q &&
      other.sort == sort &&
      other.page == page &&
      other.pageSize == pageSize &&
      _sameFilters(other.filters, filters);

  static bool _sameFilters(Map<String, String> a, Map<String, String> b) =>
      a.length == b.length && a.entries.every((e) => b[e.key] == e.value);

  @override
  int get hashCode {
    final keys = filters.keys.toList()..sort();
    return Object.hash(q, sort, page, pageSize,
        Object.hashAll([for (final k in keys) '$k=${filters[k]}']));
  }

  @override
  String toString() => 'ListQuery(${toQueryString()})';
}
