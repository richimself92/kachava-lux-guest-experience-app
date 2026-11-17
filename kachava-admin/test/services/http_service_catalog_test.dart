import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kachava_admin_dashboard/data/catalog_rule_violation.dart';
import 'package:kachava_admin_dashboard/data/http_service_catalog_repository.dart';
import 'package:kachava_admin_dashboard/domain/admin_service.dart';
import 'package:kachava_admin_dashboard/domain/catalog_values.dart';
import 'package:kachava_admin_dashboard/domain/list_query.dart';

import '../support/signed_in_api_client.dart';
import 'service_model_test.dart' show serviceJson;

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
      'data': data,
      'meta': {'page': 1, 'pageSize': 25, 'total': data.length},
    };

/// Signed uploads (method + headers) are covered in
/// test/list/http_catalog_repositories_test.dart.
void main() {
  group('HttpServiceCatalogRepository', () {
    test('lists with filters and parses the backend shape', () async {
      final server = _Server((_) => _page([serviceJson()]));
      final repo =
          HttpServiceCatalogRepository(signedInApiClient(server.client));
      final page = await repo.list(const ListQuery()
          .withFilter('section', 'DINING')
          .withFilter('usageType', 'ORDER')
          .withSort(const ListSort('order')));
      expect(server.last.url.path, '/api/v1/admin/services');
      expect(server.last.url.queryParameters, {
        'page': '1',
        'pageSize': '25',
        'sort': 'order:asc',
        'section': 'DINING',
        'usageType': 'ORDER',
      });
      expect(page.items.single.kind, ServiceKind.bar);
    });

    test('create POSTs the kind; update PATCHes without it', () async {
      final server = _Server((r) => {
            'data': {...serviceJson(), 'id': 's9'}
          });
      final repo =
          HttpServiceCatalogRepository(signedInApiClient(server.client));
      final draft =
          AdminService.parse(AdminService.emptyDraft(ServiceKind.experience));
      final created = await repo.create(draft);
      expect(server.last.method, 'POST');
      expect(server.lastBody['kind'], 'EXPERIENCE');
      expect(server.lastBody['section'], 'EXPERIENCES');
      expect(server.lastBody['experience'], isA<Map>());
      expect(created.id, 's9');

      await repo.update(AdminService.fromJson(serviceJson()));
      expect(server.last.method, 'PATCH');
      expect(server.last.url.path, '/api/v1/admin/services/s1');
      expect(server.lastBody.containsKey('kind'), isFalse);
      expect(server.lastBody['bar'], {'ageConfirmationRequired': true});
    });

    test('a 422 activation surfaces as a CatalogRuleViolation', () async {
      final server = _Server((_) => http.Response(
          jsonEncode({
            'statusCode': 422,
            'message':
                'Service cannot be active: cover image is required; name.es is required',
          }),
          422));
      final repo =
          HttpServiceCatalogRepository(signedInApiClient(server.client));
      Object? error;
      try {
        await repo.update(AdminService.fromJson(serviceJson(status: 'ACTIVE')));
      } catch (e) {
        error = e;
      }
      expect(CatalogRuleViolation.tryParse(error!)?.problems,
          ['cover image is required', 'name.es is required']);
    });

    test('items: paths and priceUSD body', () async {
      final server = _Server((r) {
        if (r.method == 'GET') {
          return _page([
            {
              'id': 'i1',
              'name': {'en': 'Mezcal', 'es': 'Mezcal'},
              'priceUSD': 12.5,
              'status': 'ACTIVE'
            }
          ]);
        }
        return {
          'data': {'id': 'i2', ...jsonDecode(r.body) as Map}
        };
      });
      final repo =
          HttpServiceCatalogRepository(signedInApiClient(server.client));
      final items = await repo.listItems('s1', const ListQuery());
      expect(server.last.url.path, '/api/v1/admin/services/s1/items');
      expect(items.items.single.priceUSD, 12.5);

      await repo.createItem(
          's1', const ServiceItem(name: LocalizedText(en: 'Tea'), priceUSD: 3));
      expect(server.last.method, 'POST');
      expect(server.lastBody['priceUSD'], 3);
      await repo.updateItem(
          's1', const ServiceItem(id: 'i1', name: LocalizedText(en: 'Tea')));
      expect(server.last.method, 'PATCH');
      expect(server.last.url.path, '/api/v1/admin/services/s1/items/i1');
    });
  });
}
