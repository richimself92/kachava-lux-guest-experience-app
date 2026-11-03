import 'package:kachava_admin_dashboard/domain/catalog_values.dart';
import 'package:kachava_admin_dashboard/domain/list_query.dart';
import 'package:kachava_admin_dashboard/domain/paged_result.dart';
import 'package:kachava_admin_dashboard/domain/service_catalog_enums.dart';
import 'package:kachava_admin_dashboard/domain/service_request.dart';

import 'in_memory_paged_source.dart';

/// A generated queue row (no business data).
ServiceRequest testRequest(int n,
        {String status = RequestStatusValues.received, bool isOrder = false}) =>
    ServiceRequest(
      id: 'req_$n',
      isOrder: isOrder,
      guestName: 'Guest $n',
      villaName: 'Villa $n',
      serviceName: LocalizedText(en: 'Service $n', es: 'Servicio $n'),
      at: '2026-11-${(n % 28 + 1).toString().padLeft(2, '0')}T10:00',
      quantity: 2,
      status: status,
      lines: [
        ServiceRequestLine(
            name: LocalizedText(en: 'Item $n', es: 'Ítem $n'), quantity: 2)
      ],
      totalUSD: 40,
    );

/// Test-only queue applying the backend rules: `status` (or OPEN), search on
/// guest/service, sort `at`, and the action -> status moves.
class FakeServiceRequestRepository implements ServiceRequestRepository {
  final List<ServiceRequest> requests = [];
  final List<(ServiceSection, ListQuery)> queries = [];
  final List<(String, RequestAction, String?)> moves = [];
  Object? failMovesWith;

  @override
  Future<PagedResult<ServiceRequest>> list(
      ServiceSection section, ListQuery query) async {
    queries.add((section, query));
    final status = query.filters['status'];
    final rest = Map.of(query.filters)
      ..remove('status')
      ..remove('range');
    final matching = requests.where((r) => switch (status) {
          null => true,
          RequestStatusValues.open => r.actions.isNotEmpty,
          _ => r.status == status,
        });
    return InMemoryPagedSource<ServiceRequest>(
      items: matching.toList(),
      searchText: (r) => [r.guestName, r.serviceName.en],
      sortValue: (r, _) => r.at,
    ).page(ListQuery(
        q: query.q,
        filters: rest,
        sort: query.sort,
        page: query.page,
        pageSize: query.pageSize));
  }

  @override
  Future<ServiceRequest> transition(String id, RequestAction action,
      {String? reason}) async {
    moves.add((id, action, reason));
    if (failMovesWith != null) throw failMovesWith!;
    final index = requests.indexWhere((r) => r.id == id);
    final r = requests[index];
    final next = ServiceRequest(
      id: r.id,
      isOrder: r.isOrder,
      guestName: r.guestName,
      villaName: r.villaName,
      serviceName: r.serviceName,
      at: r.at,
      quantity: r.quantity,
      status: switch (action) {
        RequestAction.confirm => RequestStatusValues.confirmed,
        RequestAction.start => RequestStatusValues.preparing,
        RequestAction.complete => RequestStatusValues.done,
        RequestAction.cancel => RequestStatusValues.cancelled,
      },
      lines: r.lines,
      totalUSD: r.totalUSD,
      cancellationReason: reason,
    );
    requests[index] = next;
    return next;
  }
}
