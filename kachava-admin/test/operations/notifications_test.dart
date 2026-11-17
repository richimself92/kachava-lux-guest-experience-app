import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kachava_admin_dashboard/application/admin_live_sync.dart';
import 'package:kachava_admin_dashboard/application/notification_bell_controller.dart';
import 'package:kachava_admin_dashboard/core/resort_time.dart';
import 'package:kachava_admin_dashboard/core/theme/kachava_tokens.dart';
import 'package:kachava_admin_dashboard/domain/admin_notification.dart';
import 'package:kachava_admin_dashboard/domain/admin_task.dart';
import 'package:kachava_admin_dashboard/domain/conversation.dart';
import 'package:kachava_admin_dashboard/main.dart';
import 'package:kachava_admin_dashboard/presentation/components/components.dart';
import 'package:kachava_admin_dashboard/presentation/services/service_catalog_scope.dart';
import 'package:kachava_admin_dashboard/presentation/workspaces/transportation/trip_scope.dart';

import '../support/fake_operations.dart';
import '../support/fake_resort_repositories.dart';
import '../support/fake_service_catalog.dart';
import '../transport/fake_transport_repositories.dart';
import 'recorded_operations_contract.dart';

AdminNotification _n(String id, String level, String type, String targetId,
        {bool read = false}) =>
    AdminNotification.fromJson({
      ...recordedNotification,
      'id': id,
      'level': level,
      'title': 'Title $id',
      'read': read,
      'targetRef': {'type': type, 'id': targetId, 'stayId': 'stay_a'},
    });

void main() {
  group('NotificationBellController', () {
    test('chime only when unread URGENT grows after the first read', () async {
      final repo = FakeNotificationRepository()
        ..counts = const UnreadCounts(unread: 3, urgentUnread: 1);
      final chime = FakeChime();
      final bell = NotificationBellController(repository: repo, chime: chime);
      addTearDown(bell.dispose);

      await bell.refresh();
      expect((bell.unread, chime.rings, bell.hasUrgentAlert), (3, 0, false));

      repo.counts = const UnreadCounts(unread: 4, urgentUnread: 1);
      await bell.refresh();
      expect(chime.rings, 0, reason: 'a new ACTION is silent');

      repo.counts = const UnreadCounts(unread: 5, urgentUnread: 2);
      await bell.refresh();
      expect((chime.rings, bell.hasUrgentAlert), (1, true));

      bell.silence();
      expect((chime.stops, bell.hasUrgentAlert), (1, false));
    });

    test('a failed bell sync reports reconnecting', () async {
      final repo = FakeNotificationRepository()..countsError = Exception('x');
      final bell =
          NotificationBellController(repository: repo, chime: FakeChime());
      final poll =
          AdminLiveSync(initialLoad: bell.refresh, refresh: bell.refresh);
      addTearDown(() {
        poll.dispose();
        bell.dispose();
      });
      await poll.tick();
      expect(poll.status.value, AdminSyncStatus.reconnecting);
    });
  });

  group('app: bell, Notifications screen and "Open" routing', () {
    late FakeOperations ops;
    late FakeChime chime;

    setUp(() {
      ops = FakeOperations();
      chime = FakeChime();
      ops.notifications
        ..counts = const UnreadCounts(unread: 4, urgentUnread: 1)
        ..items.addAll([
          _n('n_trip', 'URGENT', 'TRIP', 'trip-1'),
          _n('n_chat', 'ACTION', 'CONVERSATION', 'stay_a'),
          _n('n_stay', 'INFO', 'STAY', 'stay_a'),
          _n('n_task', 'ACTION', 'TASK', 'task_1'),
        ]);
      ops.reservations.rows.add(testRow('stay_a'));
      ops.tasks.tasks.add(AdminTask.fromJson(recordedTask));
      ops.conversations.rows
          .add(ConversationRow.fromJson(recordedConversationRow));
    });

    Future<void> pumpApp(WidgetTester tester) async {
      tester.view.physicalSize = const Size(1440, 960);
      tester.view.devicePixelRatio = 1;
      tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (_) async => null);
      addTearDown(() {
        tester.view.reset();
        tester.binding.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, null);
      });
      await tester.pumpWidget(ServiceCatalogScope(
        deps: fakeCatalogDeps(FakeServiceCatalogRepository()),
        child: TripScope(
          deps: TripDeps(
              trips: FakeTripRepository([
                testTrip(
                    id: 'trip-1',
                    guest: 'Ana Ruiz',
                    pickupAt: DateTime.utc(2026, 11, 3, 18))
              ]),
              stays: FakeStayList()),
          child: KachavaAdminApp(
            resort: fakeResortRepositories(),
            timeZones: testTimeZones,
            operations: ops.deps,
            staff: FakeStaffDirectory(const [testStaff]),
            chime: chime,
            zoneResolver: const FixedOffsetResolver(Duration(hours: -5)),
          ),
        ),
      ));
      await tester.pumpAndSettle();
    }

    Future<void> openNotifications(WidgetTester tester) async {
      await tester.tap(find.byKey(const Key('top-bar-alert-bell')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('workspace-admin-notifications')),
          findsOneWidget);
    }

    Future<void> openTarget(WidgetTester tester, String id) async {
      await openNotifications(tester);
      await tester.tap(find.byKey(Key('notification-open-$id')));
      await tester.pumpAndSettle();
    }

    testWidgets('bell shows the unread count and opens Notifications',
        (tester) async {
      await pumpApp(tester);
      expect(
          tester
              .widget<Text>(find.byKey(const Key('unread-alerts-badge')))
              .data,
          '4');
      expect(chime.rings, 0, reason: 'first read is the silent baseline');
      await openNotifications(tester);
      expect(ops.notifications.queries.first.filters, {'read': 'false'});
      final urgent = tester.widget<StatusChip>(
          find.byKey(const Key('notification-level-n_trip')));
      expect((urgent.label, urgent.tone), ('Urgent', StatusTone.error));
      final action = tester.widget<StatusChip>(
          find.byKey(const Key('notification-level-n_chat')));
      expect((action.label, action.tone), ('Action', StatusTone.warning));
    });

    testWidgets('Mark all read', (tester) async {
      await pumpApp(tester);
      await openNotifications(tester);
      final before = ops.notifications.countCalls;
      await tester.tap(find.byKey(const Key('primary-notifications')));
      await tester.pumpAndSettle();
      expect(ops.notifications.markAllCalls, 1);
      expect(ops.notifications.countCalls, greaterThan(before));
      expect(find.byKey(const Key('list-notifications-no-results')),
          findsOneWidget,
          reason: 'the default Unread filter is now empty');
    });

    testWidgets('TRIP opens the trip in Transportation', (tester) async {
      await pumpApp(tester);
      await openTarget(tester, 'n_trip');
      expect(ops.notifications.marked, ['n_trip']);
      expect(find.byKey(const Key('workspace-admin-transportation')),
          findsOneWidget);
      expect(find.byKey(const Key('trip-detail')), findsOneWidget);
    });

    testWidgets('CONVERSATION opens Guests › Messages with the chat',
        (tester) async {
      await pumpApp(tester);
      await openTarget(tester, 'n_chat');
      expect(find.byKey(const Key('workspace-admin-guests')), findsOneWidget);
      expect(find.byKey(const Key('conversation-panel')), findsOneWidget);
    });

    testWidgets('STAY opens the reservation detail', (tester) async {
      await pumpApp(tester);
      await openTarget(tester, 'n_stay');
      expect(find.byKey(const Key('reservation-detail')), findsOneWidget);
    });

    testWidgets('TASK opens the task detail', (tester) async {
      await pumpApp(tester);
      await openTarget(tester, 'n_task');
      expect(find.byKey(const Key('task-detail')), findsOneWidget);
    });

    testWidgets('a new URGENT (seen on Refresh) rings once; Open / Mute',
        (tester) async {
      await pumpApp(tester);
      expect(chime.rings, 0);
      ops.notifications.counts = const UnreadCounts(unread: 5, urgentUnread: 2);
      await tester.tap(find.byKey(const Key('admin-refresh-button')));
      await tester.pumpAndSettle();
      expect(chime.rings, 1);
      expect(find.byKey(const Key('admin-toast-banner')), findsOneWidget);
      await tester.tap(find.byKey(const Key('dismiss-alert-chime-btn')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('admin-toast-banner')), findsNothing);
      await tester.pumpWidget(const SizedBox());
    });
  });
}
