import 'package:flutter_test/flutter_test.dart';
import 'package:kachava_admin_dashboard/application/request_inbox_source.dart';
import 'package:kachava_admin_dashboard/domain/inbox_item.dart';
import 'package:kachava_admin_dashboard/domain/list_query.dart';
import 'package:kachava_admin_dashboard/domain/service_request.dart';

import '../support/fake_service_requests.dart';
import '../transport/fake_transport_repositories.dart';

void main() {
  late FakeServiceRequestRepository requests;
  late FakeTripRepository trips;
  late RequestInboxSource source;

  setUp(() {
    requests = FakeServiceRequestRepository()
      ..requests.addAll([
        testRequest(1,
            usageType: 'ORDER',
            isOrder: true,
            section: 'IN_VILLA',
            createdAt: DateTime.utc(2026, 11, 3, 12)),
        testRequest(2,
            usageType: 'PREFERENCE',
            section: 'IN_VILLA',
            status: RequestStatusValues.confirmed,
            createdAt: DateTime.utc(2026, 11, 3, 9)),
        testRequest(3,
            usageType: 'BOOKING',
            section: 'WELLNESS',
            status: RequestStatusValues.done,
            createdAt: DateTime.utc(2026, 11, 3, 8)),
      ]);
    trips = FakeTripRepository([
      testTrip(id: 't1', guest: 'Ana', pickupAt: testNow),
    ]);
    source = RequestInboxSource(requests: requests, trips: trips);
  });

  test('test_list_open_mergesRequestsAndTrips_newFirst', () async {
    final page = await source.list(RequestInboxSource.initialQuery);

    expect(page.items.map((i) => i.rowId), ['req_1', 'trip-t1', 'req_2']);
    expect(page.total, 3);
    final wire = requests.queries.single.$2;
    expect(requests.queries.single.$1, isNull);
    expect(wire.sort, const ListSort('queue'));
    expect(wire.filters['status'], RequestStatusValues.open);
  });

  test('test_list_withoutStatus_showsDoneAtTheBottom', () async {
    final page = await source.list(const ListQuery());
    expect(page.items.last.id, 'req_3');
    expect(page.total, 4);
  });

  test('test_list_typeFilter_tripOnly_orRequestsOnly', () async {
    final onlyTrips =
        await source.list(const ListQuery(filters: {'type': 'TRIP'}));
    final onlyOrders =
        await source.list(const ListQuery(filters: {'type': 'ORDER'}));
    final inVilla =
        await source.list(const ListQuery(filters: {'section': 'IN_VILLA'}));

    expect(onlyTrips.items.map((i) => i.type), [InboxType.trip]);
    expect(onlyOrders.items.map((i) => i.id), ['req_1']);
    expect(requests.queries.last.$2.filters['section'], 'IN_VILLA');
    expect(inVilla.items.any((i) => i.type == InboxType.trip), isFalse);
  });

  test('test_list_secondPage_slicesTheMergedQueue', () async {
    final page = await source.list(
        const ListQuery(pageSize: 10, page: 1).withPageSize(10).withPage(1));
    expect(page.items, hasLength(4));
    expect(requests.queries.last.$2.pageSize, 10);
  });

  test('test_fresh_returnsNewRequestsAndTrips_withTheBadgeCount', () async {
    final fresh = await source.fresh();
    expect(fresh.count, 2);
    expect(fresh.items.map((i) => i.rowId), containsAll(['req_1', 'trip-t1']));
  });
}
