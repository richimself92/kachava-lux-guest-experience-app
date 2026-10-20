import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kachava_admin_dashboard/application/admin_dashboard_controller.dart';
import 'package:kachava_admin_dashboard/data/admin_api_client.dart';
import 'package:kachava_admin_dashboard/data/admin_wire_mapper.dart';
import 'package:kachava_admin_dashboard/data/api_admin_operations_repository.dart';
import 'package:kachava_admin_dashboard/data/seeded_admin_repository.dart';
import 'package:kachava_admin_dashboard/domain/admin_enums.dart';
import 'package:kachava_admin_dashboard/main.dart';
import 'package:kachava_admin_dashboard/presentation/admin_command_shell.dart';

Map<String, dynamic> _sampleStayPayload() => {
      'success': true,
      'data': [
        {
          'stayId': 'stay_live_101',
          'guestTokenUuid': '11111111-2222-3333-4444-555555555555',
          'villaId': 'villa-101',
          'villaName': 'Villa 101',
          'suiteName': 'Palm Sanctuary',
          'status': 'ACTIVE_STAY',
          'stayDatesLabel': 'Dec 01 – Dec 05, 2026',
          'guestProfile': {
            'name': 'Sofia & Lucas Vega',
            'folioCard': 'Amex •••• 7788',
            'celebration': 'Honeymoon'
          },
          'personalization': {
            'pillowType': 'Memory Foam',
            'scentProfile': 'Mayan Copal',
            'occasionDetails': 'Honeymoon Escape',
            'dietary': 'Vegan',
            'dietaryAllergies': ['Peanut Allergy'],
            'selectedInterests': ['Yacht', 'Spa'],
          },
          'flightTransfer': {
            'flightNumber': 'UA 990',
            'arrivalAirport': 'EWR → CUN',
            'arrivalTime': '1:15 PM',
            'departureFlightNumber': 'UA 991',
            'departureRoute': 'CUN → EWR',
            'departureTimeLabel': '4:00 PM',
            'assignedStaffId': 'staff_carlos',
            'assignedStaffName': 'HOST ADMIN',
            'vehicleModel': 'Mercedes EQS',
            'fleetNumber': 'Fleet #01',
            'status': 'En Route',
          },
          'folioSummary': {'paymentStatus': 'PRE_AUTHORIZED'},
          'folioItems': [
            {
              'folioItemId': 'fi_1',
              'title': 'Complimentary Yacht Charter',
              'category': 'VILLA_ENTITLEMENT',
              'isComplimentary': true,
              'chargedAmountUSD': 0
            },
            {
              'folioItemId': 'fi_2',
              'title': 'Private Cenote Excursion',
              'category': 'EXCURSION',
              'isComplimentary': false,
              'chargedAmountUSD': 640.0
            },
          ],
        }
      ],
    };

void main() {
  group('AdminWireMapper Live JSON Hydration', () {
    test('test_wire_mapper_parses_stays_alerts_and_bookings', () {
      final rawStays = _sampleStayPayload();
      final stays = AdminWireMapper.parseStays(rawStays);
      expect(stays.length, 1);
      expect(stays.first.stayId, 'stay_live_101');
      expect(stays.first.villaName, 'Villa 101 — Palm Sanctuary');
      expect(stays.first.guestNames, 'Sofia & Lucas Vega');
      expect(stays.first.lifecycleStatus, StayLifecycleStatus.activeStay);
      expect(stays.first.personalization.allergies, contains('Peanut Allergy'));
      expect(stays.first.transfer.inboundFlight, 'UA 990');
      expect(stays.first.transfer.transferStatus, 'En Route');

      final alerts = AdminWireMapper.parseAlerts({
        'data': [
          {
            'alertId': 'alt_live_1',
            'stayId': 'stay_live_101',
            'villaId': 'villa-101',
            'villaName': 'Villa 101',
            'guestName': 'Sofia & Lucas Vega',
            'category': 'CONCIERGE',
            'severity': 'URGENT',
            'title': 'New Concierge Chat',
            'summary': 'Need extra pillows',
            'targetRecordId': 'req_live_1',
            'isAcknowledged': false,
            'createdAt': 'Just now',
          }
        ]
      });
      expect(alerts.first.severity, AlertSeverity.urgent);
      expect(alerts.first.guestNames, 'Sofia & Lucas Vega');

      final bookings = AdminWireMapper.parseBookings({
        'data': [
          {
            'bookingId': 'bk_live_1',
            'stayId': 'stay_live_101',
            'villaId': 'villa-101',
            'bookingType': 'YACHT_CHARTER',
            'title': 'Galeon 470 Sunset Cruise',
            'scheduledDate': '2026-12-02',
            'scheduledTimeSlot': '4:00 PM',
            'priceChargedUSD': 490.0,
            'status': 'CONFIRMED',
            'assignedStaffName': 'Capt. Velasco',
          }
        ]
      }, stays);
      expect(bookings.first.category, 'Yacht Charters');
      expect(bookings.first.priceUsd, 490.0);
    });

    test('test_wire_mapper_parses_larder_concierge_pulses_and_folio', () {
      final rawStays = _sampleStayPayload();
      final stays = AdminWireMapper.parseStays(rawStays);
      final larder = AdminWireMapper.parseLarderOrders({
        'data': [
          {
            'orderItemId': 'larder-1',
            'stayId': 'stay_live_101',
            'name': 'Artisanal Mezcal',
            'quantity': 2,
            'lineTotalUSD': 180.0,
            'storageType': 'DRY BAR PRESENTATION',
            'provisioningStatus': 'Pending',
          }
        ]
      }, stays);
      expect(larder.first.orderId, 'larder-1');
      expect(larder.first.totalUsd, 180.0);

      final tickets = AdminWireMapper.parseConciergeTickets({
        'data': [
          {
            'requestId': 'req_live_1',
            'stayId': 'stay_live_101',
            'title': 'Extra Pillows',
            'details': '2 memory foam pillows',
            'status': 'Requested',
            'photoStoragePath': '/private/photo.jpg',
            'messages': [
              {
                'sender': 'GUEST',
                'senderName': 'Sofia Vega',
                'text': 'Hello concierge!',
                'sentAt': '10:00 AM'
              }
            ],
          }
        ]
      }, stays);
      expect(tickets.first.stage, ConciergeStage.requested);
      expect(tickets.first.messages.first.body, 'Hello concierge!');

      final pulses = AdminWireMapper.parseMidStayPulses({
        'data': [
          {
            'feedbackId': 'fb_live_1',
            'stayId': 'stay_live_101',
            'selectedSentiment': 'serene',
            'selectedAspects': ['Pool Temp'],
            'note': 'Wonderful',
            'status': 'SUBMITTED'
          }
        ]
      }, stays);
      expect(pulses.first.checkInId, 'fb_live_1');

      final folio = AdminWireMapper.parseFolioItemsFromStays(
          rawStays['data'] as List<dynamic>);
      expect(folio.length, 2);
      expect(folio.first.isIncludedPrivilege, isTrue);
      expect(folio.last.amountUsd, 640.0);
    });
  });

  group('Live Sync, Chime on New Alert & Zero-State Reset', () {
    test('test_live_refresh_triggers_chime_on_new_alert_and_reset_clears_all',
        () async {
      var alertsList = <Map<String, dynamic>>[];
      var resetCalled = false;
      final mockHttp = MockClient((request) async {
        final p = request.url.path;
        if (p.endsWith('/reset')) {
          resetCalled = true;
          alertsList = [];
          return http.Response(jsonEncode({'success': true, 'data': {}}), 200);
        }
        if (p.endsWith('/alerts')) {
          return http.Response(
              jsonEncode({'success': true, 'data': alertsList}), 200);
        }
        return http.Response(jsonEncode({'success': true, 'data': []}), 200);
      });
      final repo = ApiAdminOperationsRepository(
          apiClient: AdminApiClient(httpClient: mockHttp), enableNetwork: true);
      final controller = AdminDashboardController(repository: repo);
      await controller.initialize();
      expect(controller.stays, isEmpty);

      alertsList = [
        {
          'alertId': 'alt_new_guest',
          'stayId': 'stay_1',
          'villaId': 'villa-101',
          'villaName': 'Villa 101',
          'guestName': 'Guest 101',
          'category': 'BOOKING',
          'severity': 'HIGH',
          'title': 'Booked Yacht Charter',
          'summary': 'Half-Day Charter',
          'isAcknowledged': false,
        }
      ];
      await controller.refreshFromBackend(silent: true);
      expect(controller.unreadAlertsCount, 1);
      expect(controller.lastToastMessage,
          contains('NEW GUEST UPDATE · Villa 101 — Booked Yacht Charter'));

      await controller.resetAllOperationalData();
      expect(resetCalled, isTrue);
      expect(controller.stays, isEmpty);
      expect(
          controller.villas
              .every((v) => !controller.isVillaOccupied(v.displayLabel)),
          isTrue);
      controller.dispose();
    });

    testWidgets(
        'test_top_command_bar_omits_manual_sync_reset_and_controller_reset_shows_empty_states',
        (tester) async {
      tester.view.physicalSize = const Size(1440, 960);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      await tester.pumpWidget(KachavaAdminApp(
          repository: SeededAdminRepository(), enableLivePolling: true));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('admin-refresh-btn')), findsNothing);
      expect(find.byKey(const Key('admin-reset-data-btn')), findsNothing);
      expect(find.byKey(const Key('global-search-input')), findsOneWidget);
      expect(find.byKey(const Key('quick-filter-all-villas')), findsOneWidget);
      expect(find.byKey(const Key('test-alert-sound-btn')), findsOneWidget);

      final controller = tester
          .widget<AdminCommandShell>(find.byType(AdminCommandShell))
          .controller;
      await controller.refreshFromBackend(silent: false);
      await tester.pumpAndSettle();
      expect(find.textContaining('Synced with live backend'), findsOneWidget);

      await controller.resetAllOperationalData();
      await tester.pumpAndSettle();
      expect(find.textContaining('All 8 Villas are FREE'), findsOneWidget);

      for (final tab in [
        'nav-tab-admin-stays',
        'nav-tab-admin-larder',
        'nav-tab-admin-experiences',
        'nav-tab-admin-concierge',
        'nav-tab-admin-folio'
      ]) {
        await tester.tap(find.byKey(Key(tab)));
        await tester.pumpAndSettle();
      }
      expect(
          find.textContaining(
              'No active guest folio or mid-stay pulse reviews'),
          findsOneWidget);
    });

    testWidgets('test_live_polling_refreshes_automatically_every_2_seconds',
        (tester) async {
      var alertsList = <Map<String, dynamic>>[];
      final mockHttp = MockClient((request) async {
        if (request.url.path.endsWith('/alerts')) {
          return http.Response(
              jsonEncode({'success': true, 'data': alertsList}), 200);
        }
        return http.Response(jsonEncode({'success': true, 'data': []}), 200);
      });
      final repo = ApiAdminOperationsRepository(
          apiClient: AdminApiClient(httpClient: mockHttp), enableNetwork: true);
      await tester.pumpWidget(
          KachavaAdminApp(repository: repo, enableLivePolling: true));
      await tester.pumpAndSettle();

      final shell =
          tester.widget<AdminCommandShell>(find.byType(AdminCommandShell));
      expect(shell.controller.unreadAlertsCount, 0);
      alertsList = [
        {
          'alertId': 'alt_auto_2s',
          'stayId': 'stay_1',
          'villaId': 'villa-102',
          'villaName': 'Villa 102',
          'guestName': 'Guest 102',
          'category': 'CONCIERGE',
          'severity': 'URGENT',
          'title': 'Real-Time 2s Update',
          'summary': 'Arrived within 2s',
          'isAcknowledged': false
        }
      ];
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      expect(shell.controller.unreadAlertsCount, 1);
    });
  });
}
