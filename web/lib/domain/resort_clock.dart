/// Resort wall clock, `America/Cancun` (ADR-005): UTC-5 all year, no DST.
class ResortClock {
  const ResortClock([this._now = DateTime.now]);

  static const Duration offset = Duration(hours: -5);

  final DateTime Function() _now;

  /// Current resort wall time, expressed in a UTC [DateTime].
  DateTime nowWall() => toWall(_now());

  /// Today's resort calendar day (UTC midnight).
  DateTime today() => dayOf(nowWall());

  static DateTime toWall(DateTime instant) => instant.toUtc().add(offset);

  static DateTime dayOf(DateTime wall) =>
      DateTime.utc(wall.year, wall.month, wall.day);

  /// `YYYY-MM-DD` of a resort day.
  static String isoDay(DateTime day) =>
      '${day.year.toString().padLeft(4, '0')}-${_two(day.month)}-${_two(day.day)}';

  /// `YYYY-MM-DDTHH:mm` resort wall time accepted by the backend.
  static String wallDateTime(DateTime day, String hhmm) =>
      '${isoDay(day)}T$hhmm';

  static String _two(int v) => v.toString().padLeft(2, '0');
}
