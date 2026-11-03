import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kachava_admin_dashboard/core/admin_theme.dart';
import 'package:kachava_admin_dashboard/domain/dashboard_view.dart';
import 'package:kachava_admin_dashboard/domain/trip_repository.dart';
import 'package:kachava_admin_dashboard/presentation/components/components.dart';
import 'package:kachava_admin_dashboard/presentation/operations/dashboard_screen.dart';

import '../support/fake_operations.dart';
import 'recorded_operations_contract.dart';

void main() {
  late FakeDashboardRepository repo;
  late List<String> opened;
  late int viewAll;
  late int settings;

  setUp(() {
    repo = FakeDashboardRepository()
      ..view = DashboardView.fromJson(recordedDashboard);
    opened = [];
    viewAll = 0;
    settings = 0;
  });

  Future<void> pump(WidgetTester tester, {bool isEs = false}) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      theme: KachavaAdminTheme.build(),
      home: Scaffold(
        body: DashboardScreen(
          repository: repo,
          isEs: isEs,
          onOpenStay: opened.add,
          onViewAll: () => viewAll++,
          onOpenSettings: () => settings++,
        ),
      ),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('Overview + Today pill, six KPI tiles with formula tooltips',
      (tester) async {
    await pump(tester);
    expect(find.text('Overview'), findsOneWidget);
    expect(find.text('Today · Nov 3'), findsOneWidget);
    expect(find.byType(KpiTile), findsNWidgets(6));
    for (final (key, value) in [
      ('occupied', '5'),
      ('available', '3'),
      ('occupancy', '63%'),
      ('arrivals', '2'),
      ('departures', '1'),
      ('open-requests', '4'),
    ]) {
      expect(
          find.descendant(
              of: find.byKey(Key('kpi-$key')), matching: find.text(value)),
          findsOneWidget,
          reason: key);
    }
    expect(find.byType(InfoTooltip), findsNWidgets(6));
    expect(
        find.byWidgetPredicate((w) =>
            w is InfoTooltip && w.message == 'Occupied ÷ active villas.'),
        findsOneWidget);
  });

  testWidgets('3-column activity: overstay is red "In-house · overdue"',
      (tester) async {
    await pump(tester);
    for (final header in ['Guest', 'Villa', 'Status']) {
      expect(find.text(header), findsOneWidget);
    }
    final overdue = tester.widget<StatusChip>(find.descendant(
        of: find.byKey(const Key('activity-stay_a')),
        matching: find.byType(StatusChip)));
    expect(overdue.label, 'In-house · overdue');
    expect(overdue.tone, StatusTone.error);
    final arrival = tester.widget<StatusChip>(find.descendant(
        of: find.byKey(const Key('activity-stay_b')),
        matching: find.byType(StatusChip)));
    expect((arrival.label, arrival.tone), ('Arrival', StatusTone.info));
  });

  testWidgets('row opens the stay; View all opens Reservations',
      (tester) async {
    await pump(tester);
    await tester.tap(find.byKey(const Key('activity-stay_b')));
    expect(opened, ['stay_b']);
    await tester.tap(find.byKey(const Key('dashboard-view-all')));
    expect(viewAll, 1);
    expect(find.textContaining('alert', findRichText: true), findsNothing);
  });

  testWidgets('no activity: one line, no View all', (tester) async {
    repo.view = DashboardView.fromJson({
      ...recordedDashboard,
      'activity': {'rows': [], 'total': 0},
    });
    await pump(tester);
    expect(find.text('No activity today'), findsOneWidget);
    expect(find.byKey(const Key('dashboard-view-all')), findsNothing);
  });

  testWidgets('missing time zone: one line that leads to Settings',
      (tester) async {
    repo.error = const SettingsRequiredException(['timeZone']);
    await pump(tester);
    expect(find.text('Time zone not set'), findsOneWidget);
    expect(find.byType(KpiTile), findsNothing);
    await tester.tap(find.byKey(const Key('setup-in-settings')));
    expect(settings, 1);
  });

  testWidgets('failure: one line + Retry reloads', (tester) async {
    repo.error = Exception('boom');
    await pump(tester);
    expect(find.text("Couldn't load"), findsOneWidget);
    repo.error = null;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.byType(KpiTile), findsNWidgets(6));
    expect(repo.calls, 2);
  });

  testWidgets('Spanish labels', (tester) async {
    await pump(tester, isEs: true);
    expect(find.text('Resumen'), findsOneWidget);
    expect(find.text('Hoy · 3 nov'), findsOneWidget);
    expect(find.text('Actividad de hoy'), findsOneWidget);
    expect(find.text('En estancia · vencida'), findsOneWidget);
  });
}
