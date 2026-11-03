import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kachava_admin_dashboard/application/list_query_store.dart';
import 'package:kachava_admin_dashboard/application/service_catalog_deps.dart';
import 'package:kachava_admin_dashboard/core/admin_theme.dart';
import 'package:kachava_admin_dashboard/domain/list_query.dart';
import 'package:kachava_admin_dashboard/domain/service_catalog_enums.dart';
import 'package:kachava_admin_dashboard/domain/service_request.dart';
import 'package:kachava_admin_dashboard/presentation/services/service_catalog_scope.dart';
import 'package:kachava_admin_dashboard/presentation/services/services_workspace.dart';

import '../support/fake_service_catalog.dart';
import '../support/fake_service_requests.dart';

Future<void> _size(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  late FakeServiceRequestRepository requests;
  late ListQueryStore store;

  setUp(() {
    requests = FakeServiceRequestRepository();
    store = ListQueryStore();
  });

  Future<void> pumpQueue(WidgetTester tester,
      {Size size = const Size(1440, 900), bool isEs = false}) async {
    await _size(tester, size);
    final catalog = fakeCatalogDeps(FakeServiceCatalogRepository());
    await tester.pumpWidget(MaterialApp(
      theme: KachavaAdminTheme.build(),
      home: Scaffold(
        body: ServiceCatalogScope(
          deps: ServiceCatalogDeps(
            services: catalog.services,
            providers: catalog.providers,
            signer: catalog.signer,
            transport: catalog.transport,
            picker: catalog.picker,
            requests: requests,
          ),
          child: ServiceSectionWorkspace(
            section: ServiceSection.experiences,
            queryStore: store,
            today: '2026-11-03',
            isEs: isEs,
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('section-tab-requests-experiences')));
    await tester.pumpAndSettle();
  }

  Future<void> openRow(WidgetTester tester, String id) async {
    await tester.tap(find.byKey(Key('row-requests-experiences-$id')));
    await tester.pumpAndSettle();
  }

  testWidgets('queue: 5 columns, open requests of the section, date order',
      (tester) async {
    requests.requests.addAll([
      testRequest(2),
      testRequest(1, status: RequestStatusValues.confirmed),
      testRequest(3, status: RequestStatusValues.done),
    ]);
    await pumpQueue(tester);

    for (final header in [
      'Guest · Villa',
      'Service',
      'Date / time',
      'Guests / qty',
      'Status'
    ]) {
      expect(find.text(header), findsWidgets, reason: header);
    }
    final (section, query) = requests.queries.last;
    expect(section, ServiceSection.experiences);
    expect(query.filters['status'], RequestStatusValues.open);
    expect(query.sort?.wireValue, 'at:asc');
    expect(find.text('Guest 1 · Villa 1'), findsOneWidget);
    expect(find.text('Guest 2 · Villa 2'), findsOneWidget);
    expect(find.text('Guest 3 · Villa 3'), findsNothing);
    expect(find.text('Nov 2 · 10:00'), findsOneWidget);
    expect(find.text('Confirmed'), findsWidgets);
    expect(find.byKey(const Key('filter-requests-experiences-range')),
        findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('search by guest or service reaches the query', (tester) async {
    requests.requests.addAll([testRequest(1), testRequest(2)]);
    await pumpQueue(tester);

    await tester.enterText(
        find.byKey(const Key('search-requests-experiences')), 'Service 2');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(requests.queries.last.$2.q, 'Service 2');
    expect(find.text('Guest 2 · Villa 2'), findsOneWidget);
    expect(find.text('Guest 1 · Villa 1'), findsNothing);
  });

  testWidgets('detail: one button per allowed action; Confirm moves it',
      (tester) async {
    requests.requests.add(testRequest(1));
    await pumpQueue(tester);
    await openRow(tester, 'req_1');

    expect(find.byKey(const Key('request-detail')), findsOneWidget);
    expect(find.text('Item 1 × 2'), findsOneWidget);
    for (final a in ['confirm', 'start', 'cancel']) {
      expect(find.byKey(Key('request-action-$a')), findsOneWidget, reason: a);
    }
    expect(find.byKey(const Key('request-action-complete')), findsNothing);

    await tester.tap(find.byKey(const Key('request-action-confirm')));
    await tester.pumpAndSettle();

    expect(requests.moves.single, ('req_1', RequestAction.confirm, null));
    expect(find.text('Request updated'), findsOneWidget);
    expect(find.byKey(const Key('request-action-confirm')), findsNothing);
    expect(find.byKey(const Key('request-action-complete')), findsOneWidget);
  });

  testWidgets('cancel needs a reason, then sends it', (tester) async {
    requests.requests
        .add(testRequest(1, status: RequestStatusValues.preparing));
    await pumpQueue(tester);
    await openRow(tester, 'req_1');

    await tester.tap(find.byKey(const Key('request-action-cancel')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('request-cancel-confirm')));
    await tester.pumpAndSettle();
    expect(requests.moves, isEmpty);
    expect(find.text('Required'), findsOneWidget);

    await tester.enterText(
        find.byKey(const Key('request-cancel-reason')), 'Guest left early');
    await tester.tap(find.byKey(const Key('request-cancel-confirm')));
    await tester.pumpAndSettle();

    expect(requests.moves.single,
        ('req_1', RequestAction.cancel, 'Guest left early'));
    expect(find.text('Request cancelled'), findsOneWidget);
    expect(find.text('Guest left early'), findsOneWidget);
    expect(find.byKey(const Key('request-action-start')), findsNothing);
  });

  testWidgets('a refused move keeps the request and says so', (tester) async {
    requests.requests.add(testRequest(1));
    requests.failMovesWith = Exception('422');
    await pumpQueue(tester);
    await openRow(tester, 'req_1');

    await tester.tap(find.byKey(const Key('request-action-start')));
    await tester.pumpAndSettle();

    expect(find.text("Couldn't update request"), findsOneWidget);
    expect(find.byKey(const Key('request-action-start')), findsOneWidget);
  });

  testWidgets('done requests show no actions; Spanish labels', (tester) async {
    requests.requests.add(testRequest(1, status: RequestStatusValues.done));
    store.write('requests-experiences', const ListQuery());
    await pumpQueue(tester, isEs: true);
    await openRow(tester, 'req_1');

    expect(find.text('Lista'), findsWidgets);
    expect(find.text('Servicio 1'), findsWidgets);
    expect(find.byKey(const Key('request-action-cancel')), findsNothing);
  });

  testWidgets('mobile 375: compact rows and full-screen detail fit',
      (tester) async {
    requests.requests.addAll([testRequest(1), testRequest(2)]);
    await pumpQueue(tester, size: const Size(375, 812));

    expect(find.text('Guest 1 · Villa 1'), findsOneWidget);
    await openRow(tester, 'req_1');
    expect(find.byKey(const Key('request-action-confirm')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('without a wired queue the tab shows one error line',
      (tester) async {
    await _size(tester, const Size(1440, 900));
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ServiceCatalogScope(
          deps: fakeCatalogDeps(FakeServiceCatalogRepository()),
          child: const ServiceSectionWorkspace(section: ServiceSection.dining),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('section-tab-requests-dining')));
    await tester.pumpAndSettle();

    expect(
        find.byKey(const Key('requests-dining-not-connected')), findsOneWidget);
  });
}
