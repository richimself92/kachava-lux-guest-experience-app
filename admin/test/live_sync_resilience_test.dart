import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kachava_admin_dashboard/application/admin_dashboard_controller.dart';
import 'package:kachava_admin_dashboard/application/admin_live_sync.dart';
import 'package:kachava_admin_dashboard/core/alert_chime_port.dart';
import 'package:kachava_admin_dashboard/data/admin_api_client.dart';
import 'package:kachava_admin_dashboard/data/admin_wire_mapper.dart';
import 'package:kachava_admin_dashboard/data/api_admin_operations_repository.dart';
import 'support/seeded_admin_repository.dart';
import 'package:kachava_admin_dashboard/domain/admin_sync_snapshot.dart';
import 'package:kachava_admin_dashboard/main.dart';
import 'package:kachava_admin_dashboard/presentation/admin_command_shell.dart';

import 'support/admin_sync_envelope.dart';
import 'support/signed_in_api_client.dart';

const _reconnecting = Key('sync-reconnecting-indicator');
const _noAccess = Key('sync-no-access-indicator');

class _RecordingChime implements AlertChimePort {
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

/// Offline fake whose next snapshot is released by the test.
class _GatedSnapshotRepository extends SeededAdminRepository {
  Completer<AdminSyncSnapshot>? gate;

  @override
  Future<AdminSyncSnapshot> fetchSnapshot() {
    final pending = gate;
    return pending == null ? super.fetchSnapshot() : pending.future;
  }
}

Map<String, dynamic> _malformedEnvelope() => adminSyncEnvelope(stays: [
      {...liveStayWire(), 'nights': 'three'}
    ]);

void main() {
  group('AdminLiveSync status', () {
    test('test_liveSync_refreshThrowsTypeError_setsReconnectingWithoutThrowing',
        () async {
      final sync = AdminLiveSync(
          initialLoad: () async {}, refresh: () async => throw TypeError());
      await sync.tick();

      await sync.tick();

      expect(sync.status.value, AdminSyncStatus.reconnecting);
      sync.dispose();
    });

    test('test_liveSync_forbidden_setsNoAccessAndStopsPolling', () async {
      var calls = 0;
      final sync = AdminLiveSync(
          initialLoad: () async {
            calls++;
            throw const AdminForbiddenException('Admin API HTTP 403');
          },
          refresh: () async {});
      sync.startPolling();

      await sync.tick();

      expect(sync.status.value, AdminSyncStatus.noAccess);
      expect(sync.isPolling, isFalse);
      expect(calls, 1);
      sync.dispose();
    });
  });

  group('ApiAdminOperationsRepository malformed payload', () {
    test('test_fetchSnapshot_malformedPayload_throwsFormatException', () {
      final repo = ApiAdminOperationsRepository(
          apiClient: signedInApiClient(
              MockClient((_) async => jsonResponse(_malformedEnvelope()))));

      expect(repo.fetchSnapshot(), throwsA(isA<FormatException>()));
    });
  });

  group('App sync health line', () {
    late int syncStatus;
    late Object syncBody;

    KachavaAdminApp buildApp() => KachavaAdminApp(
        repository: ApiAdminOperationsRepository(
            apiClient: signedInApiClient(MockClient((request) async {
          if (!isSyncRequest(request)) return jsonResponse({'data': []});
          return syncStatus == 200
              ? jsonResponse(syncBody)
              : http.Response('{"message":"Forbidden"}', syncStatus);
        }))),
        enableLivePolling: true);

    setUp(() {
      syncStatus = 200;
      syncBody = adminSyncEnvelope(stays: [liveStayWire()]);
    });

    testWidgets('test_app_malformedSyncPayload_showsReconnecting',
        (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      syncBody = _malformedEnvelope();
      await tester.pump(const Duration(seconds: 5));
      await tester.pump();

      expect(find.byKey(_reconnecting), findsOneWidget);
      expect(find.text('Reconnecting…'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('test_app_sync403_showsNoAccessLineInsideShell',
        (tester) async {
      syncStatus = 403;
      await tester.pumpWidget(buildApp());
      await tester.pump();
      await tester.pump(const Duration(seconds: 15));

      expect(find.byKey(_noAccess), findsOneWidget);
      expect(find.text('No access'), findsOneWidget);
      expect(find.byType(AdminCommandShell), findsOneWidget);
      expect(find.byKey(_reconnecting), findsNothing);
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('AdminDashboardController sync safety', () {
    test('test_refresh_completingAfterDispose_neverNotifiesNorChimes',
        () async {
      final repo = _GatedSnapshotRepository();
      final chime = _RecordingChime();
      final controller =
          AdminDashboardController(repository: repo, alertChime: chime);
      await controller.initialize();
      final next = await SeededAdminRepository().fetchSnapshot();
      repo.gate = Completer<AdminSyncSnapshot>();
      final inFlight = controller.refreshFromBackend(silent: true);

      controller.dispose();
      repo.gate!.complete(AdminSyncSnapshot(
          stays: next.stays,
          alerts: AdminWireMapper.parseAlerts([
            {
              'alertId': 'alt_new',
              'title': 'New request',
              'isAcknowledged': false
            }
          ]),
          bookings: next.bookings,
          larderOrders: next.larderOrders,
          conciergeTickets: next.conciergeTickets,
          midStayPulses: next.midStayPulses,
          experienceCatalog: next.experienceCatalog,
          larderCatalog: next.larderCatalog,
          folioItems: next.folioItems));

      await expectLater(inFlight, completes);
      expect(chime.triggers, 0);
    });

    test('test_silentRefresh_identicalSnapshot_skipsNotifyListeners', () async {
      final controller = AdminDashboardController(
          repository: ApiAdminOperationsRepository(
              apiClient: signedInApiClient(MockClient((request) async =>
                  isSyncRequest(request)
                      ? jsonResponse(adminSyncEnvelope(stays: [liveStayWire()]))
                      : jsonResponse({'data': []})))),
          alertChime: _RecordingChime());
      await controller.initialize();
      var notifications = 0;
      controller.addListener(() => notifications++);

      await controller.refreshFromBackend(silent: true);
      await controller.refreshFromBackend(silent: true);

      expect(notifications, 0);
      controller.dispose();
    });
  });
}
