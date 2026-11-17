import 'package:flutter/foundation.dart';

import '../domain/admin_access_denied.dart';

/// Health of the admin live sync, shown as one line in the shell.
enum AdminSyncStatus {
  /// The last sync succeeded (or none has run yet).
  live,

  /// The last sync failed transiently; the last good data stays on screen.
  reconnecting,

  /// The staff role may not read the sync feed (HTTP 403).
  noAccess,
}

/// Re-reads the bell (unread counts): one request per tick, never
/// overlapping. There is no timer (ADR-012, scale to zero): ticks come from
/// the first load, real-time signals and the manual Refresh.
///
/// The first successful tick runs [initialLoad]; later ticks run [refresh].
/// A failed tick keeps the last good data (the callbacks only apply state on
/// success) and reports [AdminSyncStatus.reconnecting] until a later tick
/// succeeds. A tick never throws.
class AdminLiveSync {
  AdminLiveSync({
    required Future<void> Function() initialLoad,
    required Future<void> Function() refresh,
  })  : _initialLoad = initialLoad,
        _refresh = refresh;

  final Future<void> Function() _initialLoad;
  final Future<void> Function() _refresh;
  final ValueNotifier<AdminSyncStatus> _status =
      ValueNotifier<AdminSyncStatus>(AdminSyncStatus.live);
  bool _loaded = false;
  bool _inFlight = false;
  bool _disposed = false;
  int _epoch = 0;

  /// Current sync health.
  ValueListenable<AdminSyncStatus> get status => _status;

  /// Runs one sync unless a previous one is still in flight.
  ///
  /// A tick that started before [reset] is discarded: it neither marks the
  /// feed loaded nor changes the status of the new session.
  Future<void> tick() async {
    if (_inFlight || _disposed) return;
    final epoch = _epoch;
    _inFlight = true;
    try {
      await (_loaded ? _refresh() : _initialLoad());
      if (epoch == _epoch) _loaded = true;
      _setStatus(epoch, AdminSyncStatus.live);
    } on AdminAccessDenied catch (error) {
      debugPrint('Admin live sync denied: $error');
      _setStatus(epoch, AdminSyncStatus.noAccess);
    } catch (error) {
      // Malformed payloads may surface as Errors; the timer must survive.
      debugPrint('Admin live sync failed: $error');
      _setStatus(epoch, AdminSyncStatus.reconnecting);
    } finally {
      if (epoch == _epoch) _inFlight = false;
    }
  }

  /// Forgets the previous staff session (401 or a different staff member):
  /// the next tick runs the initial load again and the status is live.
  void reset() {
    _epoch++;
    _loaded = false;
    _inFlight = false;
    _setStatus(_epoch, AdminSyncStatus.live);
  }

  void _setStatus(int epoch, AdminSyncStatus value) {
    if (!_disposed && epoch == _epoch) _status.value = value;
  }

  void dispose() {
    _disposed = true;
    _status.dispose();
  }
}
