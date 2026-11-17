import 'package:flutter/material.dart';

import '../../core/staff_strings.dart';
import '../../core/theme/kachava_tokens.dart';
import '../../domain/staff_member.dart';
import '../components/components.dart';

/// Create/edit one staff member; ⋮ Deactivate/Activate with a one-line
/// confirm. Name, role, department and email are required; the job title
/// sits in a collapsed "More".
class StaffDetailPanel extends StatefulWidget {
  const StaffDetailPanel({
    super.key,
    required this.member,
    required this.repository,
    required this.onClose,
    required this.onChanged,
    required this.isEs,
  });

  /// `null` creates a new staff member.
  final StaffMember? member;
  final StaffRosterRepository repository;
  final VoidCallback onClose;
  final VoidCallback onChanged;
  final bool isEs;

  @override
  State<StaffDetailPanel> createState() => _StaffDetailPanelState();
}

class _StaffDetailPanelState extends State<StaffDetailPanel> {
  static final RegExp _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  late final StaffMember? _m = widget.member;
  late String _name = _m?.fullName ?? '';
  late StaffRole? _role = _m?.rbacRole;
  late StaffDepartment? _department = _m?.department;
  late String _emailText = _m?.email ?? '';
  late String _phone = _m?.phone ?? '';
  late String _jobTitle = _m?.role ?? '';

  StaffStrings get _s => StaffStrings(widget.isEs);

  Future<void> _save() async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    final draft = StaffMember(
      staffId: _m?.staffId ?? '',
      fullName: _name.trim(),
      shortName: _m?.shortName ?? '',
      role: _jobTitle.trim(),
      department: _department!,
      rbacRole: _role!,
      email: _emailText.trim(),
      phone: _phone.trim(),
      isActive: _m?.isActive ?? true,
    );
    if (_m == null) {
      await widget.repository.create(draft);
    } else {
      await widget.repository.update(draft);
    }
    widget.onChanged();
    showAdminToastOn(messenger, _s.saved);
  }

  Future<void> _toggleActive() async {
    final m = _m!;
    final on = !m.isActive;
    final ok = await showConfirmDialog(context,
        title: on ? _s.activateQ(m.fullName) : _s.deactivateQ(m.fullName),
        confirmLabel: on ? _s.activate : _s.deactivate,
        cancelLabel: _s.cancel,
        destructive: !on);
    if (!ok || !mounted) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    try {
      await widget.repository.setActive(m.staffId, on);
      widget.onChanged();
      widget.onClose();
      showAdminToastOn(messenger, on ? _s.activated : _s.deactivated);
    } catch (_) {
      showAdminToastOn(messenger, _s.saveFailed,
          isError: true, isEs: widget.isEs);
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = _m;
    return AdminFormPanel(
      title: m?.fullName ?? _s.newStaff,
      onSave: _save,
      onClose: widget.onClose,
      failureMessage: (error) =>
          error is StaffEmailTakenException ? _s.emailTaken : null,
      isEs: widget.isEs,
      actions: [if (m != null) _menu(m)],
      children: [
        if (m != null && !m.isActive)
          Padding(
            padding: const EdgeInsets.only(bottom: KachavaTokens.space4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: StatusChip(label: _s.inactive, tone: StatusTone.neutral),
            ),
          ),
        AdminTextFormField(
          label: _s.name,
          isRequired: true,
          initialValue: _name,
          fieldKey: const Key('staff-name'),
          validator: AdminValidators.maxLength(200, widget.isEs),
          onChanged: (v) => _name = v,
          isEs: widget.isEs,
        ),
        _choice<StaffRole>(
          label: _s.role,
          key: 'staff-role',
          value: _role,
          choices: [
            for (final r in StaffRole.values) AdminChoice(r, _s.roleLabel(r))
          ],
          onChanged: (v) => _role = v,
        ),
        _choice<StaffDepartment>(
          label: _s.department,
          key: 'staff-department',
          value: _department,
          choices: [
            for (final d in StaffDepartment.values)
              AdminChoice(d, _s.departmentLabel(d))
          ],
          onChanged: (v) => _department = v,
        ),
        AdminTextFormField(
          label: _s.email,
          isRequired: true,
          initialValue: _emailText,
          fieldKey: const Key('staff-email'),
          keyboardType: TextInputType.emailAddress,
          validator: _validateEmail,
          onChanged: (v) => _emailText = v,
          isEs: widget.isEs,
        ),
        AdminTextFormField(
          label: _s.phone,
          initialValue: _phone,
          fieldKey: const Key('staff-phone'),
          keyboardType: TextInputType.phone,
          validator: AdminValidators.maxLength(200, widget.isEs),
          onChanged: (v) => _phone = v,
          isEs: widget.isEs,
        ),
        AdminAdvancedSection(
          key: const Key('staff-more'),
          title: _s.more,
          children: [
            AdminTextFormField(
              label: _s.jobTitle,
              initialValue: _jobTitle,
              fieldKey: const Key('staff-job-title'),
              validator: AdminValidators.maxLength(200, widget.isEs),
              onChanged: (v) => _jobTitle = v,
              isEs: widget.isEs,
            ),
          ],
        ),
      ],
    );
  }

  String? _validateEmail(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return AdminValidators.required(widget.isEs)(text);
    return _email.hasMatch(text) ? null : _s.invalidEmail;
  }

  /// A required dropdown (validated with the form).
  Widget _choice<T>({
    required String label,
    required String key,
    required T? value,
    required List<AdminChoice<T>> choices,
    required ValueChanged<T?> onChanged,
  }) =>
      AdminDropdownFormField<T>(
        label: label,
        isRequired: true,
        fieldKey: Key(key),
        initialValue: value,
        choices: choices,
        onChanged: onChanged,
        isEs: widget.isEs,
      );

  Widget _menu(StaffMember m) => PopupMenuButton<String>(
        key: const Key('staff-actions'),
        tooltip: _s.actions,
        onSelected: (_) => _toggleActive(),
        itemBuilder: (_) => [
          PopupMenuItem(
            key: Key(m.isActive
                ? 'staff-action-deactivate'
                : 'staff-action-activate'),
            value: 'toggle',
            child: Text(m.isActive ? _s.deactivate : _s.activate),
          ),
        ],
      );
}
