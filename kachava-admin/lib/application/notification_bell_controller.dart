import 'package:flutter/foundation.dart';

import '../core/alert_chime_port.dart';
import '../domain/admin_notification.dart';

/// Top-bar bell: unread counters from `GET /admin/notifications/unread-count`
/// (polled by [AdminLiveSync]). The chime rings only when the number of
/// unread URGENT notifications grows after the first read; the first read
/// sets the baseline silently.
class NotificationBellController extends ChangeNotifier {
  NotificationBellController({
    required NotificationRepository? repository,
    AlertChimePort? chime,
  })  : _repository = repository,
        _chime = chime ?? createAlertChimePort();

  final NotificationRepository? _repository;
  final AlertChimePort _chime;
  UnreadCounts _counts = UnreadCounts.none;
  bool _loaded = false;
  bool _urgentAlert = false;
  bool _disposed = false;

  UnreadCounts get counts => _counts;
  int get unread => _counts.unread;

  /// A new URGENT notification arrived and was not silenced yet.
  bool get hasUrgentAlert => _urgentAlert;
  bool get isRinging => _chime.isRinging;

  /// One read; throws on failure (the poller reports "Reconnecting").
  Future<void> refresh() async {
    final repository = _repository;
    if (repository == null || _disposed) return;
    final next = await repository.unreadCounts();
    if (_disposed) return;
    final newUrgent = _loaded && next.urgentUnread > _counts.urgentUnread;
    _counts = next;
    _loaded = true;
    if (newUrgent) _ring();
    notifyListeners();
  }

  void _ring() {
    _urgentAlert = true;
    _chime.triggerTenSecondChime(onAutoStop: () {
      if (!_disposed) notifyListeners();
    });
  }

  /// Rings for new guest activity (a request or a message) without the
  /// urgent line; [silence] stops it.
  void chime() {
    if (_disposed) return;
    _chime.triggerTenSecondChime(onAutoStop: () {
      if (!_disposed) notifyListeners();
    });
    notifyListeners();
  }

  /// Stops the chime and hides the urgent line.
  void silence() {
    _chime.stopChime();
    if (!_urgentAlert || _disposed) return;
    _urgentAlert = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _chime.dispose();
    super.dispose();
  }
}
