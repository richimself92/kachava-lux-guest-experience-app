import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kachava_admin_dashboard/main.dart';

void main() {
  Future<void> pumpDesktopApp(WidgetTester tester) async {
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
    await tester.pumpWidget(const KachavaAdminApp());
    await tester.pumpAndSettle();
  }

  Future<void> pumpMobileApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(const KachavaAdminApp());
    await tester.pumpAndSettle();
  }

  group('Admin Dashboard Widget Suite (Desktop & Mobile)', () {
    testWidgets(
        'test_desktop_shell_renders_sidebar_kpi_cards_and_navigates_all_6_tabs',
        (tester) async {
      await pumpDesktopApp(tester);
      expect(find.byKey(const Key('desktop-sidebar')), findsOneWidget);
      expect(find.text('HOST ADMIN'), findsOneWidget);
      expect(find.text('HOST ADMIN · COMMAND CENTER'), findsOneWidget);
      expect(find.byKey(const Key('quick-filter-villa-102')), findsNothing);
      expect(find.text('SANCTUARY COMMAND · ONLINE'), findsOneWidget);
      expect(find.text('Active Residencies'), findsOneWidget);
      expect(find.text('Open Concierge Tickets'), findsOneWidget);
      expect(find.text('Pending Bookings & Larder'), findsOneWidget);
      expect(find.text('Urgent SLA Alerts'), findsOneWidget);

      for (final tab in [
        'admin-stays',
        'admin-experiences',
        'admin-larder',
        'admin-concierge',
        'admin-folio'
      ]) {
        await tester.tap(find.byKey(Key('nav-tab-$tab')));
        await tester.pumpAndSettle();
        expect(find.byKey(Key('workspace-$tab')), findsOneWidget);
      }
    });

    testWidgets(
        'test_mobile_shell_adapts_layout_and_opens_bottom_sheet_inspector',
        (tester) async {
      await pumpMobileApp(tester);
      expect(find.byKey(const Key('desktop-sidebar')), findsNothing);
      expect(find.byKey(const Key('mobile-bottom-nav')), findsOneWidget);

      final inspectFinder = find.byKey(const Key('inspect-alert-alt_001'));
      await tester.ensureVisible(inspectFinder);
      await tester.pumpAndSettle();
      await tester.tap(inspectFinder);
      await tester.pumpAndSettle();
      expect(
          find.byKey(const Key('slide-over-inspector-drawer')), findsOneWidget);
    });

    testWidgets(
        'test_global_search_and_urgency_filter_chips_filter_alerts_stream',
        (tester) async {
      await pumpDesktopApp(tester);
      await tester.tap(find.byKey(const Key('quick-filter-urgent-only')));
      await tester.pumpAndSettle();

      expect(
          find.text(
              'Villa 102 reported Air Conditioning issue (Photo attached)'),
          findsOneWidget);
      expect(find.text('Villa 102 Curated Larder Provisioning (\$128.00 USD)'),
          findsNothing);

      await tester.enterText(
          find.byKey(const Key('global-search-input')), 'Shellfish');
      await tester.pumpAndSettle();
      expect(
          find.text('Allergy Caution: Shellfish · Chef & Yacht Crew Briefing'),
          findsOneWidget);
    });

    testWidgets(
        'test_admin_stays_copies_and_rotates_uuid_magic_link_and_updates_transfer',
        (tester) async {
      await pumpDesktopApp(tester);
      await tester.tap(find.byKey(const Key('nav-tab-admin-stays')));
      await tester.pumpAndSettle();

      expect(find.text('Nov 12, 2026 – Nov 16, 2026 (3 nights) · HOST ADMIN'),
          findsOneWidget);
      expect(find.byKey(const Key('magic-link-text-stay_villa_102')),
          findsOneWidget);
      expect(
          find.textContaining(
              'http://localhost:3000/?guestId=550e8400-e29b-41d4-a716-446655440000'),
          findsOneWidget);
      expect(find.textContaining('AA 1492'), findsOneWidget);
      expect(
          find.textContaining(
              'Special Notes & Occasion: 4th Wedding Anniversary'),
          findsOneWidget);

      await tester.tap(find.byKey(const Key('copy-magic-link-stay_villa_102')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('admin-toast-banner')), findsOneWidget);

      await tester
          .tap(find.byKey(const Key('rotate-magic-link-stay_villa_102')));
      await tester.pumpAndSettle();
      expect(find.textContaining('http://localhost:3000/?guestId=a8098c1a'),
          findsWidgets);

      final transferChip =
          find.byKey(const Key('transfer-status-stay_villa_102-En Route'));
      await tester.ensureVisible(transferChip);
      await tester.pumpAndSettle();
      await tester.tap(transferChip);
      await tester.pumpAndSettle();
      expect(find.textContaining('Transfer updated: HOST ADMIN · En Route'),
          findsOneWidget);
    });

    testWidgets(
        'test_admin_stays_occupancy_double_booking_warning_and_release_villa',
        (tester) async {
      await pumpDesktopApp(tester);
      await tester.tap(find.byKey(const Key('nav-tab-admin-stays')));
      await tester.pumpAndSettle();

      expect(find.textContaining('🟢 Villa 101 — Palm Sanctuary · FREE'),
          findsOneWidget);
      expect(
          find.textContaining('🔴 Villa 102 · OCCUPIED (Alex & Sarah Miller)'),
          findsOneWidget);

      await tester.tap(find.byKey(const Key('create-new-stay-btn')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('new-stay-villa-dropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('🔴 Villa 102 — Ceiba Suite').last);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('occupied-villa-warning')), findsOneWidget);
      expect(
          tester
              .widget<ElevatedButton>(
                  find.byKey(const Key('confirm-create-stay-btn')))
              .onPressed,
          isNull);

      await tester.tap(find.byKey(const Key('new-stay-villa-dropdown')));
      await tester.pumpAndSettle();
      await tester
          .tap(find.textContaining('🟢 Villa 106 — Copal Pavilion').last);
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('new-stay-guest-input')),
          'Marcus & Elena Sterling');
      await tester.tap(find.byKey(const Key('confirm-create-stay-btn')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Marcus & Elena Sterling'), findsWidgets);

      await tester.tap(find.byKey(const Key('release-villa-stay_101')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('confirm-release-villa-stay_101')),
          findsOneWidget);
      await tester.tap(find.byKey(const Key('confirm-release-villa-stay_101')));
      await tester.pumpAndSettle();
      expect(find.text('FREE VILLA / CHECKED OUT'), findsWidgets);
    });

    testWidgets('test_admin_stays_create_villa_locale_toggle_and_chime',
        (tester) async {
      await pumpDesktopApp(tester);
      await tester.tap(find.byKey(const Key('nav-tab-admin-stays')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('create-new-villa-btn')));
      await tester.pumpAndSettle();
      await tester.enterText(
          find.byKey(const Key('new-villa-name-input')), 'Villa 110');
      await tester.enterText(
          find.byKey(const Key('new-villa-suite-input')), 'Mayan Sanctuary');
      await tester.tap(find.byKey(const Key('confirm-create-villa-btn')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Villa 110 — Mayan Sanctuary'), findsWidgets);

      await tester.tap(find.byKey(const Key('admin-locale-toggle-btn')));
      await tester.pumpAndSettle();
      expect(find.text('✓ ES'), findsOneWidget);
      expect(find.text('+ Nueva Villa'), findsOneWidget);
      expect(find.text('HOST ADMIN · PANEL DE CONTROL'), findsOneWidget);

      await tester.tap(find.byKey(const Key('test-alert-sound-btn')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('admin-toast-banner')), findsOneWidget);
      await tester.tap(find.byKey(const Key('dismiss-alert-chime-btn')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('admin-toast-banner')), findsNothing);
    });

    testWidgets(
        'test_admin_experiences_assigns_staff_via_drawer_and_sends_notification',
        (tester) async {
      await pumpDesktopApp(tester);
      await tester.tap(find.byKey(const Key('nav-tab-admin-experiences')));
      await tester.pumpAndSettle();

      expect(find.textContaining('Galeon 470 Sky'), findsWidgets);
      await tester.tap(find.byKey(const Key('inspect-booking-bkg_102_dining')));
      await tester.pumpAndSettle();
      expect(
          find.byKey(const Key('slide-over-inspector-drawer')), findsOneWidget);

      await tester.tap(find.byKey(const Key('drawer-assign-notify-btn')));
      await tester.pumpAndSettle();
      expect(
          find.byKey(const Key('slide-over-inspector-drawer')), findsNothing);
      expect(find.textContaining('Assigned & Notified HOST ADMIN (Confirmed)'),
          findsOneWidget);
    });

    testWidgets(
        'test_admin_concierge_progresses_4_stages_opens_photo_lightbox_and_sends_reply',
        (tester) async {
      await pumpDesktopApp(tester);
      await tester.tap(find.byKey(const Key('nav-tab-admin-concierge')));
      await tester.pumpAndSettle();

      await tester
          .tap(find.byKey(const Key('stage-btn-req_102_hvac-Assigned')));
      await tester.pumpAndSettle();
      await tester
          .tap(find.byKey(const Key('stage-btn-req_102_hvac-In Progress')));
      await tester.pumpAndSettle();

      await tester
          .tap(find.byKey(const Key('open-photo-lightbox-req_102_hvac')));
      await tester.pumpAndSettle();
      expect(
          find.byKey(const Key('maintenance-photo-lightbox')), findsOneWidget);
      await tester.tap(find.byKey(const Key('close-photo-lightbox')));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('chat-input-req_102_hvac')),
          'Chiller calibrated to 66°F for your evening rest.');
      await tester.tap(find.byKey(const Key('chat-send-req_102_hvac')));
      await tester.pumpAndSettle();
      expect(find.text('Chiller calibrated to 66°F for your evening rest.'),
          findsOneWidget);

      await tester
          .tap(find.byKey(const Key('stage-btn-req_102_hvac-Completed')));
      await tester.pumpAndSettle();
      expect(find.textContaining('updated to: Completed'), findsOneWidget);
    });

    testWidgets(
        'test_admin_larder_marks_stocked_in_villa_and_admin_folio_approves_checkout',
        (tester) async {
      await pumpDesktopApp(tester);
      await tester.tap(find.byKey(const Key('nav-tab-admin-larder')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('larder-status-Pending')), findsOneWidget);
      await tester.tap(find.byKey(const Key('mark-stocked-larder_102')));
      await tester.pumpAndSettle();
      expect(find.textContaining('marked Stocked in Villa'), findsOneWidget);

      await tester.tap(find.byKey(const Key('nav-tab-admin-folio')));
      await tester.pumpAndSettle();
      expect(
          find.textContaining(
              'Guest Stay Rating & Feedback ("How Is Your Stay Going?")'),
          findsOneWidget);
      expect(find.textContaining('Acquired Services & Stay Activity Summary'),
          findsOneWidget);

      final attendBtn = find.byKey(const Key('attend-pulse-pulse_102_01'));
      await tester.ensureVisible(attendBtn);
      await tester.pumpAndSettle();
      await tester.tap(attendBtn);
      await tester.pumpAndSettle();
      expect(find.textContaining('Guest stay feedback attended by HOST ADMIN'),
          findsOneWidget);
    });

    testWidgets(
        'test_compact_320px_viewport_renders_all_6_workspaces_without_overflow',
        (tester) async {
      tester.view.physicalSize = const Size(320, 780);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      await tester.pumpWidget(const KachavaAdminApp());
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('workspace-admin-overview')), findsOneWidget);
      for (final tabId in [
        'admin-stays',
        'admin-experiences',
        'admin-larder',
        'admin-concierge',
        'admin-folio',
        'admin-overview'
      ]) {
        final navChip = find.byKey(Key('nav-tab-$tabId'));
        await tester.ensureVisible(navChip);
        await tester.pumpAndSettle();
        await tester.tap(navChip);
        await tester.pumpAndSettle();
        expect(find.byKey(Key('workspace-$tabId')), findsOneWidget);
      }
    });
  });
}
