import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kachava_admin_dashboard/core/admin_theme.dart';
import 'package:kachava_admin_dashboard/domain/admin_service.dart';
import 'package:kachava_admin_dashboard/domain/catalog_values.dart';
import 'package:kachava_admin_dashboard/domain/service_request.dart';
import 'package:kachava_admin_dashboard/domain/inbox_item.dart';
import 'package:kachava_admin_dashboard/presentation/requests/inbox_parts.dart';
import 'package:kachava_admin_dashboard/presentation/services/request_detail_panel.dart';
import 'package:kachava_admin_dashboard/presentation/services/service_item_editor.dart';
import 'package:kachava_admin_dashboard/presentation/services/service_items_section.dart';

import '../support/fake_service_catalog.dart';
import '../support/fake_service_requests.dart';

const _steak = ServiceItem(
  id: 'i1',
  name: LocalizedText(en: 'New York steak', es: 'Corte New York'),
  category: 'Proteins',
  sku: 'PRE-104',
  priceUSD: 3.3114,
  pricingUnit: PricingUnit.oz,
  portionOzOptions: [6, 8, 10, 12, 14],
  order: 1,
);
const _water = ServiceItem(
  id: 'i2',
  name: LocalizedText(en: 'Water', es: 'Agua'),
  category: 'Drinks',
  sku: 'PRE-001',
  priceUSD: 2,
  order: 2,
);

void main() {
  late FakeServiceCatalogRepository repo;

  setUp(() => repo = FakeServiceCatalogRepository());

  Future<void> pump(WidgetTester tester, Widget child,
      {double width = 640}) async {
    tester.view.physicalSize = const Size(1200, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      theme: KachavaAdminTheme.build(),
      home: Scaffold(body: SizedBox(width: width, child: child)),
    ));
    await tester.pumpAndSettle();
  }

  Future<void> pumpEditor(WidgetTester tester,
          {ServiceItem? item,
          ServiceKind kind = ServiceKind.villaStocking,
          bool isEs = false}) =>
      pump(
          tester,
          ServiceItemEditor(
            deps: fakeCatalogDeps(repo),
            serviceId: 's1',
            kind: kind,
            item: item,
            isEs: isEs,
            onClose: () {},
            onSaved: () {},
          ));

  Future<void> save(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('form-save')).first);
    await tester.pumpAndSettle();
  }

  Future<void> toggleWeight(WidgetTester tester) async {
    await tester.ensureVisible(find.byKey(const Key('svc-pricingUnit')));
    await tester.tap(find.byKey(const Key('svc-pricingUnit')));
    await tester.pumpAndSettle();
  }

  // Field labels render as uppercase labels (plus a required mark).
  Finder anyCase(String t) => find.byWidgetPredicate((w) =>
      w is Text &&
      (w.data ?? w.textSpan?.toPlainText() ?? '')
          .toLowerCase()
          .contains(t.toLowerCase()));

  group('item editor (VILLA_STOCKING)', () {
    testWidgets('writes sku, net cost, link and weight pricing',
        (tester) async {
      await pumpEditor(tester);
      expect(anyCase('Price per oz (USD)'), findsNothing);
      await tester.enterText(find.byKey(const Key('svc-name.en')), 'Steak');
      await tester.enterText(find.byKey(const Key('svc-sku')), 'PRE-104');
      await tester.enterText(
          find.byKey(const Key('svc-netCostMXN')), '30.9577');
      await tester.enterText(
          find.byKey(const Key('svc-sourceUrl')), 'https://shop.test/s');
      await toggleWeight(tester);
      expect(anyCase('Price per oz (USD)'), findsOneWidget);
      expect(find.text('6, 8, 10, 12, 14'), findsOneWidget);
      await tester.enterText(find.byKey(const Key('svc-priceUSD')), '3.3114');
      await tester.enterText(
          find.byKey(const Key('svc-portionOzOptions')), '12, 8, 8');
      await save(tester);
      final body = repo.itemWrites.single;
      expect(body['sku'], 'PRE-104');
      expect(body['netCostMXN'], 30.9577);
      expect(body['sourceUrl'], 'https://shop.test/s');
      expect(body['pricingUnit'], 'OZ');
      expect(body['priceUSD'], 3.3114);
      expect(body['portionOzOptions'], [8, 12]);
    });

    testWidgets('OZ needs a price; bad link, sku and oz are rejected',
        (tester) async {
      await pumpEditor(tester);
      await tester.enterText(find.byKey(const Key('svc-name.en')), 'Steak');
      await toggleWeight(tester);
      await save(tester);
      expect(find.text('Price required'), findsOneWidget);
      await tester.enterText(find.byKey(const Key('svc-sku')), 'A' * 41);
      await tester.enterText(find.byKey(const Key('svc-sourceUrl')), 'shop');
      await tester.enterText(
          find.byKey(const Key('svc-portionOzOptions')), '0, 99');
      await tester.pumpAndSettle();
      expect(find.text('Max 40 characters'), findsOneWidget);
      expect(find.text('Use an http(s) link'), findsOneWidget);
      expect(find.text('Use 1–64, up to 10'), findsOneWidget);
      expect(repo.itemWrites, isEmpty);
    });

    testWidgets('ITEM keeps 2 decimals; switching off clears oz options',
        (tester) async {
      await pumpEditor(tester, item: _steak);
      expect(find.text('3.3114'), findsOneWidget);
      await toggleWeight(tester);
      expect(find.byKey(const Key('svc-portionOzOptions')), findsNothing);
      await tester.enterText(find.byKey(const Key('svc-priceUSD')), '3.311');
      await tester.pumpAndSettle();
      expect(find.text('Invalid amount'), findsOneWidget);
      await tester.enterText(find.byKey(const Key('svc-priceUSD')), '3.31');
      await save(tester);
      expect(repo.itemWrites.single['pricingUnit'], 'ITEM');
      expect(repo.itemWrites.single['portionOzOptions'], <int>[]);
    });

    testWidgets('tooltips explain the admin-only fields; Spanish labels',
        (tester) async {
      await pumpEditor(tester, isEs: true);
      expect(anyCase('Costo neto (MXN)'), findsOneWidget);
      expect(anyCase('Enlace de origen'), findsOneWidget);
      expect(
          find.byTooltip('Solo admin; el huésped no lo ve.'), findsNWidgets(2));
      expect(
          find.byTooltip('El huésped elige porciones × oz; el precio es '
              'por oz.'),
          findsOneWidget);
    });

    testWidgets('other kinds do not show the pre-stocking fields',
        (tester) async {
      await pumpEditor(tester, kind: ServiceKind.bar);
      expect(find.byKey(const Key('svc-sku')), findsNothing);
      expect(find.byKey(const Key('svc-pricingUnit')), findsNothing);
      expect(find.byKey(const Key('svc-priceUSD')), findsOneWidget);
    });
  });

  group('items table', () {
    Future<void> pumpSection(WidgetTester tester, {double width = 640}) => pump(
        tester,
        SingleChildScrollView(
          child: ServiceItemsSection(
            deps: fakeCatalogDeps(repo),
            serviceId: 's1',
            kind: ServiceKind.villaStocking,
            onOpen: (_) {},
          ),
        ),
        width: width);

    testWidgets('375px: the status badge stays on one line', (tester) async {
      repo.items['s1'] = [
        const ServiceItem(
            id: 'i9',
            name: LocalizedText(en: 'A very long legacy product name here'),
            sku: 'PRE-LONG-SKU-0001',
            priceUSD: 12),
      ];
      await pumpSection(tester, width: 375);
      final badge = find.text('Disabled');
      expect(tester.widget<Text>(badge).softWrap, isFalse);
      final line = tester.getSize(badge).height;
      expect(line, lessThan(24), reason: 'one line, no wrap');
      expect(tester.takeException(), isNull);
    });

    testWidgets('default order: disabled items after active ones',
        (tester) async {
      repo.items['s1'] = [
        const ServiceItem(
            id: 'old', name: LocalizedText(en: 'Legacy'), order: 0),
        const ServiceItem(
            id: 'new',
            name: LocalizedText(en: 'Fresh'),
            order: 5,
            status: CatalogStatus.active),
      ];
      await pumpSection(tester);
      expect(tester.getTopLeft(find.text('Fresh')).dy,
          lessThan(tester.getTopLeft(find.text('Legacy')).dy));
      expect(repo.itemQueries.last.sort?.field, 'order');
    });

    testWidgets('SKU column and per-oz price', (tester) async {
      repo.items['s1'] = [_steak, _water];
      await pumpSection(tester);
      expect(find.text('SKU'), findsOneWidget);
      expect(find.text('PRE-104'), findsOneWidget);
      expect(find.text(r'$3.31 / oz'), findsOneWidget);
      expect(find.text(r'$2.00 USD'), findsOneWidget);
    });

    testWidgets('search sends q; category filter from the server list',
        (tester) async {
      repo.items['s1'] = [_steak, _water];
      await pumpSection(tester);
      await tester.enterText(find.byKey(const Key('search-items')), 'pre-0');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      expect(repo.itemQueries.last.q, 'pre-0');
      expect(find.text('Water'), findsOneWidget);
      expect(find.text('New York steak'), findsNothing);

      await tester.tap(find.byKey(const Key('clear-filters-items')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('filter-items-category')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Proteins').last);
      await tester.pumpAndSettle();
      expect(repo.itemQueries.last.filters, {'category': 'Proteins'});
      expect(repo.itemQueries.last.sort?.field, 'order');
      expect(find.text('New York steak'), findsOneWidget);
      expect(find.text('Water'), findsNothing);
    });

    testWidgets('no category filter when the categories call fails',
        (tester) async {
      repo.items['s1'] = [_water];
      repo.failCategoriesWith = Exception('down');
      await pumpSection(tester);
      expect(find.byKey(const Key('filter-items-category')), findsNothing);
      expect(find.text('Water'), findsOneWidget);
    });
  });

  group('request detail lines', () {
    const steakLine = ServiceRequestLine(
      name: LocalizedText(en: 'New York steak'),
      quantity: 5,
      pricingUnit: PricingUnit.oz,
      ozPerPortion: 12,
      unitPriceUSD: 3.3114,
      lineTotalUSD: 198.68,
    );

    test('list summaries name the oz: "5 × 12 oz New York steak"', () {
      final order = testRequest(1, isOrder: true, lines: [
        steakLine,
        const ServiceRequestLine(name: LocalizedText(en: 'Water'), quantity: 2),
      ]);
      expect(inboxSummary(RequestInboxItem(order), false, null),
          '5 × 12 oz New York steak, 2 × Water');
    });

    test('labels OZ and ITEM lines', () {
      expect(requestLineLabel(steakLine, false),
          r'New York steak — 5 × 12 oz = 60 oz · $198.68');
      const water = ServiceRequestLine(
          name: LocalizedText(en: 'Water'), quantity: 2, lineTotalUSD: 4);
      expect(requestLineLabel(water, false), r'Water × 2 · $4.00');
      const bread =
          ServiceRequestLine(name: LocalizedText(en: 'Bread'), quantity: 1);
      expect(requestLineLabel(bread, false), 'Bread × 1');
    });

    testWidgets('the panel renders the OZ line', (tester) async {
      await pump(
          tester,
          RequestDetailPanel(
            request: testRequest(1, isOrder: true, lines: [steakLine]),
            repository: FakeServiceRequestRepository(),
            onClose: () {},
            onChanged: () {},
            isEs: false,
          ));
      expect(find.textContaining('5 × 12 oz = 60 oz'), findsOneWidget);
    });
  });
}
