import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kachava_admin_dashboard/application/admin_dashboard_controller.dart';
import 'package:kachava_admin_dashboard/domain/admin_enums.dart';
import 'package:kachava_admin_dashboard/domain/list_query.dart';
import 'package:kachava_admin_dashboard/main.dart';

import 'support/seeded_admin_repository.dart';

Future<void> _pump(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(KachavaAdminApp(repository: SeededAdminRepository()));
  await tester.pumpAndSettle();
}

void main() {
  for (final size in const [Size(1440, 900), Size(375, 812)]) {
    testWidgets(
        'top bar at ${size.width.toInt()}px: title, EN/ES, bell, gear '
        'only', (tester) async {
      await _pump(tester, size);
      expect(find.byKey(const Key('global-search-input')), findsNothing);
      for (final k in [
        'quick-filter-all-villas',
        'quick-filter-urgent-only',
        'quick-filter-active-stay',
        'quick-filter-pre-arrival',
        'test-alert-sound-btn',
      ]) {
        expect(find.byKey(Key(k)), findsNothing, reason: k);
      }
      expect(find.textContaining('Test 10s'), findsNothing);
      expect(find.byKey(const Key('admin-locale-toggle-btn')), findsOneWidget);
      expect(find.byKey(const Key('top-bar-alert-bell')), findsOneWidget);
      expect(find.byKey(const Key('top-bar-settings')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('gear opens the Settings workspace (one empty-state line)',
      (tester) async {
    await _pump(tester, const Size(1440, 900));
    await tester.tap(find.byKey(const Key('top-bar-settings')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('workspace-admin-settings')), findsOneWidget);
    expect(find.byKey(const Key('top-bar-page-title')), findsOneWidget);
    expect(find.text('Settings'), findsWidgets);
    expect(find.byKey(const Key('settings-empty')), findsOneWidget);

    await tester.tap(find.byKey(const Key('admin-locale-toggle-btn')));
    await tester.pumpAndSettle();
    expect(find.text('Ajustes'), findsWidgets);
  });

  test('list queries persist per screen and reset with the staff session', () {
    final controller =
        AdminDashboardController(repository: SeededAdminRepository());
    addTearDown(controller.dispose);
    controller.listQueries
        .write('villas', const ListQuery().withFilter('status', 'BLOCKED'));
    controller.selectTab(AdminWorkspaceTab.adminSettings);
    expect(
        controller.listQueries.read('villas').filters, {'status': 'BLOCKED'});
    controller.clearSessionData();
    expect(controller.listQueries.read('villas'), const ListQuery());
  });
}
