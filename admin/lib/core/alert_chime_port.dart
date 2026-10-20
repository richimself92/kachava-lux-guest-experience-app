import 'alert_chime_stub.dart'
    if (dart.library.js_interop) 'alert_chime_web.dart';

/// Port interface for triggering and muting the 10-second luxury concierge chime.
abstract interface class AlertChimePort {
  bool get isRinging;
  void triggerTenSecondChime({void Function()? onAutoStop});
  void stopChime();
  void dispose();
}

/// Factory returning the platform-appropriate [AlertChimePort] implementation.
AlertChimePort createAlertChimePort() => createPlatformAlertChimePort();
