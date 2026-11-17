import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kachava_admin_dashboard/data/http_service_request_repository.dart';
import 'package:kachava_admin_dashboard/data/http_stay_repositories.dart';
import 'package:kachava_admin_dashboard/domain/admin_trip.dart';
import 'package:kachava_admin_dashboard/domain/list_query.dart';
import 'package:kachava_admin_dashboard/domain/service_catalog_enums.dart';
import 'package:kachava_admin_dashboard/domain/service_request.dart';
import 'package:kachava_admin_dashboard/domain/staff_member.dart';

import '../support/signed_in_api_client.dart';

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
  Map<String, dynamic> get lastBody =>
      jsonDecode(last.body) as Map<String, dynamic>;
}

Map<String, dynamic> _page(List<Map<String, dynamic>> data) => {
      'success': true,
      'data': data,
      'meta': {'page': 1, 'pageSize': 25, 'total': data.length},
    };

/// Recorded shape of one `GET /admin/requests` entry.
Map<String, dynamic> requestJson({String status = 'RECEIVED'}) => {
      'id': 'bk_1',
      'requestId': 'bk_1',
      'kind': 'BOOKING',
      'stayId': 'stay_1',
      'guestName': 'Ana Ruiz',
      'villaName': 'Villa Sol',
      'serviceId': 'svc_1',
      'serviceName': {'en': 'Cenote swim', 'es': 'Nado en cenote'},
      'section': 'EXPERIENCES',
      'at': '2026-12-02T10:00',
      'quantity': 3,
      'status': status,
      'open': true,
      'lines': [
        {
          'name': {'en': 'Cenote swim', 'es': 'Nado en cenote'},
          'quantity': 1
        }
      ],
      'totalUSD': 150,
      'cancellationReason': null,
    };

Map<String, dynamic> staffJson() => {
      'id': 'staff_1',
      'staffId': 'staff_1',
      'fullName': 'Lucia Perez',
      'shortName': 'Lucia',
      'role': '',
      'department': 'CULINARY',
      'rbacRole': 'DEPARTMENT_COORDINATOR',
      'email': 'lucia@resort.test',
      'phone': '',
      'isActive': true,
    };

void main() {
  group('HttpServiceRequestRepository', () {
    test('lists the section with status, day range, search and sort', () async {
      final server = _Server((_) => _page([requestJson()]));
      final repo =
          HttpServiceRequestRepository(signedInApiClient(server.client));
      final page = await repo.list(
          ServiceSection.experiences,
          const ListQuery(sort: ListSort('at'))
              .withFilter('status', 'OPEN')
              .withFilter(TripDateRange.filterKey, '2026-12-01..2026-12-07')
              .withSearch('ana'));

      expect(server.last.url.path, '/api/v1/admin/requests');
      expect(server.last.url.queryParameters, {
        'page': '1',
        'pageSize': '25',
        'sort': 'at:asc',
        'q': 'ana',
        'status': 'OPEN',
        'from': '2026-12-01',
        'to': '2026-12-07',
        'section': 'EXPERIENCES',
      });
      final r = page.items.single;
      expect(r.guestName, 'Ana Ruiz');
      expect(r.serviceName.es, 'Nado en cenote');
      expect((r.day, r.time), ('2026-12-02', '10:00'));
      expect(r.quantity, 3);
      expect(r.isOrder, isFalse);
      expect(r.actions,
          [RequestAction.confirm, RequestAction.start, RequestAction.cancel]);
    });

    test('posts one action (with the cancel reason) and reads the answer',
        () async {
      final server = _Server(
          (_) => {'success': true, 'data': requestJson(status: 'CANCELLED')});
      final repo =
          HttpServiceRequestRepository(signedInApiClient(server.client));

      final moved =
          await repo.transition('bk_1', RequestAction.cancel, reason: ' Rain ');

      expect(server.last.method, 'POST');
      expect(server.last.url.path, '/api/v1/admin/requests/bk_1/transition');
      expect(server.lastBody, {'action': 'CANCEL', 'reason': 'Rain'});
      expect(moved.status, 'CANCELLED');
      expect(moved.actions, isEmpty);
    });
  });

  group('staff', () {
    test('owner pickers read only active staff', () async {
      final server = _Server((_) => _page([staffJson()]));
      final list =
          await HttpStaffDirectoryRepository(signedInApiClient(server.client))
              .list();

      expect(server.last.url.queryParameters,
          {'isActive': 'true', 'pageSize': '100'});
      expect(list.single.fullName, 'Lucia Perez');
    });

    test('roster pages, creates, edits and deactivates', () async {
      final server = _Server((request) => request.method == 'GET'
          ? _page([staffJson()])
          : {'success': true, 'data': staffJson()});
      final repo = HttpStaffRosterRepository(signedInApiClient(server.client));

      final page =
          await repo.page(const ListQuery().withFilter('isActive', 'false'));
      expect(server.last.url.queryParameters['isActive'], 'false');
      expect(page.items.single.department, StaffDepartment.culinary);

      await repo.create(page.items.single);
      expect(server.last.method, 'POST');
      expect(server.lastBody, {
        'fullName': 'Lucia Perez',
        'rbacRole': 'DEPARTMENT_COORDINATOR',
        'department': 'CULINARY',
        'email': 'lucia@resort.test',
        'phone': '',
        'role': '',
      });

      await repo.update(page.items.single);
      expect(server.last.method, 'PATCH');
      expect(server.last.url.path, '/api/v1/admin/staff/staff_1');

      await repo.setActive('staff_1', false);
      expect(server.lastBody, {'isActive': false});
    });

    test('a used email (409) is StaffEmailTakenException', () async {
      final server = _Server((_) => http.Response('{"statusCode":409}', 409));
      final repo = HttpStaffRosterRepository(signedInApiClient(server.client));
      const member = StaffMember(
        staffId: '',
        fullName: 'X',
        shortName: '',
        role: '',
        department: StaffDepartment.concierge,
        rbacRole: StaffRole.hostAdmin,
        email: 'x@test.local',
        phone: '',
      );

      expect(
          () => repo.create(member), throwsA(isA<StaffEmailTakenException>()));
    });
  });
}
