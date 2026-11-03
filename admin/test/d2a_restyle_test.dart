import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'support/seeded_admin_repository.dart';
import 'package:kachava_admin_dashboard/main.dart';
import 'package:kachava_admin_dashboard/presentation/components/components.dart';
import 'support/fake_resort_repositories.dart';

Future<void> _pumpDesktop(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1440, 960);
  tester.view.devicePixelRatio = 1.0;
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform, (MethodCall methodCall) async => null);
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
    tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });
  await tester.pumpWidget(KachavaAdminApp(
      resort: fakeResortRepositories(),
      timeZones: testTimeZones,
      repository: SeededAdminRepository()));
  await tester.pumpAndSettle();
}

Future<void> _openStays(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('nav-tab-admin-stays')));
  await tester.pumpAndSettle();
}

Finder _inside(Key root, Type type) =>
    find.descendant(of: find.byKey(root), matching: find.byType(type));

/// Text inside [root] uses only the theme's Roboto (no Libre Baskerville).
void _expectNoCustomFontFamily(WidgetTester tester, Finder root) {
  final texts = tester
      .widgetList<Text>(find.descendant(of: root, matching: find.byType(Text)));
  for (final t in texts) {
    expect(t.style?.fontFamily, anyOf(isNull, 'Roboto'),
        reason: 'Text "${t.data}"');
  }
}

void main() {
  group('Phase D2a restyle', () {
    testWidgets('test_overview_noEyebrowOrBanner_keepsKpisAndAlerts',
        (tester) async {
      await _pumpDesktop(tester);

      expect(find.textContaining('SANCTUARY COMMAND CENTER'), findsNothing);
      expect(find.textContaining('FR-14'), findsNothing);
      expect(find.byKey(const Key('alerts-explanation-banner')), findsNothing);
      const overview = Key('workspace-admin-overview');
      expect(_inside(overview, PageHeader), findsOneWidget);
      expect(_inside(overview, KpiTile), findsNWidgets(4));
      expect(find.text('Active Residencies'), findsOneWidget);
      expect(find.byKey(const Key('inspect-alert-alt_001')), findsOneWidget);
      _expectNoCustomFontFamily(
          tester, find.byKey(const Key('workspace-admin-overview')));
    });

    testWidgets('test_stays_noFlowBannerOrEyebrow_usesStatusChips',
        (tester) async {
      await _pumpDesktop(tester);
      await _openStays(tester);

      expect(find.textContaining('FLOW:'), findsNothing);
      expect(find.textContaining('FR-15'), findsNothing);
      const stays = Key('workspace-admin-stays');
      expect(_inside(stays, PageHeader), findsOneWidget);
      expect(_inside(stays, StatusChip), findsWidgets);
      _expectNoCustomFontFamily(
          tester, find.byKey(const Key('workspace-admin-stays')));
    });

    testWidgets('test_stayInspector_staySummaryButton_opensFolio',
        (tester) async {
      await _pumpDesktop(tester);
      await _openStays(tester);

      await tester.tap(find.byKey(const Key('inspect-stay-stay_villa_102')));
      await tester.pumpAndSettle();
      final button = find.byKey(const Key('open-stay-summary-btn'));
      expect(button, findsOneWidget);
      expect(find.text('Stay summary'), findsWidgets);

      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('workspace-admin-folio')), findsOneWidget);
    });

    testWidgets('test_alertInspector_hidesStaySummaryButton', (tester) async {
      await _pumpDesktop(tester);

      await tester.tap(find.byKey(const Key('inspect-alert-alt_001')));
      await tester.pumpAndSettle();
      expect(
          find.byKey(const Key('slide-over-inspector-drawer')), findsOneWidget);
      expect(find.byKey(const Key('open-stay-summary-btn')), findsNothing);
    });

    testWidgets('test_staysRow_staySummaryAction_opensFolio', (tester) async {
      await _pumpDesktop(tester);
      await _openStays(tester);

      final action = find.byKey(const Key('open-stay-summary-stay_villa_102'));
      await tester.ensureVisible(action);
      await tester.pumpAndSettle();
      await tester.tap(action);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('workspace-admin-folio')), findsOneWidget);
    });
  });
}
