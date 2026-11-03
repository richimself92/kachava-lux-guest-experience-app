import 'package:flutter/material.dart';

import '../../../core/admin_i18n.dart';
import '../../../core/ops_strings.dart';
import '../../../core/resort_time.dart';
import '../../../core/theme/kachava_tokens.dart';
import '../../../domain/admin_task.dart';
import '../../../domain/staff_member.dart';
import '../../components/components.dart';
import '../ops_fields.dart';

/// One task: facts and the single next step as the primary button
/// ("Assign" asks for an owner, "Complete" for a note); "Cancel task" in ⋮.
class TaskDetailPanel extends StatefulWidget {
  const TaskDetailPanel({
    super.key,
    required this.task,
    required this.repository,
    required this.staff,
    required this.resortTime,
    required this.onClose,
    required this.onChanged,
    required this.isEs,
  });

  final AdminTask task;
  final TaskRepository repository;
  final List<StaffMember> staff;
  final ResortTime resortTime;
  final VoidCallback onClose;
  final VoidCallback onChanged;
  final bool isEs;

  @override
  State<TaskDetailPanel> createState() => _TaskDetailPanelState();
}

class _TaskDetailPanelState extends State<TaskDetailPanel> {
  late AdminTask _task = widget.task;
  bool _busy = false;

  OpsStrings get _s => OpsStrings(widget.isEs);

  Future<void> _advance() async {
    final next = _task.nextStatus;
    if (next == null) return;
    final move = await _askMove(next);
    if (move != null && mounted) await _apply(move);
  }

  Future<TaskTransition?> _askMove(String next) async {
    switch (next) {
      case TaskValues.assigned:
        final owner = await _pickOwner();
        return owner == null
            ? null
            : TaskTransition(
                to: next,
                ownerStaffId: owner.staffId,
                ownerName: owner.fullName);
      case TaskValues.completed:
        final note = await _text(_s.complete, _s.completionNote,
            const Key('task-complete-note'), false);
        return note == null ? null : TaskTransition(to: next, note: note);
      default:
        return TaskTransition(to: next);
    }
  }

  Future<String?> _text(
          String title, String label, Key key, bool destructive) =>
      showTextInputDialog(context,
          key: Key(destructive ? 'task-cancel-dialog' : 'task-complete-dialog'),
          title: title,
          fieldLabel: label,
          fieldKey: key,
          confirmLabel: title,
          cancelLabel: _s.back,
          destructive: destructive,
          isEs: widget.isEs);

  Future<StaffMember?> _pickOwner() {
    String? picked = _task.ownerStaffId;
    return showDialog<StaffMember>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        key: const Key('task-assign-dialog'),
        title: Text(_s.assign),
        content: SizedBox(
          width: 360,
          child: widget.staff.isEmpty
              ? Text(_s.noStaff)
              : AdminDropdownFormField<String>(
                  label: _s.owner,
                  isRequired: true,
                  fieldKey: const Key('task-assign-owner'),
                  initialValue: widget.staff.any((m) => m.staffId == picked)
                      ? picked
                      : null,
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
            key: const Key('task-assign-confirm'),
            onPressed: () => Navigator.of(dialogContext).pop(
                widget.staff.where((m) => m.staffId == picked).firstOrNull),
            child: Text(_s.assign),
          ),
        ],
      ),
    );
  }

  Future<void> _cancel() async {
    final reason = await _text(
        _s.cancelTask, _s.reason, const Key('task-cancel-reason'), true);
    if (reason != null && mounted) {
      await _apply(TaskTransition(to: TaskValues.cancelled, reason: reason));
    }
  }

  Future<void> _apply(TaskTransition move) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    setState(() => _busy = true);
    try {
      final updated = await widget.repository.transition(_task.id, move);
      if (mounted) setState(() => _task = updated);
      widget.onChanged();
      showAdminToastOn(messenger, AdminI18n.statusLabel(move.to, widget.isEs));
    } catch (_) {
      showAdminToastOn(messenger, _s.actionFailed,
          isError: true, isEs: widget.isEs);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = _task;
    return AdminDetailPanel(
      key: const Key('task-detail'),
      title: t.title,
      onClose: widget.onClose,
      isEs: widget.isEs,
      actions: [if (!t.isFinal) _menu()],
      body: ListView(
        padding: const EdgeInsets.all(KachavaTokens.space6),
        children: [
          Wrap(spacing: KachavaTokens.space2, children: [
            StatusChip.fromStatus(t.status,
                key: const Key('task-status'), isEs: widget.isEs),
            if (t.overdue)
              StatusChip(label: _s.overdue, tone: StatusTone.error),
          ]),
          const SizedBox(height: KachavaTokens.space4),
          FactRow(label: _s.villaGuest, value: t.villaGuest),
          FactRow(label: _s.category, value: t.category),
          FactRow(label: _s.priority, value: _s.priorityLabel(t.priority)),
          FactRow(
              label: _s.owner,
              value: AdminI18n.staffLabel(t.ownerName, widget.isEs)),
          FactRow(
              label: _s.due,
              value: widget.resortTime.label(t.dueAt, isEs: widget.isEs)),
          FactRow(label: _s.source, value: _s.sourceLabel(t.sourceType)),
          if (t.completion case final c?)
            FactRow(label: _s.completion, value: c.note),
          if (t.cancellationReason case final r?)
            FactRow(label: _s.reason, value: r),
        ],
      ),
      footer: _footer(),
    );
  }

  Widget? _footer() {
    final next = _task.nextStatus;
    if (next == null) return null;
    return Row(children: [
      const Spacer(),
      FilledButton(
        key: const Key('task-next-action'),
        onPressed: _busy ? null : _advance,
        child: Text(_s.actionFor(next)),
      ),
    ]);
  }

  Widget _menu() => PopupMenuButton<String>(
        key: const Key('task-actions'),
        tooltip: _s.actions,
        enabled: !_busy,
        onSelected: (_) => _cancel(),
        itemBuilder: (_) => [
          PopupMenuItem(
            key: const Key('task-action-cancel'),
            value: 'cancel',
            child: Text(_s.cancelTask),
          ),
        ],
      );
}
