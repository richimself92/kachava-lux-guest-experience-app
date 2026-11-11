import '../domain/list_query.dart';

/// Per-screen [ListQuery] memory. Lives above the workspaces (in the
/// dashboard controller) so a list keeps its search, filters, sort and page
/// while staff navigate away and back; cleared when the staff session ends.
class ListQueryStore {
  final Map<String, ListQuery> _queries = {};

  ListQuery read(String screenKey, {ListQuery fallback = const ListQuery()}) =>
      _queries[screenKey] ?? fallback;

  void write(String screenKey, ListQuery query) => _queries[screenKey] = query;

  void clear() => _queries.clear();
}
