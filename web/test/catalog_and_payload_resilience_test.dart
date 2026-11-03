import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kachava_guest_portal/data/repositories/api_sanctuary_repository.dart';
import 'package:kachava_guest_portal/data/repositories/sanctuary_wire_mapper.dart';
import 'package:kachava_guest_portal/domain/repositories/sanctuary_repository.dart';

const _uuid = '3f2b8c1e-4d5a-4b6c-8d7e-9f0a1b2c3d4e';
const _json = {'content-type': 'application/json; charset=utf-8'};

/// Fake backend: the stay and each catalog answer independently.
class _FakeBackend {
  int stayStatus = 200;
  String stayBody = jsonEncode({
    'success': true,
    'data': {'status': 'ACTIVE_STAY', 'villaName': 'Villa 106'},
  });
  int catalogStatus = 200;
  String? catalogBodyOverride;
  List<Map<String, Object>> experiences = [
    {'id': 'exp-sunset', 'title': 'Sunset Swim', 'price': 0},
  ];
  List<Map<String, Object>> larder = [
    {'id': 'larder-mango', 'name': 'Mango', 'price': 12},
  ];
  final List<http.Request> requests = [];

  late final MockClient client = MockClient((req) async {
    requests.add(req);
    final path = req.url.path;
    if (path.endsWith('/verify-step-up')) return stepUpResponse(req);
    if (path.contains('/catalog/')) return _catalog(path);
    return http.Response(stayBody, stayStatus, headers: _json);
  });

  http.Response Function(http.Request req) stepUpResponse =
      (_) => http.Response('{}', 403, headers: _json);

  http.Response _catalog(String path) {
    final list = path.endsWith('experiences') ? experiences : larder;
    final body =
        catalogBodyOverride ?? jsonEncode({'success': true, 'data': list});
    return http.Response(body, catalogStatus, headers: _json);
  }

  ApiSanctuaryRepository repository() => ApiSanctuaryRepository(
      baseUrl: 'http://localhost:3001/api/v1', httpClient: client);
}

Future<SanctuarySnapshot> _fetchedSnapshot(ApiSanctuaryRepository repo) async {
  final result = await repo.fetchLiveSanctuary(_uuid);
  expect(result, isA<SanctuaryFetched>());
  return (result as SanctuaryFetched).snapshot;
}

void main() {
  group('Fetch classification of definitive rejections and bad payloads', () {
    test('test_fetchLiveSanctuary_http403AccessWindowExpired_returnsRejected',
        () async {
      final backend = _FakeBackend()..stayStatus = 403;
      final result = await backend.repository().fetchLiveSanctuary(_uuid);
      expect(result, isA<SanctuaryLinkRejected>());
    });

    final malformedBodies = <String, String>{
      'html from a proxy': '<html>Bad gateway</html>',
      'data is not an object': jsonEncode({'success': true, 'data': 'oops'}),
      'status has the wrong type': jsonEncode({
        'data': {'status': 42},
      }),
      'larder quantity has the wrong type': jsonEncode({
        'data': {
          'larderOrders': [
            {'catalogItemId': 'larder-mango', 'quantity': 'two'},
          ],
        },
      }),
      'midstay rating has the wrong type': jsonEncode({
        'data': {
          'midstayFeedback': [
            {'rating': 'five'},
          ],
        },
      }),
    };
    for (final entry in malformedBodies.entries) {
      test('test_fetchLiveSanctuary_malformed_${entry.key}_returnsUnreachable',
          () async {
        final backend = _FakeBackend()..stayBody = entry.value;
        final result = await backend.repository().fetchLiveSanctuary(_uuid);
        expect(result, isA<SanctuaryUnreachable>());
      });
    }
  });

  group('Catalogs come only from the server', () {
    test('test_catalog503OnLaterPoll_keepsLastGoodCatalogWithoutSeedItems',
        () async {
      final backend = _FakeBackend();
      final repo = backend.repository();
      await _fetchedSnapshot(repo);

      backend.catalogStatus = 503;
      final snapshot = await _fetchedSnapshot(repo);

      expect(snapshot.experiences.map((e) => e.id), equals(['exp-sunset']));
      expect(snapshot.larderItems.map((i) => i.id), equals(['larder-mango']));
    });

    test('test_malformedCatalogOnLaterPoll_keepsLastGoodCatalog', () async {
      final backend = _FakeBackend();
      final repo = backend.repository();
      await _fetchedSnapshot(repo);

      backend.catalogBodyOverride = '<html>oops</html>';
      final snapshot = await _fetchedSnapshot(repo);

      expect(snapshot.experiences.map((e) => e.id), equals(['exp-sunset']));
      expect(snapshot.larderItems.map((i) => i.id), equals(['larder-mango']));
    });

    test('test_catalogNeverAvailable_isEmptyNotSeeded', () async {
      final backend = _FakeBackend()..catalogStatus = 503;
      final snapshot = await _fetchedSnapshot(backend.repository());

      expect(snapshot.experiences, isEmpty);
      expect(snapshot.larderItems, isEmpty);
    });

    test('test_catalogEmptiedByServer_isEmpty', () async {
      final backend = _FakeBackend();
      final repo = backend.repository();
      await _fetchedSnapshot(repo);

      backend
        ..experiences = []
        ..larder = [];
      final snapshot = await _fetchedSnapshot(repo);

      expect(snapshot.experiences, isEmpty);
      expect(snapshot.larderItems, isEmpty);
    });

    test('test_mapSnapshot_withoutServerCatalogs_hasNoSeededPackagesOrMenus',
        () {
      final snapshot =
          SanctuaryWireMapper.mapSnapshot(_uuid, {'status': 'ACTIVE_STAY'});

      expect(snapshot.experiences, isEmpty);
      expect(snapshot.larderItems, isEmpty);
      expect(snapshot.yachtPackages, isEmpty);
      expect(snapshot.diningMenus, isEmpty);
      expect(snapshot.yachtCharter.vesselModel, isEmpty);
      expect(snapshot.diningReservation.selectedMenuId, isEmpty);
    });
  });

  group('Step-up verification needs a real server token', () {
    http.Response tokenResponse(String token) => http.Response(
        jsonEncode({
          'success': true,
          'data': {'stepUpToken': token},
        }),
        201,
        headers: _json);

    test('test_verifyStepUp_serverIssuesToken_returnsIt', () async {
      final backend = _FakeBackend()
        ..stepUpResponse = (_) => tokenResponse('hmac-abc');
      final token =
          await backend.repository().verifyStepUpChallenge(_uuid, '106');
      expect(token, equals('hmac-abc'));
    });

    test('test_verifyStepUp_sendsTypedAnswerNotTheStayVilla', () async {
      final backend = _FakeBackend()
        ..stepUpResponse = (_) => tokenResponse('t');
      final repo = backend.repository();
      await repo.verifyStepUpChallenge(_uuid, 'Villa 106');
      await repo.verifyStepUpChallenge(_uuid, 'Rostova');

      final bodies = backend.requests
          .where((r) => r.url.path.endsWith('/verify-step-up'))
          .map((r) => jsonDecode(r.body))
          .toList();
      expect(bodies[0], equals({'villaNumber': 'Villa 106'}));
      expect(bodies[1], equals({'lastName': 'Rostova'}));
    });

    final failures = <String, http.Response Function(http.Request)>{
      'http403': (_) => http.Response('{}', 403, headers: _json),
      'http500': (_) => http.Response('{}', 500, headers: _json),
      'okWithoutToken': (_) => http.Response(
          jsonEncode({'success': true, 'data': {}}), 200,
          headers: _json),
      'malformedBody': (_) => http.Response('<html/>', 200, headers: _json),
      'networkError': (req) =>
          throw http.ClientException('Failed to fetch', req.url),
    };
    for (final entry in failures.entries) {
      test('test_verifyStepUp_${entry.key}_returnsNullNotAFabricatedToken',
          () async {
        final backend = _FakeBackend()..stepUpResponse = entry.value;
        final token =
            await backend.repository().verifyStepUpChallenge(_uuid, 'Miller');
        expect(token, isNull);
      });
    }

    test('test_verifyStepUp_timeout_returnsNull', () async {
      final never = Completer<http.Response>();
      final repo = ApiSanctuaryRepository(
        httpClient: MockClient((_) => never.future),
        requestTimeout: const Duration(milliseconds: 10),
      );
      expect(await repo.verifyStepUpChallenge(_uuid, '102'), isNull);
    });

    test('test_verifyStepUp_networkDisabled_returnsNull', () async {
      final repo = ApiSanctuaryRepository(enableNetwork: false);
      expect(await repo.verifyStepUpChallenge(_uuid, '102'), isNull);
    });
  });
}
