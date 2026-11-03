import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kachava_guest_portal/application/portal_controller.dart';
import 'package:kachava_guest_portal/core/storage/device_prefs.dart';
import 'package:kachava_guest_portal/core/theme/kachava_theme.dart';
import 'package:kachava_guest_portal/data/guest_api.dart';
import 'package:kachava_guest_portal/domain/catalog.dart';
import 'package:kachava_guest_portal/domain/journey.dart';
import 'package:kachava_guest_portal/domain/trip.dart';
import 'package:kachava_guest_portal/presentation/forms/booking_form.dart';
import 'package:kachava_guest_portal/presentation/forms/order_form.dart';
import 'package:kachava_guest_portal/presentation/forms/preference_forms.dart';
import 'package:kachava_guest_portal/presentation/forms/trip_wizard.dart';

import 'support/fake_guest_api.dart';
import 'support/fixtures.dart';

Future<PortalController> _controller(FakeGuestApi api,
    {MemoryDevicePrefs? prefs}) async {
  final c = PortalController(
    api: api,
    prefs: prefs ?? MemoryDevicePrefs(),
    initialUri: portalUri(),
    clock: clockAt(DateTime.utc(2026, 11, 1, 10)),
  );
  await c.refresh();
  return c;
}

CatalogService _svc(PortalController c, String id) =>
    c.catalog.firstWhere((s) => s.id == id);

/// Opens [form] from a host page so pop + toast behave like the app.
Future<void> _open(WidgetTester tester, Widget form,
    {Size size = const Size(390, 844)}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
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
}

Future<void> _primary(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('form-primary')));
  await tester.pumpAndSettle();
}

Future<void> _pickDay(WidgetTester tester, Key field, String day) async {
  await tester.tap(find.byKey(field));
  await tester.pumpAndSettle();
  await tester.tap(find.text(day));
  await tester.tap(find.text('OK'));
  await tester.pumpAndSettle();
}

void main() {
  group('ORDER', () {
    testWidgets(
        'steppers, sticky total, review, age check, Order after server OK',
        (tester) async {
      final api = FakeGuestApi(catalog: fullCatalog());
      final c = await _controller(api);
      await _open(
          tester,
          OrderForm(
              controller: c, service: _svc(c, 'bar'), title: '2.1 Pool bar'));
      expect(find.text('0 items · \$0 USD'), findsOneWidget);
      await tester.tap(find.byTooltip('+ Mojito'));
      await tester.pump();
      await tester.tap(find.byTooltip('+ Mojito'));
      await tester.pump();
      expect(find.text('2 items · \$28 USD'), findsOneWidget);
      await _primary(tester); // Review
      expect(find.text('Step 2 of 2'), findsOneWidget);
      await _primary(tester); // Order without age check
      expect(find.text('Confirm your age'), findsOneWidget);
      expect(api.writes, isEmpty);
      await tester.tap(find.byKey(const Key('age-check')));
      await _primary(tester);
      expect(api.writes.single.$1, 'order');
      expect(api.writes.single.$2, {
        'serviceId': 'bar',
        'items': [
          {'itemId': 'mojito', 'quantity': 2}
        ],
      });
      expect(find.text('Order sent'), findsOneWidget);
      expect(find.text('open'), findsOneWidget, reason: 'form closed');
    });

    testWidgets('server error keeps the cart and offers Retry', (tester) async {
      final api = FakeGuestApi(catalog: fullCatalog())
        ..writeFailure = FailureKind.unreachable;
      final c = await _controller(api);
      await _open(
          tester,
          OrderForm(
              controller: c,
              service: _svc(c, 'stock'),
              title: '1.3 Villa stocking'));
      await tester.tap(find.byTooltip('+ Water'));
      await tester.pump();
      await _primary(tester);
      await _primary(tester);
      expect(find.text("Couldn't send"), findsOneWidget);
      expect(find.text('Order sent'), findsNothing);
      expect(find.text('1 × Water'), findsOneWidget);
      api.writeFailure = null;
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(find.text('Order sent'), findsOneWidget);
    });

    testWidgets('Save & exit keeps a draft per guest', (tester) async {
      final prefs = MemoryDevicePrefs();
      final c =
          await _controller(FakeGuestApi(catalog: fullCatalog()), prefs: prefs);
      await _open(tester,
          OrderForm(controller: c, service: _svc(c, 'stock'), title: '1.3'));
      await tester.tap(find.byTooltip('+ Coffee'));
      await tester.pump();
      await tester.tap(find.text('Save & exit'));
      await tester.pumpAndSettle();
      expect(
          c.journey!.taskById(1, 'section:IN_VILLA')!.state, TaskState.draft);
      await _open(tester,
          OrderForm(controller: c, service: _svc(c, 'stock'), title: '1.3'));
      expect(find.text('1 items · \$12 USD'), findsOneWidget);
    });
  });

  group('BOOKING', () {
    testWidgets('date → slot → people → notes → Review → Book', (tester) async {
      final api = FakeGuestApi(catalog: fullCatalog());
      final c = await _controller(api);
      await _open(
          tester,
          BookingForm(
              controller: c, service: _svc(c, 'spa'), title: '1.4 Massage'));
      await _primary(tester);
      expect(find.text('Required'), findsNWidgets(2), reason: 'date and time');
      await _pickDay(tester, const Key('booking-date'), '3');
      await tester.tap(find.byKey(const Key('slot-16:00')));
      await tester.enterText(
          find.byKey(const Key('booking-notes')), 'Anniversary');
      await _primary(tester);
      expect(find.text('Nov 3 · 16:00 · 2 guests'), findsOneWidget);
      await _primary(tester);
      expect(api.writes.single.$2, {
        'serviceId': 'spa',
        'scheduledDate': '2026-11-03',
        'scheduledTimeSlot': '16:00',
        'partySize': 2,
        'metadata': {'notes': 'Anniversary'},
      });
      expect(find.text('Booking sent'), findsOneWidget);
    });
  });

  group('PREFERENCE', () {
    testWidgets('choice cards → Save sends one booking per choice',
        (tester) async {
      final api = FakeGuestApi(
          stay: stayJson(checkIn: '2026-11-03'), catalog: fullCatalog());
      final c = await _controller(api);
      await _open(
          tester,
          PreferenceForm(
              controller: c, service: _svc(c, 'pillow'), title: 'Pillow menu'));
      expect(find.text('Change until Nov 2, 00:00'), findsOneWidget);
      await tester.tap(find.byKey(const Key('choice-firm')));
      await tester.pump();
      await _primary(tester);
      expect(api.writes.single.$2, {
        'serviceId': 'pillow',
        'itemId': 'firm',
        'scheduledDate': '2026-11-03'
      });
      expect(find.text('Choice saved'), findsOneWidget);
    });

    testWidgets(
        '1.2 wizard: explicit None, then one page per preference service',
        (tester) async {
      final api = FakeGuestApi(catalog: fullCatalog());
      final c = await _controller(api);
      await _open(
          tester,
          PreferencesWizard(
              controller: c,
              services: [_svc(c, 'pillow')],
              title: '1.2 Preferences'));
      expect(find.text('Step 1 of 2'), findsOneWidget);
      await _primary(tester);
      expect(find.text('Required'), findsOneWidget);
      await tester.tap(find.byKey(const Key('diet-none')));
      await tester.pump();
      await _primary(tester);
      expect(api.writes.first.$1, 'preferences');
      expect(api.writes.first.$2, {'dietary': 'None', 'allergies': <String>[]});
      expect(find.text('Step 2 of 2'), findsOneWidget);
      await tester.tap(find.byKey(const Key('choice-soft')));
      await tester.pump();
      await _primary(tester);
      expect(api.writes.last.$1, 'booking');
      expect(find.text('Preferences saved'), findsOneWidget);
    });
  });

  group('TRIP wizard', () {
    Future<(FakeGuestApi, PortalController)> openTrip(WidgetTester tester,
        {CoreTask? core}) async {
      final api = FakeGuestApi(catalog: fullCatalog());
      final c = await _controller(api);
      await _open(
          tester,
          TripWizard(
              controller: c,
              service: _svc(c, 'trip1'),
              title: '1.1 Flight & transfer',
              presetType: TripType.arrival,
              core: core ?? CoreTask.flight));
      return (api, c);
    }

    testWidgets('4 pages with inline validation, Review, Send', (tester) async {
      final (api, _) = await openTrip(tester);
      expect(find.text('Step 1 of 4'), findsOneWidget);
      await _primary(tester);
      expect(find.text('Required'), findsNWidgets(2));
      await _pickDay(tester, const Key('trip-date'), '3');
      await tester.enterText(find.byKey(const Key('trip-time')), '14:30');
      await _primary(tester);
      expect(find.text('Step 2 of 4'), findsOneWidget);
      expect(find.text('CUN'), findsOneWidget,
          reason: 'single Settings airport is preselected');
      await _primary(tester);
      expect(find.text('Required'), findsNWidgets(2));
      await tester.enterText(find.byKey(const Key('trip-airline')), 'AA');
      await tester.enterText(find.byKey(const Key('trip-flight')), 'AA 1482');
      await _primary(tester);
      expect(find.text('Step 3 of 4'), findsOneWidget);
      await _primary(tester);
      expect(find.text('Required'), findsOneWidget, reason: 'vehicle');
      await tester.tap(find.byKey(const Key('vehicle-suv')));
      await tester.pump();
      await _primary(tester);
      expect(find.text('Step 4 of 4'), findsOneWidget);
      expect(find.text('Nov 3 · 14:30 · CUN'), findsOneWidget);
      expect(find.text('\$85 USD'), findsOneWidget);
      await _primary(tester);
      expect(api.writes.single.$1, 'trip');
      final body = api.writes.single.$2! as Map;
      expect(body['flight'], {
        'airline': 'AA',
        'number': 'AA 1482',
        'scheduledAt': '2026-11-03T14:30'
      });
      expect(body['itemId'], 'suv');
      expect(find.text('Trip sent'), findsOneWidget);
    });

    testWidgets('vehicle capacity is enforced', (tester) async {
      await openTrip(tester);
      await _pickDay(tester, const Key('trip-date'), '3');
      await tester.enterText(find.byKey(const Key('trip-time')), '14:30');
      await _primary(tester);
      await tester.enterText(find.byKey(const Key('trip-airline')), 'AA');
      await tester.enterText(find.byKey(const Key('trip-flight')), 'AA 1');
      await _primary(tester);
      await tester.tap(find.byKey(const Key('vehicle-suv')));
      await tester.pump();
      for (var i = 0; i < 6; i++) {
        await tester.tap(find.byTooltip('+ Passengers'));
        await tester.pump();
      }
      await _primary(tester);
      expect(find.text('Too many for vehicle'), findsOneWidget);
      expect(find.text('Step 3 of 4'), findsOneWidget);
    });

    testWidgets('"I arrange my own" completes 1.1 on the stay, without a trip',
        (tester) async {
      final (api, c) = await openTrip(tester);
      await tester.tap(find.byKey(const Key('trip-own')));
      await tester.pumpAndSettle();
      expect(api.writes.single.$1, 'journey');
      expect(api.writes.single.$2, {
        'completedTaskIds': ['core:flight']
      });
      final task = c.journey!.taskById(1, 'core:flight')!;
      expect(task.state, TaskState.done);
      expect(task.ownArrangement, isTrue);
    });
  });

  testWidgets('3.2 Rate your stay sends 1-5 stars', (tester) async {
    final api = FakeGuestApi();
    final c = await _controller(api);
    await _open(tester, RatingForm(controller: c, title: '3.2 Rate your stay'));
    await tester.tap(find.byKey(const Key('star-4')));
    await tester.pump();
    await _primary(tester);
    expect(api.writes.single.$1, 'rating');
    expect(api.writes.single.$2, {'rating': 4, 'note': ''});
    expect(find.text('Thanks for rating'), findsOneWidget);
  });
}
