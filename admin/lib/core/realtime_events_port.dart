import 'package:flutter/foundation.dart';

import '../domain/realtime_change.dart';
import 'realtime_events_stub.dart'
    if (dart.library.js_interop) 'realtime_events_web.dart';

/// State of the real-time signal listener.
enum RealtimeConnection {
  /// Not listening: never opened, closed, or failed permanently (e.g.
  /// permission denied). The caller decides whether to reconnect.
  closed,

  /// Starting, or offline (the SDK retries by itself).
  connecting,

  /// In sync with the server.
  open,
}

/// Port over the Firestore listener on `realtime_signals/<channel>`
/// (ADR-012): the backend rewrites that document on every change; each
/// write after the first snapshot is one [RealtimeChange].
abstract interface class RealtimeEventsPort {
  /// Every signal written after the listener started.
  Stream<RealtimeChange> get changes;
  ValueListenable<RealtimeConnection> get connection;

  /// Listens to [channel] (stopping any previous listener).
  void connect(String channel);
  void close();
  void dispose();
}

/// The platform implementation: a Firestore listener on the web when the
/// Firebase dart-defines are set, otherwise a no-op (real time disabled).
RealtimeEventsPort createRealtimeEventsPort() =>
    createPlatformRealtimeEventsPort();
