import 'package:flutter/material.dart';

import '../../core/inbox_strings.dart';
import '../../core/ops_strings.dart';
import '../../core/resort_time.dart';
import '../../core/theme/kachava_tokens.dart';
import '../../domain/admin_task.dart';
import '../../domain/inbox_item.dart';
import '../../domain/staff_member.dart';
import '../components/components.dart';
import '../operations/ops_fields.dart';

/// The request's operational task (spec › Tasks): status, owner, due,
/// "Open task" and the optional "Assign to staff". Without a task,
/// "Create task" (when [onCreateTask] is wired). Assigning is never needed
/// to move the request.
class InboxTaskSection extends StatefulWidget {
  const InboxTaskSection({
    super.key,
    required this.item,
    required this.tasks,
    required this.staff,
    required this.isEs,
    this.resortTime,
    this.onOpenTask,
    this.onCreateTask,
  });

  final InboxItem item;
  final TaskRepository tasks;
  final List<StaffMember> staff;
  final bool isEs;
  final ResortTime? resortTime;
  final ValueChanged<String>? onOpenTask;

  /// Creates the linked task server-side; resolves it.
  final Future<AdminTask> Function(InboxItem item)? onCreateTask;

  @override
  State<InboxTaskSection> createState() => _InboxTaskSectionState();
}

class _InboxTaskSectionState extends State<InboxTaskSection> {
  AdminTask? _task;
  bool _loaded = false;
  bool _busy = false;

  InboxStrings get _s => InboxStrings(widget.isEs);
  OpsStrings get _ops => OpsStrings(widget.isEs);

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(InboxTaskSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.status != widget.item.status) _load();
  }

  Future<void> _load() async {
    AdminTask? task;
    try {
      task = await widget.tasks.get(widget.item.taskId);
    } catch (_) {
      task = null; // No linked task (404) or not readable.
    }
    if (mounted) {
      setState(() {
        _task = task;
        _loaded = true;
      });
    }
  }

  Future<void> _assign() async {
    final owner = await _pickOwner();
    final task = _task;
    if (owner == null || task == null || !mounted) return;
    await _write(() => widget.tasks.transition(
        task.id,
        TaskTransition(
            to: TaskValues.assigned,
            ownerStaffId: owner.staffId,
            ownerName: owner.fullName)));
  }

  Future<void> _create() async {
    final create = widget.onCreateTask;
    if (create != null) await _write(() => create(widget.item));
  }

  Future<void> _write(Future<AdminTask> Function() call) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    setState(() => _busy = true);
    try {
      final task = await call();
      if (mounted) setState(() => _task = task);
    } catch (_) {
      showAdminToastOn(messenger, _ops.actionFailed,
          isError: true, isEs: widget.isEs);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<StaffMember?> _pickOwner() {
    String? picked;
    return showDialog<StaffMember>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        key: const Key('inbox-assign-dialog'),
        title: Text(_s.assign),
        content: SizedBox(
          width: 360,
          child: widget.staff.isEmpty
              ? Text(_ops.noStaff)
              : AdminDropdownFormField<String>(
                  label: _s.staffMember,
                  isRequired: true,
                  fieldKey: const Key('inbox-assign-owner'),
                  choices: [
                    for (final m in widget.staff)
                      AdminChoice(m.staffId, m.fullName)
                  ],
                  onChanged: (v) => picked = v,
                  isEs: widget.isEs),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(_s.back)),
          FilledButton(
            key: const Key('inbox-assign-confirm'),
            onPressed: () => Navigator.of(dialogContext).pop(
                widget.staff.where((m) => m.staffId == picked).firstOrNull),
            child: Text(_s.assign),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) return const SizedBox.shrink();
    final task = _task;
    return Column(
      key: const Key('inbox-task'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PanelHeading(_ops.tasks),
        if (task == null)
          _noTask()
        else ...[
          Align(
            alignment: Alignment.centerLeft,
            child: StatusChip.fromStatus(task.status,
                key: const Key('inbox-task-status'), isEs: widget.isEs),
          ),
          const SizedBox(height: KachavaTokens.space2),
          FactRow(label: _ops.owner, value: task.ownerName ?? ''),
          FactRow(
              label: _ops.due,
              value: widget.resortTime?.label(task.dueAt, isEs: widget.isEs) ??
                  ''),
          _taskActions(task),
        ],
      ],
    );
  }

  Widget _noTask() => widget.onCreateTask == null
      ? const Text('—')
      : Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            key: const Key('inbox-create-task'),
            onPressed: _busy ? null : _create,
            icon: const Icon(Icons.add_task, size: 18),
            label: Text(_s.createTask),
          ),
        );

  Widget _taskActions(AdminTask task) => Wrap(
        spacing: KachavaTokens.space2,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          if (widget.onOpenTask case final open?)
            TextButton(
              key: const Key('inbox-open-task'),
              onPressed: () => open(task.id),
              child: Text(_s.openTask),
            ),
          if (task.status == TaskValues.pending) ...[
            TextButton.icon(
              key: const Key('inbox-assign'),
              onPressed: _busy ? null : _assign,
              icon: const Icon(Icons.person_add_alt, size: 18),
              label: Text(_s.assign),
            ),
            InfoTooltip(_s.assignInfo),
          ],
        ],
      );
}
