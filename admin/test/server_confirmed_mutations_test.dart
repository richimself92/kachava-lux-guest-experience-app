import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kachava_admin_dashboard/application/admin_dashboard_controller.dart';
import 'package:kachava_admin_dashboard/data/admin_api_client.dart';
import 'package:kachava_admin_dashboard/data/admin_server_confirmation.dart';
import 'package:kachava_admin_dashboard/data/api_admin_operations_repository.dart';
import 'package:kachava_admin_dashboard/main.dart';
import 'support/fake_resort_repositories.dart';

import 'support/admin_sync_envelope.dart';
import 'support/signed_in_api_client.dart';

const _liveToken = '11111111-2222-3333-4444-555555555555';

/// Fake backend: `/sync` serves one live stay (plus [pastStays]); every POST
/// answers [postReply].
ApiAdminOperationsRepository _repoWith(http.Response Function() postReply,
        {List<Map<String, dynamic>> pastStays = const []}) =>
    ApiAdminOperationsRepository(
        apiClient: signedInApiClient(MockClient((request) async {
      if (isSyncRequest(request)) {
        return jsonResponse(
            adminSyncEnvelope(stays: [liveStayWire(), ...pastStays]));
      }
      if (request.method == 'POST') return postReply();
      return jsonResponse({'success': true, 'data': []});
    })));

Future<AdminDashboardController> _initializedController(
    http.Response Function() postReply) async {
  final controller = AdminDashboardController(repository: _repoWith(postReply));
  await controller.initialize();
  return controller;
}

Future<void> _createVilla106Stay(AdminDashboardController c) => c.createNewStay(
    villaName: 'Villa 106 — Copal Pavilion',
    guestNames: 'Marcus Sterling',
    checkInDate: 'Nov 20, 2026',
    checkOutDate: 'Nov 25, 2026',
    occasion: 'Anniversary');

void main() {
  group('Create stay is server-confirmed', () {
    test('test_repository_create_stay_server_error_propagates', () async {
      final repo = _repoWith(() => http.Response('unavailable', 503));
      await expectLater(
          repo.createStay(
              villaName: 'Villa 106',
              guestNames: 'Marcus',
              checkInDate: 'Nov 20, 2026',
              checkOutDate: 'Nov 25, 2026',
              occasion: ''),
          throwsA(isA<AdminApiException>()));
      expect(
          await repo.fetchStays().catchError((_) => const <Never>[]), isEmpty);
    });

    test('test_repository_create_stay_without_server_token_is_unconfirmed',
        () async {
      final repo = _repoWith(() => jsonResponse({
            'success': true,
            'data': {
              'stay': {'stayId': 'stay_106'}
            }
          }, 201));
      await expectLater(
          repo.createStay(
              villaName: 'Villa 106',
              guestNames: 'Marcus',
              checkInDate: 'Nov 20, 2026',
              checkOutDate: 'Nov 25, 2026',
              occasion: ''),
          throwsA(isA<AdminUnconfirmedMutationException>()));
    });

    test('test_controller_create_stay_failure_shows_error_and_no_link',
        () async {
      final c = await _initializedController(() => http.Response('x', 503));

      await _createVilla106Stay(c);

      expect(c.stays.map((s) => s.stayId), ['stay_live_101']);
      expect(c.lastToastMessage, contains('Stay not created'));
      expect(c.lastToastMessage, isNot(contains('guestId=')));
      expect(c.lastToastMessage, isNot(contains('\n')));
      c.dispose();
    });

    test('test_controller_create_stay_success_uses_server_stay_and_token',
        () async {
      final c = await _initializedController(() => jsonResponse({
            'success': true,
            'data': {
              'stay': liveStayWire(
                  stayId: 'stay_server_106',
                  guestTokenUuid: 'server-token-106',
                  villaName: 'Villa 106',
                  guestName: 'Marcus Sterling'),
            }
          }, 201));

      await _createVilla106Stay(c);

      expect(c.stays.first.stayId, 'stay_server_106');
      expect(c.lastToastMessage,
          contains('http://localhost:3000/?guestId=server-token-106'));
      c.dispose();
    });
  });

  group('Rotate token is server-confirmed', () {
    test('test_controller_rotate_token_failure_keeps_old_token', () async {
      final c = await _initializedController(() => http.Response('x', 500));

      await c.regenerateMagicLink('stay_live_101');

      expect(c.stays.single.guestTokenUuid, _liveToken);
      expect(c.lastToastMessage, contains('Link not rotated'));
      expect(c.lastToastMessage, isNot(contains('New Magic Link')));
      c.dispose();
    });

    test('test_controller_rotate_token_without_server_token_keeps_old_token',
        () async {
      final c = await _initializedController(
          () => jsonResponse({'success': true, 'data': {}}));

      await c.regenerateMagicLink('stay_live_101');

      expect(c.stays.single.guestTokenUuid, _liveToken);
      expect(c.lastToastMessage, contains('Link not rotated'));
      c.dispose();
    });
  });

  testWidgets('test_create_stay_dialog_failure_shows_one_line_error_no_link',
      (tester) async {
    tester.view.physicalSize = const Size(1440, 960);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    // Villas are derived from server stays: a checked-out stay frees Villa 106.
    await tester.pumpWidget(KachavaAdminApp(
        resort: fakeResortRepositories(),
        timeZones: testTimeZones,
        repository:
            _repoWith(() => http.Response('unavailable', 503), pastStays: [
          {
            ...liveStayWire(stayId: 'stay_past_106', villaName: 'Villa 106'),
            'villaId': 'villa-106',
            'status': 'CHECKED_OUT',
          }
        ])));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('nav-tab-admin-stays')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('create-new-stay-btn')));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const Key('new-stay-guest-input')), 'Marcus Sterling');
    await tester.enterText(
        find.byKey(const Key('new-stay-checkin-input')), 'Dec 1, 2026');
    await tester.enterText(
        find.byKey(const Key('new-stay-checkout-input')), 'Dec 4, 2026');
    await tester.pump();
    await tester.tap(find.byKey(const Key('confirm-create-stay-btn')));
    await tester.pumpAndSettle();

    expect(find.textContaining('Stay not created'), findsOneWidget);
    expect(find.textContaining('Marcus Sterling'), findsNothing);
    expect(find.textContaining('guestId=server'), findsNothing);
  });
}
