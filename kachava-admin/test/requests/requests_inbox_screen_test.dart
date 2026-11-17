import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kachava_admin_dashboard/application/guest_activity_watcher.dart';
import 'package:kachava_admin_dashboard/core/admin_theme.dart';
import 'package:kachava_admin_dashboard/core/resort_time.dart';
import 'package:kachava_admin_dashboard/domain/admin_trip.dart';
import 'package:kachava_admin_dashboard/domain/catalog_values.dart';
import 'package:kachava_admin_dashboard/domain/inbox_item.dart';
import 'package:kachava_admin_dashboard/domain/service_request.dart';
import 'package:kachava_admin_dashboard/presentation/requests/request_inbox_scope.dart';
import 'package:kachava_admin_dashboard/presentation/requests/requests_inbox_screen.dart';

import '../support/fake_service_requests.dart';
import '../transport/fake_transport_repositories.dart';

const _water = ServiceRequestLine(
    name: LocalizedText(en: 'Mineral water', es: 'Agua mineral'), quantity: 2);
const _bread = ServiceRequestLine(
    name: LocalizedText(en: 'Artisan bread', es: 'Pan artesanal'), quantity: 1);
const _gooseDown = ServiceRequestLine(
    name: LocalizedText(en: 'Goose down', es: 'Pluma de ganso'), quantity: 1);

ServiceRequest _named(ServiceRequest r, String service) => ServiceRequest(
      id: r.id,
      isOrder: r.isOrder,
      guestName: r.guestName,
      villaName: r.villaName,
      serviceName: LocalizedText(en: service, es: service),
      at: r.at,
      quantity: r.quantity,
      status: r.status,
      lines: r.lines,
      totalUSD: r.totalUSD,
      usageType: r.usageType,
      section: r.section,
      notes: r.notes,
      createdAt: r.createdAt,
      stayId: 'stay-${r.id}',
    );

void main() {
  late FakeServiceRequestRepository requests;
  late FakeTripRepository trips;
  late FakeProviderRepository providers;
  late GuestActivityWatcher watcher;

  setUp(() {
    requests = FakeServiceRequestRepository()
      ..requests.addAll([
        _named(
            testRequest(1,
                usageType: 'ORDER',
                isOrder: true,
                section: 'IN_VILLA',
                lines: const [_water, _bread],
                createdAt: testNow.subtract(const Duration(minutes: 12))),
            'Villa stocking'),
        _named(
            testRequest(2,
                usageType: 'PREFERENCE',
                section: 'IN_VILLA',
                lines: const [_gooseDown],
                createdAt: testNow.subtract(const Duration(minutes: 45))),
            'Pillow menu'),
        _named(
            testRequest(3,
                usageType: 'BOOKING',
                section: 'WELLNESS',
                status: RequestStatusValues.confirmed,
                notes: 'Strong pressure',
                createdAt: testNow.subtract(const Duration(hours: 3))),
            'Massage'),
      ]);
    trips = FakeTripRepository([
      testTrip(
          id: 't1',
          guest: 'Ana',
          pickupAt: testNow.add(const Duration(days: 1)),
          status: 'SENT_TO_PROVIDER',
          providerId: 'p1'),
    ]);
    providers = FakeProviderRepository([testProvider('p1', 'Cancun Cars')]);
    watcher = GuestActivityWatcher();
  });

  tearDown(() => watcher.dispose());

  Future<void> pump(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final deps = RequestInboxDeps(
        requests: requests, trips: trips, providers: providers);
    await tester.pumpWidget(MaterialApp(
      theme: KachavaAdminTheme.build(),
      home: Scaffold(
        body: RequestsInboxScreen(
          deps: deps,
          watcher: watcher,
          isEs: false,
          resortTime: const ResortTime(
              timeZone: 'America/Cancun', resolver: testZoneResolver),
          now: () => testNow,
        ),
      ),
    ));
    await tester.pumpAndSettle();
  }

  Finder row(String id) => find.byKey(Key('row-requests-inbox-$id'));

  testWidgets('test_inbox_listsInVillaOrderAndPreference_newFirst_withTones',
      (tester) async {
    await pump(tester, const Size(1440, 900));

    expect(find.text('2 × Mineral water, 1 × Artisan bread'), findsOneWidget);
    expect(find.text('Pillow menu: Goose down'), findsOneWidget);
    // New first, oldest waiting first: the preference (45 min) before the order.
    final pref = tester.getTopLeft(row('req_2')).dy;
    final order = tester.getTopLeft(row('req_1')).dy;
    final trip = tester.getTopLeft(row('trip-t1')).dy;
    final booking = tester.getTopLeft(row('req_3')).dy;
    expect(pref < order && order < booking && order < trip, isTrue);
    // Overdue new = urgent tone; new = warning; in progress = info.
    expect(find.byKey(const Key('inbox-chip-error')), findsOneWidget);
    expect(find.byKey(const Key('inbox-chip-warning')), findsOneWidget);
    expect(find.byKey(const Key('inbox-chip-info')), findsNWidgets(2));
    expect(find.text('12 min ago'), findsOneWidget);
    expect(find.text('In villa'), findsNothing);
    expect(find.text('Order · In villa'), findsOneWidget);
    // Unread stripes on new rows only.
    expect(find.byKey(const Key('inbox-unread-req_1')), findsOneWidget);
    expect(find.byKey(const Key('inbox-unread-req_3')), findsNothing);
  });

  testWidgets('test_orderDetail_showsLines_andNextStepsCallTheTransition',
      (tester) async {
    await pump(tester, const Size(1440, 900));
    await tester.tap(row('req_1'));
    await tester.pumpAndSettle();

    expect(find.text('2 × Mineral water\n1 × Artisan bread'), findsOneWidget);
    expect(find.byKey(const Key('inbox-timeline')), findsOneWidget);
    expect(find.byKey(const Key('inbox-unread-req_1')), findsNothing);

    for (final (label, action) in [
      ('Confirm', RequestAction.confirm),
      ('Start preparing', RequestAction.start),
      ('Mark delivered', RequestAction.complete),
    ]) {
      expect(find.widgetWithText(FilledButton, label), findsOneWidget);
      await tester.tap(find.byKey(const Key('inbox-next')));
      await tester.pumpAndSettle();
      expect(requests.moves.last.$2, action);
    }
    expect(find.byKey(const Key('inbox-next')), findsNothing);
  });

  testWidgets('test_preferenceDetail_showsTheChoice_confirmThenMarkDone',
      (tester) async {
    await pump(tester, const Size(1440, 900));
    await tester.tap(row('req_2'));
    await tester.pumpAndSettle();

    expect(find.text('Goose down'), findsOneWidget);
    await tester.tap(find.byKey(const Key('inbox-next')));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(FilledButton, 'Mark done'), findsOneWidget);
    await tester.tap(find.byKey(const Key('inbox-next')));
    await tester.pumpAndSettle();
    expect(requests.moves.map((m) => m.$2),
        [RequestAction.confirm, RequestAction.complete]);
  });

  testWidgets('test_bookingDetail_showsNotes_andCancelAsksAReason',
      (tester) async {
    await pump(tester, const Size(1440, 900));
    await tester.tap(row('req_3'));
    await tester.pumpAndSettle();

    expect(find.text('Strong pressure'), findsOneWidget);
    await tester.tap(find.byKey(const Key('inbox-cancel')));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const Key('inbox-cancel-reason')), 'Guest changed plans');
    await tester.tap(find.byKey(const Key('input-dialog-confirm')));
    await tester.pumpAndSettle();
    expect(requests.moves.single,
        ('req_3', RequestAction.cancel, 'Guest changed plans'));
  });

  testWidgets('test_tripDetail_confirmDriver_sendsDriverAndVehicle',
      (tester) async {
    await pump(tester, const Size(1440, 900));
    await tester.tap(row('trip-t1'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(FilledButton, 'Confirm driver'), findsOneWidget);
    await tester.tap(find.byKey(const Key('inbox-next')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('trip-driver-name')), 'Luis');
    await tester.enterText(find.byKey(const Key('trip-driver-phone')), '998');
    await tester.enterText(
        find.byKey(const Key('trip-vehicle-description')), 'Suburban');
    await tester.enterText(find.byKey(const Key('trip-vehicle-plate')), 'ABC');
    await tester.tap(find.text('Confirm').last);
    await tester.pumpAndSettle();

    final move = trips.moves.single.$2;
    expect((move.to, move.driver?.name, move.vehicle?.plate),
        ('CONFIRMED', 'Luis', 'ABC'));
    expect(find.widgetWithText(FilledButton, 'On the way'), findsOneWidget);
  });

  testWidgets('test_tripRequested_sendToProvider_picksAProvider',
      (tester) async {
    trips.trips[0] = testTrip(
        id: 't1', guest: 'Ana', pickupAt: testNow.add(const Duration(days: 1)));
    await pump(tester, const Size(1440, 900));
    await tester.tap(row('trip-t1'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('inbox-next')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('trip-send-provider')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancun Cars').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Send to provider').last);
    await tester.pumpAndSettle();

    expect(trips.moves.single.$2.toJson(),
        {'to': 'SENT_TO_PROVIDER', 'providerId': 'p1'});
  });

  testWidgets('test_mobile375_listAndDetail_withoutOverflow', (tester) async {
    await pump(tester, const Size(375, 812));
    expect(tester.takeException(), isNull);
    await tester.tap(row('req_1'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('inbox-next')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('test_unknownSection_typeAndSummaryFallbacks', () {
    final item = RequestInboxItem(testRequest(9));
    expect(item.type, InboxType.booking);
    expect(TripValues.flow.first, 'REQUESTED');
  });
}
