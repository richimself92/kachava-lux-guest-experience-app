import 'package:flutter/material.dart';

import '../../../core/stay_strings.dart';
import '../../../core/theme/kachava_tokens.dart';
import '../../../domain/guest_profile.dart';
import '../../../domain/reservation.dart';
import '../../components/components.dart';
import '../ops_fields.dart';

/// Loads [load] once and renders loading / one-line error + Retry / data.
class LoadedTab<T> extends StatefulWidget {
  const LoadedTab({
    super.key,
    required this.load,
    required this.builder,
    required this.isEs,
  });

  final Future<T> Function() load;
  final Widget Function(BuildContext context, T value) builder;
  final bool isEs;

  @override
  State<LoadedTab<T>> createState() => _LoadedTabState<T>();
}

class _LoadedTabState<T> extends State<LoadedTab<T>> {
  late Future<T> _future = widget.load();

  @override
  Widget build(BuildContext context) => FutureBuilder<T>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            final s = StayStrings(widget.isEs);
            return Align(
              alignment: Alignment.topLeft,
              child: AdminStateLine(
                message: s.loadFailed,
                actionLabel: s.retry,
                onAction: () => setState(() => _future = widget.load()),
                isError: true,
              ),
            );
          }
          final value = snapshot.data;
          if (snapshot.connectionState != ConnectionState.done ||
              value == null) {
            return const Align(
                alignment: Alignment.topCenter,
                child: LinearProgressIndicator());
          }
          return widget.builder(context, value);
        },
      );
}

/// Preferences and allergies of the stay's guest profile.
class GuestPreferencesTab extends StatelessWidget {
  const GuestPreferencesTab({
    super.key,
    required this.guests,
    required this.stayId,
    required this.isEs,
  });

  final GuestRepository guests;
  final String stayId;
  final bool isEs;

  @override
  Widget build(BuildContext context) => LoadedTab<GuestProfile>(
        load: () => guests.get(stayId),
        isEs: isEs,
        builder: (context, profile) =>
            GuestPreferencesView(profile: profile, isEs: isEs),
      );
}

/// Allergies (red chip when present), occasion and the comfort choices.
class GuestPreferencesView extends StatelessWidget {
  const GuestPreferencesView(
      {super.key, required this.profile, required this.isEs});

  final GuestProfile profile;
  final bool isEs;

  @override
  Widget build(BuildContext context) => ListView(
        key: const Key('guest-preferences'),
        padding: const EdgeInsets.all(KachavaTokens.space6),
        children: items(profile, isEs),
      );

  /// The rows, for embedding in another scroll view.
  static List<Widget> items(GuestProfile profile, bool isEs) {
    final s = StayStrings(isEs);
    return [
      if (profile.allergies.isNotEmpty) ...[
        Align(
          alignment: Alignment.centerLeft,
          child: StatusChip(
              key: const Key('guest-allergies'),
              label: s.allergies,
              tone: StatusTone.error),
        ),
        const SizedBox(height: KachavaTokens.space2),
        FactRow(label: s.allergies, value: profile.allergies.join(', ')),
      ],
      if (profile.occasion.isNotEmpty)
        FactRow(label: s.occasion, value: profile.occasion),
      if (profile.preferences.isEmpty && profile.allergies.isEmpty)
        AdminStateLine(message: s.noPreferences),
      for (final p in profile.preferences)
        FactRow(label: s.preferenceLabel(p.key), value: p.value),
    ];
  }
}

/// The stay's trips (from the folio) and a link to Transportation.
class StayTripsTab extends StatelessWidget {
  const StayTripsTab({
    super.key,
    required this.reservations,
    required this.row,
    required this.isEs,
    this.onOpenTrips,
    this.onOpenTrip,
  });

  final ReservationRepository reservations;
  final ReservationRow row;
  final bool isEs;
  final ValueChanged<ReservationRow>? onOpenTrips;
  final ValueChanged<String>? onOpenTrip;

  @override
  Widget build(BuildContext context) {
    final s = StayStrings(isEs);
    return LoadedTab<StayFolio>(
      load: () => reservations.folio(row.id),
      isEs: isEs,
      builder: (context, folio) => ListView(
        key: const Key('reservation-trips'),
        padding: const EdgeInsets.all(KachavaTokens.space6),
        children: [
          if (folio.trips.isEmpty) AdminStateLine(message: s.noTrips),
          for (final trip in folio.trips)
            ListTile(
              key: Key('reservation-trip-${trip.id}'),
              contentPadding: EdgeInsets.zero,
              title: Text(trip.name.of(isEs)),
              subtitle: trip.date == null ? null : Text(trip.date!),
              trailing: StatusChip.fromStatus(trip.status, isEs: isEs),
              onTap: onOpenTrip == null ? null : () => onOpenTrip!(trip.id),
            ),
          if (onOpenTrips != null)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                key: const Key('reservation-open-transportation'),
                onPressed: () => onOpenTrips!(row),
                child: Text(s.openTransportation),
              ),
            ),
        ],
      ),
    );
  }
}

/// "Stay summary": acquired services, rating, charges and total. Payments
/// are not simulated: "No PMS integration".
class StayFolioTab extends StatelessWidget {
  const StayFolioTab({
    super.key,
    required this.reservations,
    required this.stayId,
    required this.isEs,
  });

  final ReservationRepository reservations;
  final String stayId;
  final bool isEs;

  @override
  Widget build(BuildContext context) => LoadedTab<StayFolio>(
        load: () => reservations.folio(stayId),
        isEs: isEs,
        builder: (context, folio) => _view(folio),
      );

  Widget _view(StayFolio folio) {
    final s = StayStrings(isEs);
    return ListView(
      key: const Key('reservation-folio'),
      padding: const EdgeInsets.all(KachavaTokens.space6),
      children: [
        PanelHeading(s.stayServices),
        if (folio.services.isEmpty) AdminStateLine(message: s.noServices),
        for (final service in folio.services)
          _line(service.name.of(isEs), s.money(service.totalUSD),
              StatusChip.fromStatus(service.status, isEs: isEs)),
        PanelHeading(s.rating),
        FactRow(
            label: s.rating,
            value: folio.rating == null
                ? s.noRating
                : ['${folio.rating}/5', folio.ratingNote]
                    .where((t) => t.isNotEmpty)
                    .join(' · ')),
        PanelHeading(s.charges),
        for (final charge in folio.charges)
          _line(charge.title,
              charge.isComplimentary ? s.included : s.money(charge.amountUSD)),
        FactRow(label: s.total, value: s.money(folio.totalUSD)),
        FactRow(label: s.payments, value: s.noPms),
      ],
    );
  }

  Widget _line(String title, String amount, [Widget? trailing]) => Padding(
        padding: const EdgeInsets.only(bottom: KachavaTokens.space2),
        child: Row(children: [
          Expanded(child: Text(title)),
          if (trailing != null) ...[
            trailing,
            const SizedBox(width: KachavaTokens.space2),
          ],
          Text(amount),
        ]),
      );
}
