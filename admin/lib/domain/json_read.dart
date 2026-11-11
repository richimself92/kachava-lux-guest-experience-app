/// Tolerant readers for server JSON. Missing optional values become `null`
/// or empty; a missing required id is a [FormatException] (never invented).
abstract final class JsonRead {
  static String requireId(Map<String, dynamic> json, [String key = 'id']) {
    final value = text(json, key);
    if (value.isEmpty) throw FormatException('Record without "$key".');
    return value;
  }

  static String text(Map<String, dynamic> json, String key) =>
      json[key]?.toString().trim() ?? '';

  static String? textOrNull(Map<String, dynamic> json, String key) {
    final value = text(json, key);
    return value.isEmpty ? null : value;
  }

  static int? intOrNull(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is num) return value.toInt();
    return int.tryParse('${value ?? ''}');
  }

  static double? doubleOrNull(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is num) return value.toDouble();
    return double.tryParse('${value ?? ''}');
  }

  static bool flag(Map<String, dynamic> json, String key,
          {bool fallback = false}) =>
      json[key] is bool ? json[key] as bool : fallback;

  static Map<String, dynamic> object(Map<String, dynamic> json, String key) {
    final value = json[key];
    return value is Map ? Map<String, dynamic>.from(value) : const {};
  }

  static List<Map<String, dynamic>> objects(
      Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is! List) return const [];
    return [
      for (final e in value)
        if (e is Map) Map<String, dynamic>.from(e)
    ];
  }

  static List<String> strings(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is! List) return const [];
    return [
      for (final e in value)
        if ('${e ?? ''}'.trim().isNotEmpty) '$e'.trim()
    ];
  }
}
