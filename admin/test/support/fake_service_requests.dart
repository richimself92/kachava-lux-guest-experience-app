import 'package:kachava_admin_dashboard/domain/admin_task.dart';
import 'package:kachava_admin_dashboard/domain/catalog_values.dart';
import 'package:kachava_admin_dashboard/domain/list_query.dart';
import 'package:kachava_admin_dashboard/domain/paged_result.dart';
import 'package:kachava_admin_dashboard/domain/service_catalog_enums.dart';
import 'package:kachava_admin_dashboard/domain/service_request.dart';

import 'in_memory_paged_source.dart';

/// A generated queue row (no business data).
ServiceRequest testRequest(int n,
        {String status = RequestStatusValues.received,
        bool isOrder = false,
        String? usageType,
        String? section,
        String notes = '',
        DateTime? createdAt,
        List<ServiceRequestLine>? lines}) =>
    ServiceRequest(
      id: 'req_$n',
      isOrder: isOrder,
      guestName: 'Guest $n',
      villaName: 'Villa $n',
      serviceName: LocalizedText(en: 'Service $n', es: 'Servicio $n'),
      at: '2026-11-${(n % 28 + 1).toString().padLeft(2, '0')}T10:00',
      quantity: 2,
      status: status,
      lines: lines ??
          [
            ServiceRequestLine(
                name: LocalizedText(en: 'Item $n', es: 'Ítem $n'), quantity: 2)
          ],
      totalUSD: 40,
      usageType: usageType,
      section: section,
      notes: notes,
      createdAt: createdAt,
    );

/// Test-only queue applying the backend rules: `status` (or OPEN), search on
/// guest/service, sort `at`, and the action -> status moves.
class FakeServiceRequestRepository implements ServiceRequestRepository {
  final List<ServiceRequest> requests = [];
  final List<(ServiceSection?, ListQuery)> queries = [];
  final List<(String, RequestAction, String?)> moves = [];
  Object? failMovesWith;

  @override
  Future<PagedResult<ServiceRequest>> list(
      ServiceSection? section, ListQuery query) async {
    queries.add((section, query));
    final f = query.filters;
    final status = f['status'];
    final rest = Map.of(f)
      ..remove('status')
      ..remove('range')
      ..remove('section')
      ..remove('usageType');
    final matching = requests.where((r) =>
        switch (status) {
          null => true,
          RequestStatusValues.open => r.actions.isNotEmpty,
          _ => r.status == status,
        } &&
        (f['section'] == null || f['section'] == r.section) &&
        (f['usageType'] == null || f['usageType'] == r.usageType));
    return InMemoryPagedSource<ServiceRequest>(
      items: matching.toList(),
      searchText: (r) => [r.guestName, r.serviceName.en],
      sortValue: (r, field) => field == 'queue'
          ? '${_rank(r.status)}|${r.createdAt?.toIso8601String() ?? r.at}'
          : r.at,
    ).page(ListQuery(
        q: query.q,
        filters: rest,
        sort: query.sort,
        page: query.page,
        pageSize: query.pageSize));
  }

  final List<String> ensuredTasks = [];

  @override
  Future<AdminTask> ensureTask(String id) async {
    ensuredTasks.add(id);
    return AdminTask(
        id: 'task_for_$id',
        title: 'Confirm: $id',
        category: 'IN_VILLA',
        priority: 'NORMAL',
        status: TaskValues.pending,
        overdue: false,
        sourceType: 'BOOKING',
        sourceRefId: id);
  }

  @override
  Future<ServiceRequest> transition(String id, RequestAction action,
      {String? reason}) async {
    moves.add((id, action, reason));
    if (failMovesWith != null) throw failMovesWith!;
    final index = requests.indexWhere((r) => r.id == id);
    final r = requests[index];
    final next = r.withStatus(
        switch (action) {
          RequestAction.confirm => RequestStatusValues.confirmed,
          RequestAction.start => RequestStatusValues.preparing,
          RequestAction.complete => RequestStatusValues.done,
          RequestAction.cancel => RequestStatusValues.cancelled,
        },
        cancellationReason: reason);
    requests[index] = next;
    return next;
  }
}

int _rank(String status) => switch (status) {
      RequestStatusValues.received => 0,
      RequestStatusValues.done || RequestStatusValues.cancelled => 2,
      _ => 1,
    };
