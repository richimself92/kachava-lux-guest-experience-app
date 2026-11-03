import 'package:flutter_test/flutter_test.dart';
import 'package:kachava_admin_dashboard/application/admin_activity_tracker.dart';
import 'support/admin_seed_operations.dart';
import 'package:kachava_admin_dashboard/domain/admin_sync_snapshot.dart';

AdminSyncSnapshot _snapshotWith({
  List<Object> alerts = const [],
  List<Object> bookings = const [],
}) =>
    AdminSyncSnapshot(
      stays: const [],
      alerts: alerts.cast(),
      bookings: bookings.cast(),
      larderOrders: const [],
      conciergeTickets: const [],
      midStayPulses: const [],
      folioItems: const [],
    );

void main() {
  final unackedAlert =
      AdminSeedOperations.buildAlerts().firstWhere((a) => !a.isAcknowledged);
  final requestedBooking = AdminSeedOperations.buildBookings()
      .firstWhere((b) => b.status == 'Requested');

  test('test_tracker_baseline_items_are_not_reported_as_new', () {
    final tracker = AdminActivityTracker()
      ..baseline(_snapshotWith(alerts: [unackedAlert]));

    final delta = tracker.absorb(_snapshotWith(alerts: [unackedAlert]));

    expect(delta.newAlerts, isEmpty);
    expect(delta.hasNewActivity, isFalse);
  });

  test('test_tracker_new_unacknowledged_alert_reported_once', () {
    final tracker = AdminActivityTracker()..baseline(_snapshotWith());

    final first = tracker.absorb(_snapshotWith(alerts: [unackedAlert]));
    final second = tracker.absorb(_snapshotWith(alerts: [unackedAlert]));

    expect(first.newAlerts.single.alertId, unackedAlert.alertId);
    expect(second.newAlerts, isEmpty);
  });

  test('test_tracker_new_requested_booking_is_new_activity', () {
    final tracker = AdminActivityTracker()..baseline(_snapshotWith());

    final delta = tracker.absorb(_snapshotWith(bookings: [requestedBooking]));

    expect(delta.hasNewActivity, isTrue);
  });

  test('test_tracker_clear_forgets_seen_items', () {
    final tracker = AdminActivityTracker()
      ..baseline(_snapshotWith(alerts: [unackedAlert]))
      ..clear();

    expect(tracker.absorb(_snapshotWith(alerts: [unackedAlert])).newAlerts,
        hasLength(1));
  });
}
