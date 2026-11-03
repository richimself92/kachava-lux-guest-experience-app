import 'dart:async';
import 'dart:convert';
import 'support/fake_resort_repositories.dart';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:kachava_admin_dashboard/application/admin_dashboard_controller.dart';
import 'package:kachava_admin_dashboard/core/alert_chime_port.dart';
import 'package:kachava_admin_dashboard/data/admin_api_client.dart';
import 'package:kachava_admin_dashboard/data/admin_wire_mapper.dart';
import 'package:kachava_admin_dashboard/data/api_admin_operations_repository.dart';
import 'support/seeded_admin_repository.dart';
import 'package:kachava_admin_dashboard/domain/admin_entities.dart';
import 'package:kachava_admin_dashboard/main.dart';

import 'support/admin_sync_envelope.dart';
import 'support/signed_in_api_client.dart';

class _SilentChime implements AlertChimePort {
  int triggers = 0;
  @override
  bool get isRinging => false;
  @override
  void triggerTenSecondChime({void Function()? onAutoStop}) => triggers++;
  @override
  void stopChime() {}
  @override
  void dispose() {}
}

/// Offline fake whose acknowledge call is released by the test.
class _GatedAckRepository extends SeededAdminRepository {
  final Completer<void> gate = Completer<void>();
  int alertFetches = 0;

  @override
  Future<OperationalAlert> acknowledgeAlert(
      {required String alertId, required String staffId}) async {
    await gate.future;
    return super.acknowledgeAlert(alertId: alertId, staffId: staffId);
  }

  @override
  Future<List<OperationalAlert>> fetchAlerts() {
    alertFetches++;
    return super.fetchAlerts();
  }
}

Map<String, dynamic> _staffWire(String id, String name) => {
      'staffId': id,
      'fullName': name,
      'shortName': name,
      'role': 'Concierge',
      'department': 'CONCIERGE',
      'rbacRole': 'CONCIERGE_STAFF',
      'email': '$id@kachavalux.com',
      'phone': '+520000000000',
      'isActive': true,
    };

void main() {
  group('Live identity with the API repository', () {
    late List<String> calls;
    late AdminApiClient client;

    setUp(() {
      calls = [];
      client = AdminApiClient(httpClient: MockClient((request) async {
        final path = request.url.path;
        calls.add('${request.method} $path ${request.body}');
        if (path.endsWith('/auth/login')) {
          return jsonResponse({
            'success': true,
            'data': {
              'token': 'staff-token-ana',
              'staff': _staffWire('staff_srv_ana', 'Ana Ruiz'),
            }
          }, 201);
        }
        if (path.endsWith('/staff')) {
          return jsonResponse({
            'success': true,
            'data': [
              _staffWire('staff_srv_ana', 'Ana Ruiz'),
              _staffWire('staff_srv_ben', 'Ben Ortiz'),
            ]
          });
        }
        if (path.endsWith('/acknowledge')) {
          return jsonResponse({'success': true, 'data': {}});
        }
        return jsonResponse(adminSyncEnvelope(stays: [
          liveStayWire()
        ], alerts: [
          {
            'alertId': 'alt_live_1',
            'stayId': 'stay_live_101',
            'villaName': 'Villa 101',
            'title': 'Guest request',
            'isAcknowledged': false,
          }
        ]));
      }));
    });

    test('test_apiController_noSeedVillasOrStaff_usesServerAndSessionStaff',
        () async {
      final controller = AdminDashboardController(
          repository: ApiAdminOperationsRepository(apiClient: client),
          alertChime: _SilentChime());

      await controller.initialize();

      expect(controller.villas.map((v) => v.villaName), ['Villa 101']);
      expect(controller.staffDirectory.map((s) => s.staffId),
          ['staff_srv_ana', 'staff_srv_ben']);
      expect(controller.activeStaff?.staffId, 'staff_srv_ana');
      controller.dispose();
    });

    test('test_apiController_acknowledge_sendsSignedInSessionStaffId',
        () async {
      final controller = AdminDashboardController(
          repository: ApiAdminOperationsRepository(apiClient: client),
          alertChime: _SilentChime());
      await controller.initialize();

      await controller.acknowledgeAlert('alt_live_1');

      final ack = calls.singleWhere((c) => c.contains('/acknowledge'));
      final body = jsonDecode(ack.substring(ack.indexOf('{')));
      expect(body['staffId'], 'staff_srv_ana');
      expect(calls.join('\n'), isNot(contains('staff_eduardo')));
      controller.dispose();
    });
  });

  group('Guest link actions', () {
    test('test_stay_withoutServerWifi_hasNoInventedCredentials', () {
      final stay = AdminWireMapper.mapStay(liveStayWire());

      expect(stay.wifiSsid, isEmpty);
      expect(stay.wifiPasscode, isEmpty);
    });

    test('test_stay_emptyGuestToken_hasNoGuestLink', () {
      final stay = AdminWireMapper.mapStay(liveStayWire(guestTokenUuid: ''));

      expect(stay.hasGuestLink, isFalse);
      expect(AdminWireMapper.mapStay(liveStayWire()).hasGuestLink, isTrue);
    });

    Future<void> pumpStaysTab(WidgetTester tester, String? token) async {
      tester.view.physicalSize = const Size(1440, 960);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(KachavaAdminApp(
          resort: fakeResortRepositories(),
          timeZones: testTimeZones,
          repository: ApiAdminOperationsRepository(
              apiClient: signedInApiClient(MockClient((request) async =>
                  isSyncRequest(request)
                      ? jsonResponse(adminSyncEnvelope(stays: [
                          if (token != null) liveStayWire(guestTokenUuid: token)
                        ]))
                      : jsonResponse({'data': []}))))));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('nav-tab-admin-stays')));
      await tester.pumpAndSettle();
    }

    testWidgets('test_staysTab_emptyGuestToken_hidesLinkAndCopyAction',
        (tester) async {
      await pumpStaysTab(tester, '');

      expect(
          find.byKey(const Key('magic-link-text-stay_live_101')), findsNothing);
      expect(
          find.byKey(const Key('copy-magic-link-stay_live_101')), findsNothing);
      expect(find.textContaining('?guestId='), findsNothing);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('test_staysTab_withGuestToken_showsCopyAndNoCreateVilla',
        (tester) async {
      await pumpStaysTab(tester, '11111111-2222-3333-4444-555555555555');

      expect(find.byKey(const Key('copy-magic-link-stay_live_101')),
          findsOneWidget);
      expect(find.byKey(const Key('create-new-villa-btn')), findsNothing);
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('New stay without known villas', () {
    testWidgets('test_newStayDialog_noServerVillas_opensWithSubmitDisabled',
        (tester) async {
      tester.view.physicalSize = const Size(1440, 960);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(KachavaAdminApp(
          resort: fakeResortRepositories(),
          timeZones: testTimeZones,
          repository: ApiAdminOperationsRepository(
              apiClient: signedInApiClient(MockClient((request) async =>
                  isSyncRequest(request)
                      ? jsonResponse(adminSyncEnvelope())
                      : jsonResponse({'data': []}))))));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('nav-tab-admin-stays')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('create-new-stay-btn')));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.textContaining('Palm Sanctuary'), findsNothing);
      final submit = tester.widget<ElevatedButton>(
          find.byKey(const Key('confirm-create-stay-btn')));
      expect(submit.onPressed, isNull);
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('Mutation completing after dispose', () {
    test('test_acknowledge_completingAfterDispose_noFollowUpNoChimeNoThrow',
        () async {
      final repo = _GatedAckRepository();
      final chime = _SilentChime();
      final controller =
          AdminDashboardController(repository: repo, alertChime: chime);
      await controller.initialize();
      final alertId = controller.alerts.first.alertId;
      final inFlight = controller.acknowledgeAlert(alertId);

      controller.dispose();
      repo.gate.complete();

      await expectLater(inFlight, completes);
      expect(repo.alertFetches, 0);
      expect(chime.triggers, 0);
    });
  });
}
