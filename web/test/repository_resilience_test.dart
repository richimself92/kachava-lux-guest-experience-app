import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kachava_guest_portal/data/repositories/api_sanctuary_repository.dart';
import 'package:kachava_guest_portal/data/repositories/sanctuary_wire_mapper.dart';
import 'package:kachava_guest_portal/domain/entities/concierge_folio_entities.dart';
import 'package:kachava_guest_portal/domain/repositories/sanctuary_repository.dart';

import 'support/villa_102_seed_data.dart';

const _uuid = '3f2b8c1e-4d5a-4b6c-8d7e-9f0a1b2c3d4e';
const _json = {'content-type': 'application/json; charset=utf-8'};

ApiSanctuaryRepository _repoReturning(int status, {Object? body}) =>
    ApiSanctuaryRepository(
      baseUrl: 'http://localhost:3001/api/v1',
      httpClient: MockClient((_) async => http.Response(
          jsonEncode(body ?? {'success': status < 300, 'data': {}}), status,
          headers: _json)),
    );

void main() {
  group('ApiSanctuaryRepository fetch classification', () {
    for (final status in [401, 404]) {
      test('test_fetchLiveSanctuary_http${status}_returnsLinkRejected',
          () async {
        final result = await _repoReturning(status).fetchLiveSanctuary(_uuid);
        expect(result, isA<SanctuaryLinkRejected>());
      });
    }

    for (final status in [500, 502, 503, 429]) {
      test('test_fetchLiveSanctuary_http${status}_returnsUnreachable',
          () async {
        final result = await _repoReturning(status).fetchLiveSanctuary(_uuid);
        expect(result, isA<SanctuaryUnreachable>());
      });
    }

    test('test_fetchLiveSanctuary_timeout_returnsUnreachable', () async {
      final never = Completer<http.Response>();
      final repo = ApiSanctuaryRepository(
        httpClient: MockClient((_) => never.future),
        requestTimeout: const Duration(milliseconds: 10),
      );
      expect(await repo.fetchLiveSanctuary(_uuid), isA<SanctuaryUnreachable>());
    });

    test('test_fetchLiveSanctuary_networkError_returnsUnreachable', () async {
      final repo = ApiSanctuaryRepository(
        httpClient: MockClient((req) async =>
            throw http.ClientException('Failed to fetch', req.url)),
      );
      expect(await repo.fetchLiveSanctuary(_uuid), isA<SanctuaryUnreachable>());
    });

    test('test_fetchLiveSanctuary_networkDisabled_returnsUnreachable',
        () async {
      final repo = ApiSanctuaryRepository(enableNetwork: false);
      expect(await repo.fetchLiveSanctuary(_uuid), isA<SanctuaryUnreachable>());
    });

    test('test_fetchLiveSanctuary_http200_returnsFetchedSnapshot', () async {
      final repo = _repoReturning(200, body: {
        'success': true,
        'data': {'status': 'ACTIVE_STAY', 'villaName': 'Villa 106'},
      });
      final result = await repo.fetchLiveSanctuary(_uuid);
      expect(result, isA<SanctuaryFetched>());
      final snapshot = (result as SanctuaryFetched).snapshot;
      expect(snapshot.stay.villaTitle, equals('Villa 106'));
    });
  });

  group('ApiSanctuaryRepository mutation results', () {
    final snapshot = Villa102SeedData.buildDefaultSnapshot(_uuid);

    test('test_mutation_http201_returnsConfirmed', () async {
      final result = await _repoReturning(201)
          .saveYachtCharter(_uuid, snapshot.yachtCharter);
      expect(result, isA<MutationConfirmed>());
    });

    for (final status in [400, 404, 429, 500, 503]) {
      test('test_mutation_http${status}_returnsFailed', () async {
        final result = await _repoReturning(status)
            .saveYachtCharter(_uuid, snapshot.yachtCharter);
        expect(result, isA<MutationFailed>());
      });
    }

    test('test_mutation_networkError_returnsFailed', () async {
      final repo = ApiSanctuaryRepository(
        httpClient: MockClient((req) async =>
            throw http.ClientException('Failed to fetch', req.url)),
      );
      final result = await repo.submitMidStayCheckIn(
        _uuid,
        const MidStayCheckIn(
          rating: 4,
          sentimentId: 'tuned',
          housekeepingWindow: '10:30 AM',
          focusAreas: [],
          notes: '',
          requestPriorityCallback: false,
          submittedAtLabel: 'Submitted',
        ),
      );
      expect(result, isA<MutationFailed>());
    });

    test('test_mutation_networkDisabled_returnsFailed', () async {
      final repo = ApiSanctuaryRepository(enableNetwork: false);
      final result = await repo.syncFlightTransport(_uuid, snapshot.transport);
      expect(result, isA<MutationFailed>());
    });
  });

  group('SanctuaryWireMapper builds only from server data', () {
    test('test_mapSnapshot_missingServerFields_leavesThemEmptyNotSeeded', () {
      final snapshot =
          SanctuaryWireMapper.mapSnapshot(_uuid, {'status': 'ACTIVE_STAY'});
      final stay = snapshot.stay;

      expect(stay.guestUuid, equals(_uuid));
      expect(stay.guestNames, isEmpty);
      expect(stay.primaryGuestName, isEmpty);
      expect(stay.partnerName, isEmpty);
      expect(stay.lastName, isEmpty);
      expect(stay.villaNumber, isEmpty);
      expect(stay.villaTitle, isEmpty);
      expect(stay.celebrationTitle, isEmpty);
      expect(stay.stayDates, isEmpty);
      expect(stay.wifiSsid, isEmpty);
      expect(stay.wifiPassphrase, isEmpty);
      expect(stay.folioCardLabel, isEmpty);
      expect(snapshot.transport.flightNumber, isEmpty);
      expect(snapshot.transport.assignedDriver, isEmpty);
      expect(snapshot.preferences.pillowType, isEmpty);
      expect(snapshot.preferences.allergyAlerts, isEmpty);
      expect(snapshot.checklist, isEmpty);
      expect(snapshot.conciergeRequests, isEmpty);
      expect(snapshot.folioItems, isEmpty);
      expect(snapshot.chatMessages, isEmpty);
      expect(snapshot.latestMidStayCheckIn, isNull);
    });

    test('test_mapSnapshot_serverGuestCard_mapsCoupleAndPartySize', () {
      final snapshot = SanctuaryWireMapper.mapSnapshot(_uuid, {
        'status': 'PRE_ARRIVAL',
        'villaName': 'Villa 110 — Akumal',
        'guestsCount': 3,
        'selectedSignaturePrivilege': 'golf',
        'guestProfile': {
          'name': 'Elena Rostova',
          'partner': 'Ivan Rostov',
          'folioCard': 'Amex ending in 1005',
        },
      });
      expect(snapshot.stay.guestNames, equals('Elena Rostova'));
      expect(snapshot.stay.partnerName, equals('Ivan Rostov'));
      expect(snapshot.stay.guestsCount, equals(3));
      expect(snapshot.stay.selectedSignaturePrivilege, equals('golf'));
      expect(snapshot.stay.folioCardLabel, equals('Amex ending in 1005'));
    });
  });
}
