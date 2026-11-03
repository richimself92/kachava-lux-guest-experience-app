import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kachava_admin_dashboard/data/http_operations_repositories.dart';
import 'package:kachava_admin_dashboard/data/http_stay_repositories.dart';
import 'package:kachava_admin_dashboard/domain/admin_task.dart';
import 'package:kachava_admin_dashboard/domain/list_query.dart';
import 'package:kachava_admin_dashboard/domain/reservation.dart';
import 'package:kachava_admin_dashboard/domain/trip_repository.dart';

import '../support/signed_in_api_client.dart';
import 'recorded_operations_contract.dart';

/// Answers every request with [respond] and records it.
class _Server {
  _Server(this.respond);

  final Object Function(http.Request request) respond;
  final List<http.Request> requests = [];

  late final MockClient client = MockClient((request) async {
    requests.add(request);
    final body = respond(request);
    if (body is http.Response) return body;
    return http.Response(jsonEncode(body), 200,
        headers: {'content-type': 'application/json'});
  });

  http.Request get last => requests.last;
  String get lastTarget =>
      '${last.method} ${last.url.path}'.replaceFirst('/api/v1/admin', '');
  Map<String, dynamic> get lastBody =>
      jsonDecode(last.body) as Map<String, dynamic>;
}

void main() {
  group('dashboard', () {
    test('GET /dashboard maps KPIs, resort day and ≤ 8 activity rows',
        () async {
      final server = _Server((_) => wrapped(recordedDashboard));
      final view =
          await HttpDashboardRepository(signedInApiClient(server.client))
              .fetch();
      expect(server.lastTarget, 'GET /dashboard');
      expect(view.resortDate, '2026-11-03');
      expect(view.kpis.occupancyPct, 63);
      expect(view.kpis.openRequests, 4);
      expect(view.rows.first.overdue, isTrue);
      expect(view.rows.last.status, 'ARRIVAL');
      expect(view.total, 9);
    });

    test('422 SETTINGS_REQUIRED becomes SettingsRequiredException', () async {
      final server = _Server((_) => http.Response(
          jsonEncode({
            'statusCode': 422,
            'code': 'SETTINGS_REQUIRED',
            'details': ['timeZone']
          }),
          422));
      final repo = HttpDashboardRepository(signedInApiClient(server.client));
      await expectLater(
          repo.fetch(),
          throwsA(isA<SettingsRequiredException>()
              .having((e) => e.details, 'details', ['timeZone'])));
    });
  });

  group('reservations', () {
    late _Server server;
    late HttpReservationRepository repo;

    setUp(() {
      server = _Server((request) => switch (request.url.path) {
            final p when p.endsWith('/folio') => wrapped(recordedFolio),
            final p when p.endsWith('/stays') && request.method == 'GET' =>
              paged([recordedReservationRow], total: 31),
            final p when p.endsWith('/stays') => wrapped({
                'stay': {'stayId': 'stay_new'},
                'magicLinkUrl': 'http://localhost:3000/?guestId=u'
              }),
            _ => wrapped(recordedStayDetail),
          });
      repo = HttpReservationRepository(signedInApiClient(server.client));
    });

    test('list sends status, villa, sort and the date range as from/to',
        () async {
      final page = await repo.list(const ListQuery(sort: ListSort('checkIn'))
          .withFilter('status', 'PRE_ARRIVAL')
          .withFilter('villaId', 'v1')
          .withFilter('range', '2026-11-03..2026-11-09'));
      final params = server.last.url.queryParameters;
      expect(server.lastTarget, 'GET /stays');
      expect(params['status'], 'PRE_ARRIVAL');
      expect(params['villaId'], 'v1');
      expect(params['from'], '2026-11-03');
      expect(params['to'], '2026-11-09');
      expect(params['sort'], 'checkIn:asc');
      expect(params.containsKey('range'), isFalse);
      expect(page.total, 31);
      final row = page.items.single;
      expect(row.guestName, 'Ana Ruiz');
      expect(row.resortHostName, isNull);
      expect(row.magicLinkUrl, contains('guestId=uuid-1'));
    });

    test('detail maps host, Wi-Fi, notes and history', () async {
      final detail = await repo.get('stay_a');
      expect(server.lastTarget, 'GET /stays/stay_a');
      expect(detail.nights, 4);
      expect(detail.resortHostStaffId, 'stf_1');
      expect(detail.wifiSsid, 'Ceiba');
      expect(detail.internalNotes, 'VIP');
      expect(detail.statusHistory.single.to, 'ACTIVE_STAY');
    });

    test('PATCH sends only set fields; wifi nested; action + reason', () async {
      await repo.update(
          'stay_a',
          const ReservationPatch(
              internalNotes: 'Late arrival',
              wifiSsid: 'New',
              action: 'CANCEL',
              reason: 'Flight cancelled'));
      expect(server.lastTarget, 'PATCH /stays/stay_a');
      expect(server.lastBody, {
        'internalNotes': 'Late arrival',
        'wifi': {'ssid': 'New'},
        'action': 'CANCEL',
        'reason': 'Flight cancelled',
      });
    });

    test('POST /stays returns the new stay id', () async {
      final id = await repo.create(const NewReservation(
          guestName: ' Ana ',
          villaId: 'v1',
          checkIn: '2026-11-03',
          checkOut: '2026-11-07',
          guestsCount: 2,
          language: 'es'));
      expect(id, 'stay_new');
      expect(server.lastTarget, 'POST /stays');
      expect(server.lastBody, {
        'guestName': 'Ana',
        'villaId': 'v1',
        'checkIn': '2026-11-03',
        'checkOut': '2026-11-07',
        'guestsCount': 2,
        'language': 'es',
      });
    });

    test('folio maps services, rating, charges and total', () async {
      final folio = await repo.folio('stay_a');
      expect(server.lastTarget, 'GET /stays/stay_a/folio');
      expect(folio.services, hasLength(2));
      expect(folio.trips.single.id, 'trip_1');
      expect(folio.trips.single.name.of(true), 'Traslado');
      expect(folio.rating, 5);
      expect(folio.charges.single.amountUSD, 120.5);
      expect(folio.totalUSD, 1234.5);
    });
  });

  test('guests: list rows and the staff-only profile', () async {
    final server = _Server((request) => request.url.path.endsWith('/guests')
        ? paged([recordedGuestProfile])
        : wrapped(recordedGuestProfile));
    final repo = HttpGuestRepository(signedInApiClient(server.client));
    final row = (await repo.list(const ListQuery())).items.single;
    expect(row.hasAllergies, isTrue);
    expect(row.openRequests, 2);
    final profile = await repo.get('stay_a');
    expect(server.lastTarget, 'GET /guests/stay_a');
    expect(profile.allergies, ['Shellfish']);
    expect(profile.occasion, 'Anniversary');
    expect(profile.preferences.map((p) => p.key),
        ['pillow', 'dietary', 'interests', 'choice']);
    expect(profile.requestHistory.single.open, isTrue);
  });

  group('tasks', () {
    test('list filters and overdue; transition body', () async {
      final server = _Server((request) => request.method == 'GET'
          ? paged([recordedTask])
          : wrapped({...recordedTask, 'status': 'ASSIGNED'}));
      final repo = HttpTaskRepository(signedInApiClient(server.client));
      final page = await repo.list(const ListQuery(sort: ListSort('dueAt'))
          .withFilter('overdue', 'true')
          .withFilter('owner', 'stf_1'));
      expect(server.last.url.queryParameters, containsPair('overdue', 'true'));
      expect(server.last.url.queryParameters, containsPair('owner', 'stf_1'));
      final task = page.items.single;
      expect(task.overdue, isTrue);
      expect(task.stayId, 'stay_a');
      expect(task.villaGuest, 'Casa Ceiba · Ana Ruiz');
      expect(task.nextStatus, TaskValues.assigned);

      final moved = await repo.transition(
          'task_1',
          const TaskTransition(
              to: 'ASSIGNED', ownerStaffId: 'stf_1', ownerName: 'Lucia'));
      expect(server.lastTarget, 'POST /tasks/task_1/transition');
      expect(server.lastBody,
          {'to': 'ASSIGNED', 'ownerStaffId': 'stf_1', 'ownerName': 'Lucia'});
      expect(moved.status, 'ASSIGNED');
    });

    test('create posts title, category, priority, due and stay', () async {
      final server = _Server((_) => wrapped(recordedTask));
      await HttpTaskRepository(signedInApiClient(server.client)).create(
          const NewTask(
              title: 'Towels',
              category: 'Housekeeping',
              dueAt: '2026-11-03T18:00',
              stayId: 'stay_a'));
      expect(server.lastTarget, 'POST /tasks');
      expect(server.lastBody, {
        'title': 'Towels',
        'category': 'Housekeeping',
        'priority': 'NORMAL',
        'dueAt': '2026-11-03T18:00',
        'stayId': 'stay_a',
      });
    });
  });

  test('notifications: list, read, read-all and bell counts', () async {
    final server = _Server((request) {
      final path = request.url.path;
      if (path.endsWith('/unread-count')) {
        return wrapped({'unreadCount': 7, 'urgentUnreadCount': 2});
      }
      if (path.endsWith('/read-all')) return wrapped({'marked': 7});
      if (path.endsWith('/read')) {
        return wrapped({...recordedNotification, 'read': true});
      }
      return paged([recordedNotification], extra: {'unreadCount': 7});
    });
    final repo = HttpNotificationRepository(signedInApiClient(server.client));
    final n = (await repo.list(const ListQuery().withFilter('read', 'false')))
        .items
        .single;
    expect(server.last.url.queryParameters['read'], 'false');
    expect(n.level, 'ACTION');
    expect(n.target.type, 'CONVERSATION');
    expect(n.target.stayId, 'stay_a');
    expect((await repo.markRead('alert_1')).read, isTrue);
    expect(server.lastTarget, 'POST /notifications/alert_1/read');
    expect(await repo.markAllRead(), 7);
    expect(server.lastTarget, 'POST /notifications/read-all');
    final counts = await repo.unreadCounts();
    expect(server.lastTarget, 'GET /notifications/unread-count');
    expect((counts.unread, counts.urgentUnread), (7, 2));
  });

  test('conversations: inbox, messages, reply and read mark', () async {
    final server = _Server((request) {
      final path = request.url.path;
      if (path.endsWith('/conversations')) {
        return paged([recordedConversationRow]);
      }
      if (path.endsWith('/read')) return wrapped(recordedConversationRow);
      if (request.method == 'POST') {
        return wrapped({
          ...recordedMessage,
          'id': 'req_1:1',
          'from': 'STAFF',
          'photoUrl': null
        });
      }
      return paged([recordedMessage]);
    });
    final repo = HttpConversationRepository(signedInApiClient(server.client));
    final row =
        (await repo.list(const ListQuery().withFilter('awaitingReply', 'true')))
            .items
            .single;
    expect(server.last.url.queryParameters['awaitingReply'], 'true');
    expect(row.unreadCount, 2);
    expect(row.lastHasPhoto, isTrue);
    final message =
        (await repo.messages('stay_a', const ListQuery(pageSize: 50)))
            .items
            .single;
    expect(server.lastTarget, 'GET /conversations/stay_a/messages');
    expect(message.fromGuest, isTrue);
    expect(message.photoUrl, contains('signed'));
    final sent = await repo.reply('stay_a', ' On it ');
    expect(server.lastTarget, 'POST /conversations/stay_a/messages');
    expect(server.lastBody, {'text': 'On it'});
    expect(sent.fromGuest, isFalse);
    await repo.markRead('stay_a');
    expect(server.lastTarget, 'POST /conversations/stay_a/read');
  });
}
