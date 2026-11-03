import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/realtime_events_port.dart';
import '../domain/admin_access_denied.dart';
import '../domain/realtime_change.dart';
import 'admin_live_sync.dart';

/// The staff's real-time channel (`realtime.adminChannel` of the silent
/// login); null when the backend offers none. [renew] logs in again (the
/// listener was refused).
typedef RealtimeChannel = Future<String?> Function({bool renew});

/// Real-time fan-out (ADR-012). There is no periodic polling: screens
/// refresh on their first load, after their own writes, and on every
/// [RealtimeInvalidation] published here:
/// - a signal from the port, debounced for [debounce] (one batch per window);
/// - [refreshAll] (the top-bar Refresh button, the tab becoming visible);
/// - the listener coming back after it was offline (catch-up).
/// Each publication also re-reads the bell ([AdminLiveSync.tick]).
///
/// A listener failure (closed) renews the session and reconnects with
/// backoff, unless the staff login is refused ([AdminAccessDenied]).
class AdminRealtime {
  AdminRealtime({
    RealtimeEventsPort? port,
    RealtimeChannel? channel,
    AdminLiveSync? liveSync,
    this.debounce = const Duration(milliseconds: 250),
  })  : _port = port,
        _channel = channel,
        _liveSync = liveSync;

  static const Duration retryDelay = Duration(seconds: 5);
  static const Duration maxRetryDelay = Duration(seconds: 60);

  final Duration debounce;
  final RealtimeEventsPort? _port;
  final RealtimeChannel? _channel;
  final AdminLiveSync? _liveSync;
  final StreamController<RealtimeInvalidation> _out =
      StreamController<RealtimeInvalidation>.broadcast();
  final ValueNotifier<bool> _connected = ValueNotifier(false);
  final List<RealtimeChange> _pending = [];
  StreamSubscription<RealtimeChange>? _sub;
  Timer? _debounceTimer;
  Timer? _retryTimer;
  Duration _nextRetry = retryDelay;
  bool _wasOpen = false;
  bool _everOpen = false;
  bool _started = false;
  bool _disposed = false;

  /// One batch of changes per debounce window, or "everything".
  Stream<RealtimeInvalidation> get invalidations => _out.stream;

  /// Whether the signal listener is in sync with the server.
  ValueListenable<bool> get connected => _connected;

  /// Starts listening; a no-op without a port or channel source.
  Future<void> start() async {
    final port = _port;
    if (_started || _disposed || port == null || _channel == null) return;
    _started = true;
    _sub = port.changes.listen(_onChange);
    port.connection.addListener(_onConnection);
    await _connect(renew: false);
  }

  /// Refreshes every open screen and the bell now; completes when the bell
  /// re-read finishes.
  Future<void> refreshAll() async {
    if (_disposed) return;
    _debounceTimer?.cancel();
    _debounceTimer = null;
    _pending.clear();
    await _publish(RealtimeInvalidation.everything());
  }

  Future<void> _publish(RealtimeInvalidation batch) {
    if (_disposed) return Future.value();
    _out.add(batch);
    return _liveSync?.tick() ?? Future.value();
  }

  Future<void> _connect({required bool renew}) async {
    try {
      final channel = await _channel!(renew: renew);
      if (_disposed) return;
      if (channel == null || channel.isEmpty) {
        debugPrint('Realtime disabled: no admin channel.');
        return;
      }
      _port!.connect(channel);
    } on AdminAccessDenied catch (error) {
      debugPrint('Realtime disabled: $error');
    } catch (error) {
      debugPrint('Realtime channel failed: $error');
      _scheduleRetry();
    }
  }

  void _onConnection() {
    if (_disposed) return;
    final state = _port!.connection.value;
    final open = state == RealtimeConnection.open;
    _connected.value = open;
    if (open && !_wasOpen && _everOpen) {
      _publish(RealtimeInvalidation.everything());
    }
    if (open) {
      _everOpen = true;
      _nextRetry = retryDelay;
    }
    _wasOpen = open;
    if (state == RealtimeConnection.closed) _scheduleRetry();
  }

  void _scheduleRetry() {
    if (_disposed || _retryTimer != null) return;
    final delay = _nextRetry;
    final doubled = _nextRetry * 2;
    _nextRetry = doubled > maxRetryDelay ? maxRetryDelay : doubled;
    _retryTimer = Timer(delay, () {
      _retryTimer = null;
      _connect(renew: true);
    });
  }

  void _onChange(RealtimeChange change) {
    _pending.add(change);
    _debounceTimer?.cancel();
    _debounceTimer = Timer(debounce, _flush);
  }

  void _flush() {
    _debounceTimer = null;
    if (_disposed || _pending.isEmpty) return;
    final batch = RealtimeInvalidation(_pending);
    _pending.clear();
    _publish(batch);
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _debounceTimer?.cancel();
    _retryTimer?.cancel();
    _sub?.cancel();
    if (_started) {
      _port!.connection.removeListener(_onConnection);
      _port.close();
    }
    _out.close();
    _connected.dispose();
  }
}
