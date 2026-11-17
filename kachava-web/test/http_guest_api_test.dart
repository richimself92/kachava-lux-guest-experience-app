import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kachava_guest_portal/data/guest_api.dart';
import 'package:kachava_guest_portal/data/http_guest_api.dart';
import 'package:kachava_guest_portal/domain/catalog.dart';
import 'package:kachava_guest_portal/domain/json_read.dart';
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
              'method': 'PUT',
              'headers': {
                'Content-Type': 'image/jpeg',
                'x-goog-content-length-range': '0,10485760'
              },
              'storagePath': '/private/p.jpg',
              'expiresAt': '2026-11-03T10:15:00.000Z',
              'maxBytes': 10485760,
            },
          });
        }
        expect(r.headers['Content-Type'], 'image/jpeg');
        expect(r.headers['x-goog-content-length-range'], '0,10485760');
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

  test('photo: the method comes from the signer, never guessed', () async {
    String? method;
    final api = HttpGuestApi(
      baseUrl: _base,
      client: MockClient((r) async {
        if (r.url.path.endsWith('/upload-url')) {
          return _json({
            'data': {
              'uploadUrl': 'http://storage.test/any/path',
              'method': 'POST',
              'headers': {'Content-Type': 'image/jpeg'},
              'storagePath': '/private/p.jpg',
              'maxBytes': 10485760,
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
              'data': {
                'uploadUrl': 'https://s.test/o',
                'method': 'PUT',
                'headers': {'Content-Type': 'image/jpeg'},
                'storagePath': '/p',
                'maxBytes': 10485760,
              }
            })
          : http.Response('denied', 403)),
    );
    expect(await api.uploadPhoto(guestUuid, samplePhoto),
        isA<ApiFailed<String>>());
  });

  test('photo: a ticket without method or a too large photo is refused',
      () async {
    var uploads = 0;
    HttpGuestApi apiWith(Json ticket) => HttpGuestApi(
          baseUrl: _base,
          client: MockClient((r) async {
            if (r.url.path.endsWith('/upload-url')) {
              return _json({'data': ticket});
            }
            uploads++;
            return http.Response('', 200);
          }),
        );
    final noMethod = apiWith(
        {'uploadUrl': 'https://s.test/o', 'storagePath': '/p', 'maxBytes': 99});
    final tooSmall = apiWith({
      'uploadUrl': 'https://s.test/o',
      'method': 'PUT',
      'headers': const {},
      'storagePath': '/p',
      'maxBytes': 8,
    });
    expect(await noMethod.uploadPhoto(guestUuid, samplePhoto),
        isA<ApiFailed<String>>());
    expect(await tooSmall.uploadPhoto(guestUuid, samplePhoto),
        isA<ApiFailed<String>>());
    expect(uploads, 0);
  });

  test('photo upload asks for the open thread folder', () async {
    late Map<String, dynamic> body;
    final api = HttpGuestApi(
      baseUrl: _base,
      client: MockClient((r) async {
        if (r.url.path.endsWith('/upload-url')) {
          body = jsonDecode(r.body) as Map<String, dynamic>;
          return _json({
            'data': {
              'uploadUrl': 'https://s.test/o',
              'method': 'PUT',
              'headers': {'Content-Type': 'image/jpeg'},
              'storagePath': '/p',
              'maxBytes': 1000,
            }
          });
        }
        return http.Response('', 200);
      }),
    );
    await api.uploadPhoto(guestUuid, samplePhoto, threadId: 'req_7');
    expect(body['requestId'], 'req_7');
  });

  test('stay: journey marks, request timestamps and chat photo URLs', () async {
    final api = HttpGuestApi(
      baseUrl: _base,
      client: MockClient((_) async => _json({
            'data': stayJson(
              skipped: ['1:core:flight'],
              completed: ['core:departure'],
              bookings: [
                bookingJson('b1', 'spa', createdAt: '2026-11-01T09:00:00Z')
              ],
              threads: const [
                {
                  'requestId': 'c1',
                  'type': 'ask',
                  'messages': [
                    {
                      'sender': 'GUEST',
                      'text': '',
                      'sentAt': '2026-11-01T10:00:00Z',
                      'photoUrl': 'https://signed.test/read/p.jpg'
                    }
                  ],
                }
              ],
            )
          })),
    );
    final stay = (await api.fetchStay(guestUuid) as ApiOk<GuestStay>).value;
    expect(stay.skippedTaskIds, {'1:core:flight'});
    expect(stay.completedTaskIds, {'core:departure'});
    expect(stay.bookings.single.createdAt, DateTime.utc(2026, 11, 1, 9));
    expect(stay.chatMessages.single.photoUrl, 'https://signed.test/read/p.jpg');
    expect(stay.chatMessages.single.hasPhoto, isTrue);
  });

  test('guest self-service routes', () async {
    final calls = <String>[];
    final api = HttpGuestApi(
      baseUrl: _base,
      client: MockClient((r) async {
        calls.add('${r.method} ${r.url.path} ${r.body}');
        return _json({'data': const {}});
      }),
    );
    final results = [
      await api.saveOrder(guestUuid, {
        'serviceId': 'bar',
        'items': [
          {'itemId': 'i1', 'quantity': 2}
        ]
      }),
      await api.saveJourney(guestUuid, skippedTaskIds: {'1:core:flight'}),
      await api.saveJourney(guestUuid, completedTaskIds: {'core:flight'}),
      await api.cancelBooking(guestUuid, 'b1'),
      await api.changeBooking(guestUuid, 'b1', {'partySize': 3}),
      await api.cancelTrip(guestUuid, 't1'),
      await api.sendHostMessage(guestUuid, 'c1', '',
          photoStoragePath: '/private/p.jpg'),
    ];
    expect(results, everyElement(isA<ApiOk<void>>()));
    const p = '/api/v1/stays/$guestUuid';
    expect(calls, [
      'PUT $p/orders/bar {"items":[{"itemId":"i1","quantity":2}]}',
      'PUT $p/journey {"skippedTaskIds":["1:core:flight"]}',
      'PUT $p/journey {"completedTaskIds":["core:flight"]}',
      'POST $p/bookings/b1/cancel ',
      'PATCH $p/bookings/b1 {"partySize":3}',
      'POST $p/trips/t1/cancel ',
      'POST $p/concierge-requests/c1/messages {"photoStoragePath":"/private/p.jpg"}',
    ]);
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
