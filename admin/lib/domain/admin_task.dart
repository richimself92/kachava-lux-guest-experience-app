import 'json_read.dart';
import 'list_query.dart';
import 'paged_result.dart';

/// Task wire values (ADR-006/011): Pending → Assigned → In progress →
/// Completed, plus Cancelled from any open status.
abstract final class TaskValues {
  static const String pending = 'PENDING';
  static const String assigned = 'ASSIGNED';
  static const String inProgress = 'IN_PROGRESS';
  static const String completed = 'COMPLETED';
  static const String cancelled = 'CANCELLED';
  static const List<String> statuses = [
    pending,
    assigned,
    inProgress,
    completed,
    cancelled,
  ];
  static const List<String> priorities = ['LOW', 'NORMAL', 'HIGH', 'URGENT'];
  static const String defaultPriority = 'NORMAL';

  /// The single forward move from [status]; `null` once final.
  static String? next(String status) => switch (status) {
        pending => assigned,
        assigned => inProgress,
        inProgress => completed,
        _ => null,
      };

  static bool isFinal(String status) =>
      status == completed || status == cancelled;
}

/// Who completed a task and the confirmation note.
class TaskCompletion {
  const TaskCompletion(
      {required this.at, required this.by, required this.note});

  static TaskCompletion? fromJson(Object? json) {
    if (json is! Map) return null;
    final map = Map<String, dynamic>.from(json);
    return TaskCompletion(
      at: DateTime.tryParse(JsonRead.text(map, 'at'))?.toUtc(),
      by: JsonRead.text(map, 'by'),
      note: JsonRead.text(map, 'note'),
    );
  }

  final DateTime? at;
  final String by;
  final String note;
}

/// One operational task (`/admin/tasks`). [overdue] is derived by the
/// server on read.
class AdminTask {
  const AdminTask({
    required this.id,
    required this.title,
    required this.category,
    required this.priority,
    required this.status,
    required this.overdue,
    this.sourceType = 'MANUAL',
    this.stayId,
    this.villaName,
    this.guestName,
    this.ownerStaffId,
    this.ownerName,
    this.dueAt,
    this.completion,
    this.cancellationReason,
  });

  factory AdminTask.fromJson(Map<String, dynamic> json) {
    final source = JsonRead.object(json, 'source');
    return AdminTask(
      id: JsonRead.requireId(json),
      title: JsonRead.text(json, 'title'),
      category: JsonRead.text(json, 'category'),
      priority: JsonRead.text(json, 'priority'),
      status: JsonRead.text(json, 'status'),
      overdue: JsonRead.flag(json, 'overdue'),
      sourceType: JsonRead.textOrNull(source, 'type') ?? 'MANUAL',
      stayId: JsonRead.textOrNull(source, 'stayId'),
      villaName: JsonRead.textOrNull(json, 'villaName'),
      guestName: JsonRead.textOrNull(json, 'guestName'),
      ownerStaffId: JsonRead.textOrNull(json, 'ownerStaffId'),
      ownerName: JsonRead.textOrNull(json, 'ownerName'),
      dueAt: DateTime.tryParse(JsonRead.text(json, 'dueAt'))?.toUtc(),
      completion: TaskCompletion.fromJson(json['completion']),
      cancellationReason: JsonRead.textOrNull(json, 'cancellationReason'),
    );
  }

  final String id;
  final String title;
  final String category;
  final String priority;
  final String status;
  final bool overdue;
  final String sourceType;
  final String? stayId;
  final String? villaName;
  final String? guestName;
  final String? ownerStaffId;
  final String? ownerName;
  final DateTime? dueAt;
  final TaskCompletion? completion;
  final String? cancellationReason;

  String? get nextStatus => TaskValues.next(status);
  bool get isFinal => TaskValues.isFinal(status);

  /// "Villa · Guest" (either may be missing).
  String get villaGuest =>
      [villaName, guestName].whereType<String>().join(' · ');
}

/// `POST /admin/tasks/:id/transition`. Assigned needs an owner; Completed
/// needs a note; Cancelled takes a reason.
class TaskTransition {
  const TaskTransition({
    required this.to,
    this.ownerStaffId,
    this.ownerName,
    this.note,
    this.reason,
  });

  final String to;
  final String? ownerStaffId;
  final String? ownerName;
  final String? note;
  final String? reason;

  Map<String, dynamic> toJson() => {
        'to': to,
        if (ownerStaffId != null) 'ownerStaffId': ownerStaffId,
        if (ownerName != null) 'ownerName': ownerName,
        if (note != null) 'note': note,
        if (reason != null) 'reason': reason,
      };
}

/// `POST /admin/tasks`. [dueAt] is resort wall time `YYYY-MM-DDTHH:mm`.
class NewTask {
  const NewTask({
    required this.title,
    required this.category,
    this.priority = TaskValues.defaultPriority,
    this.dueAt,
    this.stayId,
    this.ownerStaffId,
    this.ownerName,
  });

  final String title;
  final String category;
  final String priority;
  final String? dueAt;
  final String? stayId;
  final String? ownerStaffId;
  final String? ownerName;

  Map<String, dynamic> toJson() => {
        'title': title.trim(),
        'category': category.trim(),
        'priority': priority,
        if (dueAt != null) 'dueAt': dueAt,
        if (stayId != null) 'stayId': stayId,
        if (ownerStaffId != null) 'ownerStaffId': ownerStaffId,
        if (ownerName != null) 'ownerName': ownerName,
      };
}

/// Tasks (`/admin/tasks`). Filters `status`, `priority`, `owner`,
/// `villaId`, `overdue=true`; `q` searches; sortable by `dueAt`.
abstract interface class TaskRepository {
  Future<PagedResult<AdminTask>> list(ListQuery query);
  Future<AdminTask> get(String id);
  Future<AdminTask> create(NewTask task);
  Future<AdminTask> transition(String id, TaskTransition move);
}
