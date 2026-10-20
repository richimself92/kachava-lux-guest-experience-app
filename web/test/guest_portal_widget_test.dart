import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kachava_guest_portal/application/sanctuary_controller.dart';
import 'package:kachava_guest_portal/core/audio/soundscape_port.dart';
import 'package:kachava_guest_portal/core/constants/screen_id.dart';
import 'package:kachava_guest_portal/data/repositories/api_sanctuary_repository.dart';
import 'package:kachava_guest_portal/main.dart';

SanctuaryController _createTestController({String? uriString}) {
  return SanctuaryController(
    repository: ApiSanctuaryRepository(enableNetwork: false),
    soundscape: SanctuarySoundscapeSynthesizer(),
    initialUri: Uri.parse(
      uriString ??
          'https://kachavalux.com/?guestId=550e8400-e29b-41d4-a716-446655440000',
    ),
  );
}

void main() {
  group('KachavaGuestPortalApp Shell, Auth & 13 Screens Widget Tests', () {
    testWidgets(
      'test_invalidMagicLinkUuid_rendersAccessRestrictedScreen',
      (tester) async {
        final controller = _createTestController(
          uriString: 'https://kachavalux.com/?guestId=invalid-uuid',
        );
        await tester.pumpWidget(KachavaGuestPortalApp(controller: controller));
        await tester.pumpAndSettle();

        expect(find.textContaining('Access Restricted'), findsWidgets);
        expect(find.textContaining('Acceso Restringido'), findsWidgets);
        expect(find.textContaining('HOST ADMIN'), findsWidgets);

        // Normal URL without ?guestId=<uuid> also renders Access Restricted
        await tester.pumpWidget(
          KachavaGuestPortalApp(
            repository: ApiSanctuaryRepository(enableNetwork: false),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.textContaining('Access Restricted'), findsWidgets);
        expect(find.textContaining('?guestId='), findsWidgets);
      },
    );

    testWidgets(
      'test_responsiveShell_rendersUnified1To11OptionsAndBottomNavOnDesktopAndMobile',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final controller = _createTestController();
        await tester.pumpWidget(KachavaGuestPortalApp(controller: controller));
        await tester.pumpAndSettle();

        // Invented desktop sidebar is completely removed; unified shell + bottom nav exist on Desktop
        expect(find.byKey(const Key('sanctuary-mobile-shell')), findsOneWidget);
        expect(
            find.byKey(const Key('sanctuary-desktop-sidebar')), findsNothing);
        expect(find.text('KACHAVA LUX'), findsOneWidget);
        expect(find.textContaining('VILLA 102 — CEIBA SUITE'), findsWidgets);
        expect(find.byKey(const Key('bottom-nav-home')), findsOneWidget);
        expect(find.byKey(const Key('bottom-nav-explore')), findsOneWidget);
        expect(find.byKey(const Key('bottom-nav-concierge')), findsOneWidget);
        expect(find.byKey(const Key('bottom-nav-profile')), findsOneWidget);
        expect(
            find.byKey(const Key('open-screen-switcher-btn')), findsOneWidget);

        // All 11 numbered options exist on Desktop Home
        const expectedHomeNavKeys = [
          'home-nav-transport',
          'home-nav-personalize',
          'home-nav-stock-villa',
          'home-nav-explore',
          'home-nav-yacht',
          'home-nav-dining',
          'home-nav-concierge',
          'home-nav-midstay',
          'home-nav-departure',
          'home-nav-profile',
          'home-nav-philosophy',
        ];
        for (final key in expectedHomeNavKeys) {
          expect(find.byKey(Key(key)), findsOneWidget);
        }

        // Switch BottomNav tabs on Desktop
        await tester.tap(find.byKey(const Key('bottom-nav-explore')));
        await tester.pumpAndSettle();
        expect(controller.currentScreen, equals(ScreenId.explore));

        await tester.tap(find.byKey(const Key('bottom-nav-home')));
        await tester.pumpAndSettle();
        expect(controller.currentScreen, equals(ScreenId.home));

        // Resize to mobile (< 768px) -> renders the exact same 11 options and bottom nav
        tester.view.physicalSize = const Size(390, 844);
        await tester.pumpAndSettle();
        expect(
            find.byKey(const Key('sanctuary-desktop-sidebar')), findsNothing);
        expect(find.byKey(const Key('sanctuary-mobile-shell')), findsOneWidget);
        for (final key in expectedHomeNavKeys) {
          expect(find.byKey(Key(key)), findsOneWidget);
        }

        // Switch BottomNav tabs on mobile: Sanctuary -> Experiences -> Concierge -> Profile
        await tester.tap(find.byKey(const Key('bottom-nav-explore')));
        await tester.pumpAndSettle();
        expect(controller.currentScreen, equals(ScreenId.explore));

        await tester.tap(find.byKey(const Key('bottom-nav-concierge')));
        await tester.pumpAndSettle();
        expect(controller.currentScreen, equals(ScreenId.concierge));

        await tester.tap(find.byKey(const Key('bottom-nav-profile')));
        await tester.pumpAndSettle();
        expect(controller.currentScreen, equals(ScreenId.profile));

        await tester.tap(find.byKey(const Key('bottom-nav-home')));
        await tester.pumpAndSettle();
        expect(controller.currentScreen, equals(ScreenId.home));
      },
    );

    testWidgets(
      'test_screenSwitcherDrawer_navigatesAcrossAllActiveScreensCleanly',
      (tester) async {
        tester.view.physicalSize = const Size(430, 932);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final controller = _createTestController();
        await tester.pumpWidget(KachavaGuestPortalApp(controller: controller));
        await tester.pumpAndSettle();

        final activeScreens =
            ScreenId.values.where((s) => s != ScreenId.included);
        for (final screen in activeScreens) {
          final openButton = find.byKey(const Key('open-screen-switcher-btn'));
          await tester.tap(openButton);
          await tester.pumpAndSettle();

          expect(find.byKey(const Key('drawer-screen-included')), findsNothing);
          final itemFinder = find.byKey(Key('drawer-screen-${screen.wireId}'));
          await tester.ensureVisible(itemFinder);
          await tester.tap(itemFinder);
          await tester.pumpAndSettle();

          expect(controller.currentScreen, equals(screen));
        }
      },
    );

    testWidgets('test_stockVillaScreen_updatesCartAndConfirmsStocking',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final controller = _createTestController();
      controller.navigateTo(ScreenId.stockVilla);
      await tester.pumpWidget(KachavaGuestPortalApp(controller: controller));
      await tester.pumpAndSettle();

      // Starts at 0 items / $0.00 USD
      expect(find.textContaining('\$0.00 USD'), findsWidgets);
      final incrementFirst = find.byKey(const Key('larder-inc-larder-1'));
      await tester.ensureVisible(incrementFirst);
      await tester.tap(incrementFirst);
      await tester.pump();
      await tester.tap(incrementFirst);
      await tester.pumpAndSettle();

      expect(controller.larderTotalAmount, equals(76));
      expect(find.textContaining('\$76.00 USD'), findsWidgets);
      await tester.tap(find.byKey(const Key('confirm-villa-stocking-btn')));
      await tester.pumpAndSettle();
      expect(controller.activeToastMessage, contains('Larder stocked'));
      expect(controller.isLarderOrderConfirmed, isTrue);
      // Banner displays the submitted items while item counter resets immediately to 0
      expect(find.textContaining('2x Endemic Tropical Fruit Harvest'),
          findsOneWidget);
      expect(controller.larderTotalCount, equals(0));
      final qtyText =
          tester.widget<Text>(find.byKey(const Key('larder-qty-larder-1')));
      expect(qtyText.data, equals('0'));
      expect(find.textContaining('\$0.00 USD'), findsWidgets);

      // Verify delivered order clears cart and shows reorder banner
      final deliveredClient = MockClient((_) async => http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'status': 'ACTIVE_STAY',
                'larderOrders': [
                  {
                    'itemId': 'larder-1',
                    'quantity': 2,
                    'provisioningStatus': 'Stocked in Villa',
                  },
                ],
              },
            }),
            200,
            headers: const {'content-type': 'application/json; charset=utf-8'},
          ));
      final deliveredCtrl = SanctuaryController(
        repository: ApiSanctuaryRepository(httpClient: deliveredClient),
        soundscape: SanctuarySoundscapeSynthesizer(),
      );
      await deliveredCtrl.initialize();
      deliveredCtrl.navigateTo(ScreenId.stockVilla);
      await tester.pumpWidget(KachavaGuestPortalApp(controller: deliveredCtrl));
      await tester.pumpAndSettle();

      expect(deliveredCtrl.larderTotalCount, equals(0));
      expect(
        find.textContaining(
            'Previous order delivered to your villa · You may place a new order anytime.'),
        findsOneWidget,
      );
      deliveredCtrl.dispose();
    });

    testWidgets(
        'test_departureScreen_rendersStayAndDepartureSummaryWithoutBillingOrSelfCheckout',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final controller = _createTestController();
      controller.updateLarderQuantity('larder-1', 1);
      await controller.confirmVillaStocking();
      await controller.submitYachtCharterRequest();
      controller.navigateTo(ScreenId.departure);
      await tester.pumpWidget(KachavaGuestPortalApp(controller: controller));
      await tester.pumpAndSettle();

      // Billing, credit card and self-checkout button must be absent
      expect(find.byKey(const Key('express-checkout-btn')), findsNothing);
      expect(find.textContaining('BILLABLE INCIDENTALS'), findsNothing);
      expect(find.textContaining('Visa ending in 8412'), findsNothing);

      // Summary sections must be present
      expect(find.textContaining('4 nights'), findsWidgets);
      expect(find.textContaining('1x Endemic Tropical Fruit Harvest'),
          findsOneWidget);
      expect(find.textContaining('Galeon 470 Sky'), findsWidgets);
      expect(find.textContaining('HOST ADMIN'), findsWidgets);
    });

    testWidgets(
      'test_yachtScreen_updatesGuestCountAndSubmitsCharterRequest',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final controller = _createTestController();
        controller.navigateTo(ScreenId.yacht);
        await tester.pumpWidget(KachavaGuestPortalApp(controller: controller));
        await tester.pumpAndSettle();

        final incBtn = find.byKey(const Key('yacht-guest-inc-btn'));
        await tester.ensureVisible(incBtn);
        await tester.tap(incBtn);
        await tester.pumpAndSettle();
        expect(controller.yachtCharter.guestCount, equals(3));

        final requestBtn = find.byKey(const Key('yacht-reserve-btn'));
        await tester.ensureVisible(requestBtn);
        await tester.tap(requestBtn);
        await tester.pumpAndSettle();

        expect(controller.yachtCharter.bookingStatus, equals('REQUESTED'));
        expect(controller.yachtCharter.isConfirmed, isFalse);
        expect(find.textContaining('⏳'), findsWidgets);
      },
    );

    testWidgets(
      'test_conciergeAndMidStayScreens_dispatchTicketsChatAndSentiment',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final controller = _createTestController();
        controller.navigateTo(ScreenId.concierge);
        await tester.pumpWidget(KachavaGuestPortalApp(controller: controller));
        await tester.pumpAndSettle();

        final requestInput = find.byKey(const Key('concierge-request-input'));
        await tester.ensureVisible(requestInput);
        await tester.enterText(requestInput, 'Extra artisanal ice bucket');
        await tester.tap(find.byKey(const Key('concierge-submit-request-btn')));
        await tester.pumpAndSettle();
        expect(controller.conciergeRequests.length, greaterThanOrEqualTo(3));

        final chatInput = find.byKey(const Key('concierge-chat-input'));
        await tester.ensureVisible(chatInput);
        await tester.enterText(chatInput, 'Please prepare beach towels');
        await tester.tap(find.byKey(const Key('concierge-chat-send-btn')));
        await tester.pumpAndSettle();
        expect(
            find.textContaining('Please prepare beach towels'), findsWidgets);

        // Navigate to Mid-Stay Check-In and submit sentiment
        controller.navigateTo(ScreenId.midstay);
        await tester.pumpAndSettle();

        // Housekeeping Schedule is no longer in MidStayScreen
        expect(find.textContaining('HOUSEKEEPING SCHEDULE'), findsNothing);

        final submitMidStayBtn = find.byKey(const Key('midstay-submit-btn'));
        await tester.ensureVisible(submitMidStayBtn);
        await tester.tap(submitMidStayBtn);
        await tester.pumpAndSettle();
        expect(controller.latestMidStayCheckIn, isNotNull);
        expect(find.textContaining('✓'), findsWidgets);
      },
    );

    testWidgets(
      'test_narrow320pxViewportAndVeridicalScreens_rendersCleanlyWithoutFakeIotOrNfc',
      (tester) async {
        tester.view.physicalSize = const Size(320, 720);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(KachavaGuestPortalApp(
            repository: ApiSanctuaryRepository(enableNetwork: false)));
        await tester.pumpAndSettle();
        expect(find.textContaining('Access Restricted'), findsWidgets);
        expect(tester.takeException(), isNull, reason: 'access-restricted');

        final controller = _createTestController();
        await controller.updateFlightDetails(controller.transport
            .copyWith(flightNumber: '', assignedDriver: '', meetingPoint: ''));
        await controller.savePersonalization(controller.preferences
            .copyWith(pillowType: '', dietaryRegimen: '', allergyAlerts: ''));
        await tester.pumpWidget(KachavaGuestPortalApp(controller: controller));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('sanctuary-mobile-shell')), findsOneWidget);

        expect(find.textContaining('23°C · Chukum'), findsNothing);
        expect(find.text('STAY STATUS'), findsOneWidget);
        expect(
            find.textContaining(
                'Not registered yet — Tap to enter your arrival flight'),
            findsOneWidget);
        expect(
            find.textContaining('Tap to configure pillows, diet & allergies'),
            findsOneWidget);

        for (final screen in ScreenId.values) {
          controller.navigateTo(screen);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull,
              reason: 'screen=${screen.name}');
        }
      },
    );

    testWidgets(
      'test_transportPersonalizeProfileYachtAndDining_veridicalInputsAndDatePickers',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final controller = _createTestController();
        await controller.updateFlightDetails(controller.transport
            .copyWith(flightNumber: '', assignedDriver: '', meetingPoint: ''));
        await tester.pumpWidget(KachavaGuestPortalApp(controller: controller));

        controller.navigateTo(ScreenId.transport);
        await tester.pumpAndSettle();
        expect(find.textContaining('Pending Flight Details'), findsOneWidget);
        expect(
            find.textContaining(
                'Awaiting chauffeur & meeting point assignment by HOST ADMIN.'),
            findsOneWidget);
        expect(find.byKey(const Key('transport-arrival-date-input')),
            findsOneWidget);
        expect(
            find.byKey(const Key('transport-airport-input')), findsOneWidget);
        expect(
            find.byKey(const Key('transport-airline-input')), findsOneWidget);
        expect(
            find.byKey(const Key('transport-terminal-input')), findsOneWidget);

        controller.navigateTo(ScreenId.personalize);
        await tester.pumpAndSettle();
        expect(find.text('Step 1'), findsNothing);
        expect(find.text('09:00 AM – 11:00 AM'), findsOneWidget);
        await tester.tap(find.text('09:00 AM – 11:00 AM'));
        await tester.pumpAndSettle();
        await tester.enterText(
            find.byKey(const Key('personalize-allergies-input')), 'Peanuts');
        await tester.enterText(find.byKey(const Key('personalize-notes-input')),
            'Coffee at 8:00 AM');
        await tester.tap(find.byKey(const Key('personalize-save-btn')));
        await tester.pumpAndSettle();
        expect(controller.preferences.allergyAlerts, equals('Peanuts'));
        expect(
            controller.preferences.occasionNote, equals('Coffee at 8:00 AM'));
        expect(controller.preferences.housekeepingCadence,
            equals('09:00 AM – 11:00 AM'));

        controller.navigateTo(ScreenId.profile);
        await tester.pumpAndSettle();
        expect(
            find.byKey(const Key('profile-nfc-keycard-switch')), findsNothing);
        expect(find.textContaining('Visa ending in 8412'), findsNothing);
        expect(find.byKey(const Key('profile-copy-wifi-btn')), findsOneWidget);
        expect(find.byKey(const Key('profile-edit-preferences-btn')),
            findsOneWidget);

        controller.navigateTo(ScreenId.yacht);
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('yacht-date-picker-btn')), findsOneWidget);

        controller.navigateTo(ScreenId.dining);
        await tester.pumpAndSettle();
        // Hardcoded evening chips must be removed
        expect(find.text('Fri, Nov 14 (Anniversary Night)'), findsNothing);
        expect(find.byKey(const Key('pick-dining-date-btn')), findsOneWidget);
        expect(find.byKey(const Key('pick-dining-time-btn')), findsOneWidget);
        final dietaryInput =
            find.byKey(const Key('dining-dietary-notes-input'));
        expect(dietaryInput, findsOneWidget);
        final dietaryField = tester.widget<TextField>(dietaryInput);
        expect(dietaryField.controller?.text, isEmpty);
        expect(find.textContaining('No Crustacean Shellfish'), findsNothing);

        // Select a preset service time chip in DiningScreen
        expect(find.text('6:30 PM'), findsOneWidget);
        await tester.tap(find.text('6:30 PM'));
        await tester.pumpAndSettle();
        expect(find.textContaining('⏰ 6:30 PM'), findsOneWidget);

        // Explore screen modal reservation dialog & locking
        controller.navigateTo(ScreenId.explore);
        await tester.pumpAndSettle();
        const firstExpId = 'exp-2';
        final reserveBtn = find.byKey(const Key('reserve-exp-$firstExpId'));
        await tester.ensureVisible(reserveBtn);
        await tester.tap(reserveBtn);
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('pick-exp-custom-time-$firstExpId')),
          findsOneWidget,
        );
        final confirmDialogBtn =
            find.byKey(const Key('confirm-exp-dialog-$firstExpId'));
        expect(confirmDialogBtn, findsOneWidget);
        await tester.tap(confirmDialogBtn);
        await tester.pumpAndSettle();

        final bookedExp =
            controller.experiences.firstWhere((e) => e.id == firstExpId);
        expect(bookedExp.bookingStatus, equals('REQUESTED'));
        expect(find.textContaining('⏳'), findsWidgets);
      },
    );
  });
}
