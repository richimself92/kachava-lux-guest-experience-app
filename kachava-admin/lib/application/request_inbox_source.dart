import 'dart:math' as math;

import '../domain/admin_trip.dart';
import '../domain/inbox_item.dart';
import '../domain/list_query.dart';
import '../domain/paged_result.dart';
import '../domain/service_request.dart';
import '../domain/trip_repository.dart';

/// Status filter values of the inbox (requests and trips share them).
abstract final class InboxStatusFilter {
  static const String open = 'OPEN';
  static const String fresh = 'NEW';
  static const String done = 'DONE';
  static const String cancelled = 'CANCELLED';
  static const List<String> all = [open, fresh, done, cancelled];
}

/// The guest's new requests: the badge count and the rows behind it.
class FreshRequests {
  const FreshRequests({required this.items, required this.count});

  static const FreshRequests none = FreshRequests(items: [], count: 0);

  final List<InboxItem> items;
  final int count;
}

/// The Requests inbox: `/admin/requests` (every section, `sort=queue`)
/// merged with `/admin/trips`. Filters `status` ([InboxStatusFilter]),
/// `section`, `type` ([InboxType] wire); `q` searches guest/service.
///
/// Requests are paged by the server. When trips are merged in, page N reads
/// the first N × pageSize requests (capped at [maxDepth]) plus the trips
/// (bounded by the backend) and slices the merged queue.
class RequestInboxSource {
  RequestInboxSource({required this.requests, this.trips});

  static const int maxDepth = 100;
  static const ListQuery initialQuery =
      ListQuery(filters: {'status': InboxStatusFilter.open});

  final ServiceRequestRepository requests;
  final TripRepository? trips;

  Future<PagedResult<InboxItem>> list(ListQuery query) async {
    final f = query.filters;
    final type = f['type'];
    final withTrips = trips != null &&
        (type == null || type == InboxType.trip.wire) &&
        (f['section'] == null || f['section'] == 'TRANSPORTATION');
    final withRequests = type != InboxType.trip.wire;
    if (!withTrips) return _requestsOnly(query);
    final depth = math.min(query.page * query.pageSize, maxDepth);
    final reqPage = withRequests
        ? await requests.list(null, _wire(query, page: 1, pageSize: depth))
        : null;
    final tripRows = await _trips(query.q, f['status']);
    final merged = <InboxItem>[
      ...?reqPage?.items.map(RequestInboxItem.new),
      ...tripRows,
    ]..sort(InboxItem.queueOrder);
    final start = (query.page - 1) * query.pageSize;
    return PagedResult(
      items: merged.skip(start).take(query.pageSize).toList(),
      page: query.page,
      pageSize: query.pageSize,
      total: (reqPage?.total ?? 0) + tripRows.length,
    );
  }

  Future<PagedResult<InboxItem>> _requestsOnly(ListQuery query) async {
    final page = await requests.list(null, _wire(query));
    return PagedResult(
      items: page.items.map(RequestInboxItem.new).toList(),
      page: page.page,
      pageSize: page.pageSize,
      total: page.total,
    );
  }

  /// New requests (received) and new trips (requested): the menu badge.
  Future<FreshRequests> fresh() async {
    final reqPage = await requests.list(
        null,
        const ListQuery(
            filters: {'status': RequestStatusValues.received},
            sort: ListSort('queue', SortDirection.desc),
            pageSize: 50));
    final tripPage = await trips?.list(
        const ListQuery(filters: {'status': 'REQUESTED'}, pageSize: maxDepth));
    return FreshRequests(
      items: [
        ...reqPage.items.map(RequestInboxItem.new),
        ...?tripPage?.items.map(TripInboxItem.new),
      ],
      count: reqPage.total + (tripPage?.total ?? 0),
    );
  }

  ListQuery _wire(ListQuery query, {int? page, int? pageSize}) {
    final filters = Map.of(query.filters)..remove('type');
    final type = query.filters['type'];
    if (type != null) filters['usageType'] = type;
    final status = _requestStatus(query.filters['status']);
    filters.remove('status');
    if (status != null) filters['status'] = status;
    return ListQuery(
      q: query.q,
      filters: filters,
      sort: const ListSort('queue'),
      page: page ?? query.page,
      pageSize: pageSize ?? query.pageSize,
    );
  }

  static String? _requestStatus(String? filter) => switch (filter) {
        InboxStatusFilter.open => RequestStatusValues.open,
        InboxStatusFilter.fresh => RequestStatusValues.received,
        InboxStatusFilter.done => RequestStatusValues.done,
        InboxStatusFilter.cancelled => RequestStatusValues.cancelled,
        _ => null,
      };

  Future<List<InboxItem>> _trips(String q, String? status) async {
    final page = await trips!.list(ListQuery(q: q, pageSize: maxDepth));
    return [
      for (final t in page.items)
        if (_tripMatches(t, status)) TripInboxItem(t),
    ];
  }

  static bool _tripMatches(AdminTrip t, String? status) => switch (status) {
        InboxStatusFilter.open => !t.isFinal,
        InboxStatusFilter.fresh => t.status == 'REQUESTED',
        InboxStatusFilter.done => t.status == 'COMPLETED',
        InboxStatusFilter.cancelled => t.status == TripValues.cancelled,
        _ => true,
      };
}
