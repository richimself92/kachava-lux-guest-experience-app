import 'package:flutter/foundation.dart';

import '../domain/realtime_change.dart';
import 'realtime_events_port.dart';

/// No-op listener (non-web platforms, headless tests, missing Firebase
/// config): never connects, never emits, schedules no timers.
class StubRealtimeEventsAdapter implements RealtimeEventsPort {
  final ValueNotifier<RealtimeConnection> _connection =
      ValueNotifier(RealtimeConnection.closed);

  @override
  Stream<RealtimeChange> get changes => const Stream.empty();

  @override
  ValueListenable<RealtimeConnection> get connection => _connection;

  @override
  void connect(String channel) {}

  @override
  void close() {}

  @override
  void dispose() => _connection.dispose();
}

RealtimeEventsPort createPlatformRealtimeEventsPort() =>
    StubRealtimeEventsAdapter();
