import 'time_zone_catalog_stub.dart'
    if (dart.library.js_interop) 'time_zone_catalog_web.dart';

/// Port: the IANA time zones staff can pick in Settings. The app ships no
/// zone list of its own: on web it is the browser's
/// `Intl.supportedValuesOf('timeZone')`; tests inject a list.
abstract interface class TimeZoneCatalog {
  /// Canonical IANA names, sorted.
  List<String> zones();
}

/// A fixed list (tests, or a host that already knows its zones).
class ListTimeZoneCatalog implements TimeZoneCatalog {
  const ListTimeZoneCatalog(this._zones);

  final List<String> _zones;

  @override
  List<String> zones() => [..._zones]..sort();
}

/// The platform catalog: the browser's zones on web, none elsewhere.
TimeZoneCatalog createTimeZoneCatalog() => createPlatformTimeZoneCatalog();
