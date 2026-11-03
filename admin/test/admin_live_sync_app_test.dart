import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kachava_admin_dashboard/data/api_admin_operations_repository.dart';
import 'package:kachava_admin_dashboard/main.dart';
import 'package:kachava_admin_dashboard/presentation/admin_command_shell.dart';
import 'support/fake_resort_repositories.dart';

import 'support/admin_sync_envelope.dart';
import 'support/signed_in_api_client.dart';

const _indicator = Key('sync-reconnecting-indicator');

void main() {
  late List<String> requests;
  late bool backendDown;

  KachavaAdminApp buildApp() {
    final client = MockClient((request) async {
      requests.add('${request.method} ${request.url.path}');
      if (backendDown) return http.Response('unavailable', 503);
      return jsonResponse(adminSyncEnvelope(stays: [liveStayWire()]));
    });
    return KachavaAdminApp(
        resort: fakeResortRepositories(),
        timeZones: testTimeZones,
        repository:
            ApiAdminOperationsRepository(apiClient: signedInApiClient(client)),
        enableLivePolling: true);
  }

  setUp(() {
    requests = [];
    backendDown = false;
  });

  testWidgets('test_app_polls_only_admin_sync_every_5_seconds', (tester) async {
    const initialLoad = ['GET /api/v1/admin/sync', 'GET /api/v1/admin/staff'];
    await tester.pumpWidget(buildApp());
    await tester.pump();
    expect(requests, initialLoad);

    await tester.pump(const Duration(seconds: 4));
    expect(requests, hasLength(2));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();

    expect(requests, [...initialLoad, 'GET /api/v1/admin/sync']);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('test_app_failed_sync_keeps_last_data_and_shows_reconnecting',
      (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();
    final controller = tester
        .widget<AdminCommandShell>(find.byType(AdminCommandShell))
        .controller;
    expect(controller.stays.single.stayId, 'stay_live_101');
    expect(find.byKey(_indicator), findsNothing);

    backendDown = true;
    await tester.pump(const Duration(seconds: 5));
    await tester.pump();

    expect(find.byKey(_indicator), findsOneWidget);
    expect(find.text('Reconnecting…'), findsOneWidget);
    expect(controller.stays.single.stayId, 'stay_live_101');

    backendDown = false;
    await tester.pump(const Duration(seconds: 5));
    await tester.pump();
    expect(find.byKey(_indicator), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });
}
