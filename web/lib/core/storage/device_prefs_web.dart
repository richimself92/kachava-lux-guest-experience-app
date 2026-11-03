import 'package:web/web.dart' as web;

import 'device_prefs.dart';

/// `localStorage` + `navigator.language`; storage may be blocked, so every
/// call fails soft.
class LocalStorageDevicePrefs implements DevicePrefs {
  @override
  String? read(String key) {
    try {
      return web.window.localStorage.getItem(key);
    } catch (_) {
      return null;
    }
  }

  @override
  void write(String key, String value) {
    try {
      web.window.localStorage.setItem(key, value);
    } catch (_) {}
  }

  @override
  void remove(String key) {
    try {
      web.window.localStorage.removeItem(key);
    } catch (_) {}
  }

  @override
  String get browserLanguage {
    try {
      return web.window.navigator.language;
    } catch (_) {
      return 'en';
    }
  }
}

DevicePrefs createPlatformDevicePrefs() => LocalStorageDevicePrefs();
