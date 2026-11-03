import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kachava_admin_dashboard/data/http_catalog_repositories.dart';
import 'package:kachava_admin_dashboard/data/http_service_catalog_repository.dart';
import 'package:kachava_admin_dashboard/data/http_uploads.dart';
import 'package:kachava_admin_dashboard/domain/admin_service.dart';
import 'package:kachava_admin_dashboard/domain/admin_settings.dart';
import 'package:kachava_admin_dashboard/domain/admin_villa.dart';
import 'package:kachava_admin_dashboard/domain/catalog_values.dart';
import 'package:kachava_admin_dashboard/domain/list_query.dart';
import 'package:kachava_admin_dashboard/domain/transport_provider.dart';

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

Map<String, dynamic> _page(List<Map<String, dynamic>> data,
        {int page = 1, int pageSize = 25, int? total}) =>
    {
      'data': data,
      'meta': {
        'page': page,
        'pageSize': pageSize,
        'total': total ?? data.length
      }
    };

void main() {
  final query = const ListQuery()
      .withSearch('ocean')
      .withFilter('status', 'AVAILABLE')
      .withSort(const ListSort('name'))
      .withPage(2);

  group('HttpVillaRepository', () {
    test('lists with ?q&page&pageSize&sort&filters and parses the envelope',
        () async {
      final server = _Server((_) => _page([
            {'id': 'v1', 'name': 'Ceiba', 'capacity': 4, 'isActive': true}
          ], page: 2, total: 26));
      final repo = HttpVillaRepository(signedInApiClient(server.client));
      final result = await repo.list(query);
      expect(server.last.method, 'GET');
      expect(server.last.url.path, '/api/v1/admin/villas');
      expect(server.last.url.queryParameters, {
        'q': 'ocean',
        'page': '2',
        'pageSize': '25',
        'sort': 'name:asc',
        'status': 'AVAILABLE',
      });
      expect(result.total, 26);
      expect(result.items.single.name, 'Ceiba');
      expect(result.items.single.capacity, 4);
    });

    test('create POSTs editable fields; update PATCHes /villas/:id', () async {
      final server = _Server((r) => {
            'data': {'id': 'v9', ...jsonDecode(r.body) as Map}
          });
      final repo = HttpVillaRepository(signedInApiClient(server.client));
      final created = await repo.create(const AdminVilla(name: 'Ceiba'));
      expect(server.last.method, 'POST');
      expect(server.last.url.path, '/api/v1/admin/villas');
      expect(server.lastBody, isNot(contains('id')));
      expect(created.id, 'v9');

      await repo
          .update(const AdminVilla(id: 'v9', name: 'Ceiba', isActive: false));
      expect(server.last.method, 'PATCH');
      expect(server.last.url.path, '/api/v1/admin/villas/v9');
      expect(server.lastBody['isActive'], isFalse);
    });

    test('a response without id is not a confirmed write', () async {
      final server = _Server((_) => {
            'data': {'name': 'Ceiba'}
          });
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

  test('HttpSettingsRepository GETs and PATCHes /settings', () async {
    final server = _Server((r) => {
          'data': r.method == 'GET'
              ? {'checkInTime': '15:00'}
              : jsonDecode(r.body) as Map
        });
    final repo = HttpSettingsRepository(signedInApiClient(server.client));
    final settings = await repo.fetch();
    expect(server.last.url.path, '/api/v1/admin/settings');
    expect(settings.checkInTime, '15:00');
    expect(settings.isConfigured, isFalse);

    final saved = await repo.update(const AdminSettings(
        checkInTime: '15:00',
        checkOutTime: '11:00',
        timeZone: 'America/Cancun',
        airports: [AirportSetting(code: 'CUN', name: 'Cancún')]));
    expect(server.last.method, 'PATCH');
    expect(server.lastBody['airports'], hasLength(1));
    expect(saved.isConfigured, isTrue);
  });

  test('HttpTransportProviderRepository uses /transport-providers', () async {
    final server = _Server((r) => r.method == 'GET'
        ? _page([
            {'id': 'p1', 'name': 'Coast Cars'}
          ])
        : {
            'data': {'id': 'p1', ...jsonDecode(r.body) as Map}
          });
    final repo =
        HttpTransportProviderRepository(signedInApiClient(server.client));
    expect((await repo.list(const ListQuery())).items.single.id, 'p1');
    expect(server.last.url.path, '/api/v1/admin/transport-providers');
    await repo.update(const TransportProvider(id: 'p1', name: 'Coast Cars'));
    expect(server.last.url.path, '/api/v1/admin/transport-providers/p1');
  });

  group('HttpServiceCatalogRepository', () {
    test('services and items paths', () async {
      final server = _Server((r) {
        if (r.method == 'GET' && r.url.path.endsWith('/items')) {
          return _page([
            {
              'id': 'i1',
              'name': {'en': 'Mezcal', 'es': 'Mezcal'},
              'price': 12.5
            }
          ]);
        }
        if (r.method == 'GET' && r.url.path.endsWith('/services')) {
          return _page([
            {
              'id': 's1',
              'name': {'en': 'Lux bar', 'es': 'Lux bar'},
              'status': 'ACTIVE',
              'pricing': {'mode': 'PER_UNIT', 'chargeToFolio': true}
            }
          ]);
        }
        final body = r.body.isEmpty ? <String, dynamic>{} : jsonDecode(r.body);
        return {
          'data': {
            'id': r.url.pathSegments.last == 'items' ? 'i2' : 's1',
            ...body as Map
          }
        };
      });
      final repo =
          HttpServiceCatalogRepository(signedInApiClient(server.client));

      final services =
          await repo.list(const ListQuery().withFilter('section', 'DINING'));
      expect(server.last.url.queryParameters['section'], 'DINING');
      expect(services.items.single.pricing.chargeToFolio, isTrue);

      await repo.get('s1');
      expect(server.last.url.path, '/api/v1/admin/services/s1');

      await repo.create(const AdminService(
          name: LocalizedText(en: 'Breakfast', es: 'Desayuno')));
      expect(server.last.method, 'POST');
      expect(server.lastBody['name'], {'en': 'Breakfast', 'es': 'Desayuno'});

      final items = await repo.listItems('s1', const ListQuery());
      expect(server.last.url.path, '/api/v1/admin/services/s1/items');
      expect(items.items.single.price, 12.5);

      await repo.createItem(
          's1', const ServiceItem(name: LocalizedText(en: 'Tea')));
      expect(server.last.url.path, '/api/v1/admin/services/s1/items');
      await repo.updateItem(
          's1', const ServiceItem(id: 'i1', name: LocalizedText(en: 'Tea')));
      expect(server.last.method, 'PATCH');
      expect(server.last.url.path, '/api/v1/admin/services/s1/items/i1');
    });
  });

  test('HttpStayListRepository pages GET /stays', () async {
    final server = _Server((_) => _page([
          {'stayId': 's1', 'guestName': 'Ana', 'status': 'PRE_ARRIVAL'}
        ], total: 40));
    final repo = HttpStayListRepository(signedInApiClient(server.client));
    final page = await repo.list(const ListQuery());
    expect(server.last.url.path, '/api/v1/admin/stays');
    expect(page.total, 40);
    expect(page.items.single.guestNames, 'Ana');
  });

  group('uploads', () {
    test('HttpUploadSigner POSTs /uploads/sign', () async {
      final server = _Server((_) => {
            'data': {
              'uploadUrl': 'https://storage.example/put?sig=1',
              'storagePath': 'services/a.png',
              'publicUrl': 'https://cdn.example/services/a.png'
            }
          });
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
      expect(signed.uploadUrl.host, 'storage.example');
      expect(signed.storagePath, 'services/a.png');
    });

    test('a sign response missing fields is rejected', () async {
      final server = _Server((_) => {
            'data': {'uploadUrl': 'https://x'}
          });
      final signer = HttpUploadSigner(signedInApiClient(server.client));
      expect(
          signer.sign(
              fileName: 'a.png',
              contentType: 'image/png',
              sizeBytes: 1,
              folder: 'f'),
          throwsFormatException);
    });

    test('HttpSignedUploadTransport PUTs bytes with the content type',
        () async {
      late http.Request put;
      final transport = HttpSignedUploadTransport(MockClient((r) async {
        put = r;
        return http.Response('', 200);
      }));
      await transport.put(Uri.parse('https://storage.example/put'),
          Uint8List.fromList([1, 2, 3]), 'image/webp');
      expect(put.method, 'PUT');
      expect(put.headers['content-type'], 'image/webp');
      expect(put.bodyBytes, [1, 2, 3]);

      final failing = HttpSignedUploadTransport(
          MockClient((_) async => http.Response('denied', 403)));
      expect(failing.put(Uri.parse('https://x'), Uint8List(1), 'image/png'),
          throwsA(isA<SignedUploadException>()));
    });
  });
}
