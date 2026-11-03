/// The record to mutate is not in the local cache, so nothing was sent.
class AdminRecordNotLoadedException implements Exception {
  const AdminRecordNotLoadedException(this.recordId);

  final String recordId;

  @override
  String toString() => 'AdminRecordNotLoadedException: $recordId not loaded.';
}

/// Id-based lookups on the admin write-through cache that never index with -1.
class CachedRecords {
  const CachedRecords._();

  /// The cached record with [id]; throws [AdminRecordNotLoadedException]
  /// (before any request is sent) when it is not loaded.
  static T find<T>(List<T> list, String Function(T) idOf, String id) =>
      list.where((e) => idOf(e) == id).firstOrNull ??
      (throw AdminRecordNotLoadedException(id));

  /// Stores [updated] in place of the record with the same id when it is still
  /// cached (a concurrent sync may have replaced the list), and returns it.
  static T replace<T>(List<T> list, String Function(T) idOf, T updated) {
    final index = list.indexWhere((e) => idOf(e) == idOf(updated));
    if (index >= 0) list[index] = updated;
    return updated;
  }
}
