import 'resort_time_stub.dart'
    if (dart.library.js_interop) 'resort_time_web.dart';

/// Port: the UTC offset of an IANA zone at an instant. On web it is the
/// browser's `Intl` data; tests inject a [FixedOffsetResolver]. The app has
/// no zone table of its own.
abstract interface class ZoneOffsetResolver {
  /// `null` when the zone is unknown to the platform.
  Duration? offsetAt(DateTime utc, String timeZone);
}

/// A constant offset (tests).
class FixedOffsetResolver implements ZoneOffsetResolver {
  const FixedOffsetResolver(this.offset);

  final Duration offset;

  @override
  Duration? offsetAt(DateTime utc, String timeZone) => offset;
}

/// The platform resolver: browser `Intl` on web, none elsewhere.
ZoneOffsetResolver createZoneOffsetResolver() =>
    createPlatformZoneOffsetResolver();

/// Resort wall time in the Settings [timeZone] (ADR-005/010). Without a
/// configured zone nothing is converted: labels say "UTC", days are unknown.
class ResortTime {
  const ResortTime({required this.timeZone, required this.resolver});

  final String? timeZone;
  final ZoneOffsetResolver resolver;

  static const List<String> _monthsEn = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  static const List<String> _monthsEs = [
    'ene', 'feb', 'mar', 'abr', 'may', 'jun', //
    'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
  ];

  /// The resort wall clock of [utc] (fields read as-is; the value is UTC
  /// only as a carrier). `null` without a usable zone.
  DateTime? wall(DateTime utc) {
    final zone = timeZone;
    if (zone == null) return null;
    final offset = resolver.offsetAt(utc.toUtc(), zone);
    return offset == null ? null : utc.toUtc().add(offset);
  }

  /// Resort calendar day of [utc] as `YYYY-MM-DD`.
  String? dayOf(DateTime utc) {
    final w = wall(utc);
    return w == null ? null : isoDay(w);
  }

  /// "Nov 4 · 09:00" in resort time; "Nov 4 · 14:00 UTC" without a zone.
  String label(DateTime? utc, {required bool isEs}) {
    if (utc == null) return '—';
    final w = wall(utc);
    final shown = w ?? utc.toUtc();
    final text = '${_day(shown, isEs)} · ${hhmm(shown)}';
    return w == null ? '$text UTC' : text;
  }

  /// "Nov 4" / "4 nov" for a `YYYY-MM-DD` day.
  static String dayLabel(String day, {required bool isEs}) {
    final d = DateTime.tryParse('${day}T00:00:00Z');
    return d == null ? day : _day(d, isEs);
  }

  static String isoDay(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${_two(d.month)}-${_two(d.day)}';

  static String hhmm(DateTime d) => '${_two(d.hour)}:${_two(d.minute)}';

  static String _day(DateTime d, bool isEs) => isEs
      ? '${d.day} ${_monthsEs[d.month - 1]}'
      : '${_monthsEn[d.month - 1]} ${d.day}';

  static String _two(int n) => n.toString().padLeft(2, '0');
}
