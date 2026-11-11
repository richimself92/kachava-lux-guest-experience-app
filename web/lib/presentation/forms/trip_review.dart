import 'package:flutter/material.dart';

import '../../core/i18n/l10n.dart';
import '../../core/theme/kachava_colors.dart';
import '../../domain/catalog.dart';
import '../../domain/forms.dart';
import '../../domain/trip.dart';
import '../common/widgets.dart';
import 'form_scaffold.dart';

/// Page 4 of the TRIP wizard: one-line summary, vehicle price and "Edit".
class TripReview extends StatelessWidget {
  const TripReview({
    super.key,
    required this.l10n,
    required this.draft,
    required this.service,
    required this.onEdit,
  });

  final L10n l10n;
  final TripDraft draft;
  final CatalogService service;
  final VoidCallback onEdit;

  String get _when => [
        if (draft.day != null) l10n.date(draft.day!),
        draft.time,
        if (draft.type.isAirport) draft.airport ?? '',
      ].where((s) => s.isNotEmpty).join(' · ');

  String get _what => draft.type.isAirport
      ? '${draft.flightNumber.trim()} · ${l10n.guests(draft.passengers)} · '
          '${draft.luggage} ${l10n.bags.toLowerCase()}'
      : '${draft.origin.trim()} → ${draft.destination.trim()} · '
          '${l10n.guests(draft.passengers)}';

  @override
  Widget build(BuildContext context) {
    final vehicle =
        service.items.where((v) => v.id == draft.vehicleId).firstOrNull;
    const body = TextStyle(fontSize: 16);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Expanded(
              child: Text(l10n.review,
                  style: Theme.of(context).textTheme.titleMedium)),
          TextButton(onPressed: onEdit, child: Text(l10n.edit)),
        ]),
        Text(_when, key: const Key('trip-review-when'), style: body),
        const SizedBox(height: 4),
        Text(_what, style: body),
        if (vehicle != null) ...[
          const SizedBox(height: 4),
          Row(children: [
            Expanded(child: Text(l10n.text(vehicle.name), style: body)),
            if (vehicle.priceUSD != null)
              Text(l10n.money(vehicle.priceUSD!),
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700)),
          ]),
        ],
        if (draft.type == TripType.departure)
          Row(children: [
            Text(l10n.pickupAt,
                style: const TextStyle(
                    fontSize: 14, color: KachavaColors.tertiary)),
            InfoTip(l10n.pickupInfo),
          ]),
      ],
    );
  }
}

/// Page 3 of the TRIP wizard: passengers, bags and vehicle cards.
class TripGroup extends StatelessWidget {
  const TripGroup({
    super.key,
    required this.l10n,
    required this.draft,
    required this.service,
    required this.issueOf,
    required this.update,
  });

  final L10n l10n;
  final TripDraft draft;
  final CatalogService service;
  final String? Function(String field) issueOf;

  /// Applies a draft change and rebuilds the wizard.
  final void Function(VoidCallback change) update;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LabeledField(
          label: l10n.passengers,
          issue: issueOf('passengers'),
          child: QuantityStepper(
            key: const Key('trip-passengers'),
            label: l10n.passengers,
            value: draft.passengers,
            min: 1,
            max: 100,
            onChanged: (v) => update(() => draft.passengers = v),
          ),
        ),
        LabeledField(
          label: l10n.bags,
          issue: issueOf('luggage'),
          child: QuantityStepper(
            key: const Key('trip-bags'),
            label: l10n.bags,
            value: draft.luggage,
            max: 100,
            onChanged: (v) => update(() => draft.luggage = v),
          ),
        ),
        if (service.items.isNotEmpty)
          LabeledField(
            label: l10n.vehicle,
            issue: issueOf('vehicle'),
            child:
                Column(children: [for (final v in service.items) _vehicle(v)]),
          ),
      ],
    );
  }

  Widget _vehicle(CatalogItem v) => ChoiceCard(
        key: Key('vehicle-${v.id}'),
        selected: draft.vehicleId == v.id,
        title: l10n.text(v.name),
        subtitle: [
          if (v.capacity != null) l10n.seats(v.capacity!.passengers),
          if (v.priceUSD != null) l10n.money(v.priceUSD!),
        ].join(' · '),
        leading: v.image == null
            ? null
            : ServicePhoto(image: v.image, l10n: l10n, radius: 8),
        onTap: () => update(() => draft.vehicleId = v.id),
      );
}
