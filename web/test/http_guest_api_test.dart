import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kachava_guest_portal/data/guest_api.dart';
import 'package:kachava_guest_portal/data/http_guest_api.dart';
import 'package:kachava_guest_portal/domain/catalog.dart';
import 'package:kachava_guest_portal/domain/stay.dart';

import 'support/fake_guest_api.dart';
import 'support/fixtures.dart';

const _base = 'http://api.test/api/v1';

http.Response _json(Object body, [int status = 200]) =>
    http.Response(jsonEncode(body), status,
        headers: {'content-type': 'application/json'});

void main() {
  test('stay: envelope parsed, bearer guest link sent', () async {
    late http.Request seen;
    final api = HttpGuestApi(
      baseUrl: _base,
      client: MockClient((r) async {
        seen = r;
        return _json(
            {'success': true, 'data': stayJson(checkIn: '2026-11-03')});
      }),
    );
    final r = await api.fetchStay(guestUuid);
    expect(seen.url.toString(), '$_base/stays/$guestUuid');
    expect(seen.headers['Authorization'], 'Bearer $guestUuid');
    final stay = (r as ApiOk<GuestStay>).value;
    expect(stay.villaName, 'Casa Ceiba');
    expect(stay.checkIn, DateTime.utc(2026, 11, 3));
  });

  test('only 401/403/404 on the stay reject the link; 5xx is transient',
      () async {
    for (final (status, kind) in [
      (401, FailureKind.linkRejected),
      (403, FailureKind.linkRejected),
      (404, FailureKind.linkRejected),
      (500, FailureKind.unreachable),
      (429, FailureKind.unreachable),
    ]) {
      final api = HttpGuestApi(
          baseUrl: _base, client: MockClient((_) async => _json({}, status)));
      expect((await api.fetchStay(guestUuid) as ApiFailed).kind, kind,
          reason: '$status');
    }
  });

  test('timeouts and bad JSON keep last data (unreachable)', () async {
    final slow = HttpGuestApi(
      baseUrl: _base,
      timeout: const Duration(milliseconds: 10),
      client: MockClient((_) => Completer<http.Response>().future),
    );
    expect((await slow.fetchStay(guestUuid) as ApiFailed).kind,
        FailureKind.unreachable);
    final bad = HttpGuestApi(
        baseUrl: _base,
        client: MockClient((_) async => http.Response('<html>', 200)));
    expect((await bad.fetchStay(guestUuid) as ApiFailed).kind,
        FailureKind.unreachable);
  });

  test('catalog reads every page of ACTIVE services', () async {
    final pages = <String>[];
    final api = HttpGuestApi(
      baseUrl: _base,
      client: MockClient((r) async {
        pages.add(r.url.query);
        final page = int.parse(r.url.queryParameters['page']!);
        final count = page == 1 ? 100 : 3;
        return _json({
          'success': true,
          'data': [
            for (var i = 0; i < count; i++)
              serviceJson(id: 's$page-$i', section: 'DINING')
          ],
          'meta': {'total': 103},
        });
      }),
    );
    final r = await api.fetchCatalog() as ApiOk<List<CatalogService>>;
    expect(r.value, hasLength(103));
    expect(pages, ['page=1&pageSize=100', 'page=2&pageSize=100']);
  });

  test('422 SETTINGS_REQUIRED is "not configured"; other 4xx invalid',
      () async {
    final api = HttpGuestApi(
      baseUrl: _base,
      client: MockClient((r) async => r.url.path.endsWith('/trips')
          ? _json({
              'success': false,
              'statusCode': 422,
              'code': 'SETTINGS_REQUIRED'
            }, 422)
          : _json({
              'success': false,
              'statusCode': 422,
              'message': 'At most 2 guests'
            }, 422)),
    );
    expect((await api.createTrip(guestUuid, {}) as ApiFailed).kind,
        FailureKind.notConfigured);
    expect((await api.createBooking(guestUuid, {}) as ApiFailed).kind,
        FailureKind.invalid);
  });

  test('photo: signed URL then PUT bytes (Cloud Storage)', () async {
    final calls = <String>[];
    final api = HttpGuestApi(
      baseUrl: _base,
      client: MockClient((r) async {
        calls.add('${r.method} ${r.url.host}${r.url.path}');
        if (r.url.path.endsWith('/upload-url')) {
          expect(jsonDecode(r.body), {
            'fileName': 'leak.jpg',
            'contentType': 'image/jpeg',
            'fileSizeBytes': 32
          });
          return _json({
            'success': true,
            'data': {
              'uploadUrl': 'https://storage.test/bucket/obj?X-Goog-Signature=1',
              'storagePath': '/private/p.jpg'
            },
          });
        }
        expect(r.headers['Content-Type'], 'image/jpeg');
        expect(r.bodyBytes.length, 32);
        return http.Response('', 200);
      }),
    );
    final r = await api.uploadPhoto(guestUuid, samplePhoto) as ApiOk<String>;
    expect(r.value, '/private/p.jpg');
    expect(calls, [
      'POST api.test/api/v1/stays/$guestUuid/concierge-requests/upload-url',
      'PUT storage.test/bucket/obj',
    ]);
  });

  test('photo: Storage emulator takes a media POST', () async {
    String? method;
    final api = HttpGuestApi(
      baseUrl: _base,
      client: MockClient((r) async {
        if (r.url.path.endsWith('/upload-url')) {
          return _json({
            'data': {
              'uploadUrl':
                  'http://localhost:9199/upload/storage/v1/b/x/o?uploadType=media&name=p',
              'storagePath': '/private/p.jpg',
            },
          });
        }
        method = r.method;
        return http.Response('{}', 200);
      }),
    );
    expect(await api.uploadPhoto(guestUuid, samplePhoto), isA<ApiOk<String>>());
    expect(method, 'POST');
  });

  test('photo upload failure is reported, never a fake success', () async {
    final api = HttpGuestApi(
      baseUrl: _base,
      client: MockClient((r) async => r.url.path.endsWith('/upload-url')
          ? _json({
              'data': {'uploadUrl': 'https://s.test/o', 'storagePath': '/p'}
            })
          : http.Response('denied', 403)),
    );
    expect(await api.uploadPhoto(guestUuid, samplePhoto),
        isA<ApiFailed<String>>());
  });

  test('chat thread is type ask in the Resort Host chat category', () async {
    late Map<String, dynamic> body;
    final api = HttpGuestApi(
      baseUrl: _base,
      client: MockClient((r) async {
        body = jsonDecode(r.body) as Map<String, dynamic>;
        return _json({
          'data': {'requestId': 'req_9'}
        }, 201);
      }),
    );
    final r = await api.startHostThread(guestUuid, text: 'Hi') as ApiOk<String>;
    expect(r.value, 'req_9');
    expect(body, {
      'type': 'ask',
      'category': HostThread.chatCategory,
      'title': 'Message',
      'details': 'Hi'
    });
  });
}
