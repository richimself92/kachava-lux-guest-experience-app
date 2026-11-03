import '../domain/admin_entities.dart';
import '../domain/admin_enums.dart';
import '../domain/admin_sync_snapshot.dart';

/// What changed in a sync compared with everything already seen.
class AdminActivityDelta {
  const AdminActivityDelta(
      {required this.newAlerts, required this.hasNewActivity});

  final List<OperationalAlert> newAlerts;
  final bool hasNewActivity;
}

/// Remembers which guest-originated items the host was already notified about.
class AdminActivityTracker {
  final Set<String> _seen = {};

  void clear() => _seen.clear();

  /// Marks everything in [snapshot] as seen without reporting it.
  void baseline(AdminSyncSnapshot snapshot) => _seen
    ..clear()
    ..addAll(_idsOf(snapshot));

  /// Reports what is new in [snapshot] and marks it as seen.
  AdminActivityDelta absorb(AdminSyncSnapshot snapshot) {
    final newAlerts = snapshot.alerts
        .where((a) => !a.isAcknowledged && !_seen.contains(a.alertId))
        .toList();
    final hasNewActivity =
        _pendingActivityIds(snapshot).difference(_seen).isNotEmpty;
    _seen.addAll(_idsOf(snapshot));
    return AdminActivityDelta(
        newAlerts: newAlerts, hasNewActivity: hasNewActivity);
  }

  static Set<String> _idsOf(AdminSyncSnapshot s) =>
      {...s.alerts.map((a) => a.alertId), ..._pendingActivityIds(s)};

  static Set<String> _pendingActivityIds(AdminSyncSnapshot s) => {
        for (final b in s.bookings.where((b) => b.status == 'Requested'))
          'bkg:${b.bookingId}',
        for (final o in s.larderOrders.where((o) => o.status == 'Pending'))
          'lrd:${o.orderId}:${o.items.length}',
        for (final t in s.conciergeTickets
            .where((t) => t.stage != ConciergeStage.completed))
          'tkt:${t.requestId}:${t.messages.where((m) => !m.isStaff).length}',
        for (final p in s.midStayPulses.where((p) => p.status != 'ATTENDED'))
          'pls:${p.checkInId}',
      };
}
