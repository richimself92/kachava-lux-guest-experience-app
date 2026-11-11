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
      bool isEs = false,
      Size size = const Size(1200, 1000),
      double width = 560}) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      theme: KachavaAdminTheme.build(),
      home: Scaffold(
        body: Row(children: [
          SizedBox(
            width: width,
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

  Future<void> tapKey(WidgetTester tester, String key) async {
    await tester.ensureVisible(find.byKey(Key(key)).first);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(Key(key)).first);
    await tester.pumpAndSettle();
  }

  Future<void> pick(WidgetTester tester, String key, String option) async {
    await tapKey(tester, key);
    await tester.tap(find.text(option).last);
    await tester.pumpAndSettle();
  }

  Future<void> openMore(WidgetTester tester) => tapKey(tester, 'svc-more');

  Future<void> save(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('form-save')).first);
    await tester.pumpAndSettle();
  }

  Future<void> uploadCover(WidgetTester tester, {bool rights = true}) async {
    await tapKey(tester, 'upload-cover-pick');
    if (rights) await tapKey(tester, 'svc-cover-rights');
  }

  Future<void> confirm(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('confirm-dialog-confirm')));
    await tester.pumpAndSettle();
  }

  void expectTexts(List<String> visible, {List<String> hidden = const []}) {
    for (final t in visible) {
      expect(find.text(t), findsWidgets, reason: 'visible: $t');
    }
    for (final t in hidden) {
      expect(find.text(t), findsNothing, reason: 'hidden: $t');
    }
  }

  testWidgets('one page, no tabs: experience essentials, rest under More',
      (tester) async {
    await pumpEditor(tester);
    expect(find.byKey(const Key('form-panel-tabbar')), findsNothing);
    expect(find.byKey(const Key('svc-usageType')), findsNothing);
    await pick(tester, 'svc-kind', 'Experience');
    expectTexts([
      'Cover',
      'Pricing',
      'Per person',
      'Duration (min)',
      'Time slots',
      'Min guests',
      'Max guests',
      'Lead time (h)',
      "What's included",
      'Meeting point',
      'More options',
    ], hidden: [
      'Itinerary',
      'Languages',
      'Min age',
      'What to bring',
      'Internal notes',
      'Guest form',
      'Use',
    ]);
    expect(find.byKey(const Key('svc-items-section')), findsNothing);
    await openMore(tester);
    expectTexts([
      'Itinerary',
      'Languages',
      'Min age',
      'What to bring',
      'Restrictions',
      'Cancel by (h)',
      'Cancellation',
      'Blocked dates',
      'Provider',
      'Internal notes',
      'Gallery',
      'Section',
    ]);
  });

  testWidgets('create derives usage and guest form, keeps panel open',
      (tester) async {
    await pumpEditor(tester);
    await pick(tester, 'svc-kind', 'Experience');
    await tester.enterText(find.byKey(const Key('svc-name.en')), 'Cenote dive');
    await tester.enterText(
        find.byKey(const Key('svc-name.es')), 'Buceo en cenote');
    await save(tester);

    final body = repo.creates.single;
    expect(body['kind'], 'EXPERIENCE');
    expect(body['section'], 'EXPERIENCES');
    expect(body['usageType'], 'BOOKING');
    expect(body['pricing']['mode'], 'PER_PERSON');
    expect(body['guestForm'], {
      'date': true,
      'time': true,
      'guests': true,
      'notes': true,
      'dietary': true,
      'health': false,
    });
    expect(body.containsKey('bar'), isFalse);
    expect(savedCalls, 1);
    expect(closed, isFalse);
    expect(find.text('Service saved'), findsOneWidget);
    expect(find.byKey(const Key('service-status')), findsOneWidget);
  });

  testWidgets('editing an old service re-derives usage and guest form',
      (tester) async {
    final old = AdminService.parse({
      ...testService(9, kind: ServiceKind.wellness).toDraftJson(),
      'usageType': 'ORDER',
      'guestForm': {'date': false, 'health': false},
    });
    repo.seed([old]);
    await pumpEditor(tester, service: old);
    await save(tester);
    expect(repo.patches.single['usageType'], 'BOOKING');
    expect(repo.patches.single['guestForm']['health'], isTrue);
    expect(repo.patches.single['guestForm']['date'], isTrue);
  });

  testWidgets('bar: products, slots and lead time; age check under More',
      (tester) async {
    await pumpEditor(tester); // the first kind is the bar
    expectTexts(['Products', 'Time slots', 'Lead time (h)'],
        hidden: ['Pricing', 'Age check', 'Max guests', 'Duration (min)']);
    expect(find.byKey(const Key('items-save-first')), findsOneWidget);
    await openMore(tester);
    expectTexts(['Age check', 'Pricing', 'Days', 'Blocked dates', 'Section']);
    await tester.enterText(find.byKey(const Key('svc-name.en')), 'Bar');
    await save(tester);
    expect(repo.creates.single['usageType'], 'ORDER');
    expect(find.byKey(const Key('items-save-first')), findsNothing);
    expect(find.byKey(const Key('items-empty')), findsOneWidget);
  });

  testWidgets('villa stocking keeps its limits under More', (tester) async {
    await pumpEditor(tester, section: ServiceSection.inVilla);
    await pick(tester, 'svc-kind', 'Villa stocking');
    expectTexts(['Products'], hidden: ['Max per item', 'Deadline (h)']);
    await openMore(tester);
    expectTexts(['Max per item', 'Deadline (h)']);
    expect(find.byKey(const Key('svc-section')), findsNothing);
  });

  testWidgets('dining: pricing, max guests, slots, menus; derived on save',
      (tester) async {
    await pumpEditor(tester, section: ServiceSection.dining);
    await pick(tester, 'svc-kind', 'Special menu');
    expectTexts(['Pricing', 'Max guests', 'Time slots', 'Menus'],
        hidden: ['Pairing', 'Lead time (h)']);
    await pick(tester, 'svc-pricing.mode', 'Fixed');
    expect(find.text('Amount (USD)'), findsOneWidget);
    await openMore(tester);
    expectTexts(['Pairing', 'Lead time (h)', 'Cancellation']);
    expect(find.byKey(const Key('svc-section')), findsNothing);
    await tester.enterText(find.byKey(const Key('svc-name.en')), 'Tasting');
    await save(tester);
    final body = repo.creates.single;
    expect(body['section'], 'DINING');
    expect(body['usageType'], 'BOOKING');
    expect(body['dining'], isA<Map>());
    expect(body['guestForm']['dietary'], isTrue);
  });

  testWidgets('wellness, preference and transport show their essentials',
      (tester) async {
    await pumpEditor(tester);
    await pick(tester, 'svc-kind', 'Wellness');
    expectTexts(['Options', 'Time slots', 'Location', 'Max guests'],
        hidden: ['Contraindications', 'Pricing']);
    expect(find.text('Health questions'), findsOneWidget);
    await pick(tester, 'svc-kind', 'Preference');
    expectTexts(['Options', 'Selection'],
        hidden: ['Change until (h)', 'Time slots', 'Lead time (h)']);
    await pick(tester, 'svc-kind', 'Transport');
    // Transfers are free for guests: vehicles are optional, under More.
    expectTexts(['Airports', 'Provider', 'Lead time (h)'],
        hidden: ['Vehicles', 'Price basis', 'Flight required', 'Pricing']);
    await openMore(tester);
    expectTexts(['Vehicles', 'Price basis', 'Flight required', 'Pricing']);
    await tester.enterText(find.byKey(const Key('svc-name.en')), 'Airport');
    await save(tester);
    expect(repo.creates.single['usageType'], 'TRIP');
    expect(repo.creates.single['guestForm']['date'], isFalse);
  });

  testWidgets('name is required in one language', (tester) async {
    await pumpEditor(tester);
    await save(tester);
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
    await save(tester);
    expect(find.text('Confirm usage rights'), findsOneWidget);
    expect(repo.patches, isEmpty);
  });

  testWidgets('items inline: add one, activate it, back to the service',
      (tester) async {
    final service = testService(4, kind: ServiceKind.breakfast);
    repo.seed([service]);
    await pumpEditor(tester, service: service);
    expect(find.text('Menus'), findsOneWidget);
    await tapKey(tester, 'items-new');
    expect(find.byKey(const Key('service-editor')), findsNothing);
    expectTexts(['Dietary tags', 'Allergens'],
        hidden: ['Origin', 'Passengers']);
    await tester.enterText(find.byKey(const Key('svc-name.en')), 'Chilaquiles');
    await tester.enterText(find.byKey(const Key('svc-name.es')), 'Chilaquiles');
    await tester.enterText(find.byKey(const Key('svc-priceUSD')), '12.5');
    await tester.enterText(
        find.byKey(const Key('svc-allergens')), 'egg, dairy');
    await save(tester);
    expect(repo.itemWrites.single['priceUSD'], 12.5);
    expect(repo.itemWrites.single['allergens'], ['egg', 'dairy']);
    expect(find.byKey(const Key('item-editor')), findsNothing);
    expect(find.byKey(const Key('service-editor')), findsOneWidget);
    expect(find.text(r'$12.50 USD'), findsOneWidget);

    final id = repo.items['s4']!.single.id;
    await tester.pump(const Duration(seconds: 5)); // the toast goes away
    await tester.pumpAndSettle();
    await tapKey(tester, 'row-items-$id');
    await tester.tap(find.byKey(const Key('item-toggle-status')));
    await tester.pumpAndSettle();
    expect(find.text('Activate this item?'), findsOneWidget);
    await confirm(tester);
    expect(repo.items['s4']!.single.status, CatalogStatus.active);
    expect(find.byKey(const Key('item-status')), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('form-cancel')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('service-editor')), findsOneWidget);
    expect(find.text('Active'), findsOneWidget);
  });

  testWidgets('transport vehicles ask for capacity', (tester) async {
    final service = testService(5, kind: ServiceKind.transport);
    repo.seed([service]);
    await pumpEditor(tester, service: service);
    await openMore(tester); // optional vehicles live under More
    await tapKey(tester, 'items-new');
    await tester.enterText(find.byKey(const Key('svc-name.en')), 'Van');
    await tester.enterText(
        find.byKey(const Key('svc-capacity.passengers')), '6');
    await tester.enterText(find.byKey(const Key('svc-capacity.luggage')), '4');
    await save(tester);
    expect(repo.itemWrites.single['capacity'], {'passengers': 6, 'luggage': 4});
  });

  testWidgets('mobile 375: every kind with More open renders without overflow',
      (tester) async {
    for (final kind in ServiceKind.values) {
      final service = testService(10 + kind.index, kind: kind);
      repo.seed([service]);
      await pumpEditor(tester,
          service: service, size: const Size(375, 812), width: 375);
      await openMore(tester);
      await tester.drag(
          find.byKey(const Key('form-panel-fields')), const Offset(0, -4000));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: kind.wire);
    }
    await tester.drag(
        find.byKey(const Key('form-panel-fields')), const Offset(0, 8000));
    await tester.pumpAndSettle();
    await tapKey(tester, 'items-new');
    expect(find.byKey(const Key('item-editor')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Spanish labels', (tester) async {
    await pumpEditor(tester, isEs: true, section: ServiceSection.experiences);
    expectTexts([
      'Nuevo servicio',
      'Tipo',
      'Precio',
      'Qué incluye',
      'Punto de encuentro',
      'Más opciones',
      'Activar',
      'Guardar',
    ]);
  });
}
