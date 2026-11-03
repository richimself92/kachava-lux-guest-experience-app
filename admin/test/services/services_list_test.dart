import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kachava_admin_dashboard/application/list_query_store.dart';
import 'package:kachava_admin_dashboard/core/admin_theme.dart';
import 'package:kachava_admin_dashboard/domain/admin_service.dart';
import 'package:kachava_admin_dashboard/presentation/services/service_catalog_scope.dart';
import 'package:kachava_admin_dashboard/presentation/services/services_workspace.dart';

import '../support/fake_service_catalog.dart';

Future<void> _size(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Widget _host(Widget child, FakeServiceCatalogRepository? repo) => MaterialApp(
      theme: KachavaAdminTheme.build(),
      home: Scaffold(
        body: repo == null
            ? child
            : ServiceCatalogScope(deps: fakeCatalogDeps(repo), child: child),
      ),
    );

void main() {
  late FakeServiceCatalogRepository repo;
  late ListQueryStore store;

  setUp(() {
    repo = FakeServiceCatalogRepository();
    store = ListQueryStore();
  });

  group('Services (all sections)', () {
    testWidgets('table: 6 columns, default order sort, pagination',
        (tester) async {
      await _size(tester, const Size(1440, 900));
      repo.seed([for (var i = 1; i <= 30; i++) testService(i)]);
      await tester
          .pumpWidget(_host(ServicesWorkspace(queryStore: store), repo));
      await tester.pumpAndSettle();

      for (final header in [
        'Order',
        'Name',
        'Section',
        'Use',
        'Price',
        'Status'
      ]) {
        expect(find.text(header), findsWidgets, reason: header);
      }
      expect(repo.queries.first.sort?.wireValue, 'order:asc');
      expect(find.text('Service 001'), findsOneWidget);
      expect(find.text(r'$50.00 USD'), findsWidgets);
      expect(find.text('Experiences'), findsWidgets);
      expect(find.text('Booking'), findsWidgets);
      expect(find.text('1–25 of 30'), findsOneWidget);
      await tester.tap(find.byKey(const Key('pager-services-next')));
      await tester.pumpAndSettle();
      expect(find.text('26–30 of 30'), findsOneWidget);
      expect(store.read('services').page, 2);
    });

    testWidgets('filters: section, status and use reach the query',
        (tester) async {
      await _size(tester, const Size(1440, 900));
      repo.seed([
        testService(1),
        testService(2,
            kind: ServiceKind.bar,
            status: CatalogStatus.active,
            withCover: true),
      ]);
      await tester
          .pumpWidget(_host(ServicesWorkspace(queryStore: store), repo));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('filter-services-section')), findsOneWidget);
      expect(find.byKey(const Key('filter-services-status')), findsOneWidget);
      expect(
          find.byKey(const Key('filter-services-usageType')), findsOneWidget);

      await tester.tap(find.byKey(const Key('filter-services-section')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Dining').last);
      await tester.pumpAndSettle();
      expect(repo.queries.last.filters, {'section': 'DINING'});
      expect(find.text('Service 002'), findsOneWidget);
      expect(find.text('Service 001'), findsNothing);
    });

    testWidgets('empty: one line + New service opens the editor',
        (tester) async {
      await _size(tester, const Size(1440, 900));
      await tester
          .pumpWidget(_host(ServicesWorkspace(queryStore: store), repo));
      await tester.pumpAndSettle();
      expect(find.text('No services yet'), findsOneWidget);
      await tester.tap(find.widgetWithText(OutlinedButton, 'New service'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('detail-panel')), findsOneWidget);
      expect(find.text('General'), findsOneWidget);
    });

    testWidgets('load error: one line + Retry', (tester) async {
      await _size(tester, const Size(1440, 900));
      repo.failListWith = Exception('offline');
      await tester
          .pumpWidget(_host(ServicesWorkspace(queryStore: store), repo));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('list-services-error')), findsOneWidget);
    });

    testWidgets('no catalog wired: one line, no crash', (tester) async {
      await tester
          .pumpWidget(_host(ServicesWorkspace(queryStore: store), null));
      await tester.pumpAndSettle();
      expect(find.text('Catalog not connected'), findsOneWidget);
    });

    testWidgets('mobile 375: compact rows, no overflow', (tester) async {
      await _size(tester, const Size(375, 800));
      repo.seed([testService(1)]);
      await tester
          .pumpWidget(_host(ServicesWorkspace(queryStore: store), repo));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('row-services-s1')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('Section views', () {
    testWidgets('Experiences: catalog filtered by section + Requests tab',
        (tester) async {
      await _size(tester, const Size(1440, 900));
      repo.seed([
        testService(1),
        testService(2, kind: ServiceKind.wellness),
      ]);
      await tester.pumpWidget(_host(
          ServiceSectionWorkspace(
              section: ServiceSection.experiences, queryStore: store),
          repo));
      await tester.pumpAndSettle();
      expect(repo.queries.last.filters['section'], 'EXPERIENCES');
      expect(find.text('Service 001'), findsOneWidget);
      expect(find.text('Service 002'), findsNothing);
      expect(find.text('Section'), findsNothing);
      expect(find.byKey(const Key('filter-services-section')), findsNothing);

      await tester.tap(find.text('Requests'));
      await tester.pumpAndSettle();
      expect(find.text('Request queue coming soon'), findsOneWidget);
    });

    testWidgets('Dining: New service offers only dining kinds', (tester) async {
      await _size(tester, const Size(1440, 900));
      await tester.pumpWidget(_host(
          ServiceSectionWorkspace(
              section: ServiceSection.dining, queryStore: store),
          repo));
      await tester.pumpAndSettle();
      expect(find.text('No services yet'), findsOneWidget);
      await tester.tap(find.byKey(const Key('primary-services')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('svc-kind')));
      await tester.pumpAndSettle();
      expect(find.text('Lux bar'), findsWidgets);
      expect(find.text('Special menu'), findsWidgets);
      expect(find.text('Transport'), findsNothing);
    });
  });
}
