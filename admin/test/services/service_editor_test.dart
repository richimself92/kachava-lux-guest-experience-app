import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kachava_admin_dashboard/core/admin_theme.dart';
import 'package:kachava_admin_dashboard/domain/admin_service.dart';
import 'package:kachava_admin_dashboard/presentation/services/service_editor.dart';

import '../support/fake_service_catalog.dart';
import '../support/fake_uploads.dart';

void main() {
  late FakeServiceCatalogRepository repo;
  late int savedCalls;
  late bool closed;

  setUp(() {
    repo = FakeServiceCatalogRepository();
    savedCalls = 0;
    closed = false;
  });

  Future<void> pumpEditor(WidgetTester tester,
      {AdminService? service,
      ServiceSection? section,
      bool isEs = false}) async {
    tester.view.physicalSize = const Size(1200, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      theme: KachavaAdminTheme.build(),
      home: Scaffold(
        body: Row(children: [
          SizedBox(
            width: 560,
            child: ServiceEditor(
              deps: fakeCatalogDeps(repo,
                  picker: FakeImageFilePicker(pickedImage())),
              service: service,
              section: section,
              isEs: isEs,
              onClose: () => closed = true,
              onSaved: () => savedCalls++,
            ),
          ),
        ]),
      ),
    ));
    await tester.pumpAndSettle();
  }

  Finder tab(String label) => find.descendant(
      of: find.byKey(const Key('form-panel-tabbar')),
      matching: find.text(label));

  Future<void> openTab(WidgetTester tester, String label) async {
    await tester.ensureVisible(tab(label));
    await tester.pumpAndSettle();
    await tester.tap(tab(label));
    await tester.pumpAndSettle();
  }

  Future<void> pick(WidgetTester tester, String key, String option) async {
    await tester.tap(find.byKey(Key(key)));
    await tester.pumpAndSettle();
    await tester.tap(find.text(option).last);
    await tester.pumpAndSettle();
  }

  Future<void> uploadCover(WidgetTester tester, {bool rights = true}) async {
    await openTab(tester, 'Images');
    await tester.tap(find.byKey(const Key('upload-cover-pick')));
    await tester.pumpAndSettle();
    if (rights) {
      await tester.tap(find.byKey(const Key('svc-cover-rights')));
      await tester.pumpAndSettle();
    }
  }

  Future<void> confirm(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('confirm-dialog-confirm')));
    await tester.pumpAndSettle();
  }

  testWidgets('create: kind decides block tab, save keeps panel open',
      (tester) async {
    await pumpEditor(tester);
    expect(find.text('New service'), findsOneWidget);
    expect(find.byKey(const Key('items-save-first')), findsNothing);
    await pick(tester, 'svc-kind', 'Experience');
    expect(tab('Experience'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('svc-name.en')), 'Cenote dive');
    await tester.enterText(
        find.byKey(const Key('svc-name.es')), 'Buceo en cenote');
    await openTab(tester, 'Experience');
    expect(find.text('Itinerary'), findsOneWidget);
    expect(find.text('Meeting point'), findsOneWidget);
    await tester.tap(find.byKey(const Key('form-save')));
    await tester.pumpAndSettle();

    final body = repo.creates.single;
    expect(body['kind'], 'EXPERIENCE');
    expect(body['section'], 'EXPERIENCES');
    expect(body['usageType'], 'BOOKING');
    expect(body['name'], {'en': 'Cenote dive', 'es': 'Buceo en cenote'});
    expect(body['status'], 'DISABLED');
    expect(body.containsKey('bar'), isFalse);
    expect(savedCalls, 1);
    expect(closed, isFalse);
    expect(find.text('Cenote dive'), findsWidgets);
    expect(find.byKey(const Key('service-status')), findsOneWidget);
    expect(find.text('Service saved'), findsOneWidget);
    await openTab(tester, 'Items');
    expect(find.byKey(const Key('items-empty')), findsOneWidget);
  });

  testWidgets('kind and use show only relevant fields', (tester) async {
    await pumpEditor(tester);
    await pick(tester, 'svc-kind', 'Transport');
    await openTab(tester, 'Price & availability');
    expect(find.text('Lead time (h)'), findsOneWidget);
    expect(find.text('Max guests'), findsOneWidget);
    expect(find.text('Days'), findsNothing);
    expect(find.text('Amount (USD)'), findsNothing);
    await pick(tester, 'svc-pricing.mode', 'Fixed');
    expect(find.text('Amount (USD)'), findsOneWidget);
    await openTab(tester, 'Guest form');
    expect(find.text('Health'), findsNothing);
    expect(find.text('Diet & allergies'), findsNothing);
    await openTab(tester, 'Transport');
    expect(find.text('Airports'), findsOneWidget);
    expect(find.text('Flight required'), findsOneWidget);
  });

  testWidgets('breakfast has no block tab; dining section limits kinds',
      (tester) async {
    await pumpEditor(tester, section: ServiceSection.dining);
    await pick(tester, 'svc-kind', 'Breakfast');
    expect(tab('Breakfast'), findsNothing);
    expect(find.byKey(const Key('svc-section')), findsNothing);
    await tester.enterText(find.byKey(const Key('svc-name.en')), 'Breakfast');
    await tester.tap(find.byKey(const Key('form-save')));
    await tester.pumpAndSettle();
    expect(repo.creates.single['section'], 'DINING');
    expect(repo.creates.single['dining'], isA<Map>());
  });

  testWidgets('name is required in one language', (tester) async {
    await pumpEditor(tester);
    await tester.tap(find.byKey(const Key('form-save')));
    await tester.pumpAndSettle();
    expect(find.text('Name required'), findsOneWidget);
    expect(repo.creates, isEmpty);
  });

  testWidgets('activate: one-line confirm, 422 problems inline, then active',
      (tester) async {
    final service = testService(1);
    repo.seed([service]);
    await pumpEditor(tester, service: service);
    await tester.tap(find.byKey(const Key('service-toggle-status')));
    await tester.pumpAndSettle();
    expect(find.text('Activate this service?'), findsOneWidget);
    await confirm(tester);
    expect(find.byKey(const Key('form-save-error')), findsOneWidget);
    expect(find.text('Cover required'), findsOneWidget);
    expect(find.text('Disabled'), findsOneWidget);

    await uploadCover(tester);
    await tester.tap(find.byKey(const Key('service-toggle-status')));
    await tester.pumpAndSettle();
    await confirm(tester);
    expect(repo.patches.last['status'], 'ACTIVE');
    expect(repo.patches.last['cover']['usageRightsConfirmed'], isTrue);
    expect(find.text('Active'), findsOneWidget);
    expect(find.text('Now active'), findsOneWidget);
    expect(find.text('Deactivate'), findsOneWidget);
  });

  testWidgets('deactivate asks first and saves DISABLED', (tester) async {
    final service =
        testService(2, status: CatalogStatus.active, withCover: true);
    repo.seed([service]);
    await pumpEditor(tester, service: service);
    await tester.tap(find.byKey(const Key('service-toggle-status')));
    await tester.pumpAndSettle();
    expect(find.text('Deactivate this service?'), findsOneWidget);
    await confirm(tester);
    expect(repo.patches.single['status'], 'DISABLED');
    expect(find.text('Disabled'), findsOneWidget);
  });

  testWidgets('a photo needs the usage-rights confirmation', (tester) async {
    final service = testService(3);
    repo.seed([service]);
    await pumpEditor(tester, service: service);
    await uploadCover(tester, rights: false);
    expect(find.byKey(const Key('svc-cover-alt-en')), findsOneWidget);
    await tester.tap(find.byKey(const Key('form-save')));
    await tester.pumpAndSettle();
    expect(find.text('Confirm usage rights'), findsOneWidget);
    expect(repo.patches, isEmpty);
  });

  testWidgets('items: kind fields, add, activate in the nested form',
      (tester) async {
    final service = testService(4, kind: ServiceKind.breakfast);
    repo.seed([service]);
    await pumpEditor(tester, service: service);
    await openTab(tester, 'Items');
    await tester.tap(find.byKey(const Key('items-new')));
    await tester.pumpAndSettle();
    expect(find.text('Dietary tags'), findsOneWidget);
    expect(find.text('Allergens'), findsOneWidget);
    expect(find.text('Origin'), findsNothing);
    expect(find.text('Passengers'), findsNothing);
    await tester.enterText(find.byKey(const Key('svc-name.en')), 'Chilaquiles');
    await tester.enterText(find.byKey(const Key('svc-name.es')), 'Chilaquiles');
    await tester.enterText(find.byKey(const Key('svc-priceUSD')), '12.5');
    await tester.enterText(
        find.byKey(const Key('svc-allergens')), 'egg, dairy');
    await tester.tap(find.descendant(
        of: find.byKey(const Key('item-editor')),
        matching: find.byKey(const Key('form-save'))));
    await tester.pumpAndSettle();
    expect(repo.itemWrites.single['priceUSD'], 12.5);
    expect(repo.itemWrites.single['allergens'], ['egg', 'dairy']);
    expect(find.byKey(const Key('item-editor')), findsNothing);
    expect(find.text(r'$12.50 USD'), findsOneWidget);

    final id = repo.items['s4']!.single.id;
    await tester.tap(find.byKey(Key('row-items-$id')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('item-toggle-status')));
    await tester.pumpAndSettle();
    expect(find.text('Activate this item?'), findsOneWidget);
    await confirm(tester);
    expect(repo.items['s4']!.single.status, CatalogStatus.active);
    expect(find.byKey(const Key('item-status')), findsOneWidget);
  });

  testWidgets('transport items ask for capacity', (tester) async {
    final service = testService(5, kind: ServiceKind.transport);
    repo.seed([service]);
    await pumpEditor(tester, service: service);
    await openTab(tester, 'Items');
    await tester.tap(find.byKey(const Key('items-new')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('svc-name.en')), 'Van');
    await tester.enterText(
        find.byKey(const Key('svc-capacity.passengers')), '6');
    await tester.enterText(find.byKey(const Key('svc-capacity.luggage')), '4');
    await tester.tap(find.descendant(
        of: find.byKey(const Key('item-editor')),
        matching: find.byKey(const Key('form-save'))));
    await tester.pumpAndSettle();
    expect(repo.itemWrites.single['capacity'], {'passengers': 6, 'luggage': 4});
  });

  testWidgets('mobile 375: every tab and the item form render without overflow',
      (tester) async {
    final service = testService(6, kind: ServiceKind.transport);
    repo.seed([service]);
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      theme: KachavaAdminTheme.build(),
      home: Scaffold(
        body: ServiceEditor(
          deps: fakeCatalogDeps(repo),
          service: service,
          onClose: () {},
          onSaved: () {},
        ),
      ),
    ));
    await tester.pumpAndSettle();
    for (final label in [
      'Images',
      'Price & availability',
      'Items',
      'Guest form',
      'Operation',
      'Transport',
      'General',
    ]) {
      await openTab(tester, label);
      expect(tester.takeException(), isNull, reason: label);
    }
    await openTab(tester, 'Items');
    await tester.tap(find.byKey(const Key('items-new')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('item-editor')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Spanish labels', (tester) async {
    await pumpEditor(tester, isEs: true);
    expect(find.text('Nuevo servicio'), findsOneWidget);
    for (final label in [
      'General',
      'Imágenes',
      'Precio y disponibilidad',
      'Ítems'
    ]) {
      expect(tab(label), findsOneWidget, reason: label);
    }
    expect(find.text('Activar'), findsOneWidget);
    expect(find.text('Guardar'), findsOneWidget);
  });
}
