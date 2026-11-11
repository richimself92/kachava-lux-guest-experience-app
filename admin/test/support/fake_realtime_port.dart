import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:kachava_admin_dashboard/core/realtime_events_port.dart';
import 'package:kachava_admin_dashboard/domain/realtime_change.dart';

/// Test double for the Firestore signal port: the test emits changes and
/// drives the connection state.
class FakeRealtimePort implements RealtimeEventsPort {
  final StreamController<RealtimeChange> _changes =
      StreamController<RealtimeChange>.broadcast();
  final ValueNotifier<RealtimeConnection> _connection =
      ValueNotifier(RealtimeConnection.closed);
  final List<String> connects = [];
  int closes = 0;

  @override
  Stream<RealtimeChange> get changes => _changes.stream;

  @override
  ValueListenable<RealtimeConnection> get connection => _connection;

  @override
  void connect(String channel) {
    connects.add(channel);
    _connection.value = RealtimeConnection.connecting;
  }

  @override
  void close() {
    closes++;
    _connection.value = RealtimeConnection.closed;
  }

  void setConnection(RealtimeConnection value) => _connection.value = value;

  void emit(String topic, {String? stayId, String scope = 'stay'}) =>
      _changes.add(RealtimeChange(scope: scope, topic: topic, stayId: stayId));

  @override
  void dispose() {
    _changes.close();
    _connection.dispose();
  }
}
