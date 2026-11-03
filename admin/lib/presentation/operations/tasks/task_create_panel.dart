import 'package:flutter/material.dart';

import '../../../core/ops_strings.dart';
import '../../../domain/admin_catalog_repositories.dart';
import '../../../domain/admin_task.dart';
import '../../../domain/reservation.dart';
import '../../../domain/staff_member.dart';
import '../../components/components.dart';
import '../../workspaces/transportation/trip_form_fields.dart';

/// "+ New task": title, category, priority (Normal), due time and owner;
/// the reservation link is optional (villa and guest are copied from it).
class TaskCreatePanel extends StatefulWidget {
  const TaskCreatePanel({
    super.key,
    required this.repository,
    required this.stays,
    required this.staff,
    required this.onClose,
    required this.onCreated,
    required this.isEs,
  });

  final TaskRepository repository;
  final StayListRepository stays;
  final List<StaffMember> staff;
  final VoidCallback onClose;
  final ValueChanged<AdminTask> onCreated;
  final bool isEs;

  @override
  State<TaskCreatePanel> createState() => _TaskCreatePanelState();
}

class _TaskCreatePanelState extends State<TaskCreatePanel> {
  final TextEditingController _due = TextEditingController();
  String _title = '';
  String _category = '';
  String _priority = TaskValues.defaultPriority;
  String? _ownerId;
  ReservationRow? _stay;

  OpsStrings get _s => OpsStrings(widget.isEs);

  @override
  void dispose() {
    _due.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    final owner = widget.staff.where((m) => m.staffId == _ownerId).firstOrNull;
    final created = await widget.repository.create(NewTask(
      title: _title,
      category: _category,
      priority: _priority,
      dueAt: TripDateTimeField.toWire(_due.text),
      stayId: _stay?.id,
      ownerStaffId: owner?.staffId,
      ownerName: owner?.fullName,
    ));
    widget.onCreated(created);
    showAdminToastOn(messenger, _s.created);
  }

  Widget _text(String label, String key, ValueChanged<String> onChanged) =>
      AdminTextFormField(
        label: label,
        isRequired: true,
        fieldKey: Key(key),
        validator: AdminValidators.all([
          AdminValidators.required(widget.isEs),
          AdminValidators.maxLength(200, widget.isEs),
        ]),
        onChanged: onChanged,
        isEs: widget.isEs,
      );

  @override
  Widget build(BuildContext context) {
    return AdminFormPanel(
      key: const Key('task-create'),
      title: _s.newTask,
      onSave: _save,
      onClose: widget.onClose,
      isEs: widget.isEs,
      children: [
        _text(_s.title, 'task-title', (v) => _title = v),
        _text(_s.category, 'task-category', (v) => _category = v),
        AdminDropdownFormField<String>(
          label: _s.priority,
          fieldKey: const Key('task-priority'),
          initialValue: _priority,
          choices: [
            for (final p in TaskValues.priorities)
              AdminChoice(p, _s.priorityLabel(p)),
          ],
          onChanged: (v) => _priority = v ?? TaskValues.defaultPriority,
          isEs: widget.isEs,
        ),
        TripDateTimeField(
          label: _s.due,
          info: _s.dueInfo,
          controller: _due,
          fieldKey: const Key('task-due'),
          isEs: widget.isEs,
        ),
        AdminDropdownFormField<String>(
          label: _s.owner,
          fieldKey: const Key('task-owner'),
          choices: [
            for (final m in widget.staff) AdminChoice(m.staffId, m.fullName)
          ],
          onChanged: (v) => _ownerId = v,
          isEs: widget.isEs,
        ),
        StayPickerField(
          stays: widget.stays,
          selected: _stay,
          isRequired: false,
          onSelected: (stay) => setState(() => _stay = stay),
          isEs: widget.isEs,
        ),
      ],
    );
  }
}
