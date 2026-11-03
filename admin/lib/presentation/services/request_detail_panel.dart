import 'package:flutter/material.dart';

import '../../core/request_strings.dart';
import '../../core/resort_time.dart';
import '../../core/service_catalog_labels.dart';
import '../../core/theme/kachava_tokens.dart';
import '../../domain/service_request.dart';
import '../components/components.dart';
import '../operations/ops_fields.dart';

/// One guest request: status, facts and one button per allowed action
/// (Confirm, Start, Complete, Cancel request). Cancel asks for a reason.
class RequestDetailPanel extends StatefulWidget {
  const RequestDetailPanel({
    super.key,
    required this.request,
    required this.repository,
    required this.onClose,
    required this.onChanged,
    required this.isEs,
  });

  final ServiceRequest request;
  final ServiceRequestRepository repository;
  final VoidCallback onClose;

  /// Runs after a server-confirmed move (reload the list).
  final VoidCallback onChanged;
  final bool isEs;

  @override
  State<RequestDetailPanel> createState() => _RequestDetailPanelState();
}

class _RequestDetailPanelState extends State<RequestDetailPanel> {
  late ServiceRequest _r = widget.request;
  bool _busy = false;

  RequestStrings get _s => RequestStrings(widget.isEs);

  Future<void> _run(RequestAction action) async {
    String? reason;
    if (action == RequestAction.cancel) {
      reason = await _askReason();
      if (reason == null || !mounted) return;
    }
    final messenger = ScaffoldMessenger.maybeOf(context);
    setState(() => _busy = true);
    try {
      final updated =
          await widget.repository.transition(_r.id, action, reason: reason);
      if (mounted) setState(() => _r = updated);
      widget.onChanged();
      showAdminToastOn(
          messenger, action == RequestAction.cancel ? _s.cancelled : _s.moved);
    } catch (_) {
      showAdminToastOn(messenger, _s.actionFailed,
          isError: true, isEs: widget.isEs);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// A required one-line reason; `null` when dismissed.
  Future<String?> _askReason() {
    final form = GlobalKey<FormState>();
    var reason = '';
    final scheme = Theme.of(context).colorScheme;
    return showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        key: const Key('request-cancel-dialog'),
        title: Text(_s.action(RequestAction.cancel)),
        content: SizedBox(
          width: 360,
          child: Form(
            key: form,
            child: AdminTextFormField(
              label: _s.reason,
              isRequired: true,
              fieldKey: const Key('request-cancel-reason'),
              validator: AdminValidators.maxLength(200, widget.isEs),
              onChanged: (v) => reason = v,
              isEs: widget.isEs,
            ),
          ),
        ),
        actions: [
          TextButton(
            key: const Key('request-cancel-back'),
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(_s.back),
          ),
          FilledButton(
            key: const Key('request-cancel-confirm'),
            style: FilledButton.styleFrom(
                backgroundColor: scheme.error, foregroundColor: scheme.onError),
            onPressed: () {
              if (form.currentState?.validate() ?? false) {
                Navigator.of(dialogContext).pop(reason.trim());
              }
            },
            child: Text(_s.action(RequestAction.cancel)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final money = ServiceCatalogLabels(widget.isEs).money;
    return AdminDetailPanel(
      title: _r.serviceName.of(isEs: widget.isEs),
      onClose: widget.onClose,
      isEs: widget.isEs,
      body: ListView(
        key: const Key('request-detail'),
        padding: const EdgeInsets.all(KachavaTokens.space6),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: StatusChip.fromStatus(_r.status,
                key: const Key('request-status'), isEs: widget.isEs),
          ),
          const SizedBox(height: KachavaTokens.space4),
          FactRow(label: _s.guest, value: _r.guestName),
          FactRow(label: _s.villa, value: _r.villaName),
          FactRow(label: _s.dateTime, value: requestWhen(_r, widget.isEs)),
          FactRow(
              label: _r.isOrder ? _s.quantity : _s.guests,
              value: '${_r.quantity}'),
          if (_r.lines.isNotEmpty)
            FactRow(
                label: _s.items,
                value: [
                  for (final l in _r.lines)
                    '${l.name.of(isEs: widget.isEs)} × ${l.quantity}'
                ].join('\n')),
          FactRow(label: _s.total, value: money(_r.totalUSD)),
          if (_r.cancellationReason case final reason?)
            FactRow(label: _s.reason, value: reason),
        ],
      ),
      footer: _footer(),
    );
  }

  Widget? _footer() {
    final actions = _r.actions;
    if (actions.isEmpty) return null;
    return Wrap(
      alignment: WrapAlignment.end,
      spacing: KachavaTokens.space2,
      runSpacing: KachavaTokens.space2,
      children: [
        for (final a in actions)
          a == RequestAction.cancel
              ? OutlinedButton(
                  key: Key('request-action-${a.wire.toLowerCase()}'),
                  style: OutlinedButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.error),
                  onPressed: _busy ? null : () => _run(a),
                  child: Text(_s.action(a)),
                )
              : a == actions.first
                  ? FilledButton(
                      key: Key('request-action-${a.wire.toLowerCase()}'),
                      onPressed: _busy ? null : () => _run(a),
                      child: Text(_s.action(a)),
                    )
                  : OutlinedButton(
                      key: Key('request-action-${a.wire.toLowerCase()}'),
                      onPressed: _busy ? null : () => _run(a),
                      child: Text(_s.action(a)),
                    ),
      ],
    );
  }
}

/// "Nov 4 · 10:00" (resort wall time as sent by the server).
String requestWhen(ServiceRequest r, bool isEs) {
  final day = ResortTime.dayLabel(r.day, isEs: isEs);
  return r.time.isEmpty ? day : '$day · ${r.time}';
}
