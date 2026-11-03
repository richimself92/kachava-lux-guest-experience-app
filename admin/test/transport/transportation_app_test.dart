import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kachava_admin_dashboard/domain/admin_enums.dart';
import 'package:kachava_admin_dashboard/main.dart';
import 'package:kachava_admin_dashboard/presentation/admin_command_shell.dart';
import 'package:kachava_admin_dashboard/presentation/navigation/admin_nav_model.dart';
import 'package:kachava_admin_dashboard/presentation/services/service_catalog_scope.dart';
import 'package:kachava_admin_dashboard/presentation/workspaces/transportation/trip_scope.dart';

import '../support/fake_resort_repositories.dart';
import '../support/fake_service_catalog.dart';
import '../support/seeded_admin_repository.dart';
import 'fake_transport_repositories.dart';

Future<void> _pumpApp(WidgetTester tester, {bool withTrips = true}) async {
  tester.view.physicalSize = const Size(1440, 960);
  tester.view.devicePixelRatio = 1;
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform, (MethodCall methodCall) async => null);
  addTearDown(() {
    tester.view.reset();
    tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });
  final app = KachavaAdminApp(
      resort: fakeResortRepositories(),
      timeZones: testTimeZones,
      repository: SeededAdminRepository());
  await tester.pumpWidget(ServiceCatalogScope(
    deps: fakeCatalogDeps(FakeServiceCatalogRepository()),
    child: withTrips
        ? TripScope(
            deps: TripDeps(trips: FakeTripRepository(), stays: FakeStayList()),
            child: app)
        : app,
  ));
  await tester.pumpAndSettle();
}

void main() {
  test('Transportation is a visible HOSPITALITY item', () {
    final item = AdminNavModel.visibleSections()
        .firstWhere((s) => s.id == 'hospitality')
        .items
        .firstWhere((i) => i.id == 'transportation');
    expect(item.workspace, AdminWorkspaceTab.adminTransportation);
    expect(item.label(true), 'Transporte');
    expect(
        AdminNavModel.itemForWorkspace(AdminWorkspaceTab.adminTransportation),
        item);
  });

  testWidgets('menu opens Trips; Services link opens the filtered catalog',
      (tester) async {
    await _pumpApp(tester);
    await tester.tap(find.byKey(const Key('nav-tab-admin-transportation')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('workspace-admin-transportation')),
        findsOneWidget);
    expect(find.byKey(const Key('list-trips')), findsOneWidget);

    await tester.tap(find.byKey(const Key('transport-tab-services')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open Services'));
    await tester.pumpAndSettle();
    final shell =
        tester.widget<AdminCommandShell>(find.byType(AdminCommandShell));
    expect(shell.controller.activeTab, AdminWorkspaceTab.adminServices);
    expect(shell.controller.listQueries.read('services').filters,
        {'section': 'TRANSPORTATION'});
    expect(find.byKey(const Key('workspace-admin-services')), findsOneWidget);
  });

  testWidgets('without trip ports: one error line, no crash', (tester) async {
    await _pumpApp(tester, withTrips: false);
    await tester.tap(find.byKey(const Key('nav-tab-admin-transportation')));
    await tester.pumpAndSettle();
    expect(find.text("Couldn't load"), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
