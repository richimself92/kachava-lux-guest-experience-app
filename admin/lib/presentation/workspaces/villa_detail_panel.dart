import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/admin_i18n.dart';
import '../../core/resort_strings.dart';
import '../../core/theme/kachava_tokens.dart';
import '../../domain/admin_catalog_repositories.dart';
import '../../domain/admin_villa.dart';
import '../components/components.dart';

/// Create/edit one villa in the side panel (mobile: full-screen sheet).
///
/// Main fields: name, category, capacity, status, housekeeping. Optional
/// ones (Wi-Fi, maintenance) sit in a collapsed "More". Secondary actions
/// (Deactivate/Activate, Delete) live in the header ⋮ menu.
class VillaDetailPanel extends StatefulWidget {
  const VillaDetailPanel({
    super.key,
    required this.villa,
    required this.repository,
    required this.onClose,
    required this.onChanged,
    required this.isEs,
  });

  /// `null` creates a new villa.
  final AdminVilla? villa;
  final VillaRepository repository;
  final VoidCallback onClose;

  /// Runs after any server-confirmed change (reload the list).
  final VoidCallback onChanged;
  final bool isEs;

  @override
  State<VillaDetailPanel> createState() => _VillaDetailPanelState();
}

class _VillaDetailPanelState extends State<VillaDetailPanel> {
  // Draft values: fields write here on change, so the collapsed (unbuilt)
  // "More" fields keep the villa's current values.
  late final AdminVilla? _v = widget.villa;
  late String _name = _v?.name ?? '';
  late String _category = _v?.category ?? '';
  late String _capacity = _v?.capacity?.toString() ?? '';
  late String _status =
      _orDefault(_v?.operationalStatus, VillaStatusValues.operational);
  late String _housekeeping =
      _orDefault(_v?.housekeepingStatus, VillaStatusValues.housekeeping);
  late String _maintenance =
      _orDefault(_v?.maintenanceStatus, VillaStatusValues.maintenance);
  late String _wifiSsid = _v?.wifiSsid ?? '';
  late String _wifiPassword = _v?.wifiPassword ?? '';
  late String _note = _v?.maintenanceNote ?? '';

  ResortStrings get _s => ResortStrings(widget.isEs);

  /// The first wire value is the sensible default of a new villa.
  static String _orDefault(String? value, List<String> allowed) =>
      value != null && allowed.contains(value) ? value : allowed.first;

  AdminVilla _draft() => AdminVilla(
        id: _v?.id ?? '',
        name: _name.trim(),
        category: _category.trim(),
        capacity: int.tryParse(_capacity.trim()),
        wifiSsid: _wifiSsid.trim(),
        wifiPassword: _wifiPassword,
        operationalStatus: _status,
        housekeepingStatus: _housekeeping,
        maintenanceStatus: _maintenance,
        maintenanceNote: _note.trim(),
        isActive: _v?.isActive ?? true,
      );

  /// Throws on failure so the form shows "Couldn't save" and stays open.
  Future<void> _save() async {
    final draft = _draft();
    if (_v == null) {
      await widget.repository.create(draft);
    } else {
      await widget.repository.update(draft);
    }
    widget.onChanged();
    if (mounted) showAdminToast(context, _s.villaSaved);
  }

  String? _validateCapacity(String? value) {
    final n = int.tryParse((value ?? '').trim());
    if (n == null) return _s.wholeNumber;
    return n < 1 || n > VillaStatusValues.maxCapacity
        ? _s.capacityRange(VillaStatusValues.maxCapacity)
        : null;
  }

  List<AdminChoice<String>> _choices(List<String> values) => [
        for (final v in values)
          AdminChoice(v, AdminI18n.statusLabel(v, widget.isEs)),
      ];

  @override
  Widget build(BuildContext context) {
    return AdminFormPanel(
      title: _v?.name ?? _s.newVilla,
      onSave: _save,
      onClose: widget.onClose,
      isEs: widget.isEs,
      actions: [
        if (_v != null)
          _VillaActionsMenu(
            villa: _v,
            repository: widget.repository,
            onDone: () {
              widget.onChanged();
              widget.onClose();
            },
            isEs: widget.isEs,
          ),
      ],
      children: [
        if (_v?.currentGuestName case final guest?)
          Padding(
            padding: const EdgeInsets.only(bottom: KachavaTokens.space4),
            child: Text('${_s.currentGuest} · $guest',
                key: const Key('villa-current-guest')),
          ),
        ..._mainFields(),
        AdminAdvancedSection(
          key: const Key('villa-more'),
          title: _s.more,
          children: _moreFields(),
        ),
      ],
    );
  }

  List<Widget> _mainFields() => [
        AdminTextFormField(
          label: _s.name,
          isRequired: true,
          initialValue: _name,
          fieldKey: const Key('villa-name'),
          validator: AdminValidators.maxLength(200, widget.isEs),
          onChanged: (v) => _name = v,
          isEs: widget.isEs,
        ),
        AdminTextFormField(
          label: _s.category,
          isRequired: true,
          initialValue: _category,
          fieldKey: const Key('villa-category'),
          validator: AdminValidators.maxLength(200, widget.isEs),
          onChanged: (v) => _category = v,
          isEs: widget.isEs,
        ),
        AdminTextFormField(
          label: _s.capacity,
          info: _s.capacityInfo,
          isRequired: true,
          initialValue: _capacity,
          fieldKey: const Key('villa-capacity'),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          validator: _validateCapacity,
          onChanged: (v) => _capacity = v,
          isEs: widget.isEs,
        ),
        AdminDropdownFormField<String>(
          label: _s.status,
          fieldKey: const Key('villa-status'),
          initialValue: _status,
          choices: _choices(VillaStatusValues.operational),
          onChanged: (v) => _status = v ?? _status,
          isEs: widget.isEs,
        ),
        AdminDropdownFormField<String>(
          label: _s.housekeeping,
          fieldKey: const Key('villa-housekeeping'),
          initialValue: _housekeeping,
          choices: _choices(VillaStatusValues.housekeeping),
          onChanged: (v) => _housekeeping = v ?? _housekeeping,
          isEs: widget.isEs,
        ),
      ];

  List<Widget> _moreFields() => [
        AdminTextFormField(
          label: _s.wifiNetwork,
          initialValue: _wifiSsid,
          fieldKey: const Key('villa-wifi-ssid'),
          validator: AdminValidators.maxLength(200, widget.isEs),
          onChanged: (v) => _wifiSsid = v,
          isEs: widget.isEs,
        ),
        AdminPasswordFormField(
          label: _s.wifiPassword,
          showLabel: _s.showPassword,
          hideLabel: _s.hidePassword,
          initialValue: _wifiPassword,
          fieldKey: const Key('villa-wifi-password'),
          toggleKey: const Key('villa-wifi-password-toggle'),
          onChanged: (v) => _wifiPassword = v,
          isEs: widget.isEs,
        ),
        AdminDropdownFormField<String>(
          label: _s.maintenance,
          fieldKey: const Key('villa-maintenance'),
          initialValue: _maintenance,
          choices: _choices(VillaStatusValues.maintenance),
          onChanged: (v) => _maintenance = v ?? _maintenance,
          isEs: widget.isEs,
        ),
        AdminTextFormField(
          label: _s.maintenanceNote,
          initialValue: _note,
          maxLines: 3,
          fieldKey: const Key('villa-maintenance-note'),
          validator: AdminValidators.maxLength(2000, widget.isEs),
          onChanged: (v) => _note = v,
          isEs: widget.isEs,
        ),
      ];
}

/// ⋮ menu: Deactivate/Activate and Delete, each behind a one-line confirm.
/// A delete refused with "has stays" (409) offers Deactivate in the toast.
class _VillaActionsMenu extends StatelessWidget {
  const _VillaActionsMenu({
    required this.villa,
    required this.repository,
    required this.onDone,
    required this.isEs,
  });

  final AdminVilla villa;
  final VillaRepository repository;
  final VoidCallback onDone;
  final bool isEs;

  ResortStrings get _s => ResortStrings(isEs);

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      key: const Key('villa-actions'),
      tooltip: _s.actions,
      onSelected: (action) =>
          action == 'delete' ? _delete(context) : _toggleActive(context),
      itemBuilder: (_) => [
        PopupMenuItem(
          key: Key(villa.isActive
              ? 'villa-action-deactivate'
              : 'villa-action-activate'),
          value: 'toggle',
          child: Text(villa.isActive ? _s.deactivate : _s.activate),
        ),
        PopupMenuItem(
          key: const Key('villa-action-delete'),
          value: 'delete',
          child: Text(_s.delete),
        ),
      ],
    );
  }

  Future<void> _toggleActive(BuildContext context) async {
    final on = !villa.isActive;
    final ok = await showConfirmDialog(context,
        title: on ? _s.activateQ(villa.name) : _s.deactivateQ(villa.name),
        confirmLabel: on ? _s.activate : _s.deactivate,
        cancelLabel: _s.cancel,
        destructive: !on);
    if (ok && context.mounted) {
      await _setActive(ScaffoldMessenger.maybeOf(context), on);
    }
  }

  /// No [BuildContext]: the toast action may run after the panel closed.
  Future<void> _setActive(ScaffoldMessengerState? messenger, bool on) async {
    try {
      await repository.setActive(villa.id, on);
      onDone();
      showAdminToastOn(messenger, on ? _s.villaActivated : _s.villaDeactivated);
    } catch (_) {
      showAdminToastOn(messenger, _s.saveFailed, isError: true, isEs: isEs);
    }
  }

  Future<void> _delete(BuildContext context) async {
    final ok = await showConfirmDialog(context,
        title: _s.deleteQ(villa.name),
        confirmLabel: _s.delete,
        cancelLabel: _s.cancel,
        destructive: true);
    if (!ok || !context.mounted) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    try {
      await repository.delete(villa.id);
      onDone();
      showAdminToastOn(messenger, _s.villaDeleted);
    } on VillaHasStaysException {
      showAdminToastOn(messenger, _s.hasStays,
          isError: true,
          actionLabel: villa.isActive ? _s.deactivate : null,
          onRetry: villa.isActive ? () => _setActive(messenger, false) : null,
          isEs: isEs);
    } catch (_) {
      showAdminToastOn(messenger, _s.saveFailed, isError: true, isEs: isEs);
    }
  }
}
