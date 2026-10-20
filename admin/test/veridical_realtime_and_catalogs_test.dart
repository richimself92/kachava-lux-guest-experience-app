import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kachava_admin_dashboard/application/admin_dashboard_controller.dart';
import 'package:kachava_admin_dashboard/application/inspector_selection.dart';
import 'package:kachava_admin_dashboard/data/admin_api_client.dart';
import 'package:kachava_admin_dashboard/data/admin_wire_mapper.dart';
import 'package:kachava_admin_dashboard/data/api_admin_operations_repository.dart';
import 'package:kachava_admin_dashboard/data/seeded_admin_repository.dart';
import 'package:kachava_admin_dashboard/main.dart';

void main() {
  group('ADR-002 Veridical Wire Mapping, Timeout & Canonical Stay Sync', () {
    test('test_api_client_timeout_8s_live_900ms_mock_and_delete_json',
        () async {
      final liveClient = AdminApiClient();
      expect(liveClient.timeout, const Duration(seconds: 8));
      liveClient.dispose();

      String? deletedPath;
      final mockHttp = MockClient((req) async {
        deletedPath = '${req.method} ${req.url.path}';
        return http.Response(jsonEncode({'success': true, 'data': {}}), 200);
      });
      final mockClient = AdminApiClient(httpClient: mockHttp);
      expect(mockClient.timeout, const Duration(milliseconds: 900));
      await mockClient.deleteJson('/catalog/experiences/exp_1');
      expect(deletedPath, 'DELETE /api/v1/admin/catalog/experiences/exp_1');
      mockClient.dispose();
    });

    test(
        'test_wire_mapper_map_stay_zero_mock_empty_personalization_and_transfer',
        () {
      final mapped = AdminWireMapper.mapStay({
        'stayId': 'stay_canonical_104',
        'guestTokenUuid': 'uuid-104-canonical',
        'villaId': 'villa-104',
        'villaName': 'Villa 104',
        'suiteName': 'Jaguar Sanctuary',
        'guestName': 'Elena Rostova',
        'checkInDate': 'Dec 10, 2026',
        'checkOutDate': 'Dec 15, 2026',
        'status': 'PRE_ARRIVAL',
        'personalization': {
          'pillowType': '',
          'scentProfile': '',
          'dietary': '',
          'dietaryAllergies': <String>[]
        },
        'flightTransfer': {
          'flightNumber': '',
          'arrivalAirport': '',
          'meetingPoint': 'Terminal 3 FBO Gate 2',
          'status': 'Not Requested'
        },
      });
      expect(mapped.stayId, 'stay_canonical_104');
      expect(mapped.personalization.pillowType, isEmpty);
      expect(mapped.personalization.scentProfile, isEmpty);
      expect(mapped.personalization.dietaryBadges, isEmpty);
      expect(mapped.transfer.inboundFlight, isEmpty);
      expect(mapped.transfer.inboundRoute, isEmpty);
      expect(mapped.transfer.vehicleLabel, isEmpty);
      expect(mapped.transfer.cabinBeverage, 'Terminal 3 FBO Gate 2');
      expect(mapped.transfer.transferStatus, 'Not Requested');
    });

    test('test_create_stay_persists_canonical_backend_stay_id_across_polls',
        () async {
      final mockHttp = MockClient((req) async {
        if (req.method == 'POST' && req.url.path.endsWith('/stays')) {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'stay': {
                  'stayId': 'stay_172999_villa_106',
                  'guestTokenUuid': 'canonical-uuid-106',
                  'villaId': 'villa-106',
                  'villaName': 'Villa 106',
                  'suiteName': 'Copal Pavilion',
                  'guestName': 'Carlos Slim',
                  'checkInDate': 'Dec 01, 2026',
                  'checkOutDate': 'Dec 06, 2026',
                  'status': 'PRE_ARRIVAL',
                  'personalization': <String, dynamic>{},
                  'flightTransfer': {'status': 'Not Requested'},
                },
              },
            }),
            201,
          );
        }
        return http.Response(jsonEncode({'success': true, 'data': []}), 200);
      });
      final repo = ApiAdminOperationsRepository(
          apiClient: AdminApiClient(httpClient: mockHttp));
      final created = await repo.createStay(
          villaName: 'Villa 106 — Copal Pavilion',
          guestNames: 'Carlos Slim',
          checkInDate: 'Dec 01, 2026',
          checkOutDate: 'Dec 06, 2026',
          occasion: 'Business Retreat');
      expect(created.stayId, 'stay_172999_villa_106');
      expect(created.guestTokenUuid, 'canonical-uuid-106');
      repo.dispose();
    });
  });

  group('Strict Guest-Only Chime & Dynamic 8-Villa Filter Engine', () {
    test('test_host_admin_mutations_never_ring_chime_and_filter_all_8_villas',
        () async {
      final ctrl =
          AdminDashboardController(repository: SeededAdminRepository());
      await ctrl.initialize();
      await ctrl.createNewStay(
          villaName: 'Villa 101 — Palm Sanctuary',
          guestNames: 'Silent Guest',
          checkInDate: 'Dec 01, 2026',
          checkOutDate: 'Dec 05, 2026',
          occasion: 'Relax');
      expect(ctrl.isChimeRinging, isFalse);

      ctrl.createVilla(
          villaName: 'Villa 109', suiteType: 'Suite', maxGuests: '2');
      expect(ctrl.isChimeRinging, isFalse);

      await ctrl.updateTransferDispatch(
          stayId: 'stay_villa_102',
          chauffeurId: 'staff_carlos',
          transferStatus: 'Confirmed',
          driverAndVehicle: 'Carlos · Escalade ESV',
          meetingPoint: 'Terminal 3 Gate 4');
      expect(ctrl.isChimeRinging, isFalse);
      final stay102 =
          ctrl.stays.firstWhere((s) => s.stayId == 'stay_villa_102');
      expect(stay102.transfer.cabinBeverage, 'Terminal 3 Gate 4');

      ctrl.setQuickFilter(villa: 'Villa 104 — Jaguar Sanctuary');
      expect(ctrl.filteredStays.length, 1);
      expect(
          AdminFilterEngine.extractVillaCode(
              ctrl.filteredStays.first.villaName),
          'Villa 104');
      ctrl.dispose();
    });
  });

  group('Interactive Villa Chips, Empty Dialogs, Assign Transfer & Catalogs UI',
      () {
    testWidgets(
        'test_free_villa_chip_opens_empty_dialog_and_assign_transfer_works',
        (tester) async {
      tester.view.physicalSize = const Size(1440, 960);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      await tester.pumpWidget(const KachavaAdminApp());
      await tester.pumpAndSettle();

      expect(
          find.byKey(const Key('alerts-explanation-banner')), findsOneWidget);
      await tester.tap(find.byKey(const Key('goto-alert-section-alt_001')));
      await tester.pumpAndSettle();
      expect(
          find.byKey(const Key('workspace-admin-concierge')), findsOneWidget);

      await tester.tap(find.byKey(const Key('nav-tab-admin-stays')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('villa-chip-villa-101')));
      await tester.pumpAndSettle();
      expect(
          tester
              .widget<TextField>(find.byKey(const Key('new-stay-guest-input')))
              .controller
              ?.text,
          isEmpty);

      await tester.enterText(
          find.byKey(const Key('new-stay-guest-input')), 'Nadia Boulanger');
      await tester.tap(find.byKey(const Key('confirm-create-stay-btn')));
      await tester.pumpAndSettle();
      expect(
          find.textContaining('Diet: Pending guest selection'), findsWidgets);
      expect(
          find.textContaining(
              'Airport Transfer: Guest has not registered flight details yet'),
          findsWidgets);

      final assignBtn = find.byKey(const Key('assign-transfer-btn-stay_101'));
      await tester.ensureVisible(assignBtn);
      await tester.pumpAndSettle();
      await tester.tap(assignBtn);
      await tester.pumpAndSettle();
      await tester.enterText(
          find.byKey(const Key('transfer-driver-input')), 'Mateo · EQS #04');
      await tester.enterText(
          find.byKey(const Key('transfer-meeting-point-input')),
          'FBO Private Lounge');
      await tester.tap(find.byKey(const Key('confirm-assign-transfer-btn')));
      await tester.pumpAndSettle();
      expect(find.textContaining('FBO Private Lounge'), findsWidgets);
    });

    testWidgets('test_experiences_and_larder_catalog_add_and_delete',
        (tester) async {
      tester.view.physicalSize = const Size(1440, 960);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      await tester.pumpWidget(const KachavaAdminApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('nav-tab-admin-experiences')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('add-catalog-experience-btn')));
      await tester.pumpAndSettle();
      await tester.enterText(
          find.byKey(const Key('catalog-exp-title-input')), 'Mayan Stargazing');
      await tester.enterText(
          find.byKey(const Key('catalog-exp-price-input')), '320');
      await tester
          .tap(find.byKey(const Key('confirm-add-catalog-experience-btn')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Mayan Stargazing'), findsWidgets);

      await tester.tap(find.byKey(const Key('nav-tab-admin-larder')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('add-catalog-larder-btn')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('catalog-larder-name-input')),
          'Kombucha Hibiscus');
      await tester.enterText(
          find.byKey(const Key('catalog-larder-price-input')), '24');
      await tester.tap(find.byKey(const Key('confirm-add-catalog-larder-btn')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Kombucha Hibiscus'), findsWidgets);
    });
  });
}
