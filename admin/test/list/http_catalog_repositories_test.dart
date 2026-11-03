import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kachava_admin_dashboard/data/admin_api_client.dart';
import 'package:kachava_admin_dashboard/data/http_catalog_repositories.dart';
import 'package:kachava_admin_dashboard/data/http_service_catalog_repository.dart';
import 'package:kachava_admin_dashboard/data/http_uploads.dart';
import 'package:kachava_admin_dashboard/domain/admin_catalog_repositories.dart';
import 'package:kachava_admin_dashboard/domain/admin_service.dart';
import 'package:kachava_admin_dashboard/domain/admin_settings.dart';
import 'package:kachava_admin_dashboard/domain/admin_villa.dart';
import 'package:kachava_admin_dashboard/domain/catalog_values.dart';
import 'package:kachava_admin_dashboard/domain/list_query.dart';
import 'package:kachava_admin_dashboard/domain/transport_provider.dart';
import 'package:kachava_admin_dashboard/domain/uploads.dart';

import '../support/recorded_contract.dart';
import '../support/signed_in_api_client.dart';

/// Captures requests and answers with [respond].
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

void main() {
  final query = const ListQuery()
      .withSearch('ocean')
      .withFilter('operationalStatus', 'AVAILABLE')
      .withFilter('isActive', 'true')
      .withSort(const ListSort('name'))
      .withPage(2);

  group('HttpVillaRepository (recorded contract)', () {
    test('lists with ?q&page&pageSize&sort&filters and parses the envelope',
        () async {
      final server = _Server((_) =>
          recordedPage([recordedVilla], page: 2, pageSize: 25, total: 26));
      final repo = HttpVillaRepository(signedInApiClient(server.client));
      final result = await repo.list(query);
      expect(server.last.method, 'GET');
      expect(server.last.url.path, '/api/v1/admin/villas');
      expect(server.last.url.queryParameters, {
        'q': 'ocean',
        'page': '2',
        'pageSize': '25',
        'sort': 'name:asc',
        'operationalStatus': 'AVAILABLE',
        'isActive': 'true',
      });
      expect(result.total, 26);
      final villa = result.items.single;
      expect(villa.id, recordedVilla['id']);
      expect(villa.name, 'Casa Ceiba');
      expect(villa.category, 'Ocean view');
      expect(villa.capacity, 4);
      expect(villa.wifiSsid, 'Ceiba-Guest');
      expect(villa.wifiPassword, 's3cret-pass');
      expect(villa.operationalStatus, 'AVAILABLE');
      expect(villa.housekeepingStatus, 'CLEAN');
      expect(villa.maintenanceStatus, 'OK');
      expect(villa.isActive, isTrue);
      expect(villa.currentGuestName, isNull);
      expect(villa.audit.updatedBy, 'admin@kachava.local');
    });

    test('an empty database is an empty page, not an error', () async {
      final server = _Server((_) => recordedPage(const []));
      final repo = HttpVillaRepository(signedInApiClient(server.client));
      final result = await repo.list(const ListQuery());
      expect(result.isEmpty, isTrue);
    });

    test('create POSTs only the editable fields the DTO accepts', () async {
      final server = _Server((r) => recordedRecord(
          {...recordedVilla, ...jsonDecode(r.body) as Map<String, dynamic>}));
      final repo = HttpVillaRepository(signedInApiClient(server.client));
      final created = await repo.create(const AdminVilla(
          name: 'Casa Ceiba',
          category: 'Ocean view',
          capacity: 4,
          wifiSsid: 'Ceiba-Guest',
          wifiPassword: 'pw',
          operationalStatus: 'AVAILABLE',
          housekeepingStatus: 'CLEAN',
          maintenanceStatus: 'OK'));
      expect(server.last.method, 'POST');
      expect(server.last.url.path, '/api/v1/admin/villas');
      expect(server.lastBody, {
        'name': 'Casa Ceiba',
        'category': 'Ocean view',
        'capacity': 4,
        'wifi': {'ssid': 'Ceiba-Guest', 'password': 'pw'},
        'operationalStatus': 'AVAILABLE',
        'housekeepingStatus': 'CLEAN',
        'maintenanceStatus': 'OK',
        'maintenanceNote': '',
        'isActive': true,
      });
      expect(created.id, recordedVilla['id']);
    });

    test('update PATCHes /villas/:id; setActive sends only isActive', () async {
      final server = _Server((r) => recordedRecord(
          {...recordedVilla, ...jsonDecode(r.body) as Map<String, dynamic>}));
      final repo = HttpVillaRepository(signedInApiClient(server.client));
      await repo.update(const AdminVilla(id: 'v9', name: 'Ceiba', capacity: 2));
      expect(server.last.method, 'PATCH');
      expect(server.last.url.path, '/api/v1/admin/villas/v9');

      final off = await repo.setActive('v9', false);
      expect(server.last.method, 'PATCH');
      expect(server.lastBody, {'isActive': false});
      expect(off.isActive, isFalse);
    });

    test('delete answers 409 "has stays" as VillaHasStaysException', () async {
      final server = _Server((_) => _status(409, recordedVillaHasStays));
      final repo = HttpVillaRepository(signedInApiClient(server.client));
      await expectLater(
          repo.delete('v1'), throwsA(isA<VillaHasStaysException>()));
      expect(server.last.method, 'DELETE');
      expect(server.last.url.path, '/api/v1/admin/villas/v1');
    });

    test('delete succeeds when the backend allows it', () async {
      final server = _Server((_) => recordedVillaDeleted);
      final repo = HttpVillaRepository(signedInApiClient(server.client));
      await repo.delete('v1');
      expect(server.last.method, 'DELETE');
    });

    test('other failures propagate unchanged', () async {
      final server = _Server((_) => _status(400, {
            'success': false,
            'statusCode': 400,
            'message': 'capacity must not be greater than 50',
          }));
      final repo = HttpVillaRepository(signedInApiClient(server.client));
      await expectLater(repo.create(const AdminVilla(name: 'x')),
          throwsA(isA<AdminApiException>()));
    });

    test('a response without id is not a confirmed write', () async {
      final server = _Server((_) => recordedRecord({'name': 'Ceiba'}));
      final repo = HttpVillaRepository(signedInApiClient(server.client));
      expect(
          repo.create(const AdminVilla(name: 'Ceiba')), throwsFormatException);
    });

    test('a list response without meta is a FormatException', () async {
      final server = _Server((_) => {'data': []});
      final repo = HttpVillaRepository(signedInApiClient(server.client));
      expect(repo.list(const ListQuery()), throwsFormatException);
    });
  });

  group('HttpSettingsRepository (recorded contract)', () {
    test('an empty database means every value is "not set"', () async {
      final server = _Server((_) => recordedEmptySettings);
      final repo = HttpSettingsRepository(signedInApiClient(server.client));
      final settings = await repo.fetch();
      expect(server.last.url.path, '/api/v1/admin/settings');
      expect(settings.checkInTime, isNull);
      expect(settings.checkOutTime, isNull);
      expect(settings.timeZone, isNull);
      expect(settings.airports, isEmpty);
      expect(settings.transportAlertLeadHours, isNull);
      expect(settings.isConfigured, isFalse);
    });

    test('PATCH sends every value (null clears) and parses hours', () async {
      final server = _Server((_) => recordedConfiguredSettings);
      final repo = HttpSettingsRepository(signedInApiClient(server.client));
      final saved = await repo.update(const AdminSettings(
          checkInTime: '15:00',
          checkOutTime: null,
          timeZone: 'America/Cancun',
          airports: [
            AirportSetting(
                code: 'CUN', name: 'Cancun', departureBufferHours: 2.5)
          ],
          transportAlertLeadHours: 24));
      expect(server.last.method, 'PATCH');
      expect(server.lastBody, {
        'checkInTime': '15:00',
        'checkOutTime': null,
        'timeZone': 'America/Cancun',
        'airports': [
          {
            'code': 'CUN',
            'name': 'Cancun',
            'departureBufferHours': 2.5,
            'isActive': true,
          }
        ],
        'transportAlertLeadHours': 24,
      });
      expect(saved.isConfigured, isTrue);
      expect(saved.airports.first.departureBufferHours, 3);
      expect(saved.airports.last.departureBufferHours, 2.5);
      expect(saved.airports.last.isActive, isFalse);
      expect(saved.transportAlertLeadHours, 24);
      expect(saved.audit.updatedBy, 'admin@kachava.local');
    });
  });

  test('HttpTransportProviderRepository uses /transport-providers', () async {
    final server = _Server((r) => r.method == 'GET'
        ? recordedPage([
            {'id': 'p1', 'providerId': 'p1', 'name': 'Coast Cars'}
          ])
        : recordedRecord({'id': 'p1', ...jsonDecode(r.body) as Map}));
    final repo =
        HttpTransportProviderRepository(signedInApiClient(server.client));
    expect((await repo.list(const ListQuery())).items.single.id, 'p1');
    expect(server.last.url.path, '/api/v1/admin/transport-providers');
    await repo.update(const TransportProvider(id: 'p1', name: 'Coast Cars'));
    expect(server.last.url.path, '/api/v1/admin/transport-providers/p1');
  });

  group('HttpServiceCatalogRepository (recorded contract)', () {
    test('parses the backend names of a service', () async {
      final server = _Server((_) => recordedPage([recordedService]));
      final repo =
          HttpServiceCatalogRepository(signedInApiClient(server.client));
      final service =
          (await repo.list(const ListQuery().withFilter('section', 'DINING')))
              .items
              .single;
      expect(server.last.url.queryParameters['section'], 'DINING');
      expect(service.kind, ServiceKind.bar);
      expect(service.usageType, UsageType.order);
      expect(service.order, 2);
      expect(service.category, 'Drinks');
      expect(service.cover?.storagePath, 'catalog/services/cover.jpg');
      expect(service.cover?.url, startsWith('http://127.0.0.1:9199/'));
      expect(service.pricing.chargeToFolio, isTrue);
      expect(service.availability.weekdays, [Weekday.mon, Weekday.fri]);
      expect(service.availability.timeSlots.single.start, '17:00');
      expect(service.availability.timeSlots.single.end, '22:00');
      expect(service.availability.minLeadHours, 2);
      expect(service.availability.offeredWhen, OfferedWhen.duringStay);
      expect(service.guestForm.date, isTrue);
      expect(service.guestForm.dietary, isFalse);
      expect(service.operation.responsibleDepartment, 'CULINARY');
      expect(service.operation.internalInstructions, 'Check ID');
      expect(service.kind.detailField, 'bar');
      expect(service.details, {'ageConfirmationRequired': true});
      expect(service.status, CatalogStatus.active);
      expect(service.canActivate, isTrue);
    });

    test('writes one type block per kind and never the resolved url', () async {
      final server = _Server((r) => recordedRecord(
          {...recordedService, ...jsonDecode(r.body) as Map<String, dynamic>}));
      final repo =
          HttpServiceCatalogRepository(signedInApiClient(server.client));
      await repo.create(const AdminService(
        kind: ServiceKind.breakfast,
        section: ServiceSection.dining,
        usageType: UsageType.booking,
        name: LocalizedText(en: 'Breakfast', es: 'Desayuno'),
        cover: CatalogImage(storagePath: 'catalog/s/a.jpg', url: 'https://x'),
        availability: ServiceAvailability(
            weekdays: [Weekday.sat],
            timeSlots: [TimeSlot('07:00', '10:00')],
            minLeadHours: 12,
            offeredWhen: OfferedWhen.beforeArrival),
        guestForm: ServiceGuestForm(date: true, dietary: true),
        operation: ServiceOperation(internalInstructions: 'Fresh juice'),
        details: {'pairingAvailable': false},
      ));
      final body = server.lastBody;
      expect(server.last.method, 'POST');
      expect(body['kind'], 'BREAKFAST');
      expect(body['usageType'], 'BOOKING');
      expect(body['order'], 0);
      expect(body['dining'], {'pairingAvailable': false});
      for (final other in [
        'bar',
        'stocking',
        'experience',
        'wellness',
        'preference',
        'transport',
        'details',
        'type',
        'usage',
        'sortOrder',
      ]) {
        expect(body.containsKey(other), isFalse, reason: other);
      }
      expect(body['cover'], {
        'storagePath': 'catalog/s/a.jpg',
        'alt': {'en': '', 'es': ''},
        'usageRightsConfirmed': false,
      });
      expect(body['availability'], {
        'weekdays': ['SAT'],
        'timeSlots': [
          {'start': '07:00', 'end': '10:00'}
        ],
        'blockedDates': [],
        'minLeadHours': 12,
        'cancellationHours': null,
        'minGuests': null,
        'maxGuests': null,
        'durationMinutes': null,
        'offeredWhen': 'BEFORE_ARRIVAL',
      });
      expect(body['guestForm'], {
        'date': true,
        'time': false,
        'guests': false,
        'notes': false,
        'dietary': true,
        'health': false,
      });
      expect(body['operation'], {
        'providerId': null,
        'responsibleDepartment': null,
        'responsibleStaffId': null,
        'requiresConfirmation': false,
        'internalInstructions': 'Fresh juice',
      });
    });

    test('items use priceUSD, status and flat item fields', () async {
      final server = _Server((r) => r.method == 'GET'
          ? recordedPage([recordedItem])
          : recordedRecord({
              ...recordedItem,
              ...jsonDecode(r.body) as Map<String, dynamic>
            }));
      final repo =
          HttpServiceCatalogRepository(signedInApiClient(server.client));
      final item =
          (await repo.listItems('svc-1', const ListQuery())).items.single;
      expect(server.last.url.path, '/api/v1/admin/services/svc-1/items');
      expect(item.priceUSD, 12.5);
      expect(item.status, CatalogStatus.active);
      expect(item.dietaryTags, ['vegan']);
      expect(item.origin, 'Oaxaca');
      expect(item.unit, 'glass');
      expect(item.capacity, isNull);

      await repo.createItem(
          'svc-1',
          const ServiceItem(
              name: LocalizedText(en: 'Van'),
              priceUSD: 90,
              status: CatalogStatus.active,
              capacity: VehicleCapacity(passengers: 6, luggage: 4)));
      final body = server.lastBody;
      expect(body['priceUSD'], 90);
      expect(body['capacity'], {'passengers': 6, 'luggage': 4});
      expect(body['status'], 'ACTIVE');
      expect(body.containsKey('price'), isFalse);
      expect(body.containsKey('details'), isFalse);
      expect(body.containsKey('isAvailable'), isFalse);

      await repo.updateItem(
          'svc-1', const ServiceItem(id: 'i1', name: LocalizedText(en: 'Tea')));
      expect(server.last.method, 'PATCH');
      expect(server.last.url.path, '/api/v1/admin/services/svc-1/items/i1');
    });
  });

  test('HttpStayListRepository pages GET /stays (ADR-011 row shape)', () async {
    final server = _Server((_) => recordedPage([
          {
            'id': 's1',
            'guestName': 'Ana',
            'villaId': 'v1',
            'villaName': 'Casa Ceiba',
            'checkIn': '2026-11-03',
            'checkOut': '2026-11-07',
            'status': 'PRE_ARRIVAL',
            'resortHostName': null,
            'magicLinkUrl': 'https://guest.test/?guestId=u1',
          }
        ], total: 40));
    final repo = HttpStayListRepository(signedInApiClient(server.client));
    final page = await repo.list(const ListQuery());
    expect(server.last.url.path, '/api/v1/admin/stays');
    expect(page.total, 40);
    expect(page.items.single.guestName, 'Ana');
    expect(page.items.single.id, 's1');
    expect(page.items.single.isOpen, isTrue);
  });

  group('uploads (recorded contract)', () {
    test('HttpUploadSigner POSTs /uploads/sign and keeps method + headers',
        () async {
      final server = _Server((_) => recordedUploadSign);
      final signer = HttpUploadSigner(signedInApiClient(server.client));
      final signed = await signer.sign(
          fileName: 'a.png',
          contentType: 'image/png',
          sizeBytes: 10,
          folder: 'services');
      expect(server.last.url.path, '/api/v1/admin/uploads/sign');
      expect(server.lastBody, {
        'fileName': 'a.png',
        'contentType': 'image/png',
        'sizeBytes': 10,
        'folder': 'services'
      });
      expect(signed.uploadUrl.host, '127.0.0.1');
      expect(signed.method, 'POST');
      expect(signed.headers, {'Content-Type': 'image/png'});
      expect(signed.storagePath, 'catalog/services/a.png');
      expect(signed.publicUrl, contains('alt=media'));
    });

    test('a sign response missing fields is rejected', () async {
      final server = _Server((_) => recordedRecord({'uploadUrl': 'https://x'}));
      final signer = HttpUploadSigner(signedInApiClient(server.client));
      expect(
          signer.sign(
              fileName: 'a.png',
              contentType: 'image/png',
              sizeBytes: 1,
              folder: 'f'),
          throwsFormatException);
    });

    test('HttpSignedUploadTransport sends the bytes with the signed method',
        () async {
      late http.Request sent;
      final transport = HttpSignedUploadTransport(MockClient((r) async {
        sent = r;
        return http.Response('', 200);
      }));
      final bytes = Uint8List.fromList([1, 2, 3]);
      await transport.send(
          SignedUploadRequest(
              url: Uri.parse('http://127.0.0.1:9199/upload'),
              method: 'POST',
              headers: const {'Content-Type': 'image/png'}),
          bytes);
      expect(sent.method, 'POST');
      expect(sent.headers['content-type'], 'image/png');
      expect(sent.bodyBytes, [1, 2, 3]);

      await transport.send(
          SignedUploadRequest(
              url: Uri.parse('https://storage.example/put'),
              method: 'PUT',
              headers: const {'Content-Type': 'image/webp'}),
          bytes);
      expect(sent.method, 'PUT');
      expect(sent.headers['content-type'], 'image/webp');

      final failing = HttpSignedUploadTransport(
          MockClient((_) async => http.Response('denied', 403)));
      expect(
          failing.send(
              SignedUploadRequest(
                  url: Uri.parse('https://x'),
                  method: 'PUT',
                  headers: const {}),
              Uint8List(1)),
          throwsA(isA<SignedUploadException>()));
    });
  });
}
