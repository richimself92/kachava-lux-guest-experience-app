/// Last catalog lists the server published, per catalog segment.
///
/// A failed catalog fetch (`null`) keeps the last good list; a list the
/// server returns (even an empty one) replaces it. Before any good answer
/// the catalog is empty: nothing is ever seeded.
class CatalogCache {
  final Map<String, List<Map<String, dynamic>>> _lastGood = {};

  List<Map<String, dynamic>> resolve(
    String segment,
    List<Map<String, dynamic>>? fresh,
  ) {
    if (fresh != null) _lastGood[segment] = fresh;
    return _lastGood[segment] ?? const [];
  }
}
