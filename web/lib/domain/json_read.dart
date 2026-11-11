/// Defensive JSON readers: a wrong or missing field never throws, it falls
/// back to an empty value so one bad record cannot blank the portal.
typedef Json = Map<String, dynamic>;

Json asJson(Object? value) =>
    value is Map ? value.map((k, v) => MapEntry('$k', v)) : <String, dynamic>{};

List<Json> asJsonList(Object? value) =>
    value is List ? value.whereType<Map>().map(asJson).toList() : const [];

String asString(Object? value) => switch (value) {
      String s => s,
      num n => '$n',
      _ => '',
    };

String? asStringOrNull(Object? value) {
  final s = asString(value);
  return s.isEmpty ? null : s;
}

int? asInt(Object? value) => switch (value) {
      int i => i,
      num n => n.round(),
      String s => int.tryParse(s),
      _ => null,
    };

double? asDouble(Object? value) => switch (value) {
      num n => n.toDouble(),
      String s => double.tryParse(s),
      _ => null,
    };

bool asBool(Object? value) => value == true;

List<String> asStringList(Object? value) => value is List
    ? value.map(asString).where((s) => s.isNotEmpty).toList()
    : const [];

DateTime? asDateTime(Object? value) {
  final s = asString(value);
  return s.isEmpty ? null : DateTime.tryParse(s);
}
