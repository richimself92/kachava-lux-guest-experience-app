import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'resort_time.dart';

@JS('Date')
extension type _JsDate._(JSObject _) implements JSObject {
  external factory _JsDate(JSNumber epochMs);
  external JSString toLocaleString(JSString locales, JSObject options);
}

final RegExp _parts = RegExp(
    r'(\d{4})\D+(\d{1,2})\D+(\d{1,2})\D+(\d{1,2})\D+(\d{1,2})\D+(\d{1,2})');

/// Reads the zone's wall clock from the browser's `Intl` data
/// (`Date.prototype.toLocaleString('sv-SE', {timeZone})` is `YYYY-MM-DD
/// HH:mm:ss`) and returns its distance to UTC.
class _BrowserZoneOffsets implements ZoneOffsetResolver {
  @override
  Duration? offsetAt(DateTime utc, String timeZone) {
    try {
      final seconds = utc.millisecondsSinceEpoch ~/ 1000 * 1000;
      final options = JSObject()
        ..['timeZone'] = timeZone.toJS
        ..['hourCycle'] = 'h23'.toJS;
      final text =
          _JsDate(seconds.toJS).toLocaleString('sv-SE'.toJS, options).toDart;
      final m = _parts.firstMatch(text);
      if (m == null) return null;
      final v = [for (var i = 1; i <= 6; i++) int.parse(m.group(i)!)];
      final wall = DateTime.utc(v[0], v[1], v[2], v[3], v[4], v[5]);
      return Duration(milliseconds: wall.millisecondsSinceEpoch - seconds);
    } catch (_) {
      // Unknown zone (RangeError) or no Intl support.
      return null;
    }
  }
}

ZoneOffsetResolver createPlatformZoneOffsetResolver() => _BrowserZoneOffsets();
