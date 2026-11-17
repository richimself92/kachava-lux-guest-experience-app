import 'package:flutter/material.dart';

import '../../../core/admin_i18n.dart';
import '../../../core/stay_strings.dart';
import '../../../domain/guest_profile.dart';
import '../../../domain/realtime_change.dart';
import '../../../domain/reservation.dart';
import '../../../domain/staff_member.dart';
import '../../components/components.dart';
import '../ops_fields.dart';
import 'reservation_summary_tab.dart';
import 'reservation_tabs.dart';

/// One reservation: tabs Summary · Preferences · Trips · Folio; the next
/// status move (Check in / Check out) is the footer's primary button and
/// "Cancel reservation" lives in the ⋮ menu (reason required).
class ReservationDetailPanel extends StatefulWidget {
  const ReservationDetailPanel({
    super.key,
    required this.row,
    required this.reservations,
    required this.guests,
    required this.staff,
    required this.onClose,
    required this.onChanged,
    required this.isEs,
    this.onOpenTrips,
    this.onOpenTrip,
  });

  final ReservationRow row;
  final ReservationRepository reservations;
  final GuestRepository guests;
  final List<StaffMember> staff;
  final VoidCallback onClose;

  /// Runs after a server-confirmed change (reload the list).
  final VoidCallback onChanged;
  final bool isEs;
  final ValueChanged<ReservationRow>? onOpenTrips;
  final ValueChanged<String>? onOpenTrip;

  @override
  State<ReservationDetailPanel> createState() => _ReservationDetailPanelState();
}

class _ReservationDetailPanelState extends State<ReservationDetailPanel>
    with AdminRealtimeRefresh<ReservationDetailPanel> {
  StayDetail? _detail;
  Object? _error;
  bool _busy = false;

  /// Resets the Summary form; a real-time reload keeps the staff's edits.
  int _formVersion = 0;

  StayStrings get _s => StayStrings(widget.isEs);
  ReservationRow get _row => _detail?.row ?? widget.row;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final detail = await widget.reservations.get(widget.row.id);
      if (mounted) setState(() => _show(detail));
    } catch (error) {
      if (mounted) setState(() => _error = error);
    }
  }

  void _show(StayDetail detail) {
    _detail = detail;
    _formVersion++;
  }

  @override
  void onRealtimeInvalidation(RealtimeInvalidation change) {
    if (!change.touchesStay(widget.row.id, const {RealtimeTopic.stay})) return;
    if (_detail == null || _busy) return;
    widget.reservations.get(widget.row.id).then((detail) {
      if (mounted && !_busy) setState(() => _detail = detail);
    }, onError: (Object error) {
      debugPrint('Reservation refresh failed: $error');
    });
  }

  /// Saves [patch]; throws on failure so the caller keeps its edits.
  Future<void> _update(ReservationPatch patch, String doneMessage) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    setState(() => _busy = true);
    try {
      final updated = await widget.reservations.update(_row.id, patch);
      if (mounted) setState(() => _show(updated));
      widget.onChanged();
      showAdminToastOn(messenger, doneMessage);
    } catch (error) {
      showAdminToastOn(messenger, _s.actionFailed,
          isError: true, isEs: widget.isEs);
      rethrow;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _move(String action) async {
    String? reason;
    if (action == StayValues.cancel) {
      reason = await showTextInputDialog(context,
          key: const Key('reservation-cancel-dialog'),
          title: _s.confirmMove(action, _row.guestName),
          fieldLabel: _s.reason,
          fieldKey: const Key('reservation-cancel-reason'),
          confirmLabel: _s.cancelReservation,
          cancelLabel: _s.back,
          destructive: true,
          isEs: widget.isEs);
      if (reason == null) return;
    } else {
      final ok = await showConfirmDialog(context,
          title: _s.confirmMove(action, _row.guestName),
          confirmLabel: _s.actionLabel(action),
          cancelLabel: _s.cancel);
      if (!ok) return;
    }
    if (!mounted) return;
    final target = switch (action) {
      StayValues.checkIn => StayValues.inHouse,
      StayValues.checkOut => StayValues.checkedOut,
      _ => StayValues.cancelled,
    };
    await _update(ReservationPatch(action: action, reason: reason),
            AdminI18n.statusLabel(target, widget.isEs))
        .catchError((Object _) {});
  }

  @override
  Widget build(BuildContext context) {
    final detail = _detail;
    final actions = StayValues.actionsFor(_row.status);
    return AdminDetailPanel(
      key: const Key('reservation-detail'),
      title: _row.guestName,
      onClose: widget.onClose,
      isEs: widget.isEs,
      actions: [if (actions.contains(StayValues.cancel)) _menu()],
      tabs: [
        AdminPanelTab(label: _s.summary, builder: (_) => _summary(detail)),
        AdminPanelTab(
          label: _s.preferences,
          builder: (_) => GuestPreferencesTab(
              guests: widget.guests, stayId: _row.id, isEs: widget.isEs),
        ),
        AdminPanelTab(
          label: _s.trips,
          builder: (_) => StayTripsTab(
            reservations: widget.reservations,
            row: _row,
            onOpenTrips: widget.onOpenTrips,
            onOpenTrip: widget.onOpenTrip,
            isEs: widget.isEs,
          ),
        ),
        AdminPanelTab(
          label: _s.folio,
          builder: (_) => StayFolioTab(
              reservations: widget.reservations,
              stayId: _row.id,
              isEs: widget.isEs),
        ),
      ],
      footer: _footer(actions),
    );
  }

  Widget _summary(StayDetail? detail) {
    if (_error != null) {
      return Align(
        alignment: Alignment.topLeft,
        child: AdminStateLine(
          key: const Key('reservation-detail-error'),
          message: _s.loadFailed,
          actionLabel: _s.retry,
          onAction: _load,
          isError: true,
        ),
      );
    }
    if (detail == null) return const LinearProgressIndicator();
    return ReservationSummaryTab(
      key: ValueKey('summary-$_formVersion'),
      detail: detail,
      staff: widget.staff,
      onSave: (patch) => _update(patch, _s.saved),
      isEs: widget.isEs,
    );
  }

  Widget? _footer(List<String> actions) {
    final primary = actions.where((a) => a != StayValues.cancel).firstOrNull;
    if (primary == null || _detail == null) return null;
    return Row(children: [
      const Spacer(),
      FilledButton(
        key: const Key('reservation-next-action'),
        onPressed: _busy ? null : () => _move(primary),
        child: Text(_s.actionLabel(primary)),
      ),
    ]);
  }

  Widget _menu() => PopupMenuButton<String>(
        key: const Key('reservation-actions'),
        tooltip: _s.actions,
        enabled: !_busy && _detail != null,
        onSelected: (_) => _move(StayValues.cancel),
        itemBuilder: (_) => [
          PopupMenuItem(
            key: const Key('reservation-action-cancel'),
            value: StayValues.cancel,
            child: Text(_s.cancelReservation),
          ),
        ],
      );
}
