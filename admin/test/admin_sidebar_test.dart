import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kachava_admin_dashboard/core/theme/kachava_tokens.dart';
import 'support/seeded_admin_repository.dart';
import 'package:kachava_admin_dashboard/domain/admin_enums.dart';
import 'package:kachava_admin_dashboard/main.dart';
import 'package:kachava_admin_dashboard/presentation/navigation/admin_nav_list.dart';

void main() {
  Future<void> pumpApp(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform, (MethodCall methodCall) async => null);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });
    await tester
        .pumpWidget(KachavaAdminApp(repository: SeededAdminRepository()));
    await tester.pumpAndSettle();
  }

  Finder inSidebar(Finder f) => find.descendant(
      of: find.byKey(const Key('desktop-sidebar')), matching: f);

  group('Desktop sidebar (1440x900)', () {
    testWidgets('test_sidebar_showsHeaderSectionsAndOnlyBuiltModules',
        (tester) async {
      await pumpApp(tester, const Size(1440, 900));
      expect(find.byKey(const Key('desktop-sidebar')), findsOneWidget);
      expect(inSidebar(find.text('KACHAVA LUX')), findsOneWidget);
      expect(inSidebar(find.text('COMMAND CENTER')), findsOneWidget);
      for (final label in [
        'GUEST OPERATIONS',
        'HOSPITALITY',
        'OPERATIONS',
        'Dashboard',
        'Reservations',
        'Services',
        'Experiences',
        'Tasks',
      ]) {
        expect(inSidebar(find.text(label)), findsOneWidget, reason: label);
      }
      for (final hidden in [
        'Guests',
        'Villas',
        'Dining',
        'Transportation',
        'Wellness',
        'Notifications',
        'TEAM',
        'SANCTUARY COMMAND · ONLINE',
      ]) {
        expect(inSidebar(find.text(hidden)), findsNothing, reason: hidden);
      }
      final texts = tester
          .widgetList<Text>(inSidebar(find.byType(Text)))
          .map((t) => t.data ?? '');
      for (final text in texts) {
        expect(RegExp(r'^\d').hasMatch(text), isFalse, reason: text);
      }
      expect(find.byKey(const Key('nav-tab-admin-folio')), findsNothing);
    });

    testWidgets('test_header_wordmarkFullyLaidOut_nextToCompactPill',
        (tester) async {
      await pumpApp(tester, const Size(1440, 900));
      expect(
          tester.getSize(find.byKey(const Key('desktop-sidebar'))).width, 300);
      final wordmark = tester
          .renderObject<RenderParagraph>(inSidebar(find.text('KACHAVA LUX')));
      expect(wordmark.didExceedMaxLines, isFalse);
      final pill = tester.widget<Text>(inSidebar(find.text('COMMAND CENTER')));
      expect(pill.style?.fontSize, 12);
      expect(tester.takeException(), isNull);
    });

    testWidgets('test_selectedItem_usesRestrainedBrownTreatment_andTapSwitches',
        (tester) async {
      await pumpApp(tester, const Size(1440, 900));
      final dashText = tester.widget<Text>(inSidebar(find.text('Dashboard')));
      expect(dashText.style?.fontWeight, FontWeight.w700);
      expect(dashText.style?.color, KachavaTokens.text);
      final resText = tester.widget<Text>(inSidebar(find.text('Reservations')));
      expect(resText.style?.fontWeight, isNot(FontWeight.w700));
      expect(resText.style?.color, KachavaTokens.text);

      final selectedBox = tester.widget<Ink>(find.descendant(
          of: find.byKey(const Key('nav-tab-admin-overview')),
          matching: find.byType(Ink)));
      final decoration = selectedBox.decoration! as BoxDecoration;
      // DESIGN.md v1.1: soft gray selected item; brown is not used for nav.
      expect(decoration.color, KachavaTokens.surface);
      expect(decoration.color, isNot(KachavaTokens.primary));

      await tester.tap(find.byKey(const Key('nav-tab-admin-stays')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('workspace-admin-stays')), findsOneWidget);
      final resAfter =
          tester.widget<Text>(inSidebar(find.text('Reservations')));
      expect(resAfter.style?.fontWeight, FontWeight.w700);
    });

    testWidgets('test_scrollDownButton_appearsOnlyWhenListOverflows',
        (tester) async {
      Widget host(double height) => MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 280,
                height: height,
                child: AdminNavList(
                  activeTab: AdminWorkspaceTab.adminOverview,
                  isEs: false,
                  onSelect: (_) {},
                ),
              ),
            ),
          );
      await tester.pumpWidget(host(900));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('sidebar-scroll-down')), findsNothing);

      await tester.pumpWidget(host(300));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('sidebar-scroll-down')), findsOneWidget);
      await tester.tap(find.byKey(const Key('sidebar-scroll-down')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('sidebar-scroll-down')),
          warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('sidebar-scroll-down')), findsNothing);
    });
  });

  group('Mobile drawer (375) and tablet rail (800)', () {
    testWidgets('test_mobile_drawer_opensFromMenu_listsItems_closesOnSelect',
        (tester) async {
      await pumpApp(tester, const Size(375, 812));
      expect(find.byKey(const Key('desktop-sidebar')), findsNothing);
      expect(find.byKey(const Key('mobile-bottom-nav')), findsNothing);
      expect(find.byKey(const Key('mobile-nav-drawer')), findsNothing);

      await tester.tap(find.byKey(const Key('mobile-nav-menu-button')));
      await tester.pumpAndSettle();
      final drawer = find.byKey(const Key('mobile-nav-drawer'));
      expect(drawer, findsOneWidget);
      for (final label in ['Dashboard', 'Reservations', 'Services', 'Tasks']) {
        expect(find.descendant(of: drawer, matching: find.text(label)),
            findsOneWidget);
      }
      await tester.tap(find.byKey(const Key('nav-tab-admin-stays')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('mobile-nav-drawer')), findsNothing);
      expect(find.byKey(const Key('workspace-admin-stays')), findsOneWidget);
    });

    testWidgets('test_tablet_rail_showsIconButtonsWithTooltips',
        (tester) async {
      await pumpApp(tester, const Size(800, 900));
      expect(find.byKey(const Key('tablet-compact-rail')), findsOneWidget);
      for (final id in [
        'admin-overview',
        'admin-stays',
        'admin-larder',
        'admin-experiences',
        'admin-concierge',
      ]) {
        expect(find.byKey(Key('nav-tab-$id')), findsOneWidget, reason: id);
      }
      expect(find.byTooltip('Reservations'), findsOneWidget);
      expect(find.byTooltip('Tasks'), findsOneWidget);
      await tester.tap(find.byKey(const Key('nav-tab-admin-concierge')));
      await tester.pumpAndSettle();
      expect(
          find.byKey(const Key('workspace-admin-concierge')), findsOneWidget);
    });
  });
}
