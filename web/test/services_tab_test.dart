import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kachava_guest_portal/data/guest_api.dart';
import 'package:kachava_guest_portal/presentation/common/widgets.dart';

import 'support/fake_guest_api.dart';
import 'support/fixtures.dart';

Future<void> _openServices(WidgetTester tester) async {
  await tester.tap(find.text('Services'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
      'cards come only from the catalog: photo, name, line, price, lead',
      (tester) async {
    await pumpPortal(tester,
        api: FakeGuestApi(catalog: fullCatalog()),
        size: const Size(1280, 2400));
    await _openServices(tester);
    expect(find.text('5 services'), findsOneWidget);
    expect(find.text('Massage'), findsOneWidget);
    expect(find.text('Short spa'), findsOneWidget);
    expect(find.text('\$120 / person'), findsOneWidget);
    expect(find.text('Included ✓'), findsOneWidget);
    expect(find.text('\$4-12 / item'), findsOneWidget);
    expect(find.text('24 h ahead'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('search (debounced) and No results + Clear', (tester) async {
    await pumpPortal(tester, api: FakeGuestApi(catalog: fullCatalog()));
    await _openServices(tester);
    await tester.enterText(find.byKey(const Key('services-search')), 'massa');
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('5 services'), findsOneWidget, reason: 'debounced');
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('1 services'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('services-search')), 'zzz');
    await tester.pumpAndSettle(const Duration(milliseconds: 400));
    expect(find.text('No results'), findsOneWidget);
    await tester.tap(find.text('Clear'));
    await tester.pumpAndSettle();
    expect(find.text('5 services'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('section chip filters; When filter narrows', (tester) async {
    await pumpPortal(tester, api: FakeGuestApi(catalog: fullCatalog()));
    await _openServices(tester);
    await tester.tap(find.byKey(const Key('chip-IN_VILLA')));
    await tester.pumpAndSettle();
    expect(find.text('2 services'), findsOneWidget);
    await tester.tap(find.byKey(const Key('chip-when')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('During').last);
    await tester.pumpAndSettle();
    expect(find.text('0 services'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('empty catalog: Nothing yet + Ask Host', (tester) async {
    await pumpPortal(tester);
    await _openServices(tester);
    expect(find.text('Nothing yet'), findsOneWidget);
    await tester.tap(find.text('Ask Host'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('screen-host')), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('catalog error: one line + Retry', (tester) async {
    await pumpPortal(tester,
        api: FakeGuestApi()..catalogFailure = FailureKind.unreachable);
    await _openServices(tester);
    expect(find.text("Couldn't load"), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('detail sheet: gallery, chips, accordions, primary by usage',
      (tester) async {
    await pumpPortal(tester, api: FakeGuestApi(catalog: fullCatalog()));
    await _openServices(tester);
    await tester.tap(find.byKey(const Key('chip-WELLNESS')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('service-card-spa')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('service-detail-spa')), findsOneWidget);
    expect(find.text('Long spa'), findsOneWidget);
    final primary = find.byKey(const Key('detail-primary'));
    expect(find.descendant(of: primary, matching: find.text('Book')),
        findsOneWidget);
    await tester.tap(primary);
    await tester.pumpAndSettle();
    expect(find.text('1.4 Massage'), findsOneWidget,
        reason: 'same journey number in the form title');
    expect(find.byKey(const Key('booking-date')), findsOneWidget);
    await unmount(tester);
  });

  testWidgets(
      'search typed during the first catalog load is kept and applied '
      'when the catalog arrives', (tester) async {
    final api = FakeGuestApi(catalog: fullCatalog())
      ..catalogFailure = FailureKind.unreachable;
    await pumpPortal(tester, api: api);
    await _openServices(tester);
    await tester.enterText(find.byKey(const Key('services-search')), 'massa');
    await tester.pump(const Duration(milliseconds: 100));

    api.catalogFailure = null;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle(const Duration(milliseconds: 400));

    final field =
        tester.widget<TextField>(find.byKey(const Key('services-search')));
    expect(field.controller!.text, 'massa');
    expect(find.text('1 services'), findsOneWidget);
    await unmount(tester);
  });

  test('photos decode at the size they are shown, never above the cap', () {
    expect(ServicePhoto.decodeWidth(358, 2), 716);
    expect(ServicePhoto.decodeWidth(358, 1), 358);
    expect(ServicePhoto.decodeWidth(1200, 3), ServicePhoto.maxDecodeWidth);
    expect(ServicePhoto.decodeWidth(double.infinity, 2),
        ServicePhoto.maxDecodeWidth);
  });

  testWidgets('a service card decodes its cover at the card width',
      (tester) async {
    await pumpPortal(tester,
        api: FakeGuestApi(catalog: fullCatalog()), size: const Size(390, 844));
    await _openServices(tester);
    final images = tester.widgetList<Image>(find.byType(Image)).toList();
    expect(images, isNotEmpty);
    for (final image in images) {
      final provider = image.image;
      expect(provider, isA<ResizeImage>());
      expect((provider as ResizeImage).width,
          lessThan(ServicePhoto.maxDecodeWidth));
    }
    await unmount(tester);
  });
}
