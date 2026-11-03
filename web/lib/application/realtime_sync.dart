import 'dart:async';

import '../core/realtime/realtime_events_port.dart';
import '../domain/realtime_channels.dart';

/// Keeps the portal fresh without polling (ADR-012): refreshes after signal
/// doc changes (debounced), after a failed listener re-subscribes, and when
/// the tab becomes visible again. Listener failures never end the session.
class RealtimeSync {
  RealtimeSync({
    required RealtimeEventsPort port,
    required void Function() refresh,
    Stream<void>? onPageVisible,
    this.retryDelay = const Duration(seconds: 5),
  })  : _port = port,
        _refresh = refresh {
    _visible = onPageVisible?.listen((_) => _refresh());
  }

  static const Duration debounce = Duration(milliseconds: 250);
  static const Duration _maxRetry = Duration(minutes: 5);

  final RealtimeEventsPort _port;
  final void Function() _refresh;
  final Duration retryDelay;

  StreamSubscription<void>? _visible;
  StreamSubscription<RealtimeSignal>? _events;
  RealtimeChannels? _channels;
  Timer? _debounceTimer;
  Timer? _retryTimer;
  int _failures = 0;
  bool _refreshOnConnect = false;
  bool _closed = false;

  /// Listens to [channels] from the latest stay view; re-subscribes when the
  /// ids rotate and stops when they disappear.
  void follow(RealtimeChannels? channels) {
    if (_closed) return;
    final active = _events != null || _retryTimer != null;
    if (channels == _channels && active) return;
    _channels = channels;
    _failures = 0;
    _subscribe(refreshOnConnect: false);
  }

  void _subscribe({required bool refreshOnConnect}) {
    _unsubscribe();
    final channels = _channels;
    if (_closed || channels == null) return;
    _refreshOnConnect = refreshOnConnect;
    _events = _port
        .watch(channels)
        .listen(_onSignal, onError: (Object _) => _onFailure());
  }

  void _onSignal(RealtimeSignal signal) {
    switch (signal) {
      case RealtimeConnected():
        _failures = 0;
        if (_refreshOnConnect) _scheduleRefresh();
        _refreshOnConnect = false;
      case RealtimeChange():
        _scheduleRefresh();
      case RealtimeDisconnected():
        _onFailure();
    }
  }

  void _scheduleRefresh() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(debounce, _refresh);
  }

  /// Retries with exponential backoff; the re-subscription refreshes once
  /// connected so changes missed meanwhile show up.
  void _onFailure() {
    _unsubscribe();
    if (_closed) return;
    final wait = retryDelay * (1 << _failures.clamp(0, 6));
    _failures++;
    _retryTimer = Timer(wait > _maxRetry ? _maxRetry : wait, () {
      _retryTimer = null;
      _subscribe(refreshOnConnect: true);
    });
  }

  void _unsubscribe() {
    _retryTimer?.cancel();
    _retryTimer = null;
    _events?.cancel();
    _events = null;
  }

  void dispose() {
    _closed = true;
    _unsubscribe();
    _debounceTimer?.cancel();
    _visible?.cancel();
  }
}
