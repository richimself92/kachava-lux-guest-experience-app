import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:kachava_admin_dashboard/data/admin_api_client.dart';
import 'package:kachava_admin_dashboard/data/api_admin_operations_repository.dart';
import 'package:kachava_admin_dashboard/domain/admin_enums.dart';
import 'package:kachava_admin_dashboard/main.dart';
import 'package:kachava_admin_dashboard/presentation/admin_command_shell.dart';

import 'support/admin_sync_envelope.dart';

const _signInScreen = Key('staff-sign-in-screen');
const _emailField = Key('staff-sign-in-email');
const _submit = Key('staff-sign-in-submit');
const _error = Key('staff-sign-in-error');

void main() {
  late List<String> requests;
  late int loginStatus;
  late int syncStatus;

  Widget buildApp() {
    final client = AdminApiClient(httpClient: MockClient((request) async {
      final auth = request.headers['Authorization'] ?? 'no-auth';
      requests.add('${request.method} ${request.url.path} $auth');
      if (request.url.path.endsWith('/auth/login')) {
        return loginStatus == 201
            ? jsonResponse({
                'success': true,
                'data': {'token': 'staff-token-1'}
              }, 201)
            : jsonResponse({'message': 'Invalid staff credentials'}, 401);
      }
      if (syncStatus == 401) {
        return jsonResponse({'message': 'Unauthorized'}, 401);
      }
      return jsonResponse(adminSyncEnvelope(stays: [liveStayWire()]));
    }));
    return KachavaAdminApp(
        repository: ApiAdminOperationsRepository(apiClient: client),
        authClient: client,
        enableLivePolling: true);
  }

  Future<void> signIn(WidgetTester tester) async {
    await tester.enterText(
        find.byKey(_emailField), 'eduardo.rivera@kachavalux.com');
    await tester.tap(find.byKey(_submit));
    await tester.pumpAndSettle();
  }

  setUp(() {
    requests = [];
    loginStatus = 201;
    syncStatus = 200;
  });

  testWidgets('test_app_signedOut_showsSignInAndSendsNoAdminCalls',
      (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pump(const Duration(seconds: 12));

    expect(find.byKey(_signInScreen), findsOneWidget);
    expect(find.byType(AdminCommandShell), findsNothing);
    expect(requests, isEmpty);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('test_app_signIn_postsLoginThenSyncsWithBearerAndShowsShell',
      (tester) async {
    await tester.pumpWidget(buildApp());

    await signIn(tester);

    expect(requests, [
      'POST /api/v1/admin/auth/login no-auth',
      'GET /api/v1/admin/sync Bearer staff-token-1',
      'GET /api/v1/admin/staff Bearer staff-token-1',
    ]);
    expect(find.byType(AdminCommandShell), findsOneWidget);
    expect(find.byKey(_signInScreen), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('test_app_signInRejected_showsErrorAndStaysOnSignIn',
      (tester) async {
    loginStatus = 401;
    await tester.pumpWidget(buildApp());

    await signIn(tester);

    expect(find.byKey(_error), findsOneWidget);
    expect(find.byKey(_signInScreen), findsOneWidget);
    expect(find.byType(AdminCommandShell), findsNothing);
    expect(requests, ['POST /api/v1/admin/auth/login no-auth']);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
      'test_app_sync401_returnsToSignInStopsPollingAndRestoresTabOnReauth',
      (tester) async {
    await tester.pumpWidget(buildApp());
    await signIn(tester);
    final controller = tester
        .widget<AdminCommandShell>(find.byType(AdminCommandShell))
        .controller;
    controller.selectTab(AdminWorkspaceTab.adminStays);

    syncStatus = 401;
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    expect(find.byKey(_signInScreen), findsOneWidget);
    expect(find.byType(AdminCommandShell), findsNothing);
    final callsWhileSignedOut = requests.length;
    await tester.pump(const Duration(seconds: 15));
    expect(requests, hasLength(callsWhileSignedOut));

    syncStatus = 200;
    await signIn(tester);
    expect(find.byType(AdminCommandShell), findsOneWidget);
    expect(controller.activeTab, AdminWorkspaceTab.adminStays);
    expect(requests.sublist(requests.length - 2), [
      'GET /api/v1/admin/sync Bearer staff-token-1',
      'GET /api/v1/admin/staff Bearer staff-token-1',
    ]);
    await tester.pumpWidget(const SizedBox());
  });
}
