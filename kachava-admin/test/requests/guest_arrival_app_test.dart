import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kachava_admin_dashboard/main.dart';
import 'package:kachava_admin_dashboard/presentation/requests/request_inbox_scope.dart';

import '../support/fake_operations.dart';
import '../support/fake_resort_repositories.dart';
import '../support/fake_service_requests.dart';
import '../transport/fake_transport_repositories.dart';
import 'guest_activity_watcher_test.dart' show guestMessage;

void main() {
  late FakeServiceRequestRepository requests;
  late FakeOperations ops;
  late FakeChime chime;

  setUp(() {
    requests = FakeServiceRequestRepository()
      ..requests.add(testRequest(1, section: 'IN_VILLA'));
    ops = FakeOperations();
    chime = FakeChime();
  });

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform, (MethodCall methodCall) async => null);
    addTearDown(() {
      tester.view.reset();
      tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });
    await tester.pumpWidget(KachavaAdminApp(
      resort: fakeResortRepositories(),
      timeZones: testTimeZones,
      operations: ops.deps,
      chime: chime,
      inbox: RequestInboxDeps(requests: requests, trips: FakeTripRepository()),
    ));
    await tester.pumpAndSettle();
  }

  Future<void> refresh(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('admin-refresh-button')));
    await tester.pumpAndSettle();
  }

  Finder badge(String id) => find.descendant(
      of: find.byKey(Key('nav-badge-$id')), matching: find.byType(Text));

  testWidgets('test_badge_countsNewRequests_andPageLoadIsSilent',
      (tester) async {
    await pump(tester);
    expect(tester.widget<Text>(badge('requests')).data, '1');
    expect(chime.rings, 0);
    expect(find.byKey(const Key('guest-arrival-toast')), findsNothing);
  });

  testWidgets('test_newRequest_chimes_toast_open_opensItInTheInbox',
      (tester) async {
    await pump(tester);
    requests.requests.add(testRequest(2, section: 'IN_VILLA'));

    await refresh(tester);

    expect(chime.rings, 1);
    expect(tester.widget<Text>(badge('requests')).data, '2');
    expect(find.text('New request · Villa 2 · Service 2'), findsOneWidget);
    await tester.tap(find.byKey(const Key('guest-arrival-open')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('workspace-admin-requests')), findsOneWidget);
    expect(find.byKey(const Key('inbox-detail')), findsOneWidget);
    expect(find.byKey(const Key('guest-arrival-toast')), findsNothing);
    expect(chime.stops, greaterThan(0));

    await refresh(tester);
    expect(chime.rings, 1, reason: 'already seen: no second chime');
  });

  testWidgets('test_newGuestMessage_chimes_andOpenShowsTheChat',
      (tester) async {
    final t0 = DateTime.utc(2026, 11, 3, 15);
    await pump(tester);
    ops.conversations.rows.add(guestMessage('s1', t0));

    await refresh(tester);

    expect(chime.rings, 1);
    expect(tester.widget<Text>(badge('messages')).data, '1');
    expect(find.textContaining('New message · Villa Coral · Valeria Gómez'),
        findsOneWidget);
    await tester.tap(find.byKey(const Key('guest-arrival-open')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('workspace-admin-messages')), findsOneWidget);
    expect(find.byKey(const Key('chat-thread-s1')), findsOneWidget);
  });
}
