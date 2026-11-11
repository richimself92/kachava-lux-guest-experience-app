import 'package:flutter/material.dart';

import '../../../application/list_query_store.dart';
import '../../../application/paged_list_controller.dart';
import '../../../core/admin_i18n.dart';
import '../../../core/ops_strings.dart';
import '../../../core/resort_time.dart';
import '../../../core/theme/kachava_tokens.dart';
import '../../../domain/admin_catalog_repositories.dart';
import '../../../domain/admin_task.dart';
import '../../../domain/list_query.dart';
import '../../../domain/staff_member.dart';
import '../../components/components.dart';
import '../operations_scope.dart';
import 'task_create_panel.dart';
import 'task_detail_panel.dart';

/// OPERATIONS › Tasks: Title, Villa / Guest, Owner, Priority, Due, Status
/// (+ red "Overdue" chip); filters status / priority / owner / overdue,
/// search, sort by due; "+ New task"; detail with the next-step action.
class TasksScreen extends StatefulWidget {
  const TasksScreen({
    super.key,
    required this.tasks,
    required this.stays,
    required this.queries,
    required this.staff,
    required this.resortTime,
    required this.isEs,
    this.openId,
    this.onOpenRequest,
  });

  static const String storeKey = 'tasks';

  final TaskRepository tasks;

  /// Stays to link a new task to.
  final StayListRepository stays;
  final ListQueryStore queries;
  final List<StaffMember> staff;
  final ResortTime resortTime;
  final bool isEs;

  /// A task to open on arrival (notification "Open").
  final String? openId;

  /// "From request": opens the guest's requests in the inbox.
  final ValueChanged<AdminTask>? onOpenRequest;

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  late final PagedListController<AdminTask> _list = PagedListController(
    fetch: widget.tasks.list,
    initialQuery: const ListQuery(sort: ListSort('dueAt')),
    store: widget.queries,
    storeKey: TasksScreen.storeKey,
  );

  OpsStrings get _s => OpsStrings(widget.isEs);

  @override
  void dispose() {
    _list.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => OpenRecordLoader<AdminTask>(
        id: widget.openId,
        load: widget.tasks.get,
        builder: (context, initial) => _screen(initial),
      );

  Widget _screen(AdminTask? initial) => AdminListScreen<AdminTask>(
        key: const Key('workspace-admin-tasks'),
        entity: 'tasks',
        title: _s.tasks,
        controller: _list,
        columns: _columns(),
        rowId: (t) => t.id,
        compactTitle: (t) => t.title,
        compactSubtitle: (t) => [
          if (t.villaGuest.isNotEmpty) t.villaGuest,
          widget.resortTime.label(t.dueAt, isEs: widget.isEs),
        ].join(' · '),
        compactTrailing: _statusCell,
        filters: _filters(),
        emptyMessage: _s.noTasks,
        primaryActionLabel: _s.newTask,
        detailBuilder: _detail,
        initialDetail: initial,
        isEs: widget.isEs,
      );

  Widget _detail(BuildContext context, AdminTask? task, VoidCallback close) {
    if (task == null) {
      return TaskCreatePanel(
        repository: widget.tasks,
        stays: widget.stays,
        staff: widget.staff,
        onClose: close,
        onCreated: (_) => _list.load(),
        isEs: widget.isEs,
      );
    }
    return TaskDetailPanel(
      task: task,
      repository: widget.tasks,
      staff: widget.staff,
      resortTime: widget.resortTime,
      onClose: close,
      onChanged: _list.load,
      isEs: widget.isEs,
      onOpenRequest: widget.onOpenRequest,
    );
  }

  Widget _statusCell(AdminTask t) => Wrap(
        spacing: KachavaTokens.space1,
        runSpacing: KachavaTokens.space1,
        children: [
          StatusChip.fromStatus(t.status, isEs: widget.isEs),
          if (t.overdue)
            StatusChip(
                key: Key('task-overdue-${t.id}'),
                label: _s.overdue,
                tone: StatusTone.error),
        ],
      );

  /// The title with its origin underneath (the table holds 6 columns).
  Widget _titleCell(AdminTask t) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          TruncatedText(t.title),
          DefaultTextStyle.merge(
              style: const TextStyle(fontSize: 12), child: _originCell(t)),
        ],
      );

  /// "From request · Villa · Order" or "Internal" (the detail links to the
  /// request).
  Widget _originCell(AdminTask t) => Text(
        t.fromGuestRequest
            ? _s.fromRequest(t.villaName ?? '—', _s.sourceLabel(t.sourceType))
            : _s.internal,
        key: Key('task-origin-${t.id}'),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: KachavaTokens.textSecondary),
      );

  List<AdminTableColumn<AdminTask>> _columns() => [
        AdminTableColumn(label: _s.title, cell: _titleCell, flex: 3),
        AdminTableColumn(
            label: _s.villaGuest,
            text: (t) => AdminI18n.orDash(t.villaGuest),
            flex: 2),
        AdminTableColumn(
            label: _s.owner,
            text: (t) => AdminI18n.staffLabel(t.ownerName, widget.isEs)),
        AdminTableColumn(
            label: _s.priority,
            flex: 1,
            cell: (t) => StatusChip(
                label: _s.priorityLabel(t.priority),
                tone: TaskTone.priority(t.priority))),
        AdminTableColumn(
            label: _s.due,
            text: (t) => widget.resortTime.label(t.dueAt, isEs: widget.isEs),
            sortField: 'dueAt'),
        AdminTableColumn(label: _s.status, cell: _statusCell),
      ];

  List<AdminListFilter> _filters() => [
        AdminListFilter(key: 'status', label: _s.status, options: [
          for (final v in TaskValues.statuses)
            AdminFilterOption(v, AdminI18n.statusLabel(v, widget.isEs)),
        ]),
        AdminListFilter(key: 'priority', label: _s.priority, options: [
          for (final p in TaskValues.priorities)
            AdminFilterOption(p, _s.priorityLabel(p)),
        ]),
        AdminListFilter(key: 'owner', label: _s.owner, options: [
          for (final m in widget.staff)
            AdminFilterOption(m.staffId, m.fullName),
        ]),
        AdminListFilter(key: 'origin', label: _s.origin, options: [
          AdminFilterOption('GUEST', _s.guestRequest),
          AdminFilterOption('INTERNAL', _s.internal),
        ]),
        AdminListFilter(
            key: 'overdue',
            label: _s.overdueOnly,
            options: [AdminFilterOption('true', _s.yes)]),
      ];
}

/// Chip tone of a task priority (label always shown).
abstract final class TaskTone {
  static StatusTone priority(String p) => switch (p) {
        'URGENT' => StatusTone.error,
        'HIGH' => StatusTone.warning,
        _ => StatusTone.neutral,
      };
}
