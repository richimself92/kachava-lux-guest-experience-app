import 'resort_time.dart';

/// Non-web hosts have no zone data: times show in UTC.
ZoneOffsetResolver createPlatformZoneOffsetResolver() => const _NoZones();

class _NoZones implements ZoneOffsetResolver {
  const _NoZones();

  @override
  Duration? offsetAt(DateTime utc, String timeZone) => null;
}
