import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kachava_admin_dashboard/application/admin_dashboard_controller.dart';
import 'package:kachava_admin_dashboard/core/app_config.dart';
import 'package:kachava_admin_dashboard/core/responsive_breakpoints.dart';
import 'package:kachava_admin_dashboard/data/admin_api_client.dart';
import 'package:kachava_admin_dashboard/data/admin_session.dart';
import 'package:kachava_admin_dashboard/data/api_admin_operations_repository.dart';
import 'package:kachava_admin_dashboard/data/seeded_admin_repository.dart';
import 'package:kachava_admin_dashboard/domain/admin_enums.dart';

import 'support/admin_sync_envelope.dart';
import 'support/signed_in_api_client.dart';

void main() {
  group('AdminApiClient REST Contract & Envelope Unwrapping', () {
    test('test_api_client_attaches_bearer_staff_jwt_and_parses_json', () async {
      String? capturedAuthHeader;
      String? capturedPath;
      final mockHttp = MockClient((request) async {
        capturedAuthHeader = request.headers['Authorization'];
        capturedPath = request.url.path;
        return http.Response(
          jsonEncode({
            'success': true,
            'data': {'acknowledged': true}
          }),
          200,
        );
      });

      final client = AdminApiClient(
        session: AdminSession(token: 'test_staff_token_123'),
        httpClient: mockHttp,
      );
      final response = await client.patchJson(
        '/alerts/alt_001/acknowledge',
        {'staffId': 'staff_eduardo'},
      );

      expect(capturedAuthHeader, 'Bearer test_staff_token_123');
      expect(capturedPath, '/api/v1/admin/alerts/alt_001/acknowledge');
      expect(response['success'], isTrue);
      expect(response['acknowledged'], isTrue);
      client.dispose();
    });

    test('test_api_client_normalizes_base_url_and_unwraps_data_envelope',
        () async {
      String? capturedPath;
      final mockHttp = MockClient((request) async {
        capturedPath = request.url.path;
        return http.Response(
          jsonEncode({
            'success': true,
            'data': {'guestTokenUuid': '550e8400-e29b-41d4-a716-446655440999'},
            'meta': {'requestId': 'req_1'},
          }),
          200,
        );
      });

      final client = AdminApiClient(
        baseUrl: 'http://localhost:3001/api/v1/',
        session: AdminSession(token: 'test_staff_token'),
        httpClient: mockHttp,
      );
      final response = await client.postJson(
        '/stays/stay_villa_102/regenerate-token',
        {},
      );

      expect(
          capturedPath, '/api/v1/admin/stays/stay_villa_102/regenerate-token');
      expect(
          response['guestTokenUuid'], '550e8400-e29b-41d4-a716-446655440999');
      expect(AdminAppConfig.apiBaseUrl, isNotEmpty);
    });

    test('test_api_client_signIn_posts_email_then_sends_issued_token_on_sync',
        () async {
      final requests = <String>[];
      String? loginBody;
      String? syncAuth;
      final mockHttp = MockClient((request) async {
        requests.add('${request.method} ${request.url.path}');
        if (request.url.path.endsWith('/auth/login')) {
          loginBody = request.body;
          expect(request.headers['Authorization'], isNull);
          return http.Response(
              jsonEncode({
                'success': true,
                'data': {'token': 'hmac_signed_staff_jwt'}
              }),
              201);
        }
        syncAuth = request.headers['Authorization'];
        return http.Response(jsonEncode({'success': true, 'data': {}}), 200);
      });
      final client = AdminApiClient(httpClient: mockHttp);

      await client.signIn('mateo@kachavalux.com');
      await client.getJson('/sync');

      expect(requests,
          ['POST /api/v1/admin/auth/login', 'GET /api/v1/admin/sync']);
      expect(jsonDecode(loginBody!), {'email': 'mateo@kachavalux.com'});
      expect(syncAuth, 'Bearer hmac_signed_staff_jwt');
      expect(client.session.isAuthenticated, isTrue);
    });

    test('test_api_client_without_session_refuses_call_and_sends_nothing',
        () async {
      var calls = 0;
      final mockHttp = MockClient((_) async {
        calls++;
        return http.Response('{}', 200);
      });
      final client = AdminApiClient(httpClient: mockHttp);

      await expectLater(
          client.getJson('/sync'), throwsA(isA<AdminUnauthorizedException>()));
      expect(calls, 0);
    });

    test('test_api_client_signIn_rejected_throws_and_stays_signed_out',
        () async {
      final mockHttp = MockClient(
          (_) async => http.Response('{"message":"Invalid credentials"}', 401));
      final client = AdminApiClient(httpClient: mockHttp);

      await expectLater(client.signIn('nobody@example.com'),
          throwsA(isA<AdminUnauthorizedException>()));
      expect(client.session.isAuthenticated, isFalse);
    });

    test('test_api_client_401_response_expires_session_and_throws', () async {
      final session = AdminSession(token: 'expired_token');
      var notified = 0;
      session.addListener(() => notified++);
      final mockHttp = MockClient(
          (_) async => http.Response('{"message":"Unauthorized"}', 401));
      final client = AdminApiClient(httpClient: mockHttp, session: session);

      await expectLater(
          client.getJson('/sync'), throwsA(isA<AdminUnauthorizedException>()));
      expect(session.isAuthenticated, isFalse);
      expect(notified, 1);
    });

    test('test_api_client_throws_explicit_exception_on_non_2xx', () async {
      final mockHttp = MockClient(
          (_) async => http.Response('{"message":"Unavailable"}', 503));
      final client = AdminApiClient(
          httpClient: mockHttp, session: AdminSession(token: 'staff_token'));
      expect(() => client.getJson('/stays'), throwsA(isA<AdminApiException>()));
    });
  });

  group('ApiAdminOperationsRepository Hybrid Offline Fallback & DTO Alignment',
      () {
    test('test_api_repository_offline_propagates_failure_without_seed_data',
        () async {
      final failingHttp = MockClient(
          (_) async => throw http.ClientException('Connection refused'));
      final repo = ApiAdminOperationsRepository(
        apiClient: signedInApiClient(failingHttp),
      );
      final controller = AdminDashboardController(repository: repo);

      await expectLater(
          controller.initialize(), throwsA(isA<http.ClientException>()));
      expect(controller.stays, isEmpty);
      expect(controller.alerts, isEmpty);
      controller.dispose();
    });

    test('test_api_repository_sends_aligned_dto_payloads_on_mutations',
        () async {
      final payloads = <String, Map<String, dynamic>>{};
      final mockHttp = MockClient((request) async {
        if (request.body.isNotEmpty) {
          payloads['${request.method} ${request.url.path}'] =
              jsonDecode(request.body) as Map<String, dynamic>;
        }
        if (request.url.path.endsWith('/admin/staff')) {
          return jsonResponse({
            'success': true,
            'data': [
              {
                'staffId': 'staff_carlos',
                'fullName': 'Carlos',
                'department': 'TRANSPORT',
              },
              {
                'staffId': 'staff_velasco',
                'fullName': 'Velasco',
                'department': 'MARINE',
              },
            ]
          });
        }
        if (isSyncRequest(request)) {
          return jsonResponse(adminSyncEnvelope(stays: [
            liveStayWire(stayId: 'stay_villa_102')
          ], bookings: [
            {'bookingId': 'bkg_102_yacht', 'stayId': 'stay_villa_102'}
          ]));
        }
        if (request.method == 'POST') {
          return jsonResponse({
            'success': true,
            'data': {'stay': liveStayWire(stayId: 'stay_106')}
          }, 201);
        }
        return http.Response(jsonEncode({'success': true, 'data': {}}), 200);
      });
      final repo =
          ApiAdminOperationsRepository(apiClient: signedInApiClient(mockHttp));
      await repo.fetchSnapshot();
      await repo.fetchStaffDirectory();
      await repo.createStay(
          villaName: 'Villa 106',
          guestNames: 'Marcus Sterling',
          checkInDate: '2026-11-20',
          checkOutDate: '2026-11-25',
          occasion: 'Anniversary');
      await repo.updateTransferDispatch(
          stayId: 'stay_villa_102',
          chauffeurId: 'staff_carlos',
          transferStatus: 'En Route');
      await repo.assignAndUpdateBooking(
          bookingId: 'bkg_102_yacht',
          staffId: 'staff_velasco',
          status: 'Confirmed');

      final createStayBody = payloads['POST /api/v1/admin/stays']!;
      expect(createStayBody['guestName'], 'Marcus Sterling');
      expect(createStayBody['villaId'], 'Villa 106');
      expect(createStayBody['villaName'], 'Villa 106');
      final transferBody =
          payloads['PATCH /api/v1/admin/stays/stay_villa_102/transfer']!;
      expect(transferBody['status'], 'En Route');
      expect(transferBody['assignedStaffId'], 'staff_carlos');
      final bookingBody =
          payloads['PATCH /api/v1/admin/bookings/bkg_102_yacht/assign']!;
      expect(bookingBody['status'], 'CONFIRMED');
      expect(bookingBody['assignedStaffId'], 'staff_velasco');
      expect(bookingBody['assignedDepartment'], 'MARINE');
      repo.dispose();
    });
  });

  group('Responsive Breakpoints', () {
    test('test_breakpoints_resolve_mobile_tablet_desktop_correctly', () {
      expect(AdminBreakpoints.resolve(390), AdminViewportSize.mobile);
      expect(AdminBreakpoints.resolve(599), AdminViewportSize.mobile);
      expect(AdminBreakpoints.resolve(600), AdminViewportSize.tablet);
      expect(AdminBreakpoints.resolve(1023), AdminViewportSize.tablet);
      expect(AdminBreakpoints.resolve(1024), AdminViewportSize.desktop);
      expect(AdminBreakpoints.resolve(1440), AdminViewportSize.desktop);
    });
  });

  group('AdminDashboardController & SeededAdminRepository', () {
    late SeededAdminRepository repository;
    late AdminDashboardController controller;

    setUp(() async {
      repository = SeededAdminRepository();
      controller = AdminDashboardController(repository: repository);
      await controller.initialize();
    });

    test('test_initial_state_loads_villa_102_and_staff_directory', () {
      expect(controller.activeStaff?.fullName, 'HOST ADMIN');
      expect(controller.activeStaff?.rbacRole, StaffRole.hostAdmin);
      expect(controller.stays, isNotEmpty);
      expect(
        controller.stays.first.magicLinkUrl,
        'http://localhost:3000/?guestId=550e8400-e29b-41d4-a716-446655440000',
      );
      expect(controller.unreadAlertsCount, greaterThan(0));
    });

    test('test_global_search_and_urgency_filtering_narrows_records', () {
      controller.setSearchQuery('AA 1492');
      expect(controller.filteredStays.length, 1);
      expect(controller.filteredStays.first.villaName, contains('Villa 102'));

      controller.setSearchQuery('');
      controller.toggleUrgentOnlyFilter(true);
      expect(
        controller.filteredAlerts
            .every((a) => a.severity == AlertSeverity.urgent),
        isTrue,
      );
    });

    test('test_regenerate_magic_link_rotates_uuid_for_villa_102', () async {
      final stay = controller.stays.first;
      final previousUuid = stay.guestTokenUuid;
      await controller.regenerateMagicLink(stay.stayId);
      final updated =
          controller.stays.firstWhere((s) => s.stayId == stay.stayId);
      expect(updated.guestTokenUuid, isNot(equals(previousUuid)));
      expect(updated.guestTokenUuid.length, 36);
      expect(controller.lastToastMessage,
          contains('http://localhost:3000/?guestId='));
    });

    test('test_update_transfer_dispatch_updates_chauffeur_and_status',
        () async {
      final stay = controller.stays.first;
      await controller.updateTransferDispatch(
        stayId: stay.stayId,
        chauffeurId: 'staff_carlos',
        transferStatus: 'En Route',
      );
      final updated =
          controller.stays.firstWhere((s) => s.stayId == stay.stayId);
      expect(updated.transfer.assignedChauffeurName, contains('HOST ADMIN'));
      expect(updated.transfer.transferStatus, 'En Route');
    });

    test('test_assign_booking_staff_and_send_notification', () async {
      final yachtBooking = controller.bookings.firstWhere(
        (b) => b.title.contains('Galeon 470 Sky'),
      );
      await controller.assignAndNotifyBooking(
        bookingId: yachtBooking.bookingId,
        staffId: 'staff_velasco',
        status: 'Confirmed',
      );
      final updated = controller.bookings
          .firstWhere((b) => b.bookingId == yachtBooking.bookingId);
      expect(updated.status, 'Confirmed');
      expect(updated.assignedStaffName, contains('HOST ADMIN'));
      expect(updated.notifiedAt, isNotNull);
    });

    test('test_advance_concierge_ticket_4_stages_and_send_chat_reply',
        () async {
      final ticket = controller.conciergeTickets
          .firstWhere((t) => t.stage == ConciergeStage.requested);
      await controller.advanceConciergeTicketStage(
          requestId: ticket.requestId,
          targetStage: ConciergeStage.assigned,
          staffId: 'staff_mateo_eng');
      await controller.advanceConciergeTicketStage(
          requestId: ticket.requestId, targetStage: ConciergeStage.inProgress);
      await controller.sendConciergeHostReply(
          requestId: ticket.requestId,
          messageText: 'Thermal engineer en route to Villa 102.');
      expect(controller.lastToastMessage, 'Reply sent to guest by HOST ADMIN');
      await controller.advanceConciergeTicketStage(
          requestId: ticket.requestId, targetStage: ConciergeStage.completed);

      final completed = controller.conciergeTickets
          .firstWhere((t) => t.requestId == ticket.requestId);
      expect(completed.stage, ConciergeStage.completed);
      expect(
          completed.messages
              .any((m) => m.body.contains('Thermal engineer en route')),
          isTrue);
    });

    test('test_mark_larder_order_stocked_in_villa_and_approve_express_checkout',
        () async {
      final order = controller.larderOrders.first;
      await controller.updateLarderOrderStatus(
          orderId: order.orderId,
          status: 'Stocked in Villa',
          staffId: 'staff_sofia');
      final updatedOrder =
          controller.larderOrders.firstWhere((o) => o.orderId == order.orderId);
      expect(updatedOrder.status, 'Stocked in Villa');
      expect(updatedOrder.items.every((i) => i.isStocked), isTrue);

      final stay = controller.stays.first;
      await controller.approveExpressCheckout(
          stayId: stay.stayId, approveLateCheckout: true);
      final updatedStay =
          controller.stays.firstWhere((s) => s.stayId == stay.stayId);
      expect(updatedStay.lifecycleStatus, StayLifecycleStatus.checkedOut);
      expect(updatedStay.paymentStatus, 'SETTLED');
      expect(updatedStay.lateCheckoutApproved, isTrue);
      expect(controller.isChimeRinging, isFalse);

      controller.triggerTestAlertSound();
      expect(controller.isChimeRinging, isTrue);
      controller.dismissToastAndStopChime();
      expect(controller.isChimeRinging, isFalse);
      expect(controller.lastToastMessage, isNull);
    });

    test('test_8_villas_occupancy_double_booking_guard_and_release_villa',
        () async {
      expect(controller.villas.length, 8);
      expect(controller.isVillaOccupied('Villa 101 — Palm Sanctuary'), isFalse);
      expect(controller.isVillaOccupied('Villa 102 — Ceiba Suite'), isTrue);
      expect(
          controller.isVillaOccupied('Villa 104 — Jaguar Sanctuary'), isTrue);
      expect(controller.isVillaOccupied('Villa 106 — Copal Pavilion'), isFalse);
      expect(controller.isVillaOccupied('Villa 108 — Oceanfront Pavilion'),
          isTrue);

      final countBefore = controller.stays.length;
      await controller.createNewStay(
          villaName: 'Villa 102 — Ceiba Suite',
          guestNames: 'Blocked Guest',
          checkInDate: 'Nov 20, 2026',
          checkOutDate: 'Nov 24, 2026',
          occasion: 'Attempted');
      expect(controller.stays.length, countBefore);
      expect(controller.lastToastMessage,
          contains('occupied by Alex & Sarah Miller'));

      await controller.checkOutAndReleaseVilla('stay_villa_102');
      expect(controller.isVillaOccupied('Villa 102 — Ceiba Suite'), isFalse);
      expect(controller.lastToastMessage,
          'Check-out complete: Villa released and available for new guest');
    });
  });
}
