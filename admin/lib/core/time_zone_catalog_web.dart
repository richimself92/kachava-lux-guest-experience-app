import 'dart:js_interop';

import 'time_zone_catalog.dart';

@JS('Intl.supportedValuesOf')
external JSArray<JSString> _supportedValuesOf(String key);

/// The browser's IANA zones (`Intl.supportedValuesOf('timeZone')`).
class _BrowserTimeZoneCatalog implements TimeZoneCatalog {
  List<String>? _cache;

  @override
  List<String> zones() => _cache ??= _read();

  static List<String> _read() {
    try {
      return [for (final z in _supportedValuesOf('timeZone').toDart) z.toDart]
        ..sort();
    } catch (_) {
      // Very old browsers lack the API: staff then see an empty list.
      return const [];
    }
  }
}

TimeZoneCatalog createPlatformTimeZoneCatalog() => _BrowserTimeZoneCatalog();
