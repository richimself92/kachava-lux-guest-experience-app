import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kachava_admin_dashboard/data/api_admin_operations_repository.dart';
import 'package:kachava_admin_dashboard/data/http_catalog_repositories.dart';
import 'package:kachava_admin_dashboard/domain/admin_catalog_repositories.dart';
import 'package:kachava_admin_dashboard/domain/admin_settings.dart';
import 'package:kachava_admin_dashboard/main.dart';

import '../support/fake_resort_repositories.dart';
import '../support/recorded_contract.dart';
import '../support/signed_in_api_client.dart';

/// The real backend with an EMPTY database, answered from recorded shapes:
/// any other path is a 404, like the removed `/admin/catalog/*`.
class _EmptyBackend {
  final List<String> requests = [];
  final List<String> notFound = [];

  late final MockClient client = MockClient((request) async {
    final path = request.url.path.replaceFirst('/api/v1/admin', '');
    requests.add('${request.method} $path');
    final body = switch ((request.method, path)) {
      ('GET', '/sync') => {
          'success': true,
          'data': {
            'stays': [],
            'alerts': {'alerts': [], 'unreadCount': 0},
            'bookings': [],
            'larderOrders': [],
            'conciergeRequests': [],
            'midstayFeedback': [],
          },
        },
      ('GET', '/staff' || '/villas') => recordedPage(const []),
      ('GET', '/settings') => recordedEmptySettings,
      _ => null,
    };
    if (body == null) {
      notFound.add('${request.method} $path');
      return http.Response('{"statusCode":404}', 404);
    }
    return http.Response(jsonEncode(body), 200,
        headers: {'content-type': 'application/json'});
  });
}

Future<_EmptyBackend> _pumpApp(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final backend = _EmptyBackend();
  final api = signedInApiClient(backend.client);
  await tester.pumpWidget(KachavaAdminApp(
    repository: ApiAdminOperationsRepository(apiClient: api),
    resort: AdminResortRepositories(
        settings: HttpSettingsRepository(api),
        villas: HttpVillaRepository(api)),
    timeZones: testTimeZones,
  ));
  await tester.pumpAndSettle();
  return backend;
}

void main() {
  for (final size in const [Size(1440, 900), Size(375, 812)]) {
    testWidgets(
        'empty backend at ${size.width.toInt()}px: loads with no errors '
        'and never calls a removed endpoint', (tester) async {
      final backend = await _pumpApp(tester, size);
      expect(find.byKey(const Key('workspace-admin-overview')), findsOneWidget);
      expect(
          find.byKey(const Key('sync-reconnecting-indicator')), findsNothing);
      expect(find.byKey(const Key('sync-no-access-indicator')), findsNothing);
      expect(find.byKey(const Key('admin-toast-banner')), findsNothing);
      // Dashboard shows zeros and the one-line Settings link.
      expect(find.text('0'), findsWidgets);
      expect(find.text('Time zone not set'), findsOneWidget);
      expect(tester.takeException(), isNull);

      expect(backend.requests,
          containsAll(['GET /sync', 'GET /staff', 'GET /settings']));
      for (final r in backend.requests) {
        expect(r, isNot(contains('/catalog/')), reason: r);
        expect(r, isNot(endsWith('/reset')), reason: r);
      }
      expect(backend.notFound, isEmpty);
    });
  }

  testWidgets(
      '"Set up in Settings" opens Settings; Villas shows its empty line',
      (tester) async {
    final backend = await _pumpApp(tester, const Size(1440, 900));
    await tester.tap(find.byKey(const Key('setup-in-settings')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('settings-form')), findsOneWidget);
    expect(find.text('No airports'), findsOneWidget);

    await tester.tap(find.byKey(const Key('nav-tab-admin-villas')));
    await tester.pumpAndSettle();
    expect(find.text('No villas yet'), findsOneWidget);
    expect(
        backend.requests.where((r) => r.startsWith('GET /villas')), isNotEmpty);
    expect(backend.notFound, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the link disappears once the time zone is configured',
      (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final settings =
        FakeSettingsRepository(const AdminSettings(timeZone: 'America/Cancun'));
    await tester.pumpWidget(KachavaAdminApp(
      repository: ApiAdminOperationsRepository(
          apiClient: signedInApiClient(_EmptyBackend().client)),
      resort: fakeResortRepositories(settings: settings),
      timeZones: testTimeZones,
    ));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('setup-in-settings')), findsNothing);
  });
}
