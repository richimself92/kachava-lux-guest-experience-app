import 'package:kachava_admin_dashboard/core/resort_time.dart';
import 'package:kachava_admin_dashboard/data/admin_stay_wire_mapper.dart';
import 'package:kachava_admin_dashboard/domain/admin_catalog_repositories.dart';
import 'package:kachava_admin_dashboard/domain/admin_service.dart';
import 'package:kachava_admin_dashboard/domain/admin_stay_entities.dart';
import 'package:kachava_admin_dashboard/domain/admin_trip.dart';
import 'package:kachava_admin_dashboard/domain/list_query.dart';
import 'package:kachava_admin_dashboard/domain/paged_result.dart';
import 'package:kachava_admin_dashboard/domain/transport_provider.dart';
import 'package:kachava_admin_dashboard/domain/trip_repository.dart';

import '../support/in_memory_paged_source.dart';

/// Test resort zone: UTC-5 all year (like America/Cancun).
const Duration testOffset = Duration(hours: -5);
const FixedOffsetResolver testZoneResolver = FixedOffsetResolver(testOffset);

/// "Now" of the widget tests: 2026-11-03 10:00 resort time.
final DateTime testNow = DateTime.utc(2026, 11, 3, 15);

/// In-memory `/admin/trips` with the backend's one-step flow rules.
class FakeTripRepository implements TripRepository {
  FakeTripRepository([List<AdminTrip> trips = const []])
      : trips = List.of(trips);

  final List<AdminTrip> trips;
  final List<ListQuery> queries = [];
  final List<NewTripRequest> created = [];
  final List<(String, TripTransition)> moves = [];
  Object? failList;
  Object? failWrite;
  int _ids = 0;

  @override
  Future<PagedResult<AdminTrip>> list(ListQuery query) async {
    queries.add(query);
    if (failList != null) throw failList!;
    final range = TripDateRange.parse(query.filters[TripDateRange.filterKey]);
    final rows = [
      for (final t in trips)
        if (_inRange(t, range) && _matches(t, query)) t
    ]..sort((a, b) => a.pickupAt!.compareTo(b.pickupAt!));
    if (query.sort?.direction == SortDirection.desc) {
      rows.setAll(0, rows.reversed.toList());
    }
    return InMemoryPagedSource<AdminTrip>(
      items: rows,
      searchText: (_) => const [''],
      sortValue: (_, __) => null,
    ).page(ListQuery(page: query.page, pageSize: query.pageSize));
  }

  static bool _inRange(AdminTrip t, TripDateRange? range) {
    if (range == null) return true;
    final day = ResortTime.isoDay(t.pickupAt!.add(testOffset));
    return day.compareTo(range.from) >= 0 && day.compareTo(range.to) <= 0;
  }

  static bool _matches(AdminTrip t, ListQuery query) {
    final f = query.filters;
    final q = query.q.toLowerCase().replaceAll(' ', '');
    final flight = (t.flight?.number ?? '').toLowerCase().replaceAll(' ', '');
    return (f['status'] == null || f['status'] == t.status) &&
        (f['type'] == null || f['type'] == t.type) &&
        (f['providerId'] == null || f['providerId'] == t.providerId) &&
        (q.isEmpty ||
            t.guestName.toLowerCase().contains(query.q.toLowerCase()) ||
            (flight.isNotEmpty && flight.contains(q)));
  }

  @override
  Future<AdminTrip> get(String id) async => trips.firstWhere((t) => t.id == id);

  @override
  Future<AdminTrip> create(NewTripRequest request) async {
    if (failWrite != null) throw failWrite!;
    created.add(request);
    final flightAt = _wallToUtc(request.flight?.scheduledAt);
    final pickup = _wallToUtc(request.pickupAt) ??
        (request.type == 'DEPARTURE'
            ? flightAt!.subtract(const Duration(hours: 3))
            : flightAt);
    final trip = testTrip(
      id: 'trip-${++_ids}',
      guest: 'Guest of ${request.stayId}',
      type: request.type,
      pickupAt: pickup!,
      flightNumber: request.flight?.number,
      providerId: request.providerId,
    );
    trips.add(trip);
    return trip;
  }

  @override
  Future<AdminTrip> transition(String id, TripTransition move) async {
    if (failWrite != null) throw failWrite!;
    moves.add((id, move));
    final index = trips.indexWhere((t) => t.id == id);
    final t = trips[index];
    if (move.to != TripValues.cancelled && t.nextStatus != move.to) {
      throw StateError('Cannot move ${t.status} to ${move.to}');
    }
    return trips[index] = _moved(t, move);
  }

  static AdminTrip _moved(AdminTrip t, TripTransition move) => AdminTrip(
        id: t.id,
        stayId: t.stayId,
        villaId: t.villaId,
        villaName: t.villaName,
        guestName: t.guestName,
        type: t.type,
        status: move.to,
        airportCode: t.airportCode,
        flight: t.flight,
        pickupAt: t.pickupAt,
        origin: t.origin,
        destination: t.destination,
        passengers: t.passengers,
        providerId: move.providerId ?? t.providerId,
        driver: move.driver ?? t.driver,
        vehicle: move.vehicle ?? t.vehicle,
        cancellationReason: move.reason ?? t.cancellationReason,
        createdBy: t.createdBy,
        history: [
          ...t.history,
          TripStatusChange(
              from: t.status,
              to: move.to,
              at: testNow,
              by: 'admin@test.local',
              reason: move.reason),
        ],
        unconfirmedDue: move.to == 'REQUESTED' || move.to == 'SENT_TO_PROVIDER'
            ? t.unconfirmedDue
            : false,
      );

  static DateTime? _wallToUtc(String? wall) =>
      wall == null ? null : DateTime.parse('${wall}Z').subtract(testOffset);
}

/// A generated trip (no business data).
AdminTrip testTrip({
  required String id,
  required String guest,
  required DateTime pickupAt,
  String type = 'ARRIVAL',
  String status = 'REQUESTED',
  String villa = 'Villa 01',
  String? flightNumber,
  String? providerId,
  TripDriver? driver,
  bool? unconfirmedDue = false,
}) =>
    AdminTrip(
      id: id,
      stayId: 'stay-$id',
      villaId: 'villa-$id',
      villaName: villa,
      guestName: guest,
      type: type,
      status: status,
      airportCode: TripValues.isAirport(type) ? 'CUN' : null,
      flight: TripValues.isAirport(type)
          ? TripFlight(
              airline: 'Test Air',
              number: flightNumber ?? 'TA 1',
              scheduledAt: pickupAt)
          : null,
      origin: type == 'LOCAL' ? 'Villa' : null,
      destination: type == 'LOCAL' ? 'Town' : null,
      pickupAt: pickupAt,
      passengers: 2,
      providerId: providerId,
      driver: driver,
      createdBy: 'STAFF',
      history: [
        TripStatusChange(
            from: null,
            to: 'REQUESTED',
            at: testNow,
            by: 'admin@test.local',
            reason: null),
      ],
      unconfirmedDue: unconfirmedDue,
    );

/// In-memory `/admin/transport-providers`.
class FakeProviderRepository implements TransportProviderRepository {
  FakeProviderRepository([List<TransportProvider> providers = const []])
      : providers = List.of(providers);

  final List<TransportProvider> providers;
  final List<ListQuery> queries = [];
  Object? failWith;
  int _ids = 0;

  @override
  Future<PagedResult<TransportProvider>> list(ListQuery query) async {
    queries.add(query);
    if (failWith != null) throw failWith!;
    return InMemoryPagedSource<TransportProvider>(
      items: providers,
      searchText: (p) => [p.name, p.phone, p.email],
      sortValue: (p, _) => p.name,
      filterValue: (p, key) => key == 'isActive' ? '${p.isActive}' : null,
    ).page(query);
  }

  @override
  Future<TransportProvider> create(TransportProvider provider) async {
    if (failWith != null) throw failWith!;
    final saved = TransportProvider.fromJson(
        {...provider.toWriteJson(), 'id': 'prov-${++_ids}'});
    providers.add(saved);
    return saved;
  }

  @override
  Future<TransportProvider> update(TransportProvider provider) async {
    if (failWith != null) throw failWith!;
    final index = providers.indexWhere((p) => p.id == provider.id);
    return providers[index] = TransportProvider.fromJson(
        {...provider.toWriteJson(), 'id': provider.id});
  }
}

TransportProvider testProvider(String id, String name,
        {bool isActive = true}) =>
    TransportProvider(
        id: id,
        name: name,
        phone: '+52 000 $id',
        email: '$id@test.local',
        isActive: isActive);

/// Transport services and vehicles (only the reads the screen uses).
class FakeTransportCatalog implements ServiceCatalogRepository {
  FakeTransportCatalog({
    this.services = const [],
    this.items = const {},
  });

  final List<AdminService> services;
  final Map<String, List<ServiceItem>> items;
  final List<ListQuery> queries = [];

  @override
  Future<PagedResult<AdminService>> list(ListQuery query) async {
    queries.add(query);
    final kind = query.filters['kind'];
    final status = query.filters['status'];
    final rows = [
      for (final s in services)
        if ((kind == null || s.kind.wire == kind) &&
            (status == null || s.status.wire == status))
          s
    ];
    return PagedResult(
        items: rows, page: 1, pageSize: query.pageSize, total: rows.length);
  }

  @override
  Future<PagedResult<ServiceItem>> listItems(
      String serviceId, ListQuery query) async {
    final rows = items[serviceId] ?? const [];
    return PagedResult(
        items: rows, page: 1, pageSize: query.pageSize, total: rows.length);
  }

  @override
  Future<AdminService> get(String id) => throw UnimplementedError();
  @override
  Future<AdminService> create(AdminService service) =>
      throw UnimplementedError();
  @override
  Future<AdminService> update(AdminService service) =>
      throw UnimplementedError();
  @override
  Future<ServiceItem> createItem(String serviceId, ServiceItem item) =>
      throw UnimplementedError();
  @override
  Future<ServiceItem> updateItem(String serviceId, ServiceItem item) =>
      throw UnimplementedError();
}

AdminService testTransportService(String id, String name) =>
    AdminService.fromJson({
      'id': id,
      'kind': 'TRANSPORT',
      'section': 'TRANSPORTATION',
      'usageType': 'TRIP',
      'name': {'en': name, 'es': '$name ES'},
      'status': 'ACTIVE',
    });

ServiceItem testVehicle(String id, String name, int passengers) =>
    ServiceItem.fromJson({
      'id': id,
      'name': {'en': name, 'es': name},
      'capacity': {'passengers': passengers, 'luggage': 4},
      'status': 'ACTIVE',
    });

/// In-memory `/admin/stays` search.
class FakeStayList implements StayListRepository {
  FakeStayList([this.stays = const []]);

  final List<AdminStayRecord> stays;
  final List<ListQuery> queries = [];

  @override
  Future<PagedResult<AdminStayRecord>> list(ListQuery query) async {
    queries.add(query);
    final q = query.q.toLowerCase();
    final rows = [
      for (final s in stays)
        if (q.isEmpty || s.guestNames.toLowerCase().contains(q)) s
    ];
    return PagedResult(
        items: rows, page: 1, pageSize: query.pageSize, total: rows.length);
  }
}

AdminStayRecord testStay(String id, String guest, String villa,
        {String status = 'PRE_ARRIVAL'}) =>
    AdminStayWireMapper.map({
      'stayId': id,
      'villaId': 'villa-$id',
      'villaName': villa,
      'guestName': guest,
      'status': status,
      'checkIn': '2026-11-03',
      'checkOut': '2026-11-08',
    });

TransportRepositories fakeTransport({
  FakeTripRepository? trips,
  FakeProviderRepository? providers,
  FakeTransportCatalog? services,
  FakeStayList? stays,
}) =>
    TransportRepositories(
      trips: trips ?? FakeTripRepository(),
      providers: providers ?? FakeProviderRepository(),
      services: services ?? FakeTransportCatalog(),
      stays: stays ?? FakeStayList(),
    );
