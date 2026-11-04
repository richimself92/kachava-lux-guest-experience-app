import 'package:flutter/material.dart';

import '../../core/inbox_strings.dart';
import '../../core/resort_time.dart';
import '../../core/service_catalog_labels.dart';
import '../../core/theme/kachava_tokens.dart';
import '../../domain/admin_trip.dart';
import '../../domain/inbox_item.dart';
import '../../domain/list_query.dart';
import '../../domain/service_request.dart';
import '../../domain/transport_provider.dart';
import '../components/components.dart';
import '../operations/ops_fields.dart';
import '../workspaces/transportation/trip_status_dialogs.dart';
import 'inbox_parts.dart';
import 'request_inbox_scope.dart';

/// One guest request in plain words: who, when, exactly what was asked,
/// the status chip with a short timeline, and one obvious next-step button
/// ("Confirm", "Start preparing", "Mark delivered", "Send to provider", ...)
/// plus "Cancel request" (with a reason) as the secondary action.
class InboxDetailPanel extends StatefulWidget {
  const InboxDetailPanel({
    super.key,
    required this.item,
    required this.deps,
    required this.onClose,
    required this.onChanged,
    required this.isEs,
    this.resortTime,
    this.now,
    this.taskSection,
    this.onMessageGuest,
  });

  final InboxItem item;
  final RequestInboxDeps deps;
  final VoidCallback onClose;

  /// Runs after a server-confirmed move (reload list and badge).
  final VoidCallback onChanged;
  final bool isEs;
  final ResortTime? resortTime;
  final DateTime Function()? now;

  /// Linked task (owner, "Assign to staff", "Open task").
  final Widget? taskSection;

  /// Opens the guest's conversation.
  final ValueChanged<InboxItem>? onMessageGuest;

  @override
  State<InboxDetailPanel> createState() => _InboxDetailPanelState();
}

class _InboxDetailPanelState extends State<InboxDetailPanel> {
  late InboxItem _item = widget.item;
  bool _busy = false;

  @override
  void didUpdateWidget(InboxDetailPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(widget.item, oldWidget.item)) _item = widget.item;
  }

  InboxStrings get _s => InboxStrings(widget.isEs);

  Future<void> _next() async {
    final step = _item.nextStep;
    if (step == null) return;
    switch (step) {
      case RequestStep(:final action):
        await _apply(() async => RequestInboxItem(
            await widget.deps.requests.transition(_item.id, action)));
      case TripStep():
        final move = await _tripMove(step);
        if (move != null && mounted) await _applyTrip(move);
    }
  }

  Future<TripTransition?> _tripMove(TripStep step) async {
    final trip = (_item as TripInboxItem).trip;
    if (step.needsProvider) {
      final providers = await _providers();
      if (!mounted) return null;
      return showSendToProviderDialog(context,
          providers: providers,
          currentProviderId: trip.providerId,
          isEs: widget.isEs);
    }
    if (step.needsDriver) {
      return showConfirmTripDialog(context, trip: trip, isEs: widget.isEs);
    }
    return TripTransition(to: step.to);
  }

  Future<List<TransportProvider>> _providers() async {
    try {
      final page = await widget.deps.providers
          ?.list(const ListQuery(filters: {'isActive': 'true'}, pageSize: 50));
      return page?.items ?? const [];
    } catch (_) {
      return const [];
    }
  }

  Future<void> _cancel() async {
    if (_item is TripInboxItem) {
      final move = await showCancelTripDialog(context, isEs: widget.isEs);
      if (move != null && mounted) await _applyTrip(move, cancelled: true);
      return;
    }
    final reason = await showTextInputDialog(context,
        key: const Key('inbox-cancel-dialog'),
        title: _s.cancel,
        fieldLabel: _s.reason,
        fieldKey: const Key('inbox-cancel-reason'),
        confirmLabel: _s.cancel,
        cancelLabel: _s.back,
        isEs: widget.isEs,
        destructive: true);
    if (reason == null || !mounted) return;
    await _apply(
        () async => RequestInboxItem(await widget.deps.requests
            .transition(_item.id, RequestAction.cancel, reason: reason)),
        cancelled: true);
  }

  Future<void> _applyTrip(TripTransition move, {bool cancelled = false}) =>
      _apply(() async {
        final trips = widget.deps.trips;
        if (trips == null) throw StateError('Trips not connected');
        return TripInboxItem(await trips.transition(_item.id, move));
      }, cancelled: cancelled);

  Future<void> _apply(Future<InboxItem> Function() write,
      {bool cancelled = false}) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    setState(() => _busy = true);
    try {
      final updated = await write();
      if (mounted) setState(() => _item = updated);
      widget.onChanged();
      showAdminToastOn(messenger, cancelled ? _s.cancelled : _s.moved);
    } catch (_) {
      showAdminToastOn(messenger, _s.failed, isError: true, isEs: widget.isEs);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = (widget.now ?? DateTime.now)().toUtc();
    return AdminDetailPanel(
      title: inboxTitle(_item, widget.isEs),
      onClose: widget.onClose,
      isEs: widget.isEs,
      body: ListView(
        key: const Key('inbox-detail'),
        padding: const EdgeInsets.all(KachavaTokens.space6),
        children: [
          Wrap(
            spacing: KachavaTokens.space2,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              InboxStatusChip(
                  key: const Key('inbox-detail-status'),
                  item: _item,
                  isEs: widget.isEs,
                  overdue: _item.isOverdue(now)),
              if (_item.askedAt case final at?)
                Text(_s.ago(now.difference(at)),
                    style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
          const SizedBox(height: KachavaTokens.space3),
          InboxTimeline(item: _item, isEs: widget.isEs),
          const SizedBox(height: KachavaTokens.space4),
          ..._facts(),
          if (widget.taskSection case final section?) section,
        ],
      ),
      footer: _footer(),
    );
  }

  List<Widget> _facts() {
    final s = _s;
    final asked = _item.askedAt;
    return [
      FactRow(label: s.guest, value: _item.guestName),
      FactRow(label: s.villa, value: _item.villaName),
      FactRow(
          label: s.askedAt,
          value: asked == null
              ? ''
              : widget.resortTime?.label(asked, isEs: widget.isEs) ??
                  ResortTime.hhmm(asked)),
      ...switch (_item) {
        RequestInboxItem(:final request) => _requestFacts(request),
        TripInboxItem(:final trip) => _tripFacts(trip),
      },
    ];
  }

  List<Widget> _requestFacts(ServiceRequest r) {
    final s = _s;
    final isEs = widget.isEs;
    final lines = [
      for (final l in r.lines) '${l.quantity} × ${l.name.of(isEs: isEs)}'
    ].join('\n');
    final money = ServiceCatalogLabels(isEs).money;
    return switch (_item.type) {
      InboxType.order => [
          FactRow(label: s.items, value: lines),
          FactRow(label: s.total, value: money(r.totalUSD)),
        ],
      InboxType.preference => [
          FactRow(
              label: s.choice,
              value: r.lines.map((l) => l.name.of(isEs: isEs)).join(', ')),
        ],
      _ => [
          FactRow(label: s.date, value: ResortTime.dayLabel(r.day, isEs: isEs)),
          FactRow(label: s.time, value: r.time),
          FactRow(label: s.partySize, value: '${r.quantity}'),
          if (r.lines.isNotEmpty) FactRow(label: s.option, value: lines),
          if (r.totalUSD != null)
            FactRow(label: s.total, value: money(r.totalUSD)),
        ],
    }
      ..addAll([
        if (r.notes.isNotEmpty) FactRow(label: s.notes, value: r.notes),
        if (r.cancellationReason case final reason?)
          FactRow(label: s.reason, value: reason),
      ]);
  }

  List<Widget> _tripFacts(AdminTrip t) {
    final s = _s;
    final time = widget.resortTime;
    final flight = t.flight;
    return [
      if (flight != null)
        FactRow(
            label: s.flight,
            value: [
              '${flight.airline} ${flight.number}'.trim(),
              if (flight.scheduledAt case final at?)
                time?.label(at, isEs: widget.isEs) ?? '',
            ].where((v) => v.isNotEmpty).join(' · ')),
      FactRow(
          label: s.pickup,
          value: time?.label(t.pickupAt, isEs: widget.isEs) ?? ''),
      FactRow(label: s.passengers, value: '${t.passengers}'),
      FactRow(label: s.luggage, value: '${t.luggage}'),
      if (t.driver case final d?)
        FactRow(label: s.driver, value: '${d.name} · ${d.phone}'),
      if (t.vehicle case final v?)
        FactRow(label: s.vehicle, value: '${v.description} · ${v.plate}'),
      if (t.guestNotes.isNotEmpty) FactRow(label: s.notes, value: t.guestNotes),
      if (t.cancellationReason case final reason?)
        FactRow(label: s.reason, value: reason),
    ];
  }

  Widget? _footer() {
    final step = _item.nextStep;
    final message = widget.onMessageGuest;
    if (step == null && !_item.canCancel && message == null) return null;
    return Wrap(
      alignment: WrapAlignment.end,
      spacing: KachavaTokens.space2,
      runSpacing: KachavaTokens.space2,
      children: [
        if (message != null)
          TextButton.icon(
            key: const Key('inbox-message-guest'),
            onPressed: () => message(_item),
            icon: const Icon(Icons.chat_bubble_outline, size: 18),
            label: Text(_s.messageGuest),
          ),
        if (_item.canCancel)
          OutlinedButton(
            key: const Key('inbox-cancel'),
            style: OutlinedButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error),
            onPressed: _busy ? null : _cancel,
            child: Text(_s.cancel),
          ),
        if (step != null)
          FilledButton(
            key: const Key('inbox-next'),
            onPressed: _busy ? null : _next,
            child: Text(_s.step(step.label)),
          ),
      ],
    );
  }
}

/// The forward flow as a short timeline: done steps checked, the current
/// one bold; a cancelled request shows its last step and "Cancelled".
class InboxTimeline extends StatelessWidget {
  const InboxTimeline({super.key, required this.item, required this.isEs});

  final InboxItem item;
  final bool isEs;

  @override
  Widget build(BuildContext context) {
    final s = InboxStrings(isEs);
    final flow = item.flow;
    final current = flow.indexOf(item.status);
    final text = Theme.of(context).textTheme.bodySmall;
    return Wrap(
      key: const Key('inbox-timeline'),
      spacing: KachavaTokens.space2,
      runSpacing: KachavaTokens.space1,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (var i = 0; i < flow.length; i++)
          Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(
              i <= current ? Icons.check_circle : Icons.radio_button_unchecked,
              size: 16,
              color: i <= current
                  ? KachavaTokens.primary
                  : KachavaTokens.textSecondary,
            ),
            const SizedBox(width: KachavaTokens.space1),
            Text(s.stageStatus(flow[i]),
                style: text?.copyWith(
                    fontWeight:
                        i == current ? FontWeight.w700 : FontWeight.w400)),
          ]),
        if (current < 0) Text(s.stageStatus(item.status), style: text),
      ],
    );
  }
}
