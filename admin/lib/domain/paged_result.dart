import 'dart:math' as math;

/// One page of a server-side list: `{ data: [...], meta: { page, pageSize,
/// total } }`.
class PagedResult<T> {
  const PagedResult({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.total,
  });

  final List<T> items;
  final int page;
  final int pageSize;
  final int total;

  /// Parses the backend list envelope. A missing `data` list or `meta` block
  /// is a [FormatException]: counts are never invented.
  static PagedResult<T> fromEnvelope<T>(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic> item) mapItem,
  ) {
    final data = json['data'];
    final meta = json['meta'];
    if (data is! List || meta is! Map) {
      throw const FormatException('List response without { data, meta }.');
    }
    return PagedResult(
      items: [
        for (final raw in data)
          if (raw is Map) mapItem(Map<String, dynamic>.from(raw)),
      ],
      page: _int(meta['page'], 'page'),
      pageSize: _int(meta['pageSize'], 'pageSize'),
      total: _int(meta['total'], 'total'),
    );
  }

  static int _int(Object? value, String name) {
    if (value is num) return value.toInt();
    final parsed = int.tryParse('${value ?? ''}');
    if (parsed == null) throw FormatException('meta.$name is not a number.');
    return parsed;
  }

  bool get isEmpty => total == 0;
  int get pageCount => total == 0 ? 1 : (total / pageSize).ceil();
  bool get hasPrevious => page > 1;
  bool get hasNext => page * pageSize < total;

  /// 1-based index of the first visible row (0 when there are none).
  int get rangeStart => items.isEmpty ? 0 : (page - 1) * pageSize + 1;

  /// 1-based index of the last visible row (0 when there are none).
  int get rangeEnd =>
      items.isEmpty ? 0 : math.min(rangeStart + items.length - 1, total);
}
