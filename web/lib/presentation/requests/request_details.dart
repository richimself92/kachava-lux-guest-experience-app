import 'package:flutter/material.dart';

import '../../core/i18n/l10n.dart';
import '../../core/platform/phone_dialer.dart';
import '../../core/theme/kachava_colors.dart';
import '../../domain/requests.dart';
import '../../domain/trip.dart';
import '../common/labels.dart';
import '../common/widgets.dart';

/// Body of the request detail sheet: when, status steps (or the cancel
/// reason), what was asked with prices, and the trip/driver block.
class RequestDetails extends StatelessWidget {
  const RequestDetails({
    super.key,
    required this.l10n,
    required this.request,
    required this.title,
  });

  final L10n l10n;
  final GuestRequest request;
  final String title;

  static const _body = TextStyle(fontSize: 15);
  static const _bold = TextStyle(fontSize: 15, fontWeight: FontWeight.w700);

  @override
  Widget build(BuildContext context) {
    final r = request;
    final when = requestWhen(l10n, r);
    final trip = r.trip;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        if (when.isNotEmpty) Text(when, style: _body),
        const SizedBox(height: 12),
        ..._status(),
        if (trip != null) ..._trip(trip),
        if (r.lines.isNotEmpty) ...[
          const Divider(height: 24),
          for (final line in r.lines)
            _row(
                '${line.quantity} × ${l10n.text(line.name)}',
                line.lineTotalUSD == null
                    ? ''
                    : l10n.money(line.lineTotalUSD!)),
        ],
        if (r.totalUSD != null && r.totalUSD! > 0)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: _row(l10n.total, l10n.money(r.totalUSD!), style: _bold),
          ),
        if (trip != null && showsDriver(r))
          _DriverBlock(l10n: l10n, trip: trip),
      ],
    );
  }

  List<Widget> _status() {
    final r = request;
    if (r.status == RequestStatus.cancelled) {
      final reason = requestReason(l10n, r);
      return [
        StatusChip(status: r.status, l10n: l10n),
        if (reason.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(reason, style: _body),
          ),
      ];
    }
    final third = r.kind == RequestKind.trip
        ? RequestStatus.onTheWay
        : RequestStatus.preparing;
    final steps = [
      r.status == RequestStatus.arranging
          ? RequestStatus.arranging
          : RequestStatus.received,
      RequestStatus.confirmed,
      third,
      RequestStatus.done,
    ];
    return [
      for (final s in steps) _step(s, s.trackIndex <= r.status.trackIndex)
    ];
  }

  Widget _step(RequestStatus s, bool reached) => Row(children: [
        Icon(reached ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 20,
            color: reached
                ? KachavaColors.confirmedGreen
                : KachavaColors.onSurfaceVariant),
        const SizedBox(width: 8),
        Text(l10n.status(s), style: const TextStyle(fontSize: 15, height: 2)),
      ]);

  List<Widget> _trip(GuestTrip trip) {
    final what = tripWhat(l10n, trip);
    final party = [
      if (trip.passengers > 0) l10n.guests(trip.passengers),
      if (trip.luggage > 0) l10n.bagsCount(trip.luggage),
    ].join(' · ');
    return [
      if (what.isNotEmpty || party.isNotEmpty) const Divider(height: 24),
      if (what.isNotEmpty) Text(what, style: _body),
      if (party.isNotEmpty) Text(party, style: _body),
    ];
  }

  Widget _row(String label, String value, {TextStyle style = _body}) =>
      Row(children: [
        Expanded(child: Text(label, style: style)),
        if (value.isNotEmpty) Text(value, style: style),
      ]);
}

/// Driver name, tappable phone, vehicle and plate (after confirmation).
class _DriverBlock extends StatelessWidget {
  const _DriverBlock({required this.l10n, required this.trip});

  final L10n l10n;
  final GuestTrip trip;

  @override
  Widget build(BuildContext context) {
    final vehicle =
        [trip.vehicle, trip.plate].where((s) => s.isNotEmpty).join(' · ');
    return Column(
      key: const Key('trip-driver'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 24),
        Text(l10n.driver,
            style: const TextStyle(
                fontSize: 14, color: KachavaColors.onSurfaceVariant)),
        Text(trip.driverName,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        if (vehicle.isNotEmpty)
          Text(vehicle, style: const TextStyle(fontSize: 15)),
        if (trip.driverPhone.isNotEmpty)
          Semantics(
            label: l10n.callDriver(trip.driverName),
            button: true,
            excludeSemantics: true,
            child: TextButton.icon(
              key: const Key('trip-driver-phone'),
              style: TextButton.styleFrom(
                  minimumSize: const Size(48, 48),
                  padding: const EdgeInsets.symmetric(horizontal: 8)),
              onPressed: () => dialPhone(trip.driverPhone),
              icon: const Icon(Icons.phone_outlined, size: 20),
              label: Text(trip.driverPhone),
            ),
          ),
      ],
    );
  }
}
