import 'dart:async';
import 'dart:convert';
import 'support/fake_resort_repositories.dart';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kachava_admin_dashboard/core/app_config.dart';
import 'package:kachava_admin_dashboard/data/admin_api_client.dart';
import 'package:kachava_admin_dashboard/data/admin_session.dart';
import 'package:kachava_admin_dashboard/domain/admin_access_denied.dart';
import 'package:kachava_admin_dashboard/data/http_operations_repositories.dart';
import 'package:kachava_admin_dashboard/main.dart';
import 'package:kachava_admin_dashboard/presentation/admin_command_shell.dart';
import 'package:kachava_admin_dashboard/presentation/operations/operations_scope.dart';

import 'support/fake_operations.dart';

const _login = 'POST /api/v1/admin/auth/login';
const _sync = 'GET /api/v1/admin/notifications/unread-count';

/// Fake backend: login issues `tok-<n>` (n = login count); [syncReply] decides
/// how every other call answers given the bearer it carried.
class _FakeBackend {
  _FakeBackend({this.loginGate, this.loginStatus = 201});

  final Completer<void>? loginGate;
  final int loginStatus;
  final requests = <String>[];
  final loginEmails = <String>[];
  http.Response Function(String? auth) syncReply = (_) => jsonResponse({
        'success': true,
        'data': {'unreadCount': 0, 'urgentUnreadCount': 0}
      });

  int get logins => requests.where((r) => r.startsWith(_login)).length;

  late final MockClient client = MockClient((request) async {
    final auth = request.headers['Authorization'];
    requests.add('${request.method} ${request.url.path} ${auth ?? 'no-auth'}');
    if (request.url.path.endsWith('/auth/login')) {
      loginEmails.add((jsonDecode(request.body) as Map)['email'] as String);
      await loginGate?.future;
      if (loginStatus != 201) {
        return jsonResponse({'message': 'Rejected'}, loginStatus);
      }
      return jsonResponse({
        'success': true,
        'data': {
          'token': 'tok-${loginEmails.length}',
          'staff': {'staffId': 'stf_1', 'fullName': 'Ana Host', 'role': 'Host'},
        }
      }, 201);
    }
    return syncReply(auth);
  });
}

void main() {
  group('AdminApiClient silent staff authentication', () {
    test('test_firstRequest_logsInOnceWithConfiguredEmail_thenSendsBearer',
        () async {
      final backend = _FakeBackend();
      final client = AdminApiClient(httpClient: backend.client);

      await client.getJson('/notifications/unread-count');
      await client.getJson('/notifications/unread-count');

      expect(backend.requests,
          ['$_login no-auth', '$_sync Bearer tok-1', '$_sync Bearer tok-1']);
      expect(backend.loginEmails, [AdminAppConfig.adminStaffEmail]);
      expect(AdminAppConfig.adminStaffEmail, 'eduardo.rivera@kachavalux.com');
      expect(client.session.staff?.staffId, 'stf_1');
    });

    test('test_concurrentFirstRequests_shareSingleLogin', () async {
      final gate = Completer<void>();
      final backend = _FakeBackend(loginGate: gate);
      final client = AdminApiClient(httpClient: backend.client);

      final both = Future.wait([
        client.getJson('/notifications/unread-count'),
        client.getJson('/x')
      ]);
      await Future<void>.delayed(Duration.zero);
      gate.complete();
      await both;

      expect(backend.logins, 1);
      expect(backend.requests.where((r) => r.endsWith('Bearer tok-1')),
          hasLength(2));
    });

    test('test_401_relogsInAndRetriesOnce_succeeds', () async {
      final backend = _FakeBackend()
        ..syncReply = (auth) => auth == 'Bearer tok-1'
            ? jsonResponse({'message': 'Unauthorized'}, 401)
            : jsonResponse({'data': {}});
      final client = AdminApiClient(httpClient: backend.client);

      await client.getJson('/notifications/unread-count');

      expect(backend.requests, [
        '$_login no-auth',
        '$_sync Bearer tok-1',
        '$_login no-auth',
        '$_sync Bearer tok-2',
      ]);
      expect(client.session.token, 'tok-2');
    });

    test('test_persistent401_throwsUnauthorizedAfterExactlyOneRetry', () async {
      final backend = _FakeBackend()
        ..syncReply = (_) => jsonResponse({'message': 'Unauthorized'}, 401);
      final client = AdminApiClient(httpClient: backend.client);

      await expectLater(client.getJson('/notifications/unread-count'),
          throwsA(isA<AdminUnauthorizedException>()));

      expect(backend.logins, 2);
      expect(backend.requests.where((r) => r.startsWith(_sync)), hasLength(2));
    });

    test('test_loginRejected_throwsUnauthorizedWithoutCallingEndpoint',
        () async {
      final requests = <String>[];
      final client = AdminApiClient(httpClient: MockClient((request) async {
        requests.add(request.url.path);
        return jsonResponse({'message': 'Invalid staff credentials'}, 401);
      }));

      await expectLater(client.getJson('/notifications/unread-count'),
          throwsA(isA<AdminUnauthorizedException>()));

      expect(requests, ['/api/v1/admin/auth/login']);
      expect(client.session.isAuthenticated, isFalse);
    });

    test('test_loginRejected_isTerminalAccessDenied', () async {
      for (final status in [401, 403]) {
        final backend = _FakeBackend(loginStatus: status);
        final client = AdminApiClient(httpClient: backend.client);
        await expectLater(client.getJson('/notifications/unread-count'),
            throwsA(isA<AdminAccessDenied>()),
            reason: '$status');
      }
    });

    test('test_retry401_keepsSessionReplacedByConcurrentLogin', () async {
      late AdminApiClient client;
      client = AdminApiClient(
          session: AdminSession(token: 'stale'),
          httpClient: MockClient((request) async {
            if (request.url.path.endsWith('/auth/login')) {
              return jsonResponse({
                'data': {'token': 'tok-1'}
              }, 201);
            }
            if (request.headers['Authorization'] == 'Bearer tok-1') {
              // A concurrent caller re-logged in while this retry was in flight.
              client.session.open('tok-fresh');
            }
            return jsonResponse({'message': 'Unauthorized'}, 401);
          }));

      await expectLater(
          client.getJson('/x'), throwsA(isA<AdminUnauthorizedException>()));

      expect(client.session.token, 'tok-fresh');
    });
  });

  group('App without any sign-in', () {
    Widget buildApp(_FakeBackend backend) => KachavaAdminApp(
        resort: fakeResortRepositories(),
        timeZones: testTimeZones,
        operations: _operations(AdminApiClient(httpClient: backend.client)),
        enableLivePolling: true);

    testWidgets('test_app_showsShellDirectly_withSilentLogin', (tester) async {
      final backend = _FakeBackend();
      await tester.pumpWidget(buildApp(backend));
      await tester.pumpAndSettle();

      expect(find.byType(AdminCommandShell), findsOneWidget);
      expect(find.text('Staff Sign-In'), findsNothing);
      expect(find.text('Staff email'), findsNothing);
      expect(find.byKey(const Key('staff-sign-in-email')), findsNothing);
      expect(
          backend.requests.take(2), ['$_login no-auth', '$_sync Bearer tok-1']);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('test_app_sync403_staysInShellWithNoAccessLine',
        (tester) async {
      final backend = _FakeBackend()
        ..syncReply = (_) => jsonResponse({'message': 'Forbidden'}, 403);
      await tester.pumpWidget(buildApp(backend));
      await tester.pumpAndSettle();

      expect(find.byType(AdminCommandShell), findsOneWidget);
      expect(find.byKey(const Key('sync-no-access-indicator')), findsOneWidget);
      expect(find.text('No access'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('test_app_login401_showsNoAccess_andStopsPolling',
        (tester) async {
      final backend = _FakeBackend(loginStatus: 401);
      await tester.pumpWidget(buildApp(backend));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('sync-no-access-indicator')), findsOneWidget);
      expect(find.text('No access'), findsOneWidget);
      expect(
          find.byKey(const Key('sync-reconnecting-indicator')), findsNothing);
      final logins = backend.logins;
      await tester.pump(const Duration(seconds: 16));
      await tester.pumpAndSettle();
      expect(backend.logins, logins, reason: 'polling must stop');
      await tester.pumpWidget(const SizedBox());
    });
  });
}

OperationsDeps _operations(AdminApiClient api) {
  final ops = FakeOperations();
  return OperationsDeps(
    dashboard: ops.dashboard,
    reservations: ops.reservations,
    guests: ops.guests,
    tasks: ops.tasks,
    notifications: HttpNotificationRepository(api),
    conversations: ops.conversations,
  );
}
