import 'device_prefs_stub.dart'
    if (dart.library.js_interop) 'device_prefs_web.dart';

/// Small per-device key/value store (language, skipped tasks, drafts,
/// last seen Host message). Every access fails soft.
abstract interface class DevicePrefs {
  String? read(String key);
  void write(String key, String value);
  void remove(String key);

  /// Browser language tag (`navigator.language`), e.g. `es-MX`.
  String get browserLanguage;
}

/// In-memory [DevicePrefs] for tests and non-browser platforms.
class MemoryDevicePrefs implements DevicePrefs {
  MemoryDevicePrefs({this.browserLanguage = 'en-US', Map<String, String>? seed})
      : values = {...?seed};

  final Map<String, String> values;

  @override
  final String browserLanguage;

  @override
  String? read(String key) => values[key];

  @override
  void write(String key, String value) => values[key] = value;

  @override
  void remove(String key) => values.remove(key);
}

DevicePrefs createDevicePrefs() => createPlatformDevicePrefs();
