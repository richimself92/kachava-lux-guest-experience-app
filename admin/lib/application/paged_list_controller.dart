import 'dart:async';

import 'package:flutter/foundation.dart';

import '../domain/list_query.dart';
import '../domain/paged_result.dart';
import 'list_query_store.dart';

/// Loads one page for a query (a repository `list` method).
typedef PagedFetcher<T> = Future<PagedResult<T>> Function(ListQuery query);

/// What an admin list renders.
enum ListLoadStatus {
  /// First load, nothing to show yet (skeleton rows).
  loading,

  /// Rows to show (possibly dimmed while [PagedListController.isRefreshing]).
  data,

  /// The collection has no records at all (one line + primary action).
  empty,

  /// Search/filters match nothing (one line + "Clear filters").
  noResults,

  /// The last load failed (one line + "Retry").
  error,
}

/// Server-driven list state: debounced search, filters, sort and paging over
/// one [ListQuery], with a sequence guard so only the newest response wins.
class PagedListController<T> extends ChangeNotifier {
  PagedListController({
    required PagedFetcher<T> fetch,
    ListQuery initialQuery = const ListQuery(),
    ListQueryStore? store,
    String? storeKey,
    this.debounce = const Duration(milliseconds: 300),
  })  : assert(store == null || storeKey != null),
        _fetch = fetch,
        _store = store,
        _storeKey = storeKey,
        _query =
            store?.read(storeKey!, fallback: initialQuery) ?? initialQuery {
    _searchText = _query.q;
  }

  final PagedFetcher<T> _fetch;
  final ListQueryStore? _store;
  final String? _storeKey;
  final Duration debounce;

  ListQuery _query;
  late String _searchText;
  PagedResult<T>? _result;
  Object? _error;
  bool _loading = false;
  int _sequence = 0;
  Timer? _debounceTimer;
  bool _disposed = false;

  ListQuery get query => _query;

  /// The search box text (may run ahead of [query] during the debounce).
  String get searchText => _searchText;
  PagedResult<T>? get result => _result;
  List<T> get items => _result?.items ?? const [];
  Object? get error => _error;

  /// Loading while older rows are still on screen (render them dimmed).
  bool get isRefreshing => _loading && _result != null && _error == null;

  ListLoadStatus get status {
    if (_error != null) return ListLoadStatus.error;
    final result = _result;
    if (result == null) return ListLoadStatus.loading;
    if (!result.isEmpty) return ListLoadStatus.data;
    return _query.hasActiveFilters
        ? ListLoadStatus.noResults
        : ListLoadStatus.empty;
  }

  /// Fetches the current query; older in-flight responses are ignored.
  Future<void> load() async {
    final sequence = ++_sequence;
    _loading = true;
    _error = null;
    _notify();
    int? clampTo;
    try {
      final result = await _fetch(_query);
      if (_isStale(sequence)) return;
      if (result.items.isEmpty && result.total > 0 && _query.page > 1) {
        clampTo = result.pageCount;
      } else {
        _result = result;
      }
    } catch (error) {
      if (_isStale(sequence)) return;
      _error = error;
    }
    // A page past the end (rows deleted elsewhere) moves to the last page.
    if (clampTo != null) return _apply(_query.withPage(clampTo));
    _loading = false;
    _notify();
  }

  Future<void> retry() => load();

  /// Background reload of the same query and page (a real-time change):
  /// rows stay on screen undimmed; a failure keeps them (the shell shows
  /// "Reconnecting"). Without rows yet it is a normal [load].
  Future<void> refresh() async {
    if (_disposed) return;
    if (_result == null || _error != null) return load();
    final sequence = ++_sequence;
    try {
      final result = await _fetch(_query);
      if (_isStale(sequence)) return;
      if (result.items.isEmpty && result.total > 0 && _query.page > 1) {
        return await _apply(_query.withPage(result.pageCount));
      }
      _result = result;
    } catch (error) {
      if (_isStale(sequence)) return;
      debugPrint('List refresh failed: $error');
    }
    _loading = false;
    _notify();
  }

  /// Debounced search; the page resets to 1 when it applies.
  void search(String text) {
    _searchText = text;
    _debounceTimer?.cancel();
    _debounceTimer = Timer(debounce, () => _apply(_query.withSearch(text)));
    _notify();
  }

  Future<void> setFilter(String key, String? value) =>
      _apply(_query.withFilter(key, value));

  /// Replaces filters and sort at once (mobile filter sheet "Apply").
  Future<void> applyFiltersAndSort(
          Map<String, String> filters, ListSort? sort) =>
      _apply(_query.withFilters(filters).withSort(sort));

  /// Removes only the search text, immediately.
  Future<void> clearSearchOnly() {
    _debounceTimer?.cancel();
    _searchText = '';
    return _apply(_query.withSearch(''));
  }

  Future<void> clearFilters() {
    _debounceTimer?.cancel();
    _searchText = '';
    return _apply(_query.clearFilters());
  }

  Future<void> toggleSort(String field) => _apply(_query.toggleSort(field));
  Future<void> goToPage(int page) => _apply(_query.withPage(page));
  Future<void> setPageSize(int size) => _apply(_query.withPageSize(size));

  Future<void> nextPage() async {
    if (_result?.hasNext ?? false) await goToPage(_query.page + 1);
  }

  Future<void> previousPage() async {
    if (_query.page > 1) await goToPage(_query.page - 1);
  }

  Future<void> _apply(ListQuery next) {
    if (_disposed || (next == _query && _result != null && !_loading)) {
      return Future.value();
    }
    _query = next;
    if (_storeKey != null) _store?.write(_storeKey, next);
    return load();
  }

  bool _isStale(int sequence) => _disposed || sequence != _sequence;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _debounceTimer?.cancel();
    super.dispose();
  }
}
