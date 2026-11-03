import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kachava_admin_dashboard/application/admin_dashboard_views.dart';
import 'package:kachava_admin_dashboard/core/admin_i18n.dart';
import 'support/seeded_admin_repository.dart';
import 'package:kachava_admin_dashboard/domain/admin_enums.dart';
import 'package:kachava_admin_dashboard/main.dart';
import 'package:kachava_admin_dashboard/presentation/admin_command_shell.dart';
import 'package:kachava_admin_dashboard/presentation/components/components.dart';

/// Track D5: review fixes (category labels, top-bar tap targets & a11y).
void main() {
  Future<AdminCommandShell> pumpApp(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester
        .pumpWidget(KachavaAdminApp(repository: SeededAdminRepository()));
    await tester.pumpAndSettle();
    return tester.widget<AdminCommandShell>(find.byType(AdminCommandShell));
  }

  test('test_alertCategoryLabel_mapsLegacyWireValuesToDisplayLabels', () {
    expect(AdminI18n.alertCategoryLabel(AlertCategory.concierge, false),
        'Resort Host');
    expect(
        AdminI18n.alertCategoryLabel(AlertCategory.larder, false), 'Services');
    expect(
        AdminI18n.alertCategoryLabel(AlertCategory.midstay, false), 'Mid-stay');
    expect(AdminI18n.alertCategoryLabel(AlertCategory.concierge, true),
        'Resort Host');
    expect(
        AdminI18n.alertCategoryLabel(AlertCategory.larder, true), 'Servicios');
    expect(AdminI18n.alertCategoryLabel(AlertCategory.midstay, true),
        'Mitad de estancia');
    // Wire values are untouched.
    expect(AlertCategory.concierge.label, 'CONCIERGE');
  });

  testWidgets('test_overview_categoryChips_showDisplayLabelsNotWireValues',
      (tester) async {
    await pumpApp(tester, const Size(1440, 960));
    Finder chipText(String wire, String text) => find.descendant(
        of: find.byKey(Key('alert-cat-$wire')), matching: find.text(text));
    expect(chipText('CONCIERGE', 'Resort Host'), findsOneWidget);
    expect(chipText('LARDER', 'Services'), findsOneWidget);
    expect(chipText('MIDSTAY', 'Mid-stay'), findsOneWidget);
    for (final raw in ['CONCIERGE', 'LARDER', 'MIDSTAY']) {
      expect(find.text(raw), findsNothing, reason: raw);
    }
  });

  group('Top command bar', () {
    const keys = [
      'admin-locale-toggle-btn',
      'top-bar-alert-bell',
    ];

    testWidgets('test_pills_have48dpTapHeight_andFocusRing', (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpApp(tester, const Size(1440, 960));
      for (final k in keys) {
        final finder = find.byKey(Key(k));
        expect(tester.getSize(finder).height, greaterThanOrEqualTo(48),
            reason: k);
        expect(find.ancestor(of: finder, matching: find.byType(FocusRing)),
            findsOneWidget,
            reason: k);
      }
      expect(find.bySemanticsLabel(RegExp(r'^EN \| ES')), findsOneWidget);
      expect(find.textContaining('Test 10s'), findsNothing);
      semantics.dispose();
    });

    testWidgets('test_compactBar_buttonsAre48x48_andGearHasTooltip',
        (tester) async {
      await pumpApp(tester, const Size(375, 812));
      for (final k in ['top-bar-settings', 'top-bar-alert-bell']) {
        final size = tester.getSize(find.byKey(Key(k)));
        expect(size.height, greaterThanOrEqualTo(48), reason: k);
        expect(size.width, greaterThanOrEqualTo(48), reason: k);
      }
      expect(find.byTooltip('Settings'), findsOneWidget);
    });

    testWidgets('test_bell_tooltipAndSemantics_areLocalized', (tester) async {
      final semantics = tester.ensureSemantics();
      final shell = await pumpApp(tester, const Size(1440, 960));
      final unread = shell.controller.unreadAlertsCount;
      expect(
          find.byTooltip('Unread operational alerts: $unread'), findsOneWidget);
      expect(
          find.bySemanticsLabel(RegExp('^Unread operational alerts: $unread')),
          findsOneWidget);

      await tester.tap(find.byKey(const Key('admin-locale-toggle-btn')));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Alertas operativas sin leer: $unread'),
          findsOneWidget);
      expect(
          find.bySemanticsLabel(
              RegExp('^Alertas operativas sin leer: $unread')),
          findsOneWidget);
      semantics.dispose();
    });
  });
}
