import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kachava_guest_portal/application/portal_controller.dart';
import 'package:kachava_guest_portal/core/platform/phone_dialer.dart';
import 'package:kachava_guest_portal/core/storage/device_prefs.dart';
import 'package:kachava_guest_portal/domain/json_read.dart';
import 'package:kachava_guest_portal/domain/requests.dart';

import 'support/fake_guest_api.dart';
import 'support/fake_realtime_port.dart';
import 'support/fixtures.dart';

const Json _driver = {'name': 'Test Driver', 'phone': '+52 200'};
const Json _vehicle = {'description': 'White van', 'plate': 'TST-1'};

Json _line(String id, String name, int qty, double total) => {
      'orderItemId': id,
      'serviceId': 'stock',
      'catalogItemId': 'i-$id',
      'itemName': {'en': name, 'es': name},
      'quantity': qty,
      'lineTotalUSD': total,
      'provisioningStatus': 'Pending',
      'createdAt': '2026-11-02T09:00:00Z',
    };

Future<FakeGuestApi> _requests(WidgetTester tester, FakeGuestApi api,
    {Size size = const Size(390, 844)}) async {
  await pumpPortal(tester, api: api, size: size);
  await tester.tap(find.descendant(
      of: find.byKey(const Key('portal-tabs')),
      matching: find.text('Requests')));
  await tester.pumpAndSettle();
  return api;
}

Finder _inCard(String id, Finder f) =>
    find.descendant(of: find.byKey(Key('request-$id')), matching: f);

Finder _inSheet(String id, Finder f) =>
    find.descendant(of: find.byKey(Key('request-sheet-$id')), matching: f);

Future<void> _open(WidgetTester tester, String id) async {
  await tester.tap(find.byKey(Key('request-$id')));
  await tester.pumpAndSettle();
}

void main() {
  test('driver phone becomes a tel: link with digits only', () {
    expect(telUri('+52 (998) 123-4567').toString(), 'tel:+529981234567');
    expect(telUri('998 123 4567').toString(), 'tel:9981234567');
  });

  testWidgets(
      'an order shows its lines on the card and lines + total in detail',
      (tester) async {
    await _requests(
        tester,
        FakeGuestApi(
          stay: stayJson(larder: [
            _line('l1', 'Mineral water', 2, 6),
            _line('l2', 'Artisan bread', 1, 5),
          ]),
          catalog: fullCatalog(),
        ));
    expect(
        _inCard(
            'order:stock', find.text('2 × Mineral water, 1 × Artisan bread')),
        findsOneWidget);
    expect(_inCard('order:stock', find.text('Ordered Mon Nov 2 · 04:00')),
        findsOneWidget);
    await _open(tester, 'order:stock');
    expect(_inSheet('order:stock', find.text('2 × Mineral water')),
        findsOneWidget);
    expect(_inSheet('order:stock', find.text('\$6 USD')), findsOneWidget);
    expect(_inSheet('order:stock', find.text('\$11 USD')), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('a preference shows the option chosen', (tester) async {
    await _requests(
        tester,
        FakeGuestApi(
          stay: stayJson(bookings: [
            bookingJson('p1', 'pillow',
                usageType: 'PREFERENCE',
                section: 'IN_VILLA',
                date: '',
                slot: '',
                itemId: 'goose',
                lines: const [
                  {
                    'itemId': 'goose',
                    'name': {'en': 'Goose down', 'es': 'Pluma de ganso'},
                    'quantity': 1,
                  }
                ]),
            bookingJson('p2', 'pillow',
                usageType: 'PREFERENCE',
                section: 'IN_VILLA',
                date: '',
                slot: '',
                itemId: 'firm',
                createdAt: '2026-10-01T10:00:00Z'),
          ]),
          catalog: fullCatalog(),
        ));
    expect(
        _inCard('booking:p1', find.textContaining('Svc pillow · Goose down')),
        findsOneWidget);
    expect(_inCard('booking:p2', find.textContaining('Svc pillow · Firm')),
        findsOneWidget,
        reason: 'option name falls back to the catalog item');
    await unmount(tester);
  });

  testWidgets('a trip shows day and time first, the flight second',
      (tester) async {
    await _requests(
        tester, FakeGuestApi(catalog: fullCatalog(), trips: [tripJson('t1')]));
    expect(_inCard('trip:t1', find.text('Tue Nov 3 · 14:30 · 3 guests')),
        findsOneWidget);
    expect(
        _inCard('trip:t1', find.text('Flight AA 1482 · CUN')), findsOneWidget);
    expect(_inCard('trip:t1', find.text('Received')), findsOneWidget);
    expect(find.byKey(const Key('trip-driver')), findsNothing);
    await _open(tester, 'trip:t1');
    expect(_inSheet('trip:t1', find.text('Tue Nov 3 · 14:30 · 3 guests')),
        findsOneWidget);
    expect(find.byKey(const Key('trip-driver')), findsNothing,
        reason: 'no driver before confirmation');
    await unmount(tester);
  });

  testWidgets('sent to the provider reads Arranging', (tester) async {
    await _requests(
        tester,
        FakeGuestApi(
            catalog: fullCatalog(),
            trips: [tripJson('t1', status: 'SENT_TO_PROVIDER')]));
    expect(_inCard('trip:t1', find.text('Arranging')), findsOneWidget);
    expect(find.text('SENT_TO_PROVIDER'), findsNothing);
    await unmount(tester);
  });

  testWidgets('a confirmed trip shows driver, tappable phone, vehicle, plate',
      (tester) async {
    await _requests(
        tester,
        FakeGuestApi(catalog: fullCatalog(), trips: [
          tripJson('t1',
              status: 'CONFIRMED', driver: _driver, vehicle: _vehicle)
        ]));
    expect(_inCard('trip:t1', find.text('Driver Test Driver · White van')),
        findsOneWidget);
    await _open(tester, 'trip:t1');
    final block = find.byKey(const Key('trip-driver'));
    expect(find.descendant(of: block, matching: find.text('Test Driver')),
        findsOneWidget);
    expect(find.descendant(of: block, matching: find.text('White van · TST-1')),
        findsOneWidget);
    final phone = find.byKey(const Key('trip-driver-phone'));
    expect(find.descendant(of: phone, matching: find.text('+52 200')),
        findsOneWidget);
    expect(tester.getSize(phone).height, greaterThanOrEqualTo(48));
    await tester.tap(phone);
    await tester.pumpAndSettle();
    await unmount(tester);
  });

  testWidgets('cancelled requests show the reason', (tester) async {
    await _requests(
        tester,
        FakeGuestApi(
          stay: stayJson(bookings: [
            bookingJson('b1', 'spa',
                status: 'CANCELLED', cancellationReason: 'Heavy rain'),
          ]),
          catalog: fullCatalog(),
          trips: [
            tripJson('t1',
                status: 'CANCELLED', cancellationReason: 'Cancelled by guest')
          ],
        ));
    expect(_inCard('booking:b1', find.text('Heavy rain')), findsOneWidget);
    expect(_inCard('trip:t1', find.text('Cancelled by you')), findsOneWidget);
    await _open(tester, 'booking:b1');
    expect(_inSheet('booking:b1', find.text('Heavy rain')), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('a status change re-renders the card with the driver',
      (tester) async {
    final api = await _requests(
        tester, FakeGuestApi(catalog: fullCatalog(), trips: [tripJson('t1')]));
    expect(_inCard('trip:t1', find.text('Received')), findsOneWidget);
    api.tripsJson = [
      tripJson('t1', status: 'CONFIRMED', driver: _driver, vehicle: _vehicle)
    ];
    await tester.tap(find.byKey(const Key('guest-refresh-button')));
    await tester.pumpAndSettle();
    expect(_inCard('trip:t1', find.text('Confirmed')), findsOneWidget);
    expect(_inCard('trip:t1', find.text('Driver Test Driver · White van')),
        findsOneWidget);
    api.tripsJson = [
      tripJson('t1', status: 'EN_ROUTE', driver: _driver, vehicle: _vehicle)
    ];
    await tester.tap(find.byKey(const Key('guest-refresh-button')));
    await tester.pumpAndSettle();
    expect(_inCard('trip:t1', find.text('On the way')), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('a realtime signal re-fetches trips (ADR-012)', (tester) async {
    final api = FakeGuestApi(
      stay: {
        ...stayJson(),
        'realtime': {'channel': 'ch-1', 'global': 'global'},
      },
      trips: [tripJson('t1')],
    );
    final port = FakeRealtimePort();
    final c = PortalController(
      api: api,
      prefs: MemoryDevicePrefs(),
      initialUri: portalUri(),
      realtime: port,
      onPageVisible: FakeVisibility().onVisible,
      realtimeRetry: const Duration(seconds: 5),
    );
    await c.start();
    await tester.pump();
    port.connect();
    await tester.pump(const Duration(seconds: 1));
    api.tripsJson = [
      tripJson('t1', status: 'CONFIRMED', driver: _driver, vehicle: _vehicle)
    ];
    port.change();
    await tester.pump(const Duration(seconds: 1));
    final trip = c.requests.single;
    expect(trip.status, RequestStatus.confirmed);
    expect(trip.trip!.driverPhone, '+52 200');
    expect(trip.trip!.plate, 'TST-1');
    c.dispose();
  });

  for (final lang in ['en', 'es']) {
    testWidgets('long request cards and detail fit 375px ($lang)',
        (tester) async {
      final api = FakeGuestApi(
        stay: stayJson(larder: [
          for (var i = 0; i < 6; i++)
            _line('l$i', 'Extra virgin olive oil from Yucatán $i', 3, 24.5),
        ]),
        catalog: fullCatalog(),
        trips: [
          tripJson('t1', status: 'CONFIRMED', driver: const {
            'name': 'Maximiliano Hernández de la Cruz',
            'phone': '+52 998 123 4567'
          }, vehicle: const {
            'description': 'Chevrolet Suburban Premier black',
            'plate': 'YUC-123-A'
          })
        ],
      );
      await pumpPortal(tester,
          api: api,
          size: const Size(375, 812),
          prefs: MemoryDevicePrefs(browserLanguage: lang));
      await tester.tap(find.descendant(
          of: find.byKey(const Key('portal-tabs')),
          matching: find.text(lang == 'es' ? 'Solicitudes' : 'Requests')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await _open(tester, 'trip:t1');
      expect(tester.takeException(), isNull);
      await unmount(tester);
    });
  }
}
