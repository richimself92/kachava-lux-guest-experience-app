import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kachava_admin_dashboard/application/list_query_store.dart';
import 'package:kachava_admin_dashboard/core/admin_theme.dart';
import 'package:kachava_admin_dashboard/domain/guest_profile.dart';
import 'package:kachava_admin_dashboard/domain/reservation.dart';
import 'package:kachava_admin_dashboard/presentation/operations/reservations/reservations_screen.dart';

import '../support/fake_operations.dart';
import '../support/fake_resort_repositories.dart';
import 'recorded_operations_contract.dart';

void main() {
  late FakeReservationRepository reservations;
  late FakeGuestRepository guests;
  late ListQueryStore store;
  late List<String> clipboard;
  late List<ReservationRow> openedTrips;

  setUp(() {
    reservations = FakeReservationRepository()
      ..rows.addAll([
        testRow('stay_a', guest: 'Ana Ruiz'),
        testRow('stay_b',
            guest: 'Bruno Diaz',
            status: StayValues.inHouse,
            host: 'Lucia Host'),
      ])
      ..folioView = StayFolio.fromJson(recordedFolio);
    guests = FakeGuestRepository()
      ..profiles['stay_a'] = GuestProfile.fromJson(recordedGuestProfile);
    store = ListQueryStore();
    clipboard = [];
    openedTrips = [];
  });

  Future<void> pump(WidgetTester tester, {String? openId}) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') {
        clipboard.add((call.arguments as Map)['text'] as String);
      }
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null));
    await tester.pumpWidget(MaterialApp(
      theme: KachavaAdminTheme.build(),
      home: Scaffold(
        body: ReservationsScreen(
          reservations: reservations,
          guests: guests,
          villas: FakeVillaRepository(generatedVillas(3)),
          queries: store,
          staff: const [testStaff],
          isEs: false,
          today: '2026-11-03',
          openId: openId,
          onOpenTrips: openedTrips.add,
        ),
      ),
    ));
    await tester.pumpAndSettle();
  }

  Future<void> openRow(WidgetTester tester, String id) async {
    await tester.tap(find.byKey(Key('row-reservations-$id')));
    await tester.pumpAndSettle();
  }

  testWidgets('table: 6 columns, arrival sort by default, filters',
      (tester) async {
    await pump(tester);
    for (final h in [
      'Guest',
      'Villa',
      'Arrival',
      'Departure',
      'Status',
      'Resort Host'
    ]) {
      expect(find.text(h), findsWidgets, reason: h);
    }
    expect(reservations.queries.first.sort?.wireValue, 'checkIn:asc');
    expect(find.text('Nov 3'), findsWidgets);
    expect(find.text('Unassigned'), findsOneWidget);
    expect(find.text('Lucia Host'), findsOneWidget);
    for (final f in ['status', 'villaId', 'range']) {
      expect(find.byKey(Key('filter-reservations-$f')), findsOneWidget,
          reason: f);
    }
  });

  testWidgets('Summary: copy link, Wi-Fi, host and notes save as one PATCH',
      (tester) async {
    await pump(tester);
    await openRow(tester, 'stay_a');
    expect(find.text('Summary'), findsOneWidget);
    expect(find.text('Folio'), findsOneWidget);
    await tester.tap(find.byKey(const Key('reservation-copy-link')));
    await tester.pumpAndSettle();
    expect(clipboard, ['https://guest.test/?guestId=stay_a']);
    expect(find.text('Link copied'), findsOneWidget);

    await tester.enterText(
        find.byKey(const Key('reservation-notes')), 'Late arrival');
    await tester.ensureVisible(find.byKey(const Key('reservation-save')));
    await tester.tap(find.byKey(const Key('reservation-save')));
    await tester.pumpAndSettle();
    expect(reservations.patches.single.$1, 'stay_a');
    expect(reservations.patches.single.$2, {'internalNotes': 'Late arrival'});
  });

  testWidgets('Check in asks to confirm, then sends CHECK_IN', (tester) async {
    await pump(tester);
    await openRow(tester, 'stay_a');
    await tester.tap(find.byKey(const Key('reservation-next-action')));
    await tester.pumpAndSettle();
    expect(find.text('Check in Ana Ruiz?'), findsOneWidget);
    await tester.tap(find.byKey(const Key('confirm-dialog-confirm')));
    await tester.pumpAndSettle();
    expect(reservations.patches.single.$2, {'action': 'CHECK_IN'});
    expect(find.text('Check out'), findsOneWidget);
  });

  testWidgets('Cancel needs a reason (⋮ menu)', (tester) async {
    await pump(tester);
    await openRow(tester, 'stay_a');
    await tester.tap(find.byKey(const Key('reservation-actions')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('reservation-action-cancel')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('input-dialog-confirm')));
    await tester.pumpAndSettle();
    expect(find.text('Required'), findsOneWidget);
    expect(reservations.patches, isEmpty);
    await tester.enterText(
        find.byKey(const Key('reservation-cancel-reason')), 'No show');
    await tester.tap(find.byKey(const Key('input-dialog-confirm')));
    await tester.pumpAndSettle();
    expect(reservations.patches.single.$2,
        {'action': 'CANCEL', 'reason': 'No show'});
  });

  testWidgets('Preferences, Trips and Folio tabs', (tester) async {
    await pump(tester);
    await openRow(tester, 'stay_a');
    await tester.tap(find.text('Preferences'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('guest-allergies')), findsOneWidget);
    expect(find.text('Goose down'), findsOneWidget);

    await tester.tap(find.text('Trips'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('reservation-trip-trip_1')), findsOneWidget);
    await tester.tap(find.byKey(const Key('reservation-open-transportation')));
    expect(openedTrips.single.id, 'stay_a');

    await tester.tap(find.text('Folio'));
    await tester.pumpAndSettle();
    expect(find.text('Cenote tour'), findsWidgets);
    expect(find.text(r'$1,234.50 USD'), findsOneWidget);
    expect(find.text('5/5 · Lovely'), findsOneWidget);
    expect(find.text('No PMS integration'), findsOneWidget);
  });

  testWidgets('+ New reservation: required fields, then POST', (tester) async {
    await pump(tester);
    await tester.tap(find.byKey(const Key('primary-reservations')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('form-save')));
    await tester.pumpAndSettle();
    expect(find.text('Required'), findsWidgets);
    expect(reservations.creates, isEmpty);

    await tester.enterText(
        find.byKey(const Key('reservation-guest')), 'Carla Gomez');
    await tester.tap(find.byKey(const Key('reservation-villa')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Villa 01').last);
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const Key('reservation-check-in')), '2026-11-10');
    await tester.enterText(
        find.byKey(const Key('reservation-check-out')), '2026-11-09');
    await tester.tap(find.byKey(const Key('form-save')));
    await tester.pumpAndSettle();
    expect(find.text('After arrival date'), findsOneWidget);

    await tester.enterText(
        find.byKey(const Key('reservation-check-out')), '2026-11-12');
    await tester.tap(find.byKey(const Key('form-save')));
    await tester.pumpAndSettle();
    expect(reservations.creates.single, {
      'guestName': 'Carla Gomez',
      'villaId': 'v1',
      'checkIn': '2026-11-10',
      'checkOut': '2026-11-12',
    });
    expect(find.text('Reservation created'), findsOneWidget);
  });

  testWidgets('openId opens that stay on arrival', (tester) async {
    await pump(tester, openId: 'stay_b');
    expect(find.byKey(const Key('reservation-detail')), findsOneWidget);
    expect(find.text('Bruno Diaz'), findsWidgets);
    expect(find.text('Check out'), findsOneWidget);
  });
}
