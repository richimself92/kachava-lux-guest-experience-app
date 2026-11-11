import 'device_prefs.dart';

/// Headless platforms (`flutter test`) keep preferences in memory only.
DevicePrefs createPlatformDevicePrefs() => MemoryDevicePrefs();
