import 'package:flutter/material.dart';

import '../../../core/admin_i18n.dart';
import '../../../core/resort_time.dart';
import '../../../core/theme/kachava_tokens.dart';
import '../../../core/transport_strings.dart';
import '../../../domain/admin_trip.dart';
import '../../../domain/transport_provider.dart';

/// Requested → Sent → Confirmed → En route → Completed. Reached steps show a
/// check, the current one is filled; a cancelled trip keeps the steps it
/// reached. Each step also has a text label (never color only).
class TripStatusStepper extends StatelessWidget {
  const TripStatusStepper({super.key, required this.trip, required this.isEs});

  final AdminTrip trip;
  final bool isEs;

  /// Index in [TripValues.flow] of the last step the trip reached.
  int get _reached {
    final status = trip.status;
    if (status != TripValues.cancelled) return TripValues.flow.indexOf(status);
    final steps = [
      for (final h in trip.history)
        if (TripValues.flow.contains(h.to)) TripValues.flow.indexOf(h.to)
    ];
    return steps.isEmpty ? 0 : steps.reduce((a, b) => a > b ? a : b);
  }

  @override
  Widget build(BuildContext context) {
    final s = TransportStrings(isEs);
    final reached = _reached;
    final cancelled = trip.status == TripValues.cancelled;
    final style = Theme.of(context).textTheme.labelSmall;
    return Row(
      key: const Key('trip-stepper'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (i, step) in TripValues.flow.indexed)
          Expanded(
            child: Column(children: [
              Icon(
                key: Key('trip-step-$step'),
                i < reached || (i == reached && (cancelled || trip.isFinal))
                    ? Icons.check_circle
                    : i == reached
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                size: 20,
                color: i <= reached
                    ? KachavaTokens.primary
                    : KachavaTokens.inputBorder,
              ),
              const SizedBox(height: KachavaTokens.space1),
              Text(s.stepLabel(step),
                  textAlign: TextAlign.center,
                  style: style?.copyWith(
                      color: i <= reached
                          ? KachavaTokens.text
                          : KachavaTokens.textSecondary)),
            ]),
          ),
      ],
    );
  }
}

/// Label/value rows of a trip; empty values are skipped.
class TripDetailFacts extends StatelessWidget {
  const TripDetailFacts({
    super.key,
    required this.trip,
    required this.providers,
    required this.resortTime,
    required this.isEs,
  });

  final AdminTrip trip;
  final List<TransportProvider> providers;
  final ResortTime resortTime;
  final bool isEs;

  @override
  Widget build(BuildContext context) {
    final rows = [
      for (final (label, value) in _facts())
        if (value.trim().isNotEmpty) _row(context, label, value),
    ];
    return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch, children: rows);
  }

  List<(String, String)> _facts() {
    final s = TransportStrings(isEs);
    final t = trip;
    final provider = providers.where((p) => p.id == t.providerId).firstOrNull;
    String join(List<String?> parts) =>
        parts.where((p) => p != null && p.trim().isNotEmpty).join(' · ');
    return [
      (s.pickup, resortTime.label(t.pickupAt, isEs: isEs)),
      (s.villa, t.villaName),
      (s.type, join([s.typeLabel(t.type), t.airportCode])),
      if (t.flight case final f?)
        (
          s.flight,
          join([
            f.number,
            f.airline,
            resortTime.label(f.scheduledAt, isEs: isEs)
          ])
        ),
      (
        s.route,
        join([
          if (t.origin != null || t.destination != null)
            '${t.origin ?? '—'} → ${t.destination ?? '—'}',
          if (t.roundTrip) s.roundTrip,
          if (t.waitMinutes case final w?) '${s.waitMinutes} $w',
        ])
      ),
      (s.passengers, '${t.passengers}'),
      (s.luggage, '${t.luggage}'),
      (
        s.service,
        join([t.serviceName.of(isEs: isEs), t.vehicleName.of(isEs: isEs)])
      ),
      (s.provider, join([provider?.name, provider?.phone])),
      (s.driver, join([t.driver?.name, t.driver?.phone])),
      (s.vehicle, join([t.vehicle?.description, t.vehicle?.plate])),
      (s.reason, t.cancellationReason ?? ''),
      (s.guestNotes, t.guestNotes),
      (s.notes, t.notes),
      (s.createdBy, t.createdBy == 'GUEST' ? s.byGuest : s.byStaff),
    ];
  }

  Widget _row(BuildContext context, String label, String value) {
    final theme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: KachavaTokens.space3),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(
          width: 120,
          child: Text(label,
              style: theme.bodySmall
                  ?.copyWith(color: KachavaTokens.textSecondary)),
        ),
        Expanded(child: Text(value, style: theme.bodyMedium)),
      ]),
    );
  }
}

/// `statusHistory[]`, newest first: "Confirmed · Nov 3 · 10:00 · by".
class TripHistoryList extends StatelessWidget {
  const TripHistoryList({
    super.key,
    required this.trip,
    required this.resortTime,
    required this.isEs,
  });

  final AdminTrip trip;
  final ResortTime resortTime;
  final bool isEs;

  @override
  Widget build(BuildContext context) {
    if (trip.history.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context).textTheme;
    return Column(
      key: const Key('trip-history'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(TransportStrings(isEs).history, style: theme.titleSmall),
        const SizedBox(height: KachavaTokens.space2),
        for (final h in trip.history.reversed)
          Padding(
            padding: const EdgeInsets.only(bottom: KachavaTokens.space2),
            child: Text(
              [
                AdminI18n.statusLabel(h.to, isEs),
                resortTime.label(h.at, isEs: isEs),
                if (h.by.isNotEmpty) h.by,
                if (h.reason case final r?) r,
              ].join(' · '),
              style: theme.bodySmall,
            ),
          ),
      ],
    );
  }
}
