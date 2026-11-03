import 'package:flutter/material.dart';

import '../../../core/admin_i18n.dart';
import '../../../core/resort_time.dart';
import '../../../core/theme/kachava_tokens.dart';
import '../../../core/transport_strings.dart';
import '../../../domain/admin_trip.dart';
import '../../../domain/transport_provider.dart';
import '../../../domain/trip_repository.dart';
import '../../components/components.dart';
import 'trip_detail_parts.dart';
import 'trip_status_dialogs.dart';

/// One trip: status + stepper, details and history, with the single next
/// action as the primary button ("Send to provider", "Confirm", "En route",
/// "Complete") and "Cancel trip" in the ⋮ menu.
class TripDetailPanel extends StatefulWidget {
  const TripDetailPanel({
    super.key,
    required this.trip,
    required this.repository,
    required this.providers,
    required this.resortTime,
    required this.onClose,
    required this.onChanged,
    required this.isEs,
  });

  final AdminTrip trip;
  final TripRepository repository;
  final List<TransportProvider> providers;
  final ResortTime resortTime;
  final VoidCallback onClose;

  /// Runs after a server-confirmed change (reload the list).
  final VoidCallback onChanged;
  final bool isEs;

  @override
  State<TripDetailPanel> createState() => _TripDetailPanelState();
}

class _TripDetailPanelState extends State<TripDetailPanel> {
  late AdminTrip _trip = widget.trip;
  bool _busy = false;

  TransportStrings get _s => TransportStrings(widget.isEs);

  Future<void> _advance() async {
    final next = _trip.nextStatus;
    if (next == null) return;
    final move = await _askMove(next);
    if (move != null && mounted) await _apply(move);
  }

  Future<TripTransition?> _askMove(String next) => switch (next) {
        'SENT_TO_PROVIDER' => showSendToProviderDialog(context,
            providers: widget.providers,
            currentProviderId: _trip.providerId,
            isEs: widget.isEs),
        'CONFIRMED' =>
          showConfirmTripDialog(context, trip: _trip, isEs: widget.isEs),
        _ => Future.value(TripTransition(to: next)),
      };

  Future<void> _cancel() async {
    final move = await showCancelTripDialog(context, isEs: widget.isEs);
    if (move != null && mounted) await _apply(move);
  }

  /// Shows the server answer; a refused move keeps the trip as it was.
  Future<void> _apply(TripTransition move) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    setState(() => _busy = true);
    try {
      final updated = await widget.repository.transition(_trip.id, move);
      if (mounted) setState(() => _trip = updated);
      widget.onChanged();
      showAdminToastOn(
          messenger,
          move.to == TripValues.cancelled
              ? _s.tripCancelled
              : _s.movedTo(AdminI18n.statusLabel(move.to, widget.isEs)));
    } catch (_) {
      showAdminToastOn(messenger, _s.actionFailed,
          isError: true, isEs: widget.isEs);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminDetailPanel(
      title: _trip.guestName,
      onClose: widget.onClose,
      isEs: widget.isEs,
      actions: [if (!_trip.isFinal) _menu()],
      body: ListView(
        key: const Key('trip-detail'),
        padding: const EdgeInsets.all(KachavaTokens.space6),
        children: [
          _statusRow(),
          const SizedBox(height: KachavaTokens.space4),
          TripStatusStepper(trip: _trip, isEs: widget.isEs),
          const SizedBox(height: KachavaTokens.space6),
          TripDetailFacts(
            trip: _trip,
            providers: widget.providers,
            resortTime: widget.resortTime,
            isEs: widget.isEs,
          ),
          const SizedBox(height: KachavaTokens.space4),
          TripHistoryList(
              trip: _trip, resortTime: widget.resortTime, isEs: widget.isEs),
        ],
      ),
      footer: _footer(),
    );
  }

  Widget _statusRow() => Wrap(
        spacing: KachavaTokens.space2,
        runSpacing: KachavaTokens.space2,
        children: [
          StatusChip.fromStatus(_trip.status,
              key: const Key('trip-status'), isEs: widget.isEs),
          if (_trip.unconfirmedDue == true)
            StatusChip(
                key: const Key('trip-unconfirmed'),
                label: _s.unconfirmed,
                tone: StatusTone.error),
        ],
      );

  Widget? _footer() {
    final next = _trip.nextStatus;
    if (next == null) return null;
    return Row(children: [
      const Spacer(),
      FilledButton(
        key: const Key('trip-next-action'),
        onPressed: _busy ? null : _advance,
        child: Text(_s.actionFor(next)),
      ),
    ]);
  }

  Widget _menu() => PopupMenuButton<String>(
        key: const Key('trip-actions'),
        tooltip: _s.actions,
        enabled: !_busy,
        onSelected: (_) => _cancel(),
        itemBuilder: (_) => [
          PopupMenuItem(
            key: const Key('trip-action-cancel'),
            value: 'cancel',
            child: Text(_s.cancelTrip),
          ),
        ],
      );
}
