import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:kachava_admin_dashboard/application/admin_dashboard_controller.dart';
import 'package:kachava_admin_dashboard/application/admin_live_sync.dart';
import 'package:kachava_admin_dashboard/data/admin_api_client.dart';
import 'package:kachava_admin_dashboard/data/admin_cached_records.dart';
import 'package:kachava_admin_dashboard/data/admin_staff_mapper.dart';
import 'package:kachava_admin_dashboard/data/api_admin_operations_repository.dart';
import 'package:kachava_admin_dashboard/domain/admin_enums.dart';
import 'package:kachava_admin_dashboard/main.dart';
import 'package:kachava_admin_dashboard/presentation/admin_command_shell.dart';

import 'support/admin_sync_envelope.dart';
import 'support/signed_in_api_client.dart';

const _noAccessScreen = Key('admin-no-access-screen');
const _signInScreen = Key('staff-sign-in-screen');
const _guestName = 'Sofia & Lucas Vega';
const _token = '11111111-2222-3333-4444-555555555555';

Map<String, dynamic> _staffWire(String id) =>
    {'staffId': id, 'fullName': 'Staff $id', 'role': 'Host'};

void main() {
  group('Cross-session isolation in the app', () {
    late int syncStatus;
    late AdminApiClient client;

    KachavaAdminApp buildApp() {
      client = AdminApiClient(httpClient: MockClient((request) async {
        if (request.url.path.endsWith('/auth/login')) {
          final email = (jsonDecode(request.body) as Map)['email'] as String;
          return jsonResponse({
            'data': {
              'token': 'tok-$email',
              'staff': _staffWire(email.split('@').first)
            }
          }, 201);
        }
        if (syncStatus != 200) return jsonResponse({'m': 'x'}, syncStatus);
        return isSyncRequest(request)
            ? jsonResponse(adminSyncEnvelope(stays: [liveStayWire()]))
            : jsonResponse({'data': []});
      }));
      return KachavaAdminApp(
          repository: ApiAdminOperationsRepository(apiClient: client),
          authClient: client,
          enableLivePolling: true);
    }

    Future<void> signIn(WidgetTester tester, String email) async {
      await tester.enterText(
          find.byKey(const Key('staff-sign-in-email')), email);
      await tester.tap(find.byKey(const Key('staff-sign-in-submit')));
      await tester.pumpAndSettle();
    }

    Future<AdminDashboardController> signInUserA(WidgetTester tester) async {
      syncStatus = 200;
      await tester.pumpWidget(buildApp());
      await signIn(tester, 'a@kachavalux.com');
      final controller = tester
          .widget<AdminCommandShell>(find.byType(AdminCommandShell))
          .controller;
      controller.selectTab(AdminWorkspaceTab.adminStays);
      controller.showToast('Stay created ($_guestName): $_token');
      await tester.pumpAndSettle();
      expect(find.textContaining(_guestName), findsWidgets);
      return controller;
    }

    void expectNoUserAData(AdminDashboardController controller) {
      expect(find.byKey(_noAccessScreen), findsOneWidget);
      expect(find.byType(AdminCommandShell), findsNothing);
      expect(find.textContaining(_guestName), findsNothing);
      expect(find.textContaining(_token), findsNothing);
      expect(controller.stays, isEmpty);
      expect(controller.folioItems, isEmpty);
      expect(controller.staffDirectory, isEmpty);
      expect(controller.lastToastMessage, isNull);
    }

    testWidgets('test_app_userA401ThenUserBForbidden_rendersNoUserAData',
        (tester) async {
      final controller = await signInUserA(tester);

      syncStatus = 401;
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      expect(find.byKey(_signInScreen), findsOneWidget);
      syncStatus = 403;
      await signIn(tester, 'b@kachavalux.com');

      expectNoUserAData(controller);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('test_app_sessionReopenedAsOtherStaff_clearsPreviousData',
        (tester) async {
      final controller = await signInUserA(tester);

      syncStatus = 403;
      client.session
          .open('tok-b', staff: AdminStaffMapper.tryMap(_staffWire('b')));
      await tester.pumpAndSettle();

      expectNoUserAData(controller);
      await tester.pumpWidget(const SizedBox());
    });
    testWidgets('test_app_noAccessSignOut_returnsToSignIn', (tester) async {
      syncStatus = 403;
      await tester.pumpWidget(buildApp());
      await signIn(tester, 'b@kachavalux.com');
      expect(find.byKey(_noAccessScreen), findsOneWidget);

      await tester.tap(find.byKey(const Key('admin-no-access-sign-out')));
      await tester.pumpAndSettle();

      expect(find.byKey(_signInScreen), findsOneWidget);
      expect(client.session.isAuthenticated, isFalse);
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('AdminLiveSync.reset', () {
    test('test_liveSync_reset_nextTickRunsInitialLoadAndStatusLive', () async {
      var initialLoads = 0;
      final sync = AdminLiveSync(
          initialLoad: () async {
            initialLoads++;
            if (initialLoads == 1) return;
            throw const AdminForbiddenException('403');
          },
          refresh: () async {});
      await sync.tick();
      await sync.tick();
      expect(initialLoads, 1);

      sync.reset();
      expect(sync.status.value, AdminSyncStatus.live);
      await sync.tick();

      expect(initialLoads, 2);
      expect(sync.status.value, AdminSyncStatus.noAccess);
      sync.dispose();
    });

    test('test_liveSync_tickInFlightDuringReset_isDiscarded', () async {
      final gate = Completer<void>();
      var initialLoads = 0;
      final sync = AdminLiveSync(
          initialLoad: () {
            initialLoads++;
            return initialLoads == 1 ? gate.future : Future.value();
          },
          refresh: () async => throw StateError('must not refresh'));
      sync.startPolling();
      final stale = sync.tick();

      sync.reset();
      final fresh = sync.tick();
      gate.completeError(const AdminForbiddenException('403'));
      await Future.wait([stale, fresh]);

      expect(initialLoads, 2);
      expect(sync.status.value, AdminSyncStatus.live);
      expect(sync.isPolling, isTrue);
      sync.dispose();
    });
  });

  group('Repository cache clearing', () {
    test('test_apiRepository_clearCache_dropsRecordsAndSendsNoMutation',
        () async {
      final requests = <String>[];
      final repo = ApiAdminOperationsRepository(
          apiClient: signedInApiClient(MockClient((request) async {
        requests.add('${request.method} ${request.url.path}');
        return jsonResponse(adminSyncEnvelope(stays: [liveStayWire()]));
      })));
      await repo.fetchSnapshot();

      repo.clearCache();

      await expectLater(repo.regenerateGuestUuid('stay_live_101'),
          throwsA(isA<AdminRecordNotLoadedException>()));
      expect(requests, ['GET /api/v1/admin/sync']);
    });
  });
}
