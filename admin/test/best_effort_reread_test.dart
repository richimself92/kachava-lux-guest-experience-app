import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kachava_admin_dashboard/application/admin_dashboard_controller.dart';
import 'package:kachava_admin_dashboard/data/admin_api_client.dart';
import 'package:kachava_admin_dashboard/data/admin_session.dart';
import 'package:kachava_admin_dashboard/data/admin_staff_mapper.dart';
import 'package:kachava_admin_dashboard/data/api_admin_operations_repository.dart';
import 'package:kachava_admin_dashboard/domain/admin_enums.dart';
import 'package:kachava_admin_dashboard/main.dart';
import 'package:kachava_admin_dashboard/presentation/admin_command_shell.dart';

import 'support/admin_sync_envelope.dart';

const _newToken = '99999999-8888-7777-6666-555555555555';
const _staffWire = {'staffId': 'stf_1', 'fullName': 'Ana Host', 'role': 'Host'};

/// Fake backend: `/sync` serves one stay and one alert, `/staff` answers
/// [staffStatus], mutations succeed and every other read fails with 503.
ApiAdminOperationsRepository _repo({int staffStatus = 200}) =>
    ApiAdminOperationsRepository(
        apiClient: AdminApiClient(
            session: AdminSession(
                token: 'test-staff-token',
                staff: AdminStaffMapper.tryMap(_staffWire)),
            httpClient: MockClient((request) async {
              final path = request.url.path;
              if (isSyncRequest(request)) {
                return jsonResponse(adminSyncEnvelope(stays: [
                  liveStayWire()
                ], alerts: [
                  {'alertId': 'alt_1', 'title': 'Towels', 'stayId': 'x'}
                ]));
              }
              if (path.endsWith('/staff')) {
                return jsonResponse({
                  'data': [_staffWire]
                }, staffStatus);
              }
              if (path.endsWith('/regenerate-token')) {
                return jsonResponse({
                  'data': {'guestTokenUuid': _newToken}
                }, 201);
              }
              if (request.method == 'PATCH') return jsonResponse({'ok': 1});
              return http.Response('unavailable', 503);
            })));

Future<AdminDashboardController> _loaded() async {
  final controller = AdminDashboardController(repository: _repo());
  await controller.initialize();
  return controller;
}

void main() {
  group('Confirmed mutation with a failed re-read', () {
    test('test_regenerateMagicLink_rereadFails_reportsSuccessWithNewLink',
        () async {
      final c = await _loaded();

      await c.regenerateMagicLink('stay_live_101');

      expect(c.lastToastMessage, contains('New Magic Link generated'));
      expect(c.lastToastMessage, contains(_newToken));
      expect(c.stays.single.guestTokenUuid, _newToken);
    });

    test('test_acknowledgeAlert_rereadFails_reportsSuccessNotNotSaved',
        () async {
      final c = await _loaded();

      await c.acknowledgeAlert('alt_1');

      expect(c.lastToastMessage, startsWith('Alert attended'));
    });

    test('test_checkInGuest_rereadFails_reportsSuccessAndPatchesStay',
        () async {
      final c = await _loaded();

      await c.checkInGuest('stay_live_101');

      expect(c.lastToastMessage, startsWith('Guest checked in'));
      expect(c.stays.single.lifecycleStatus, StayLifecycleStatus.activeStay);
    });
  });

  group('Staff roster is not required for the first load', () {
    for (final status in [403, 503]) {
      test('test_initialize_staff${status}_loadsSyncWithEmptyRosterAndNotice',
          () async {
        final c =
            AdminDashboardController(repository: _repo(staffStatus: status));

        await c.initialize();

        expect(c.stays.single.stayId, 'stay_live_101');
        expect(c.staffDirectory, isEmpty);
        expect(c.lastToastMessage, 'Staff list unavailable.');
      });
    }

    testWidgets('test_app_staff403_showsShellNotNoAccess', (tester) async {
      await tester
          .pumpWidget(KachavaAdminApp(repository: _repo(staffStatus: 403)));
      await tester.pumpAndSettle();

      expect(find.byType(AdminCommandShell), findsOneWidget);
      expect(find.byKey(const Key('admin-no-access-screen')), findsNothing);
      expect(find.text('Staff list unavailable.'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });
  });
}
