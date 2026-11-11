import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kachava_admin_dashboard/data/admin_api_client.dart';
import 'package:kachava_admin_dashboard/data/http_trip_repository.dart';
import 'package:kachava_admin_dashboard/domain/admin_trip.dart';
import 'package:kachava_admin_dashboard/domain/list_query.dart';
import 'package:kachava_admin_dashboard/domain/trip_repository.dart';

import '../support/recorded_contract.dart';
import '../support/signed_in_api_client.dart';
import 'recorded_trip_contract.dart';

/// Captures requests and answers with [respond] (a JSON body, or a full
/// [http.Response] for error statuses).
class _Server {
  _Server(this.respond);

  final Object? Function(http.Request request) respond;
  final List<http.Request> requests = [];

  late final MockClient client = MockClient((request) async {
    requests.add(request);
    final body = respond(request);
    if (body is http.Response) return body;
    return http.Response(jsonEncode(body), 200,
        headers: {'content-type': 'application/json'});
  });

  http.Request get last => requests.last;
  Map<String, dynamic> get lastBody =>
      jsonDecode(last.body) as Map<String, dynamic>;
}

http.Response _status(int code, Map<String, dynamic> body) =>
    http.Response(jsonEncode(body), code,
        headers: {'content-type': 'application/json'});

HttpTripRepository _repo(_Server server) =>
    HttpTripRepository(signedInApiClient(server.client));

void main() {
  group('AdminTrip.fromJson (recorded contract)', () {
    test('maps an airport trip with snapshot, flight and history', () {
      final trip = AdminTrip.fromJson(recordedTrip);
      expect(trip.id, 'trip_5b1e');
      expect(trip.stayId, 'stay_1');
      expect(trip.guestName, 'Ana Ruiz');
      expect(trip.villaName, 'Casa Ceiba');
      expect(trip.type, 'DEPARTURE');
      expect(trip.airportCode, 'CUN');
      expect(trip.flight?.airline, 'Aeromexico');
      expect(trip.flight?.number, 'AM 512');
      expect(trip.flight?.scheduledAt, DateTime.utc(2026, 11, 4, 17));
      expect(trip.pickupAt, DateTime.utc(2026, 11, 4, 14));
      expect(trip.serviceName.en, 'Airport transfer');
      expect(trip.vehicleName.es, 'Camioneta');
      expect(trip.vehicleCapacity?.passengers, 6);
      expect(trip.passengers, 2);
      expect(trip.luggage, 3);
      expect(trip.guestNotes, 'Baby seat');
      expect(trip.notes, 'Gate 3');
      expect(trip.providerId, 'prov_1');
      expect(trip.driver, isNull);
      expect(trip.status, 'SENT_TO_PROVIDER');
      expect(trip.createdBy, 'STAFF');
      expect(trip.unconfirmedDue, isTrue);
      expect(trip.history.map((h) => h.to), ['REQUESTED', 'SENT_TO_PROVIDER']);
      expect(trip.history.first.from, isNull);
      expect(trip.history.last.at, DateTime.utc(2026, 11, 3, 5, 10));
      expect(trip.history.last.by, 'admin@kachava.local');
      expect(trip.nextStatus, 'CONFIRMED');
      expect(trip.isFinal, isFalse);
    });

    test('maps a legacy local trip: no snapshot, driver and vehicle, final',
        () {
      final trip = AdminTrip.fromJson(recordedLocalTrip);
      expect(trip.serviceId, isNull);
      expect(trip.serviceName.isEmpty, isTrue);
      expect(trip.vehicleCapacity, isNull);
      expect(trip.origin, 'Villa');
      expect(trip.destination, 'Tulum ruins');
      expect(trip.roundTrip, isTrue);
      expect(trip.waitMinutes, 90);
      expect(trip.driver?.name, 'Luis');
      expect(trip.driver?.phone, '+52 984 000');
      expect(trip.vehicle?.description, 'White Suburban');
      expect(trip.vehicle?.plate, 'ABC-123');
      expect(trip.cancellationReason, 'Guest changed plans');
      expect(trip.unconfirmedDue, isNull);
      expect(trip.isFinal, isTrue);
      expect(trip.nextStatus, isNull);
    });

    test('a record without id is unconfirmed (FormatException)', () {
      expect(() => AdminTrip.fromJson({...recordedTrip, 'id': null}),
          throwsFormatException);
    });
  });

  group('TripValues', () {
    test('one-step flow; final statuses have no next step', () {
      expect(TripValues.next('REQUESTED'), 'SENT_TO_PROVIDER');
      expect(TripValues.next('SENT_TO_PROVIDER'), 'CONFIRMED');
      expect(TripValues.next('CONFIRMED'), 'EN_ROUTE');
      expect(TripValues.next('EN_ROUTE'), 'COMPLETED');
      expect(TripValues.next('COMPLETED'), isNull);
      expect(TripValues.next('CANCELLED'), isNull);
      expect(TripValues.isAirport('ARRIVAL'), isTrue);
      expect(TripValues.isAirport('LOCAL'), isFalse);
    });
  });

  group('TripDateRange', () {
    test('encodes and parses inclusive resort days', () {
      const range = TripDateRange('2026-11-03', '2026-11-04');
      expect(range.encode(), '2026-11-03..2026-11-04');
      expect(TripDateRange.parse('2026-11-03..2026-11-04'), range);
      expect(TripDateRange.parse('2026-11-03'), isNull);
      expect(TripDateRange.parse('x..y'), isNull);
    });

    test('presets around a resort day', () {
      final presets = TripDateRange.presets('2026-12-31');
      expect(presets.todayAndTomorrow.encode(), '2026-12-31..2027-01-01');
      expect(presets.today.encode(), '2026-12-31..2026-12-31');
      expect(presets.tomorrow.encode(), '2027-01-01..2027-01-01');
      expect(presets.next7Days.encode(), '2026-12-31..2027-01-06');
      expect(presets.last7Days.encode(), '2026-12-24..2026-12-30');
    });
  });

  group('HttpTripRepository (recorded contract)', () {
    test('list sends q/page/sort/filters and turns the range into from/to',
        () async {
      final server = _Server(
          (_) => recordedPage([recordedTrip, recordedLocalTrip], total: 2));
      final query = const ListQuery(sort: ListSort('pickupAt'))
          .withSearch('am512')
          .withFilter('status', 'REQUESTED')
          .withFilter('providerId', 'prov_1')
          .withFilter(TripDateRange.filterKey, '2026-11-03..2026-11-04');
      final result = await _repo(server).list(query);
      expect(server.last.method, 'GET');
      expect(server.last.url.path, '/api/v1/admin/trips');
      expect(server.last.url.queryParameters, {
        'q': 'am512',
        'page': '1',
        'pageSize': '25',
        'sort': 'pickupAt:asc',
        'status': 'REQUESTED',
        'providerId': 'prov_1',
        'from': '2026-11-03',
        'to': '2026-11-04',
      });
      expect(result.total, 2);
      expect(result.items.map((t) => t.id), ['trip_5b1e', 'trip_local']);
    });

    test('get reads one trip', () async {
      final server = _Server((_) => recordedRecord(recordedTrip));
      final trip = await _repo(server).get('trip_5b1e');
      expect(server.last.url.path, '/api/v1/admin/trips/trip_5b1e');
      expect(trip.guestName, 'Ana Ruiz');
    });

    test('create posts only the given fields (departure: no pickup)', () async {
      final server = _Server((_) => recordedRecord(recordedTrip));
      final created = await _repo(server).create(const NewTripRequest(
        stayId: 'stay_1',
        serviceId: 'svc_transfer',
        itemId: 'item_van',
        type: 'DEPARTURE',
        airportCode: 'CUN',
        flight: TripFlightInput(
            airline: 'Aeromexico',
            number: 'AM 512',
            scheduledAt: '2026-11-04T11:00'),
        passengers: 2,
        luggage: 3,
        notes: 'Gate 3',
        providerId: 'prov_1',
      ));
      expect(server.last.method, 'POST');
      expect(server.last.url.path, '/api/v1/admin/trips');
      expect(server.lastBody, {
        'stayId': 'stay_1',
        'serviceId': 'svc_transfer',
        'itemId': 'item_van',
        'type': 'DEPARTURE',
        'airportCode': 'CUN',
        'flight': {
          'airline': 'Aeromexico',
          'number': 'AM 512',
          'scheduledAt': '2026-11-04T11:00',
        },
        'passengers': 2,
        'luggage': 3,
        'notes': 'Gate 3',
        'providerId': 'prov_1',
      });
      expect(created.pickupAt, DateTime.utc(2026, 11, 4, 14));
    });

    test('create of a local trip sends origin, destination, pickup, wait',
        () async {
      final server = _Server((_) => recordedRecord(recordedLocalTrip));
      await _repo(server).create(const NewTripRequest(
        stayId: 'stay_2',
        serviceId: 'svc_local',
        type: 'LOCAL',
        pickupAt: '2026-11-03T09:30',
        origin: 'Villa',
        destination: 'Tulum ruins',
        roundTrip: true,
        waitMinutes: 90,
        passengers: 3,
        guestNotes: 'Water',
      ));
      expect(server.lastBody, {
        'stayId': 'stay_2',
        'serviceId': 'svc_local',
        'type': 'LOCAL',
        'pickupAt': '2026-11-03T09:30',
        'origin': 'Villa',
        'destination': 'Tulum ruins',
        'roundTrip': true,
        'waitMinutes': 90,
        'passengers': 3,
        'guestNotes': 'Water',
      });
    });

    test('transition posts the one-step move with driver and vehicle',
        () async {
      final server = _Server((_) => recordedRecord(
          {...recordedTrip, 'status': 'CONFIRMED', 'unconfirmedDue': false}));
      final trip = await _repo(server).transition(
          'trip_5b1e',
          const TripTransition(
            to: 'CONFIRMED',
            driver: TripDriver(name: 'Luis', phone: '+52 984 000'),
            vehicle: TripVehicle(description: 'Van', plate: 'ABC-123'),
          ));
      expect(server.last.method, 'POST');
      expect(server.last.url.path, '/api/v1/admin/trips/trip_5b1e/transition');
      expect(server.lastBody, {
        'to': 'CONFIRMED',
        'driver': {'name': 'Luis', 'phone': '+52 984 000'},
        'vehicle': {'description': 'Van', 'plate': 'ABC-123'},
      });
      expect(trip.status, 'CONFIRMED');
      expect(trip.unconfirmedDue, isFalse);
    });

    test('send to provider and cancel carry providerId / reason only',
        () async {
      final server = _Server((_) => recordedRecord(recordedTrip));
      final repo = _repo(server);
      await repo.transition('t1',
          const TripTransition(to: 'SENT_TO_PROVIDER', providerId: 'prov_1'));
      expect(
          server.lastBody, {'to': 'SENT_TO_PROVIDER', 'providerId': 'prov_1'});
      await repo.transition(
          't1', const TripTransition(to: 'CANCELLED', reason: 'No show'));
      expect(server.lastBody, {'to': 'CANCELLED', 'reason': 'No show'});
    });

    test('422 SETTINGS_REQUIRED becomes SettingsRequiredException', () async {
      final server = _Server((_) => _status(422, recordedSettingsRequired));
      await expectLater(
        _repo(server).list(const ListQuery()),
        throwsA(isA<SettingsRequiredException>()
            .having((e) => e.details, 'details', ['timeZone'])),
      );
      await expectLater(
        _repo(server).create(const NewTripRequest(
            stayId: 's', serviceId: 'x', type: 'LOCAL', passengers: 1)),
        throwsA(isA<SettingsRequiredException>()),
      );
    });

    test('a plain 422 stays an AdminApiException', () async {
      final server = _Server((_) => _status(422, recordedRuleError));
      await expectLater(
        _repo(server).transition('t1', const TripTransition(to: 'EN_ROUTE')),
        throwsA(isA<AdminApiException>()
            .having((e) => e.statusCode, 'statusCode', 422)),
      );
    });
  });
}
