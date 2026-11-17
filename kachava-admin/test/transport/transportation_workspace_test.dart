import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kachava_admin_dashboard/application/list_query_store.dart';
import 'package:kachava_admin_dashboard/application/resort_settings_controller.dart';
import 'package:kachava_admin_dashboard/core/admin_theme.dart';
import 'package:kachava_admin_dashboard/domain/admin_settings.dart';
import 'package:kachava_admin_dashboard/domain/admin_trip.dart';
import 'package:kachava_admin_dashboard/domain/trip_repository.dart';
import 'package:kachava_admin_dashboard/presentation/components/components.dart';
import 'package:kachava_admin_dashboard/presentation/workspaces/transportation/transportation_workspace.dart';

import '../support/fake_resort_repositories.dart';
import 'fake_transport_repositories.dart';

const _configured = AdminSettings(
  checkInTime: '15:00',
  checkOutTime: '11:00',
  timeZone: 'America/Cancun',
  airports: [
    AirportSetting(code: 'CUN', name: 'Cancun', departureBufferHours: 3)
  ],
  transportAlertLeadHours: 24,
);

class _Harness {
  int settingsOpened = 0;
  int servicesOpened = 0;
}

Future<_Harness> _pump(
  WidgetTester tester,
  TransportRepositories repos, {
  AdminSettings settings = _configured,
  bool isEs = false,
  Size size = const Size(1440, 900),
  bool withServicesLink = true,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final harness = _Harness();
  final resort = ResortSettingsController(FakeSettingsRepository(settings))
    ..load();
  addTearDown(resort.dispose);
  await tester.pumpWidget(MaterialApp(
    theme: KachavaAdminTheme.build(),
    home: Scaffold(
      body: TransportationWorkspace(
        repositories: repos,
        resortSettings: resort,
        queries: ListQueryStore(),
        zoneResolver: testZoneResolver,
        now: () => testNow,
        isEs: isEs,
        onOpenSettings: () => harness.settingsOpened++,
        onOpenServices:
            withServicesLink ? () => harness.servicesOpened++ : null,
      ),
    ),
  ));
  await tester.pumpAndSettle();
  return harness;
}

Finder _row(String id) => find.byKey(Key('row-trips-$id'));

Future<void> _tapKey(WidgetTester tester, String key) async {
  await tester.ensureVisible(find.byKey(Key(key)));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(Key(key)));
  await tester.pumpAndSettle();
}

Future<void> _type(WidgetTester tester, String key, String text) async {
  await tester.ensureVisible(find.byKey(Key(key)));
  await tester.enterText(find.byKey(Key(key)), text);
  await tester.pump();
}

Future<void> _choose(WidgetTester tester, String key, String label) async {
  await _tapKey(tester, key);
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
}

/// Resort 2026-11-03 10:00 (UTC-5): today = Nov 3, tomorrow = Nov 4.
FakeTripRepository _tripsAroundToday() => FakeTripRepository([
      testTrip(
          id: 'today',
          guest: 'Ana Ruiz',
          villa: 'Casa Ceiba',
          pickupAt: DateTime.utc(2026, 11, 3, 17),
          flightNumber: 'AM 512',
          providerId: 'p1',
          unconfirmedDue: true),
      testTrip(
          id: 'tomorrow',
          guest: 'Bea Soto',
          type: 'LOCAL',
          status: 'CONFIRMED',
          pickupAt: DateTime.utc(2026, 11, 4, 14),
          providerId: 'p1',
          driver: const TripDriver(name: 'Luis', phone: '+52 1')),
      testTrip(
          id: 'later',
          guest: 'Carl Diaz',
          type: 'DEPARTURE',
          pickupAt: DateTime.utc(2026, 11, 7, 14)),
    ]);

void main() {
  group('Trips list', () {
    testWidgets('defaults to today + tomorrow, 6 columns in resort time',
        (tester) async {
      final trips = _tripsAroundToday();
      await _pump(
          tester,
          fakeTransport(
              trips: trips,
              providers: FakeProviderRepository(
                  [testProvider('p1', 'Cancun Shuttles')])));
      final query = trips.queries.first;
      expect(query.filters[TripDateRange.filterKey], '2026-11-03..2026-11-04');
      expect(query.sort?.wireValue, 'pickupAt:asc');
      final table = tester.widget<AdminDataTable<AdminTrip>>(
          find.byType(AdminDataTable<AdminTrip>));
      expect(table.columns.map((c) => c.label).toList(), [
        'Pickup',
        'Guest · Villa',
        'Type',
        'Flight',
        'Provider / Driver',
        'Status',
      ]);
      expect(_row('today'), findsOneWidget);
      expect(_row('tomorrow'), findsOneWidget);
      expect(_row('later'), findsNothing);
      expect(find.text('Nov 3 · 12:00'), findsOneWidget);
      expect(find.text('Ana Ruiz · Casa Ceiba'), findsOneWidget);
      expect(find.text('AM 512'), findsOneWidget);
      expect(find.text('Cancun Shuttles'), findsOneWidget);
      expect(find.text('Cancun Shuttles · Luis'), findsOneWidget);
      expect(find.text('Requested'), findsOneWidget);
      expect(find.text('REQUESTED'), findsNothing);
      // Only the due trip carries the error chip.
      expect(find.byKey(const Key('unconfirmed-today')), findsOneWidget);
      expect(find.byKey(const Key('unconfirmed-tomorrow')), findsNothing);
      expect(find.byKey(const Key('trips-settings-missing')), findsNothing);
    });

    testWidgets('date, status, type filters and search reach the query',
        (tester) async {
      final trips = _tripsAroundToday();
      await _pump(tester, fakeTransport(trips: trips));
      await tester.tap(find.byKey(const Key('filter-trips-range')));
      await tester.pumpAndSettle();
      await tester.tap(find
          .widgetWithText(CheckedPopupMenuItem<String>, 'Next 7 days')
          .last);
      await tester.pumpAndSettle();
      expect(trips.queries.last.filters[TripDateRange.filterKey],
          '2026-11-03..2026-11-09');
      expect(_row('later'), findsOneWidget);

      await tester.tap(find.byKey(const Key('filter-trips-type')));
      await tester.pumpAndSettle();
      await tester.tap(
          find.widgetWithText(CheckedPopupMenuItem<String>, 'Departure').last);
      await tester.pumpAndSettle();
      expect(trips.queries.last.filters['type'], 'DEPARTURE');
      expect(_row('today'), findsNothing);
      expect(_row('later'), findsOneWidget);

      await tester.tap(find.byKey(const Key('clear-filters-trips')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('search-trips')), 'am512');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      expect(trips.queries.last.q, 'am512');
      expect(_row('today'), findsOneWidget);
      expect(_row('tomorrow'), findsNothing);
    });

    testWidgets('no time zone: one setup line, no date window', (tester) async {
      final trips = _tripsAroundToday();
      final harness = await _pump(tester, fakeTransport(trips: trips),
          settings: const AdminSettings());
      expect(find.text('Time zone not set'), findsOneWidget);
      expect(trips.queries.first.filters, isEmpty);
      expect(find.byKey(const Key('filter-trips-range')), findsNothing);
      // Without a zone, times say UTC instead of guessing.
      expect(find.text('Nov 3 · 17:00 UTC'), findsOneWidget);
      await tester.tap(find.byKey(const Key('setup-in-settings')));
      expect(harness.settingsOpened, 1);
    });

    testWidgets('SETTINGS_REQUIRED from the API shows the setup line',
        (tester) async {
      final trips = _tripsAroundToday()
        ..failList = const SettingsRequiredException(['timeZone']);
      await _pump(tester, fakeTransport(trips: trips));
      expect(find.byKey(const Key('trips-settings-missing')), findsOneWidget);
      expect(find.text('Time zone not set'), findsOneWidget);
    });

    testWidgets('empty window: one line with "Clear filters"', (tester) async {
      await _pump(tester, fakeTransport());
      expect(find.text('No results'), findsOneWidget);
      expect(find.byKey(const Key('primary-trips')), findsOneWidget);
    });

    testWidgets('Spanish labels', (tester) async {
      await _pump(tester, fakeTransport(trips: _tripsAroundToday()),
          isEs: true);
      expect(find.text('Viajes'), findsWidgets);
      expect(find.text('Proveedores'), findsOneWidget);
      expect(find.text('3 nov · 12:00'), findsOneWidget);
      expect(find.text('Sin confirmar'), findsOneWidget);
      expect(find.text('Nuevo viaje'), findsOneWidget);
    });
  });

  group('Trip detail and status flow', () {
    testWidgets('one next action at a time, then cancel with a reason',
        (tester) async {
      final trips = _tripsAroundToday();
      await _pump(
          tester,
          fakeTransport(
              trips: trips,
              providers: FakeProviderRepository([
                testProvider('p1', 'Cancun Shuttles'),
                testProvider('p2', 'Old Cabs', isActive: false),
              ])));
      await tester.tap(_row('today'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('trip-stepper')), findsOneWidget);
      expect(find.byKey(const Key('trip-history')), findsOneWidget);
      expect(find.byKey(const Key('trip-unconfirmed')), findsOneWidget);
      expect(find.text('Send to provider'), findsOneWidget);

      // Send to provider: the trip's active provider is preselected.
      await _tapKey(tester, 'trip-next-action');
      expect(find.byKey(const Key('trip-send-dialog')), findsOneWidget);
      expect(find.text('Old Cabs'), findsNothing);
      await _tapKey(tester, 'trip-dialog-confirm');
      expect(trips.moves.last.$2.toJson(),
          {'to': 'SENT_TO_PROVIDER', 'providerId': 'p1'});
      expect(find.text('Trip · Sent to provider'), findsOneWidget);

      // Confirm needs driver name and phone.
      await _tapKey(tester, 'trip-next-action');
      await _tapKey(tester, 'trip-dialog-confirm');
      expect(find.text('Required'), findsNWidgets(2));
      await _type(tester, 'trip-driver-name', 'Luis');
      await _type(tester, 'trip-driver-phone', '+52 984 000');
      await _type(tester, 'trip-vehicle-plate', 'ABC-123');
      await _tapKey(tester, 'trip-dialog-confirm');
      expect(trips.moves.last.$2.toJson(), {
        'to': 'CONFIRMED',
        'driver': {'name': 'Luis', 'phone': '+52 984 000'},
        'vehicle': {'description': '', 'plate': 'ABC-123'},
      });
      expect(find.byKey(const Key('trip-unconfirmed')), findsNothing);
      expect(find.text('En route'), findsWidgets);

      await _tapKey(tester, 'trip-next-action');
      expect(trips.moves.last.$2.to, 'EN_ROUTE');
      expect(find.text('Complete'), findsOneWidget);

      // Cancel from the ⋮ menu: the reason is required.
      await _tapKey(tester, 'trip-actions');
      await _tapKey(tester, 'trip-action-cancel');
      await _tapKey(tester, 'trip-dialog-confirm');
      expect(find.text('Required'), findsOneWidget);
      await _type(tester, 'trip-cancel-reason', 'Flight cancelled');
      await _tapKey(tester, 'trip-dialog-confirm');
      expect(trips.moves.last.$2.toJson(),
          {'to': 'CANCELLED', 'reason': 'Flight cancelled'});
      expect(find.text('Trip cancelled'), findsOneWidget);
      // Final: no next action, no menu.
      expect(find.byKey(const Key('trip-next-action')), findsNothing);
      expect(find.byKey(const Key('trip-actions')), findsNothing);
      expect(find.textContaining('Flight cancelled'), findsWidgets);
    });

    testWidgets('a refused move keeps the trip and shows one line',
        (tester) async {
      final trips = _tripsAroundToday();
      await _pump(tester, fakeTransport(trips: trips));
      await tester.tap(_row('tomorrow'));
      await tester.pumpAndSettle();
      trips.failWrite = Exception('422');
      await _tapKey(tester, 'trip-next-action');
      expect(find.text("Couldn't update"), findsOneWidget);
      expect(trips.trips[1].status, 'CONFIRMED');
    });
  });

  group('New trip', () {
    FakeTransportCatalog catalog() => FakeTransportCatalog(
          services: [testTransportService('svc1', 'Airport transfer')],
          items: {
            'svc1': [testVehicle('van', 'Van', 6)],
          },
        );

    FakeStayList stays() => FakeStayList([
          testStay('stay1', 'Ana Ruiz', 'Casa Ceiba'),
          testStay('stay2', 'Old Guest', 'Casa Luna', status: 'CHECKED_OUT'),
        ]);

    Future<void> pickStay(WidgetTester tester) async {
      await _type(tester, 'trip-stay', 'ana');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ana Ruiz · Casa Ceiba').last);
      await tester.pumpAndSettle();
    }

    testWidgets('departure without pickup: backend suggestion in the toast',
        (tester) async {
      final trips = FakeTripRepository();
      await _pump(tester,
          fakeTransport(trips: trips, services: catalog(), stays: stays()));
      await _tapKey(tester, 'primary-trips');
      await _tapKey(tester, 'form-save');
      expect(find.text('Pick a stay'), findsOneWidget);
      expect(trips.created, isEmpty);

      await pickStay(tester);
      await _choose(tester, 'trip-vehicle', 'Van · 6 passengers');
      await _choose(tester, 'trip-type', 'Departure');
      await _type(tester, 'trip-airline', 'Aeromexico');
      await _type(tester, 'trip-flight-number', 'AM 512');
      await _type(tester, 'trip-flight-time', '2026-11-05 12:00');
      await _type(tester, 'trip-passengers', '9');
      await _tapKey(tester, 'form-save');
      expect(find.text('Max 6'), findsOneWidget);
      await _type(tester, 'trip-passengers', '2');
      await _tapKey(tester, 'form-save');

      expect(trips.created.single.toJson(), {
        'stayId': 'stay1',
        'serviceId': 'svc1',
        'itemId': 'van',
        'type': 'DEPARTURE',
        'airportCode': 'CUN',
        'flight': {
          'airline': 'Aeromexico',
          'number': 'AM 512',
          'scheduledAt': '2026-11-05T12:00',
        },
        'passengers': 2,
        'luggage': 0,
      });
      // Flight 12:00 − 3 h airport buffer, computed by the backend.
      expect(find.text('Trip created · Pickup Nov 5 · 09:00'), findsOneWidget);
      expect(find.byKey(const Key('detail-panel')), findsNothing);
    });

    testWidgets('local trip needs origin, destination and pickup',
        (tester) async {
      final trips = FakeTripRepository();
      await _pump(tester,
          fakeTransport(trips: trips, services: catalog(), stays: stays()));
      await _tapKey(tester, 'primary-trips');
      await pickStay(tester);
      await _choose(tester, 'trip-type', 'Local');
      expect(find.byKey(const Key('trip-airline')), findsNothing);
      await _tapKey(tester, 'form-save');
      expect(find.text('Required'), findsNWidgets(3));
      await _type(tester, 'trip-origin', 'Villa');
      await _type(tester, 'trip-destination', 'Tulum');
      await _type(tester, 'trip-pickup', '2026-11-03 25:00');
      await _tapKey(tester, 'form-save');
      expect(find.text('Use YYYY-MM-DD HH:mm'), findsOneWidget);
      await _type(tester, 'trip-pickup', '2026-11-03 16:30');
      await _tapKey(tester, 'form-save');
      final sent = trips.created.single.toJson();
      expect(sent['type'], 'LOCAL');
      expect(sent['origin'], 'Villa');
      expect(sent['destination'], 'Tulum');
      expect(sent['pickupAt'], '2026-11-03T16:30');
      expect(sent['roundTrip'], false);
      expect(sent.containsKey('flight'), isFalse);
    });

    testWidgets('SETTINGS_REQUIRED on save: form stays open with the link',
        (tester) async {
      final trips = FakeTripRepository()
        ..failWrite = const SettingsRequiredException(['airports.CUN']);
      final harness = await _pump(tester,
          fakeTransport(trips: trips, services: catalog(), stays: stays()));
      await _tapKey(tester, 'primary-trips');
      await pickStay(tester);
      await _type(tester, 'trip-airline', 'Aeromexico');
      await _type(tester, 'trip-flight-number', 'AM 1');
      await _type(tester, 'trip-flight-time', '2026-11-05 12:00');
      await _tapKey(tester, 'form-save');
      expect(find.byKey(const Key('form-save-error')), findsOneWidget);
      expect(find.text('Settings incomplete'), findsOneWidget);
      await tester
          .tap(find.widgetWithText(SnackBarAction, 'Set up in Settings'));
      expect(harness.settingsOpened, 1);
      // The inline link sits at the top of the (still open) form.
      await tester.drag(
          find.byKey(const Key('form-panel-fields')), const Offset(0, 2000));
      await tester.pumpAndSettle();
      expect(
          find.byKey(const Key('trip-form-settings-missing')), findsOneWidget);
    });

    testWidgets('no transport services: one line', (tester) async {
      await _pump(tester, fakeTransport());
      await _tapKey(tester, 'primary-trips');
      expect(find.text('No transport services'), findsOneWidget);
    });
  });

  group('Providers and Services tabs', () {
    testWidgets('create, edit and deactivate a provider', (tester) async {
      final providers = FakeProviderRepository();
      await _pump(tester, fakeTransport(providers: providers));
      await _tapKey(tester, 'transport-tab-providers');
      expect(find.text('No providers yet'), findsOneWidget);

      await _tapKey(tester, 'primary-providers');
      await _type(tester, 'provider-email', 'bad');
      await _tapKey(tester, 'form-save');
      expect(find.text('Required'), findsOneWidget);
      expect(find.text('Invalid email'), findsOneWidget);
      await _type(tester, 'provider-name', 'Cancun Shuttles');
      await _type(tester, 'provider-phone', '+52 998 000');
      await _type(tester, 'provider-email', 'ops@shuttles.test');
      await _tapKey(tester, 'form-save');
      expect(find.text('Provider saved'), findsOneWidget);
      expect(providers.providers.single.toWriteJson(), {
        'name': 'Cancun Shuttles',
        'phone': '+52 998 000',
        'email': 'ops@shuttles.test',
        'isActive': true,
      });
      expect(find.byKey(const Key('row-providers-prov-1')), findsOneWidget);

      await tester.tap(find.byKey(const Key('row-providers-prov-1')));
      await tester.pumpAndSettle();
      await _type(tester, 'provider-phone', '+52 998 111');
      await _tapKey(tester, 'form-save');
      expect(providers.providers.single.phone, '+52 998 111');

      await tester.tap(find.byKey(const Key('row-providers-prov-1')));
      await tester.pumpAndSettle();
      await _tapKey(tester, 'provider-actions');
      await _tapKey(tester, 'provider-action-deactivate');
      await _tapKey(tester, 'confirm-dialog-confirm');
      expect(providers.providers.single.isActive, isFalse);
      expect(find.text('Provider deactivated'), findsOneWidget);
      expect(find.text('Inactive'), findsOneWidget);
    });

    testWidgets('Services tab: one line + link to Services', (tester) async {
      final harness = await _pump(tester, fakeTransport());
      await _tapKey(tester, 'transport-tab-services');
      expect(find.text('Managed in Services'), findsOneWidget);
      await tester.tap(find.text('Open Services'));
      expect(harness.servicesOpened, 1);
    });

    testWidgets('Services tab without the Services screen: line only',
        (tester) async {
      await _pump(tester, fakeTransport(), withServicesLink: false);
      await _tapKey(tester, 'transport-tab-services');
      expect(find.text('Managed in Services'), findsOneWidget);
      expect(find.text('Open Services'), findsNothing);
    });
  });

  testWidgets('mobile: compact rows, full-screen detail', (tester) async {
    await _pump(tester, fakeTransport(trips: _tripsAroundToday()),
        size: const Size(375, 800));
    expect(find.text('Ana Ruiz · Casa Ceiba'), findsOneWidget);
    await tester.tap(find.text('Ana Ruiz · Casa Ceiba'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('trip-stepper')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
