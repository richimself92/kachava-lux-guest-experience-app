import 'package:flutter_test/flutter_test.dart';
import 'package:kachava_admin_dashboard/core/resort_time.dart';

void main() {
  const cancun = ResortTime(
      timeZone: 'America/Cancun',
      resolver: FixedOffsetResolver(Duration(hours: -5)));

  test('wall time and resort day use the Settings zone offset', () {
    final wall = cancun.wall(DateTime.utc(2026, 11, 4, 14));
    expect(wall, DateTime.utc(2026, 11, 4, 9));
    // 03:00 UTC is still the previous evening in Cancun.
    expect(cancun.dayOf(DateTime.utc(2026, 11, 3, 3)), '2026-11-02');
    expect(cancun.dayOf(DateTime.utc(2026, 11, 3, 6)), '2026-11-03');
  });

  test('no time zone configured: no wall time, no resort day', () {
    const unset = ResortTime(
        timeZone: null, resolver: FixedOffsetResolver(Duration.zero));
    expect(unset.wall(DateTime.utc(2026, 11, 4, 14)), isNull);
    expect(unset.dayOf(DateTime.utc(2026, 11, 4, 14)), isNull);
  });

  test('a resolver that cannot read the zone gives no wall time', () {
    const unknown =
        ResortTime(timeZone: 'Mars/Base', resolver: _NoZoneResolver());
    expect(unknown.wall(DateTime.utc(2026, 11, 4)), isNull);
  });

  test('labels: "Nov 4 · 09:00" (EN), "4 nov · 09:00" (ES), UTC fallback', () {
    final utc = DateTime.utc(2026, 11, 4, 14);
    expect(cancun.label(utc, isEs: false), 'Nov 4 · 09:00');
    expect(cancun.label(utc, isEs: true), '4 nov · 09:00');
    const unset = ResortTime(
        timeZone: null, resolver: FixedOffsetResolver(Duration.zero));
    expect(unset.label(utc, isEs: false), 'Nov 4 · 14:00 UTC');
    expect(cancun.label(null, isEs: false), '—');
  });

  test('day labels for the date range chips', () {
    expect(ResortTime.dayLabel('2026-11-04', isEs: false), 'Nov 4');
    expect(ResortTime.dayLabel('2026-01-15', isEs: true), '15 ene');
  });
}

class _NoZoneResolver implements ZoneOffsetResolver {
  const _NoZoneResolver();

  @override
  Duration? offsetAt(DateTime utc, String timeZone) => null;
}
