/// Mutable form state over a private deep copy of a JSON object, addressed
/// by dotted paths (`pricing.note.en`). Form fields write on every change
/// so the draft is always current; the entity is parsed from [json] on save.
class JsonDraft {
  JsonDraft(Map<String, dynamic> initial)
      : _json = _deepCopy(initial) as Map<String, dynamic>;

  final Map<String, dynamic> _json;

  /// The live draft (a fresh deep copy is taken on construction only).
  Map<String, dynamic> get json => _json;

  Object? get(String path) {
    Object? node = _json;
    for (final key in path.split('.')) {
      if (node is! Map) return null;
      node = node[key];
    }
    return node;
  }

  /// Sets [path], creating intermediate objects as needed.
  void set(String path, Object? value) {
    final keys = path.split('.');
    var node = _json;
    for (final key in keys.take(keys.length - 1)) {
      final child = node[key];
      if (child is Map<String, dynamic>) {
        node = child;
      } else {
        node = node[key] = <String, dynamic>{};
      }
    }
    node[keys.last] = _deepCopy(value);
  }

  void remove(String path) {
    final keys = path.split('.');
    final parent =
        keys.length == 1 ? _json : get(keys.take(keys.length - 1).join('.'));
    if (parent is Map) parent.remove(keys.last);
  }

  String text(String path) => '${get(path) ?? ''}';

  int? intOrNull(String path) {
    final value = get(path);
    return value is num ? value.toInt() : int.tryParse('${value ?? ''}');
  }

  double? doubleOrNull(String path) {
    final value = get(path);
    return value is num ? value.toDouble() : double.tryParse('${value ?? ''}');
  }

  bool flag(String path) => get(path) == true;

  List<String> strings(String path) {
    final value = get(path);
    return value is List ? [for (final e in value) '$e'] : const [];
  }

  static Object? _deepCopy(Object? value) => switch (value) {
        Map() => <String, dynamic>{
            for (final e in value.entries) '${e.key}': _deepCopy(e.value)
          },
        List() => [for (final e in value) _deepCopy(e)],
        _ => value,
      };
}
