import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/admin_i18n.dart';
import '../../../core/stay_strings.dart';
import '../../../core/theme/kachava_tokens.dart';
import '../../../domain/reservation.dart';
import '../../../domain/staff_member.dart';
import '../../components/components.dart';
import '../ops_fields.dart';

/// Summary tab: guest link (Copy), stay facts, Resort Host, Wi-Fi and
/// internal notes. Edits are saved with one "Save" (open stays only).
class ReservationSummaryTab extends StatefulWidget {
  const ReservationSummaryTab({
    super.key,
    required this.detail,
    required this.staff,
    required this.onSave,
    required this.isEs,
  });

  final StayDetail detail;
  final List<StaffMember> staff;

  /// Throws on failure (the edits stay in the form).
  final Future<void> Function(ReservationPatch patch) onSave;
  final bool isEs;

  @override
  State<ReservationSummaryTab> createState() => _ReservationSummaryTabState();
}

class _ReservationSummaryTabState extends State<ReservationSummaryTab> {
  late final TextEditingController _ssid =
      TextEditingController(text: widget.detail.wifiSsid);
  late final TextEditingController _password =
      TextEditingController(text: widget.detail.wifiPassword);
  late final TextEditingController _notes =
      TextEditingController(text: widget.detail.internalNotes);
  late String? _hostId = widget.detail.resortHostStaffId;
  bool _saving = false;

  StayStrings get _s => StayStrings(widget.isEs);
  StayDetail get _d => widget.detail;
  bool get _editable => _d.row.isOpen;

  @override
  void dispose() {
    _ssid.dispose();
    _password.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _copyLink() async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    await Clipboard.setData(ClipboardData(text: _d.row.magicLinkUrl));
    showAdminToastOn(messenger, _s.linkCopied);
  }

  ReservationPatch _patch() {
    final host = widget.staff.where((m) => m.staffId == _hostId).firstOrNull;
    return ReservationPatch(
      resortHostStaffId: host?.staffId,
      resortHostName: host?.fullName,
      internalNotes:
          _notes.text.trim() == _d.internalNotes ? null : _notes.text.trim(),
      wifiSsid: _ssid.text.trim() == _d.wifiSsid ? null : _ssid.text.trim(),
      wifiPassword: _password.text == _d.wifiPassword ? null : _password.text,
    );
  }

  Future<void> _save() async {
    final patch = _patch();
    if (patch.toJson().isEmpty) return;
    setState(() => _saving = true);
    try {
      await widget.onSave(patch);
    } catch (_) {
      // The panel shows the one-line error toast.
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const Key('reservation-summary'),
      padding: const EdgeInsets.all(KachavaTokens.space6),
      children: [
        _link(),
        const SizedBox(height: KachavaTokens.space4),
        FactRow(label: _s.villa, value: _d.row.villaName),
        FactRow(
            label: _s.dates,
            value:
                '${_s.range(_d.row.checkIn, _d.row.checkOut)} (${_s.nights(_d.nights)})'),
        FactRow(
            label: _s.status,
            value: AdminI18n.statusLabel(_d.row.status, widget.isEs)),
        FactRow(label: _s.guests, value: '${_d.guestsCount}'),
        FactRow(label: _s.language, value: _s.languageLabel(_d.language)),
        if (_d.occasion.isNotEmpty)
          FactRow(label: _s.occasion, value: _d.occasion),
        if (_d.cancellationReason case final reason?)
          FactRow(label: _s.reason, value: reason),
        const SizedBox(height: KachavaTokens.space2),
        ..._editor(),
      ],
    );
  }

  Widget _link() => Row(children: [
        Expanded(
          child: Text(_s.guestLink,
              style: Theme.of(context).textTheme.titleMedium),
        ),
        OutlinedButton.icon(
          key: const Key('reservation-copy-link'),
          onPressed: _d.row.magicLinkUrl.isEmpty ? null : _copyLink,
          icon: const Icon(Icons.copy, size: 18),
          label: Text(_s.copy),
        ),
      ]);

  List<Widget> _editor() => [
        _hostField(),
        AdminTextFormField(
          label: _s.wifiName,
          controller: _ssid,
          fieldKey: const Key('reservation-wifi-ssid'),
          isEs: widget.isEs,
        ),
        AdminPasswordFormField(
          label: _s.wifiPassword,
          showLabel: _s.show,
          hideLabel: _s.hide,
          initialValue: _d.wifiPassword,
          onChanged: (v) => _password.text = v,
          fieldKey: const Key('reservation-wifi-password'),
          isEs: widget.isEs,
        ),
        AdminTextFormField(
          label: _s.internalNotes,
          info: _s.notesInfo,
          controller: _notes,
          maxLines: 4,
          fieldKey: const Key('reservation-notes'),
          isEs: widget.isEs,
        ),
        if (_editable)
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton(
              key: const Key('reservation-save'),
              onPressed: _saving ? null : _save,
              child: Text(_s.save),
            ),
          ),
      ];

  Widget _hostField() {
    if (widget.staff.isEmpty) {
      return FactRow(
          label: _s.resortHost, value: _d.row.resortHostName ?? _s.unassigned);
    }
    return AdminDropdownFormField<String>(
      label: _s.resortHost,
      fieldKey: const Key('reservation-host'),
      initialValue:
          widget.staff.any((m) => m.staffId == _hostId) ? _hostId : null,
      choices: [
        for (final m in widget.staff) AdminChoice(m.staffId, m.fullName)
      ],
      onChanged: (v) => setState(() => _hostId = v),
      isEs: widget.isEs,
    );
  }
}
