import 'time_zone_catalog.dart';

/// Non-web hosts have no browser zone list.
TimeZoneCatalog createPlatformTimeZoneCatalog() =>
    const ListTimeZoneCatalog([]);
