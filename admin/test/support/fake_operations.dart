import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:kachava_admin_dashboard/core/alert_chime_port.dart';
import 'package:kachava_admin_dashboard/domain/admin_notification.dart';
import 'package:kachava_admin_dashboard/domain/admin_task.dart';
import 'package:kachava_admin_dashboard/domain/conversation.dart';
import 'package:kachava_admin_dashboard/domain/dashboard_view.dart';
import 'package:kachava_admin_dashboard/domain/guest_profile.dart';
import 'package:kachava_admin_dashboard/domain/list_query.dart';
import 'package:kachava_admin_dashboard/domain/paged_result.dart';
import 'package:kachava_admin_dashboard/domain/reservation.dart';
import 'package:kachava_admin_dashboard/domain/staff_member.dart';
import 'package:kachava_admin_dashboard/presentation/operations/operations_scope.dart';

/// JSON response for `MockClient` fakes.
http.Response jsonResponse(Object body, [int status = 200]) =>
    http.Response(jsonEncode(body), status,
        headers: {'content-type': 'application/json'});

PagedResult<T> pageOf<T>(List<T> items, ListQuery query) {
  final start = (query.page - 1) * query.pageSize;
  return PagedResult(
    items: items.skip(start).take(query.pageSize).toList(),
    page: query.page,
    pageSize: query.pageSize,
    total: items.length,
  );
}

ReservationRow testRow(String id,
        {String guest = 'Ana Ruiz',
        String villa = 'Casa Ceiba',
        String status = StayValues.preArrival,
        String? host}) =>
    ReservationRow(
      id: id,
      guestName: guest,
      villaId: 'villa_1',
      villaName: villa,
      checkIn: '2026-11-03',
      checkOut: '2026-11-07',
      status: status,
      resortHostName: host,
      magicLinkUrl: 'https://guest.test/?guestId=$id',
    );

StayDetail testDetail(ReservationRow row,
        {String notes = '', String ssid = 'Ceiba-WiFi'}) =>
    StayDetail(
      row: row,
      nights: 4,
      guestsCount: 2,
      email: '',
      phone: '',
      language: 'en',
      occasion: '',
      resortHostStaffId: null,
      wifiSsid: ssid,
      wifiPassword: 'secret',
      internalNotes: notes,
      cancellationReason: null,
      statusHistory: const [],
    );

/// In-memory dashboard: [view] or [error].
class FakeDashboardRepository implements DashboardRepository {
  DashboardView? view;
  Object? error;
  int calls = 0;

  @override
  Future<DashboardView> fetch() async {
    calls++;
    if (error != null) throw error!;
    return view!;
  }
}

class FakeReservationRepository implements ReservationRepository {
  final List<ReservationRow> rows = [];
  final Map<String, StayDetail> details = {};
  final List<ListQuery> queries = [];
  final List<(String, Map<String, dynamic>)> patches = [];
  final List<Map<String, dynamic>> creates = [];
  StayFolio folioView = const StayFolio(
      services: [], rating: null, ratingNote: '', charges: [], totalUSD: 0);

  @override
  Future<PagedResult<ReservationRow>> list(ListQuery query) async {
    queries.add(query);
    final q = query.q.toLowerCase();
    return pageOf(
        rows.where((r) => r.guestName.toLowerCase().contains(q)).toList(),
        query);
  }

  @override
  Future<StayDetail> get(String id) async =>
      details[id] ?? testDetail(rows.firstWhere((r) => r.id == id));

  @override
  Future<String> create(NewReservation reservation) async {
    creates.add(reservation.toJson());
    final id = 'stay_${creates.length}';
    rows.add(testRow(id, guest: reservation.guestName));
    return id;
  }

  @override
  Future<StayDetail> update(String id, ReservationPatch patch) async {
    patches.add((id, patch.toJson()));
    final current = await get(id);
    final status = switch (patch.action) {
      StayValues.checkIn => StayValues.inHouse,
      StayValues.checkOut => StayValues.checkedOut,
      StayValues.cancel => StayValues.cancelled,
      _ => current.row.status,
    };
    final row = testRow(id, guest: current.row.guestName, status: status);
    final updated =
        testDetail(row, notes: patch.internalNotes ?? current.internalNotes);
    details[id] = updated;
    return updated;
  }

  @override
  Future<StayFolio> folio(String id) async => folioView;
}

class FakeGuestRepository implements GuestRepository {
  final List<GuestRow> rows = [];
  final Map<String, GuestProfile> profiles = {};

  @override
  Future<PagedResult<GuestRow>> list(ListQuery query) async =>
      pageOf(rows, query);

  @override
  Future<GuestProfile> get(String stayId) async => profiles[stayId]!;
}

class FakeTaskRepository implements TaskRepository {
  final List<AdminTask> tasks = [];
  final List<ListQuery> queries = [];
  final List<(String, Map<String, dynamic>)> moves = [];
  final List<Map<String, dynamic>> creates = [];

  @override
  Future<PagedResult<AdminTask>> list(ListQuery query) async {
    queries.add(query);
    return pageOf(tasks, query);
  }

  @override
  Future<AdminTask> get(String id) async => tasks.firstWhere((t) => t.id == id);

  @override
  Future<AdminTask> create(NewTask task) async {
    creates.add(task.toJson());
    final created = AdminTask(
        id: 'task_${creates.length}',
        title: task.title,
        category: task.category,
        priority: task.priority,
        status: TaskValues.pending,
        overdue: false);
    tasks.add(created);
    return created;
  }

  @override
  Future<AdminTask> transition(String id, TaskTransition move) async {
    moves.add((id, move.toJson()));
    final t = await get(id);
    final next = AdminTask(
        id: t.id,
        title: t.title,
        category: t.category,
        priority: t.priority,
        status: move.to,
        overdue: false,
        ownerName: move.ownerName ?? t.ownerName,
        ownerStaffId: move.ownerStaffId ?? t.ownerStaffId);
    tasks[tasks.indexOf(t)] = next;
    return next;
  }
}

class FakeNotificationRepository implements NotificationRepository {
  final List<AdminNotification> items = [];
  final List<ListQuery> queries = [];
  final List<String> marked = [];
  UnreadCounts counts = UnreadCounts.none;
  Object? countsError;
  int countCalls = 0;
  int markAllCalls = 0;

  @override
  Future<PagedResult<AdminNotification>> list(ListQuery query) async {
    queries.add(query);
    final read = query.filters['read'];
    return pageOf(
        items.where((n) => read == null || '${n.read}' == read).toList(),
        query);
  }

  @override
  Future<AdminNotification> markRead(String id) async {
    marked.add(id);
    final n = items.firstWhere((n) => n.id == id);
    items[items.indexOf(n)] = n.asRead();
    return n.asRead();
  }

  @override
  Future<int> markAllRead() async {
    markAllCalls++;
    for (var i = 0; i < items.length; i++) {
      items[i] = items[i].asRead();
    }
    return items.length;
  }

  @override
  Future<UnreadCounts> unreadCounts() async {
    countCalls++;
    if (countsError != null) throw countsError!;
    return counts;
  }
}

class FakeConversationRepository implements ConversationRepository {
  final List<ConversationRow> rows = [];
  final Map<String, List<ConversationMessage>> threads = {};
  final List<String> readMarks = [];
  final List<(String, String)> replies = [];

  @override
  Future<PagedResult<ConversationRow>> list(ListQuery query) async =>
      pageOf(rows, query);

  @override
  Future<PagedResult<ConversationMessage>> messages(
          String stayId, ListQuery query) async =>
      pageOf(threads[stayId] ?? const [], query);

  @override
  Future<ConversationMessage> reply(String stayId, String text) async {
    replies.add((stayId, text));
    final message = ConversationMessage(
        id: 'm${replies.length}',
        fromGuest: false,
        senderName: 'Host',
        text: text,
        at: DateTime.utc(2026, 11, 3, 15));
    threads.putIfAbsent(stayId, () => []).add(message);
    return message;
  }

  @override
  Future<void> markRead(String stayId) async => readMarks.add(stayId);
}

class FakeStaffDirectory implements StaffDirectoryRepository {
  FakeStaffDirectory([this.staff = const []]);

  final List<StaffMember> staff;

  @override
  Future<List<StaffMember>> list() async => staff;
}

const StaffMember testStaff = StaffMember(
  staffId: 'stf_1',
  fullName: 'Lucia Host',
  shortName: 'Lucia',
  role: 'Resort Host',
  department: StaffDepartment.concierge,
  rbacRole: StaffRole.conciergeStaff,
  email: 'lucia@test',
  phone: '',
);

/// Every fake of the operations screens, wired as [deps].
class FakeOperations {
  final dashboard = FakeDashboardRepository()
    ..view = const DashboardView(
        resortDate: '2026-11-03',
        kpis: DashboardKpis(
            occupiedVillas: 0,
            availableVillas: 0,
            occupancyPct: 0,
            arrivals: 0,
            departures: 0,
            openRequests: 0),
        rows: [],
        total: 0);
  final reservations = FakeReservationRepository();
  final guests = FakeGuestRepository();
  final tasks = FakeTaskRepository();
  final notifications = FakeNotificationRepository();
  final conversations = FakeConversationRepository();

  OperationsDeps get deps => OperationsDeps(
        dashboard: dashboard,
        reservations: reservations,
        guests: guests,
        tasks: tasks,
        notifications: notifications,
        conversations: conversations,
      );
}

/// Records chime calls instead of playing audio.
class FakeChime implements AlertChimePort {
  int rings = 0;
  int stops = 0;
  bool _ringing = false;

  @override
  bool get isRinging => _ringing;

  @override
  void triggerTenSecondChime({void Function()? onAutoStop}) {
    rings++;
    _ringing = true;
  }

  @override
  void stopChime() {
    stops++;
    _ringing = false;
  }

  @override
  void dispose() {}
}
