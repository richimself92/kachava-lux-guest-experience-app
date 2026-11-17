import 'package:flutter/material.dart';

import '../../core/stay_strings.dart';
import '../../core/admin_theme.dart';
import '../../domain/dashboard_view.dart';
import '../components/components.dart';

/// Quiet square "Today · Nov 3" label (resort day from Settings).
class TodayPill extends StatelessWidget {
  const TodayPill({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(
            horizontal: KachavaTokens.space3, vertical: KachavaTokens.space1),
        decoration: BoxDecoration(
          color: KachavaTokens.wash,
          border: Border.all(color: KachavaTokens.line),
          borderRadius: BorderRadius.circular(KachavaTokens.radius),
        ),
        child: Text(label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: KachavaTokens.ink,
                fontFeatures: KachavaTextStyles.tabular)),
      );
}

/// Six KPI cells in a [HairlineGrid]: 3 per row on desktop, 2 on tablets
/// and phones, 1 below 360px.
class DashboardKpiGrid extends StatelessWidget {
  const DashboardKpiGrid({super.key, required this.kpis, required this.isEs});

  final DashboardKpis kpis;
  final bool isEs;

  @override
  Widget build(BuildContext context) {
    final s = StayStrings(isEs);
    final tiles = [
      ('occupied', '${kpis.occupiedVillas}', s.occupiedVillas, s.occupiedInfo),
      (
        'available',
        '${kpis.availableVillas}',
        s.availableVillas,
        s.availableInfo
      ),
      ('occupancy', '${kpis.occupancyPct}%', s.occupancy, s.occupancyInfo),
      ('arrivals', '${kpis.arrivals}', s.arrivals, s.arrivalsInfo),
      ('departures', '${kpis.departures}', s.departures, s.departuresInfo),
      (
        'open-requests',
        '${kpis.openRequests}',
        s.openRequests,
        s.openRequestsInfo
      ),
    ];
    return HairlineGrid(
      children: [
        for (final (id, value, label, info) in tiles)
          KpiTile(key: Key('kpi-$id'), value: value, label: label, info: info),
      ],
    );
  }
}

/// Status chip of an activity row; an overstay is red "In-house · overdue".
class ActivityStatusChip extends StatelessWidget {
  const ActivityStatusChip({super.key, required this.row, required this.isEs});

  final ActivityRow row;
  final bool isEs;

  @override
  Widget build(BuildContext context) {
    final s = StayStrings(isEs);
    final (label, tone) = row.overdue
        ? (s.inHouseOverdue, StatusTone.error)
        : switch (row.status) {
            'ARRIVAL' => (s.arrival, StatusTone.info),
            'DEPARTURE' => (s.departure, StatusTone.neutral),
            _ => (s.inHouse, StatusTone.success),
          };
    return StatusChip(label: label, tone: tone);
  }
}
