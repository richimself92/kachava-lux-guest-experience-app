import 'catalog.dart';
import 'resort_clock.dart';
import 'stay.dart';
import 'trip.dart';

enum RequestKind { order, booking, preference, trip, host }

/// Plain guest-facing statuses; raw enums never reach the screen.
enum RequestStatus {
  received,

  /// A trip the resort sent to its transport provider (still before the
  /// confirmation dot).
  arranging,
  confirmed,
  preparing,
  onTheWay,
  done,
  cancelled
}

/// Server reason stored when the guest cancels (backend
/// `GUEST_CANCELLATION_REASON`); shown as "Cancelled by you".
const String guestCancellationReason = 'Cancelled by guest';

extension RequestStatusTrack on RequestStatus {
  /// Position on the 4-dot track (Received, Confirmed, Preparing/On the way,
  /// Done); cancelled has no position.
  int get trackIndex => switch (this) {
        RequestStatus.received || RequestStatus.arranging => 0,
        RequestStatus.confirmed => 1,
        RequestStatus.preparing || RequestStatus.onTheWay => 2,
        RequestStatus.done => 3,
        RequestStatus.cancelled => -1,
      };

  bool get isActive =>
      this != RequestStatus.done && this != RequestStatus.cancelled;
}

RequestStatus bookingStatusOf(String raw) => switch (raw) {
      'CONFIRMED' => RequestStatus.confirmed,
      'IN_PREPARATION' => RequestStatus.preparing,
      'COMPLETED' => RequestStatus.done,
      'CANCELLED' => RequestStatus.cancelled,
      _ => RequestStatus.received,
    };

/// SENT_TO_PROVIDER reads "Arranging" (the provider itself stays hidden).
RequestStatus tripStatusOf(String raw) => switch (raw) {
      'SENT_TO_PROVIDER' => RequestStatus.arranging,
      'CONFIRMED' => RequestStatus.confirmed,
      'EN_ROUTE' => RequestStatus.onTheWay,
      'COMPLETED' => RequestStatus.done,
      'CANCELLED' => RequestStatus.cancelled,
      _ => RequestStatus.received,
    };

/// Villa-stocking `provisioningStatus` is free text set by staff.
RequestStatus larderStatusOf(String raw) {
  final s = raw.toLowerCase();
  if (s.contains('cancel')) return RequestStatus.cancelled;
  if (s.contains('deliver') ||
      s.contains('complete') ||
      s.contains('stocked') ||
      s.contains('done')) {
    return RequestStatus.done;
  }
  if (s.contains('progress') ||
      s.contains('prepar') ||
      s.contains('provision')) {
    return RequestStatus.preparing;
  }
  if (s.contains('confirm') || s.contains('assign')) {
    return RequestStatus.confirmed;
  }
  return RequestStatus.received;
}

RequestStatus hostStatusOf(String raw, bool isCompleted) {
  if (isCompleted) return RequestStatus.done;
  return switch (raw) {
    'Assigned' => RequestStatus.confirmed,
    'In Progress' => RequestStatus.preparing,
    'Completed' => RequestStatus.done,
    _ => RequestStatus.received,
  };
}

/// One row of My requests, composed client-side from the guest endpoints and
/// ordered by the server `createdAt`.
class GuestRequest {
  const GuestRequest({
    required this.id,
    required this.kind,
    required this.status,
    this.serviceId,
    this.section = '',
    this.name = LocalizedText.empty,
    this.plainName = '',
    this.day,
    this.time = '',
    this.people = 0,
    this.sortAt,
    this.lines = const [],
    this.totalUSD,
    this.trip,
    this.booking,
    this.reason = '',
  });

  final String id;
  final RequestKind kind;
  final RequestStatus status;
  final String? serviceId;
  final String section;

  /// Snapshot name (bilingual); [plainName] when only free text exists.
  final LocalizedText name;
  final String plainName;

  /// Resort calendar day of the service, if any.
  final DateTime? day;

  /// `HH:mm` resort time, if any.
  final String time;
  final int people;
  final DateTime? sortAt;
  final List<SnapshotLine> lines;
  final double? totalUSD;
  final GuestTrip? trip;
  final GuestBooking? booking;

  /// Cancellation reason from the server ('' when none).
  final String reason;

  /// The guest may cancel while the server status is still the initial one.
  bool get canCancel =>
      (booking?.isInitial ?? false) || (trip?.isInitial ?? false);

  /// Date, time and party can be changed on a REQUESTED booking (not choices).
  bool get canChange =>
      kind == RequestKind.booking && (booking?.isInitial ?? false);
}

/// Builds My requests: orders (grouped per service), bookings, preferences,
/// trips and non-chat Resort Host requests, newest first.
List<GuestRequest> composeRequests({
  required GuestStay stay,
  required List<GuestTrip> trips,
  required List<CatalogService> catalog,
}) {
  final byId = {for (final s in catalog) s.id: s};
  final out = <GuestRequest>[
    ..._larderRequests(stay.larderOrders, byId),
    for (final b in stay.bookings) _bookingRequest(b, byId[b.serviceId]),
    for (final t in trips) _tripRequest(t),
    for (final h in stay.threads.where((t) => !t.isChat)) _hostRequest(h),
  ];
  out.sort((a, b) {
    final x = a.sortAt, y = b.sortAt;
    if (x == null && y == null) return 0;
    if (x == null) return 1;
    if (y == null) return -1;
    return y.compareTo(x);
  });
  return out;
}

Iterable<GuestRequest> _larderRequests(
    List<LarderOrderLine> lines, Map<String, CatalogService> byId) sync* {
  final groups = <String, List<LarderOrderLine>>{};
  for (final line in lines) {
    groups.putIfAbsent(line.serviceId, () => []).add(line);
  }
  for (final MapEntry(key: serviceId, value: group) in groups.entries) {
    final statuses = group.map((l) => larderStatusOf(l.status)).toList();
    final live = statuses.where((s) => s != RequestStatus.cancelled).toList();
    final status = live.isEmpty
        ? RequestStatus.cancelled
        : live.reduce((a, b) => a.trackIndex <= b.trackIndex ? a : b);
    final service = byId[serviceId];
    final created = group
        .map((l) => l.createdAt)
        .whereType<DateTime>()
        .fold<DateTime?>(null, (a, b) => a == null || b.isBefore(a) ? b : a);
    yield GuestRequest(
      id: 'order:$serviceId',
      kind: RequestKind.order,
      status: status,
      serviceId: serviceId,
      section: service?.section ?? '',
      name: service?.name ?? LocalizedText.empty,
      lines: [
        for (final l in group)
          SnapshotLine(
              name: l.name, quantity: l.quantity, lineTotalUSD: l.lineTotalUSD),
      ],
      totalUSD: group.fold<double>(0, (sum, l) => sum + l.lineTotalUSD),
      sortAt: created,
    );
  }
}

GuestRequest _bookingRequest(GuestBooking b, CatalogService? service) {
  return GuestRequest(
    id: 'booking:${b.id}',
    kind: b.usageType == UsageType.preference
        ? RequestKind.preference
        : RequestKind.booking,
    status: bookingStatusOf(b.status),
    serviceId: b.serviceId,
    section: b.section,
    name: b.snapshot.serviceName.isEmpty
        ? LocalizedText(en: b.title, es: b.title)
        : _join(b.snapshot.serviceName, _chosenItem(b, service)),
    day: _parseDay(b.scheduledDate),
    time: b.scheduledTimeSlot,
    people: b.usageType == UsageType.preference ? 0 : b.partySize,
    sortAt: b.createdAt ?? b.snapshot.capturedAt,
    lines: b.snapshot.lines,
    totalUSD: b.snapshot.totalUSD,
    booking: b,
    reason: b.cancellationReason,
  );
}

/// Option chosen (preference/item booking): the snapshot line, or the
/// catalog item when an older booking has no snapshot line.
LocalizedText? _chosenItem(GuestBooking b, CatalogService? service) {
  final itemId = b.itemId;
  if (itemId == null) return null;
  if (b.snapshot.lines.isNotEmpty) return b.snapshot.lines.first.name;
  return service?.items.where((i) => i.id == itemId).firstOrNull?.name;
}

LocalizedText _join(LocalizedText service, LocalizedText? item) {
  if (item == null || item.isEmpty) return service;
  String j(String a, String b) => b.isEmpty ? a : (a.isEmpty ? b : '$a · $b');
  return LocalizedText(en: j(service.en, item.en), es: j(service.es, item.es));
}

GuestRequest _tripRequest(GuestTrip t) {
  final at = t.pickupAt ?? t.flightAt;
  final wall = at == null ? null : ResortClock.toWall(at);
  return GuestRequest(
    id: 'trip:${t.id}',
    kind: RequestKind.trip,
    status: tripStatusOf(t.status),
    serviceId: t.serviceId,
    section: t.snapshot?.section ?? 'TRANSPORTATION',
    name: t.snapshot?.serviceName ?? LocalizedText.empty,
    day: wall == null ? null : ResortClock.dayOf(wall),
    time: wall == null
        ? ''
        : '${wall.hour.toString().padLeft(2, '0')}:${wall.minute.toString().padLeft(2, '0')}',
    people: t.passengers,
    sortAt: t.createdAt,
    lines: t.snapshot?.lines ?? const [],
    totalUSD: t.snapshot?.totalUSD,
    trip: t,
    reason: t.cancellationReason,
  );
}

GuestRequest _hostRequest(HostThread h) => GuestRequest(
      id: 'host:${h.id}',
      kind: RequestKind.host,
      status: hostStatusOf(h.status, h.isCompleted),
      plainName: h.title,
      sortAt: h.createdAt,
    );

DateTime? _parseDay(String iso) {
  if (iso.length < 10) return null;
  final d = DateTime.tryParse(iso.substring(0, 10));
  return d == null ? null : DateTime.utc(d.year, d.month, d.day);
}
