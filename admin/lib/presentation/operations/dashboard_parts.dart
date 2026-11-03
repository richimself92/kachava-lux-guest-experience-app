import 'package:flutter/material.dart';

import '../../core/stay_strings.dart';
import '../../core/theme/kachava_tokens.dart';
import '../../domain/dashboard_view.dart';
import '../components/components.dart';

/// Neutral "Today · Nov 3" pill (resort day from Settings).
class TodayPill extends StatelessWidget {
  const TodayPill({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(
            horizontal: KachavaTokens.space3, vertical: KachavaTokens.space1),
        decoration: BoxDecoration(
          color: KachavaTokens.surface,
          borderRadius: BorderRadius.circular(KachavaTokens.radiusPill),
        ),
        child: Text(label, style: Theme.of(context).textTheme.labelLarge),
      );
}

/// Six KPI tiles: 3 per row on wide screens, 2 on narrow ones.
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
    return LayoutBuilder(builder: (context, constraints) {
      const gap = KachavaTokens.space4;
      final columns = constraints.maxWidth >= 720 ? 3 : 2;
      final width = (constraints.maxWidth - (columns - 1) * gap) / columns;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [
          for (final (id, value, label, info) in tiles)
            SizedBox(
              width: width,
              child: KpiTile(
                  key: Key('kpi-$id'), value: value, label: label, info: info),
            ),
        ],
      );
    });
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

/// "Today's activity": Guest, Villa, Status; a row opens the stay.
class TodaysActivityTable extends StatelessWidget {
  const TodaysActivityTable({
    super.key,
    required this.view,
    required this.isEs,
    required this.onOpenStay,
    required this.onViewAll,
  });

  final DashboardView view;
  final bool isEs;
  final ValueChanged<String> onOpenStay;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    final s = StayStrings(isEs);
    final theme = Theme.of(context);
    return Column(
      key: const Key('dashboard-activity'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(children: [
          Expanded(
            child: Text(s.todaysActivity, style: theme.textTheme.titleLarge),
          ),
          if (view.total > 0)
            TextButton(
              key: const Key('dashboard-view-all'),
              onPressed: onViewAll,
              child: Text(s.viewAll),
            ),
        ]),
        const SizedBox(height: KachavaTokens.space2),
        if (view.rows.isEmpty)
          AdminStateLine(
              key: const Key('dashboard-activity-empty'), message: s.noActivity)
        else ...[
          _row(context,
              cells: [Text(s.guest), Text(s.villa), Text(s.status)],
              header: true),
          for (final row in view.rows)
            _row(context,
                key: Key('activity-${row.stayId}'),
                onTap: () => onOpenStay(row.stayId),
                cells: [
                  Text(row.guestName,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(row.villaName,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: ActivityStatusChip(row: row, isEs: isEs),
                  ),
                ]),
        ],
      ],
    );
  }

  Widget _row(BuildContext context,
      {Key? key,
      required List<Widget> cells,
      VoidCallback? onTap,
      bool header = false}) {
    final style = header
        ? Theme.of(context)
            .textTheme
            .labelMedium
            ?.copyWith(color: KachavaTokens.textSecondary)
        : Theme.of(context).textTheme.bodyMedium;
    final content = Container(
      constraints: const BoxConstraints(minHeight: 48),
      padding: const EdgeInsets.symmetric(horizontal: KachavaTokens.space2),
      decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: KachavaTokens.border))),
      child: DefaultTextStyle.merge(
        style: style,
        child: Row(children: [
          Expanded(flex: 3, child: cells[0]),
          Expanded(flex: 2, child: cells[1]),
          Expanded(flex: 2, child: cells[2]),
        ]),
      ),
    );
    if (onTap == null) return content;
    return FocusRing(
      borderRadius: KachavaTokens.radiusSm,
      child: InkWell(key: key, onTap: onTap, child: content),
    );
  }
}
