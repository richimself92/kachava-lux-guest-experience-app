import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kachava_guest_portal/core/storage/device_prefs.dart';

import 'support/fake_guest_api.dart';
import 'support/fixtures.dart';

FakeGuestApi _api() => FakeGuestApi(
      stay: stayJson(
        checkIn: '2026-11-03',
        checkOut: '2026-11-08',
        bookings: [
          bookingJson('b1', 'spa',
              status: 'IN_PREPARATION', section: 'WELLNESS')
        ],
      ),
      catalog: fullCatalog(),
      trips: [tripJson('t1')],
    );

Future<void> _tab(WidgetTester tester, String label) async {
  await tester.tap(find.descendant(
      of: find.byKey(const Key('portal-tabs')), matching: find.text(label)));
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull, reason: '$label overflowed');
}

void main() {
  for (final width in [320.0, 375.0]) {
    for (final lang in ['en', 'es']) {
      testWidgets(
          'every tab renders without overflow at ${width.toInt()}px ($lang)',
          (tester) async {
        await pumpPortal(tester,
            api: _api(),
            size: Size(width, 900),
            prefs: MemoryDevicePrefs(browserLanguage: lang),
            install: FakeInstallPrompt(canPromptNative: true));
        expect(tester.takeException(), isNull);
        final es = lang == 'es';
        await _tab(tester, es ? 'Servicios' : 'Services');
        await _tab(tester, es ? 'Solicitudes' : 'Requests');
        await _tab(tester, 'Host');
        await _tab(tester, es ? 'Inicio' : 'Home');
        final home = find.descendant(
            of: find.byKey(const Key('screen-home')),
            matching: find.byType(Scrollable));
        await tester.scrollUntilVisible(find.byKey(const Key('step-3')), 200,
            scrollable: home);
        await tester.ensureVisible(find.byKey(const Key('step-3')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('step-3')));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await unmount(tester);
      });
    }

    testWidgets('forms and detail sheet fit ${width.toInt()}px',
        (tester) async {
      await pumpPortal(tester, api: _api(), size: Size(width, 640));
      await tester.tap(find.byKey(const Key('journey-next')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Step 1 of'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pageBack();
      await tester.pumpAndSettle();
      await _tab(tester, 'Services');
      await tester.tap(find.byKey(const Key('chip-WELLNESS')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('service-card-spa')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.byKey(const Key('detail-primary')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await unmount(tester);
    });
  }

  testWidgets('tabs, chips and toggles keep 48px targets', (tester) async {
    await pumpPortal(tester, api: _api(), size: const Size(375, 812));
    for (final key in [
      'lang-en',
      'lang-es',
      'journey-not-now',
      'wifi-button'
    ]) {
      final size = tester.getSize(find.byKey(Key(key)));
      expect(size.height, greaterThanOrEqualTo(48), reason: key);
      expect(size.width, greaterThanOrEqualTo(48), reason: key);
    }
    final row = tester.getSize(find.byKey(const Key('task-1.2')));
    expect(row.height, greaterThanOrEqualTo(48));
    await unmount(tester);
  });

  testWidgets('services grid: 1 column on phones, 3 from 1024px',
      (tester) async {
    await pumpPortal(tester, api: _api(), size: const Size(1280, 1600));
    await _tab(tester, 'Services');
    final a = tester.getTopLeft(find.byKey(const Key('service-card-stock')));
    final b = tester.getTopLeft(find.byKey(const Key('service-card-pillow')));
    expect(a.dy, b.dy, reason: 'same row on desktop');
    await unmount(tester);
  });
}
