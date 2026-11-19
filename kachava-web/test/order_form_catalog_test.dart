import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kachava_guest_portal/application/portal_controller.dart';
import 'package:kachava_guest_portal/core/storage/device_prefs.dart';
import 'package:kachava_guest_portal/core/theme/kachava_theme.dart';
import 'package:kachava_guest_portal/domain/json_read.dart';
import 'package:kachava_guest_portal/core/i18n/l10n.dart';
import 'package:kachava_guest_portal/presentation/common/kit.dart';
import 'package:kachava_guest_portal/presentation/forms/order_form.dart';
import 'package:kachava_guest_portal/presentation/forms/order_item_rows.dart';

import 'support/fake_guest_api.dart';
import 'support/fixtures.dart';

List<Json> _catalog({Json extra = const {}, Json guestInfo = const {}}) => [
      {
        ...serviceJson(
          guestInfo: guestInfo,
          id: 'stock',
          section: 'IN_VILLA',
          usageType: 'ORDER',
          kind: 'VILLA_STOCKING',
          offeredWhen: 'BEFORE_ARRIVAL',
          nameEn: 'Villa stocking',
          pricing: const {'mode': 'PER_UNIT', 'amount': null},
          items: [
            itemJson('water', nameEn: 'Water', price: 4, category: 'Drinks'),
            itemJson('steak',
                nameEn: 'New York steak',
                price: 3.3114,
                category: 'Proteins',
                pricingUnit: 'OZ',
                portionOzOptions: [6, 8, 10, 12, 14]),
            itemJson('ham',
                nameEn: 'Serrano ham',
                nameEs: 'Jamón serrano',
                price: 2,
                category: 'Deli'),
          ],
        ),
        ...extra,
      },
    ];

Future<PortalController> _open(WidgetTester tester, FakeGuestApi api,
    {double width = 390, MemoryDevicePrefs? prefs}) async {
  final c = PortalController(
    api: api,
    prefs: prefs ?? MemoryDevicePrefs(),
    initialUri: portalUri(),
    clock: clockAt(DateTime.utc(2026, 11, 1, 10)),
  );
  await c.refresh();
  tester.view.physicalSize = Size(width, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  final form = OrderForm(
      controller: c,
      service: c.catalog.firstWhere((s) => s.id == 'stock'),
      title: '1.3 Villa stocking');
  await tester.pumpWidget(MaterialApp(
    theme: KachavaTheme.buildTheme(),
    home: Scaffold(
      body: Builder(
        builder: (ctx) => TextButton(
          onPressed: () => Navigator.of(ctx)
              .push(MaterialPageRoute<void>(builder: (_) => form)),
          child: const Text('open'),
        ),
      ),
    ),
  ));
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return c;
}

Future<void> _pickOz(WidgetTester tester, int oz) async {
  await tester.tap(find.byKey(const Key('oz-steak')));
  await tester.pumpAndSettle();
  await tester.tap(find.text('$oz oz').last);
  await tester.pumpAndSettle();
}

Future<void> _plus(WidgetTester tester, String tooltip, int times) async {
  for (var i = 0; i < times; i++) {
    await tester.tap(find.byTooltip('+ $tooltip'));
    await tester.pump();
  }
}

void main() {
  chipBarTests();
  testWidgets('OZ row: per-oz price, portions × oz estimate, total, payload',
      (tester) async {
    final api = FakeGuestApi(catalog: _catalog());
    await _open(tester, api);
    expect(find.text('\$3.31 / oz'), findsOneWidget);
    expect(find.text('PORTIONS'), findsOneWidget);
    expect(find.text('OZ PER PORTION'), findsOneWidget);
    expect(find.text('8 oz'), findsOneWidget, reason: 'default 8 oz');
    expect(find.text('Estimated — final cut weight may vary'), findsOneWidget);
    expect(find.byKey(const Key('oz-estimate-steak')), findsNothing);
    await _pickOz(tester, 12);
    await _plus(tester, 'New York steak', 5);
    expect(find.text('Estimated total · 5 × 12 oz = 60 oz · \$198.68'),
        findsOneWidget);
    expect(find.text('5 items · \$198.68 USD'), findsOneWidget);
    await tester.tap(find.byKey(const Key('form-primary')));
    await tester.pumpAndSettle();
    expect(find.text('5 × 12 oz New York steak'), findsOneWidget);
    await tester.tap(find.byKey(const Key('form-primary')));
    await tester.pumpAndSettle();
    expect(api.writes.single.$2, {
      'serviceId': 'stock',
      'items': [
        {'itemId': 'steak', 'quantity': 5, 'ozPerPortion': 12},
      ],
    });
  });

  testWidgets('search (accent-insensitive) and category filter',
      (tester) async {
    await _open(tester, FakeGuestApi(catalog: _catalog()));
    expect(find.text('Search products'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('order-search')), 'SERRANO');
    await tester.pump();
    expect(find.text('Serrano ham'), findsOneWidget);
    expect(find.text('Water'), findsNothing);
    await tester.enterText(find.byKey(const Key('order-search')), 'zzz');
    await tester.pump();
    expect(find.text('No results'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('order-search')), '');
    await tester.tap(find.byKey(const Key('order-cat-Proteins')));
    await tester.pumpAndSettle();
    expect(find.text('New York steak'), findsOneWidget);
    expect(find.text('Water'), findsNothing);
    await tester.ensureVisible(find.byKey(const Key('order-cat-all')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('order-cat-all')));
    await tester.pumpAndSettle();
    expect(find.text('Water'), findsOneWidget);
  });

  testWidgets('Save & exit keeps portions and oz', (tester) async {
    final prefs = MemoryDevicePrefs();
    final api = FakeGuestApi(catalog: _catalog());
    await _open(tester, api, prefs: prefs);
    await _pickOz(tester, 14);
    await _plus(tester, 'New York steak', 2);
    await tester.tap(find.text('Save & exit'));
    await tester.pumpAndSettle();
    await _open(tester, api, prefs: prefs);
    expect(find.text('Estimated total · 2 × 14 oz = 28 oz · \$92.72'),
        findsOneWidget);
  });

  testWidgets('375px: no overflow, OZ controls are >= 44px', (tester) async {
    await _open(tester, FakeGuestApi(catalog: _catalog()), width: 375);
    await _plus(tester, 'New York steak', 1);
    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byKey(const Key('oz-steak'))).height,
        greaterThanOrEqualTo(44));
    expect(tester.getSize(find.byKey(const Key('order-cat-all'))).height,
        greaterThanOrEqualTo(44));
    expect(tester.getSize(find.byKey(const Key('order-search'))).height,
        greaterThanOrEqualTo(44));
  });

  testWidgets('review: terms, required substitution choice and acceptance',
      (tester) async {
    final api = FakeGuestApi(
        catalog: _catalog(extra: const {
      'stocking': {'askSubstitutions': true}
    }, guestInfo: const {
      'terms': {'en': 'Prices may vary.\n\nDelivery before arrival.', 'es': 'x'}
    }));
    await _open(tester, api, width: 375);
    await _plus(tester, 'Water', 1);
    await tester.tap(find.byKey(const Key('form-primary')));
    await tester.pumpAndSettle();
    expect(find.text('TERMS & CONDITIONS'), findsOneWidget);
    expect(find.text('Prices may vary.\n\nDelivery before arrival.'),
        findsOneWidget);
    expect(find.byKey(const Key('subs-yes')), findsOneWidget);
    await tester.tap(find.byKey(const Key('form-primary')));
    await tester.pumpAndSettle();
    expect(api.writes, isEmpty);
    expect(find.text('Choose an option'), findsOneWidget);
    expect(find.text('Accept the terms'), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('subs-no')));
    await tester.tap(find.byKey(const Key('subs-no')));
    await tester.ensureVisible(find.byKey(const Key('terms-check')));
    await tester.tap(find.byKey(const Key('terms-check')));
    await tester.pump();
    expect(tester.takeException(), isNull);
    for (final k in ['subs-yes', 'subs-no', 'terms-check']) {
      expect(
          tester.getSize(find.byKey(Key(k))).height, greaterThanOrEqualTo(44),
          reason: k);
    }
    await tester.tap(find.byKey(const Key('form-primary')));
    await tester.pumpAndSettle();
    expect(api.writes.single.$2, {
      'serviceId': 'stock',
      'items': [
        {'itemId': 'water', 'quantity': 1},
      ],
      'substitutionsAllowed': false,
      'termsAccepted': true,
    });
  });

  testWidgets('Save & exit keeps the substitution choice', (tester) async {
    final prefs = MemoryDevicePrefs();
    final api = FakeGuestApi(
        catalog: _catalog(extra: const {
      'stocking': {'askSubstitutions': true}
    }));
    await _open(tester, api, prefs: prefs);
    await _plus(tester, 'Water', 1);
    await tester.tap(find.byKey(const Key('form-primary')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('subs-yes')));
    await tester.pump();
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save & exit'));
    await tester.pumpAndSettle();
    await _open(tester, api, prefs: prefs);
    await tester.tap(find.byKey(const Key('form-primary')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('form-primary')));
    await tester.pumpAndSettle();
    expect((api.writes.single.$2 as Map)['substitutionsAllowed'], isTrue);
  });
}

Widget _bar(String? category, List<String> cats) => MaterialApp(
      theme: KachavaTheme.buildTheme(),
      home: Scaffold(
        body: OrderFilterBar(
          l10n: const L10n(Lang.en),
          categories: cats,
          category: category,
          onQuery: (_) {},
          onCategory: (_) {},
        ),
      ),
    );

void _expectOnScreen(WidgetTester tester, String key) {
  final chip = tester.getRect(find.byKey(Key(key)));
  expect(chip.left, greaterThanOrEqualTo(0), reason: key);
  expect(chip.right, lessThanOrEqualTo(375), reason: key);
}

bool _selected(WidgetTester tester, String key) =>
    tester.widget<SegmentTab>(find.byKey(Key(key))).selected;

void chipBarTests() {
  final cats = [for (var i = 0; i < 14; i++) 'Category $i'];
  testWidgets('chip bar scrolls the selected chip into view', (tester) async {
    tester.view.physicalSize = const Size(375, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(_bar('Category 13', cats));
    await tester.pumpAndSettle();
    _expectOnScreen(tester, 'order-cat-Category 13');
    await tester.pumpWidget(_bar('Category 2', cats));
    await tester.pumpAndSettle();
    _expectOnScreen(tester, 'order-cat-Category 2');
    final selected = [
      for (final k in ['all', ...cats])
        if (_selected(tester, 'order-cat-$k')) k
    ];
    expect(selected, ['Category 2'], reason: 'only one chip highlighted');
  });
}
