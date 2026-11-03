import '../domain/admin_stay_entities.dart';

/// Shared value readers for admin wire payloads.
///
/// Missing values become empty strings, `0`, `null`, or empty lists: no guest,
/// villa, staff, card, or date value is ever invented.
class WireValues {
  const WireValues._();

  /// First non-blank value of [vals] (trimmed), or `''`.
  static String text(List<Object?> vals) {
    for (final v in vals) {
      final s = v?.toString().trim() ?? '';
      if (s.isNotEmpty) return s;
    }
    return '';
  }

  /// Record identifier from the first present key, or `null` when absent.
  static String? id(Map<String, dynamic> m, List<String> keys) {
    final value = text([for (final k in keys) m[k]]);
    return value.isEmpty ? null : value;
  }

  /// Trimmed [v], or null when it is null or blank.
  static String? blankToNull(String? v) =>
      (v == null || v.trim().isEmpty) ? null : v.trim();

  static Map<String, dynamic> asMap(Object? v) =>
      v is Map ? Map<String, dynamic>.from(v) : const {};

  static double toDouble(Object? v) =>
      v is num ? v.toDouble() : (double.tryParse('${v ?? ''}') ?? 0.0);

  static List<String> toStrList(Object? v) => v is List
      ? v.map((e) => e.toString()).toList()
      : (v is String && v.trim().isNotEmpty ? [v.trim()] : const []);

  /// Wire booking/larder labels normalized to the admin display values.
  static String bookingCategory(String s) {
    final u = s.toUpperCase();
    if (u.contains('YACHT')) return 'Yacht Charters';
    if (u.contains('DINING')) return 'Private Dining';
    if (u.contains('PRIVILEGE') || u.contains('INCLUDED')) {
      return 'Included Privileges';
    }
    return 'Excursions';
  }

  static String bookingStatus(String s) => switch (s.toUpperCase()) {
        'CONFIRMED' => 'Confirmed',
        'COMPLETED' => 'Completed',
        'CANCELLED' || 'CANCELED' => 'Cancelled',
        _ => 'Requested',
      };

  static String larderStatus(String s) => s.toUpperCase().contains('STOCKED')
      ? 'Stocked in Villa'
      : (s.toUpperCase().contains('ASSIGNED') ? 'Assigned' : 'Pending');

  static AdminStayRecord? findStay(List<AdminStayRecord> stays, String? id) =>
      id == null ? null : stays.where((s) => s.stayId == id).firstOrNull;

  /// Nights between the two labels, else the server `nights`, else `0`.
  static int nights(String checkIn, String checkOut, Object? rawNights) {
    final a = _dateParts(checkIn), b = _dateParts(checkOut);
    if (a != null && b != null) {
      // A label without a year borrows the other end's year for the count.
      final dIn = DateTime.utc(a.y ?? b.y ?? 2000, a.m, a.d),
          dOut = DateTime.utc(b.y ?? a.y ?? 2000, b.m, b.d);
      final days = dOut.difference(dIn).inDays;
      if (days > 0) return days;
    }
    return (rawNights as num?)?.toInt() ?? 0;
  }

  static const _months = {
    'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'may': 5, 'jun': 6, //
    'jul': 7, 'aug': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12,
  };

  /// Parses ISO or "Mon D[, YYYY]" labels into parts (year may be absent).
  static ({int? y, int m, int d})? _dateParts(String raw) {
    final s = raw.trim();
    if (s.isEmpty) return null;
    final iso = DateTime.tryParse(s);
    if (iso != null) return (y: iso.year, m: iso.month, d: iso.day);
    final match = RegExp(r'([A-Za-z]{3})[a-z]*\s+(\d{1,2})(?:,?\s*(\d{4}))?')
        .firstMatch(s);
    if (match == null) return null;
    final m = _months[match.group(1)!.toLowerCase()],
        d = int.tryParse(match.group(2)!);
    if (m == null || d == null) return null;
    return (y: int.tryParse(match.group(3) ?? ''), m: m, d: d);
  }
}
