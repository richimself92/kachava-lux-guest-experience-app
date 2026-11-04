import 'package:flutter/material.dart';

import '../../application/portal_controller.dart';
import '../../core/i18n/l10n.dart';
import '../../core/theme/kachava_colors.dart';
import '../../data/guest_api.dart';
import '../../domain/catalog.dart';
import '../../domain/journey.dart';
import '../../domain/requests.dart';
import '../common/labels.dart';
import '../common/widgets.dart';
import '../forms/booking_form.dart';
import 'request_card.dart';
import 'request_details.dart';

enum RequestsFilter { all, active, done }

/// My requests: one list, newest first, plain statuses and a 4-dot track.
class RequestsTab extends StatefulWidget {
  const RequestsTab({
    super.key,
    required this.controller,
    required this.onBrowse,
    required this.onAskHost,
  });

  final PortalController controller;
  final VoidCallback onBrowse;

  /// Opens the Resort Host chat with the request attached.
  final ValueChanged<String> onAskHost;

  @override
  State<RequestsTab> createState() => _RequestsTabState();
}

class _RequestsTabState extends State<RequestsTab> {
  RequestsFilter _filter = RequestsFilter.all;

  /// Journey number of the task a request belongs to ("1.3").
  Map<String, String> _numbers(Journey? journey) {
    final out = <String, String>{};
    if (journey == null) return out;
    for (final step in journey.steps) {
      for (final task in step.tasks) {
        for (final s in task.services) {
          out.putIfAbsent(s.id, () => task.number);
        }
      }
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final l10n = c.l10n;
    final all = c.requests;
    final list = all.where((r) => switch (_filter) {
          RequestsFilter.all => true,
          RequestsFilter.active => r.status.isActive,
          RequestsFilter.done => !r.status.isActive,
        });
    final numbers = _numbers(c.journey);
    return PageWidth(
      maxWidth: 720,
      child: ListView(
        key: const Key('screen-requests'),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Text(l10n.myRequests, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Wrap(spacing: 8, children: [
            for (final (f, label) in [
              (RequestsFilter.all, l10n.all),
              (RequestsFilter.active, l10n.chipActive),
              (RequestsFilter.done, l10n.chipDone),
            ])
              ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48),
                child: FilterChip(
                  key: Key('requests-${f.name}'),
                  label: Text(label),
                  selected: _filter == f,
                  materialTapTargetSize: MaterialTapTargetSize.padded,
                  onSelected: (_) => setState(() => _filter = f),
                ),
              ),
          ]),
          const SizedBox(height: 8),
          if (all.isEmpty)
            OneLineState(
              key: const Key('requests-empty'),
              message: l10n.noRequests,
              actionLabel: l10n.browseServices,
              onAction: widget.onBrowse,
            )
          else if (list.isEmpty)
            OneLineState(message: l10n.noResults)
          else
            for (final r in list) _row(l10n, r, numbers[r.serviceId]),
        ],
      ),
    );
  }

  Widget _row(L10n l10n, GuestRequest r, String? number) {
    final name = requestName(l10n, r);
    final title = number == null ? name : '$number $name';
    return RequestCard(
      l10n: l10n,
      request: r,
      title: title,
      onTap: () => _openSheet(l10n, r, title),
    );
  }

  void _openSheet(L10n l10n, GuestRequest r, String title) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: KachavaColors.surface,
      builder: (ctx) => ConstrainedBox(
        constraints:
            BoxConstraints(maxHeight: MediaQuery.sizeOf(ctx).height * 0.85),
        child: ListView(
          key: Key('request-sheet-${r.id}'),
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            RequestDetails(l10n: l10n, request: r, title: title),
            const SizedBox(height: 16),
            _actions(ctx, l10n, r, title),
          ],
        ),
      ),
    );
  }

  /// While the server still holds the initial status: Change (bookings)
  /// and Cancel; afterwards Ask Host.
  Widget _actions(BuildContext sheet, L10n l10n, GuestRequest r, String title) {
    if (!r.canCancel) {
      return Row(children: [
        Expanded(
          child: FilledButton.tonal(
            key: const Key('request-ask-host'),
            onPressed: () {
              Navigator.of(sheet).pop();
              widget.onAskHost(title);
            },
            child: Text(l10n.askHost),
          ),
        ),
      ]);
    }
    final service = r.canChange
        ? widget.controller.catalog
            .where((s) => s.id == r.serviceId)
            .firstOrNull
        : null;
    return Row(children: [
      if (service != null) ...[
        Expanded(
          child: FilledButton.tonal(
            key: const Key('request-change'),
            onPressed: () {
              Navigator.of(sheet).pop();
              _openChange(service, r, title);
            },
            child: Text(l10n.change),
          ),
        ),
        const SizedBox(width: 8),
      ],
      Expanded(
        child: OutlinedButton(
          key: const Key('request-cancel'),
          onPressed: () => _confirmCancel(sheet, l10n, r, title),
          child: Text(l10n.cancelRequest),
        ),
      ),
      InfoTip(l10n.changeInfo),
    ]);
  }

  void _openChange(CatalogService service, GuestRequest r, String title) {
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => BookingForm(
        controller: widget.controller,
        service: service,
        title: title,
        changing: r.booking,
      ),
    ));
  }

  Future<void> _confirmCancel(
      BuildContext sheet, L10n l10n, GuestRequest r, String title) async {
    final confirmed = await showDialog<bool>(
      context: sheet,
      builder: (dialog) => AlertDialog(
        content: Text(l10n.cancelConfirm(title)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialog).pop(false),
            child: Text(l10n.keepRequest),
          ),
          FilledButton(
            key: const Key('request-cancel-confirm'),
            autofocus: true,
            onPressed: () => Navigator.of(dialog).pop(true),
            child: Text(l10n.cancelRequest),
          ),
        ],
      ),
    );
    if (confirmed != true || !sheet.mounted) return;
    Navigator.of(sheet).pop();
    final result = await widget.controller.cancelRequest(r);
    if (!mounted) return;
    switch (result) {
      case ApiOk():
        showPortalToast(context, l10n.requestCancelled);
      case ApiFailed():
        showPortalToast(context, failureMessage(l10n, result), error: true);
    }
  }
}
