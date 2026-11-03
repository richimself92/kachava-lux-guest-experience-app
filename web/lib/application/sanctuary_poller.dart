import 'dart:async';

/// Single gate for every server refresh: the first load, manual refreshes
/// and periodic background polls. Polls never overlap: a request made while
/// one is in flight joins it instead of starting another.
///
/// A poll never throws: every error goes to `onError` and the timer keeps
/// running, so one unexpected failure cannot end live updates.
class SanctuaryPoller {
  SanctuaryPoller({
    required Future<void> Function() onPoll,
    required void Function(Object error, StackTrace stack) onError,
    this.interval = defaultInterval,
  })  : _onPoll = onPoll,
        _onError = onError;

  static const Duration defaultInterval = Duration(seconds: 10);

  final Duration interval;
  final Future<void> Function() _onPoll;
  final void Function(Object error, StackTrace stack) _onError;
  Timer? _timer;
  Future<void>? _inFlight;

  void start() {
    _timer?.cancel();
    _timer = Timer.periodic(interval, (_) => unawaited(pollNow()));
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  /// Polls now, or returns the poll already in flight.
  Future<void> pollNow() =>
      _inFlight ??= _pollReportingErrors().whenComplete(() => _inFlight = null);

  Future<void> _pollReportingErrors() async {
    try {
      await _onPoll();
    } catch (error, stack) {
      _onError(error, stack);
    }
  }
}
