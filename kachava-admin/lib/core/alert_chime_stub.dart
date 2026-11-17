import 'alert_chime_port.dart';

/// Synchronous stub implementation for headless tests (`dart:io`).
/// Avoids scheduling timers so widget tests never fail with pending timer assertions.
class StubAlertChimeAdapter implements AlertChimePort {
  bool _ringing = false;

  @override
  bool get isRinging => _ringing;

  @override
  void triggerTenSecondChime({void Function()? onAutoStop}) {
    _ringing = true;
  }

  @override
  void stopChime() {
    _ringing = false;
  }

  @override
  void dispose() {
    _ringing = false;
  }
}

AlertChimePort createPlatformAlertChimePort() => StubAlertChimeAdapter();
