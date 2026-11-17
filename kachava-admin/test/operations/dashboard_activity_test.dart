import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kachava_admin_dashboard/core/admin_theme.dart';
import 'package:kachava_admin_dashboard/core/resort_time.dart';
import 'package:kachava_admin_dashboard/domain/dashboard_view.dart';
import 'package:kachava_admin_dashboard/presentation/operations/dashboard_screen.dart';

import '../support/fake_operations.dart';
import '../transport/fake_transport_repositories.dart';

Map<String, dynamic> _row(String id, String status,
        {bool overdue = false,
        String stayStatus = 'ACTIVE_STAY',
        Map<String, dynamic>? next,
        int requests = 0,
        int messages = 0}) =>
    {
      'stayId': id,
      'guestName': 'Guest $id',
      'villaId': 'v-$id',
      'villaName': 'Villa $id',
      'status': status,
      'overdue': overdue,
      'stayStatus': stayStatus,
      'pending': {'requests': requests, 'messages': messages},
      'next': next,
    };

final _view = {
  'resortDate': '2026-11-03',
  'kpis': {
    'occupiedVillas': 3,
    'availableVillas': 5,
    'occupancyPct': 38,
    'arrivals': 1,
    'departures': 1,
    'openRequests': 3,
  },
  'activity': {
    'total': 4,
    'rows': [
      _row('over', 'IN_HOUSE', overdue: true, requests: 1),
      _row('dep', 'DEPARTURE', next: {
        'kind': 'FLIGHT',
        'at': '2026-11-03T19:10:00.000Z',
        'flightNumber': 'AA 1',
        'transfer': 'DRIVER_CONFIRMED',
      }),
      _row('arr', 'ARRIVAL',
          stayStatus: 'PRE_ARRIVAL',
          requests: 2,
          messages: 1,
          next: {
            'kind': 'FLIGHT',
            'at': '2026-11-03T19:10:00.000Z',
            'transfer': 'NO_DRIVER',
          }),
      _row('in', 'IN_HOUSE', next: {
        'kind': 'BOOKING',
        'title': {'en': 'Massage', 'es': 'Masaje'},
        'date': '2026-11-04',
        'time': '16:00',
      }),
    ],
  },
};

void main() {
  late FakeDashboardRepository repo;
  late List<(String, String)> actions;
  late List<String> requestsOf;
  late List<String> messagesOf;

  setUp(() {
    repo = FakeDashboardRepository()..view = DashboardView.fromJson(_view);
    actions = [];
    requestsOf = [];
    messagesOf = [];
  });

  Future<void> pump(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      theme: KachavaAdminTheme.build(),
      home: Scaffold(
        body: DashboardScreen(
          repository: repo,
          isEs: false,
          onOpenStay: (_) {},
          onViewAll: () {},
          onOpenSettings: () {},
          resortTime: const ResortTime(
              timeZone: 'America/Cancun', resolver: testZoneResolver),
          onStayAction: (row, action) async =>
              actions.add((row.stayId, action)),
          onOpenRequests: (row) => requestsOf.add(row.guestName),
          onOpenMessages: (row) => messagesOf.add(row.stayId),
        ),
      ),
    ));
    await tester.pumpAndSettle();
  }

  String text(WidgetTester tester, String key) =>
      tester.widget<Text>(find.byKey(Key(key))).data!;

  testWidgets('test_1440_nextEvent_pending_andInlineActions', (tester) async {
    await pump(tester, const Size(1440, 1000));

    expect(text(tester, 'activity-next-dep'), '✈ 14:10 · driver confirmed');
    expect(
        text(tester, 'activity-next-arr'), '✈ 14:10 · transfer without driver');
    expect(text(tester, 'activity-next-in'), 'Massage · tomorrow 16:00');
    expect(text(tester, 'activity-next-over'), '—');
    expect(find.text('2 requests'), findsOneWidget);
    expect(find.text('1 message'), findsOneWidget);
    // Overstay and departure: Check-out; arrival: Check-in; in-house: none.
    expect(find.byKey(const Key('activity-action-over')), findsOneWidget);
    expect(find.byKey(const Key('activity-action-in')), findsNothing);
    expect(
        find.descendant(
            of: find.byKey(const Key('activity-action-arr')),
            matching: find.text('Check-in')),
        findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('test_checkIn_confirmsThenCallsTheStayAction_andReloads',
      (tester) async {
    await pump(tester, const Size(1440, 1000));
    final before = repo.calls;
    await tester.tap(find.byKey(const Key('activity-action-arr')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm-dialog-confirm')));
    await tester.pumpAndSettle();

    expect(actions, [('arr', 'CHECK_IN')]);
    expect(repo.calls, before + 1);
    await tester.tap(find.byKey(const Key('activity-action-dep')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm-dialog-cancel')));
    await tester.pumpAndSettle();
    expect(actions, hasLength(1));
  });

  testWidgets('test_pendingLinks_openRequestsAndMessages', (tester) async {
    await pump(tester, const Size(1440, 1000));
    await tester.tap(find.byKey(const Key('activity-requests-arr')));
    await tester.tap(find.byKey(const Key('activity-messages-arr')));
    expect(requestsOf, ['Guest arr']);
    expect(messagesOf, ['arr']);
  });

  testWidgets('test_375_stackedRows_withoutOverflow', (tester) async {
    await pump(tester, const Size(375, 1400));
    expect(find.byKey(const Key('activity-action-arr')), findsOneWidget);
    expect(find.text('2 requests'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
