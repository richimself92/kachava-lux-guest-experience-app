import 'package:flutter/material.dart';

import '../../core/dashboard_strings.dart';
import '../../core/resort_time.dart';
import '../../core/stay_strings.dart';
import '../../core/theme/kachava_tokens.dart';
import '../../domain/dashboard_view.dart';
import '../components/components.dart';
import 'dashboard_parts.dart';

/// "Today's activity" (server order: overstay, departures, arrivals,
/// in-house): Guest | Villa | Status | Next | Pending | action. The row
/// opens the stay; "Pending" opens the guest's requests or messages; the
/// inline button checks the guest in (arrival day) or out (departure day,
/// overstay) after a one-line confirm. Narrow widths stack each row.
class TodaysActivityTable extends StatelessWidget {
  const TodaysActivityTable({
    super.key,
    required this.view,
    required this.isEs,
    required this.onOpenStay,
    required this.onViewAll,
    this.resortTime,
    this.onStayAction,
    this.onOpenRequests,
    this.onOpenMessages,
  });

  static const double tableBreakpoint = 760;

  final DashboardView view;
  final bool isEs;
  final ValueChanged<String> onOpenStay;
  final VoidCallback onViewAll;
  final ResortTime? resortTime;

  /// `CHECK_IN` / `CHECK_OUT` of the row's stay (already confirmed).
  final Future<void> Function(ActivityRow row, String action)? onStayAction;
  final ValueChanged<ActivityRow>? onOpenRequests;
  final ValueChanged<ActivityRow>? onOpenMessages;

  @override
  Widget build(BuildContext context) {
    final s = StayStrings(isEs);
    final theme = Theme.of(context);
    return LayoutBuilder(builder: (context, constraints) {
      final wide = constraints.maxWidth >= tableBreakpoint;
      return Column(
        key: const Key('dashboard-activity'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            Expanded(
                child:
                    Text(s.todaysActivity, style: theme.textTheme.titleLarge)),
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
                key: const Key('dashboard-activity-empty'),
                message: s.noActivity)
          else ...[
            if (wide) _header(context),
            for (final row in view.rows)
              _ActivityLine(row: row, table: this, wide: wide),
          ],
        ],
      );
    });
  }

  Widget _header(BuildContext context) {
    final s = StayStrings(isEs);
    final d = DashboardStrings(isEs);
    return _cells(
      context,
      style: Theme.of(context)
          .textTheme
          .labelMedium
          ?.copyWith(color: KachavaTokens.textSecondary),
      cells: [
        Text(s.guest),
        Text(s.villa),
        Text(s.status),
        Text(d.next),
        Text(d.pending),
        const SizedBox.shrink(),
      ],
    );
  }

  static const List<int> _flex = [3, 2, 2, 4, 3, 2];

  Widget _cells(BuildContext context,
          {required List<Widget> cells, TextStyle? style}) =>
      Container(
        constraints: const BoxConstraints(minHeight: 52),
        padding: const EdgeInsets.symmetric(horizontal: KachavaTokens.space2),
        decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: KachavaTokens.border))),
        child: DefaultTextStyle.merge(
          style: style ?? Theme.of(context).textTheme.bodyMedium,
          child: Row(children: [
            for (var i = 0; i < cells.length; i++)
              Expanded(flex: _flex[i], child: cells[i]),
          ]),
        ),
      );
}

class _ActivityLine extends StatefulWidget {
  const _ActivityLine(
      {required this.row, required this.table, required this.wide});

  final ActivityRow row;
  final TodaysActivityTable table;
  final bool wide;

  @override
  State<_ActivityLine> createState() => _ActivityLineState();
}

class _ActivityLineState extends State<_ActivityLine> {
  bool _busy = false;

  ActivityRow get _row => widget.row;
  TodaysActivityTable get _t => widget.table;
  DashboardStrings get _d => DashboardStrings(_t.isEs);

  Future<void> _act(String action) async {
    final run = _t.onStayAction;
    if (run == null) return;
    final ok = await showConfirmDialog(context,
        title: _d.confirmTitle(action, _row.guestName),
        confirmLabel: action == 'CHECK_IN' ? _d.checkIn : _d.checkOut,
        cancelLabel: _d.back);
    if (!ok || !mounted) return;
    setState(() => _busy = true);
    try {
      await run(_row, action);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _next() => Text(
        _d.nextText(_row.next, _t.view.resortDate, _t.resortTime),
        key: Key('activity-next-${_row.stayId}'),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      );

  Widget _pending() {
    final links = <Widget>[
      if (_row.pendingRequests > 0)
        _link('activity-requests-${_row.stayId}',
            _d.requests(_row.pendingRequests), _t.onOpenRequests),
      if (_row.pendingMessages > 0)
        _link('activity-messages-${_row.stayId}',
            _d.messages(_row.pendingMessages), _t.onOpenMessages),
    ];
    if (links.isEmpty) return const Text('—');
    return Wrap(crossAxisAlignment: WrapCrossAlignment.center, children: links);
  }

  Widget _link(String key, String label, ValueChanged<ActivityRow>? open) =>
      TextButton(
        key: Key(key),
        style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            minimumSize: const Size(48, 40)),
        onPressed: open == null ? null : () => open(_row),
        child: Text(label),
      );

  Widget _action() {
    final action = _row.stayAction;
    if (action == null || _t.onStayAction == null) {
      return const SizedBox.shrink();
    }
    return Align(
      alignment: Alignment.centerRight,
      child: FilledButton(
        key: Key('activity-action-${_row.stayId}'),
        onPressed: _busy ? null : () => _act(action),
        child: Text(action == 'CHECK_IN' ? _d.checkIn : _d.checkOut),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chip = Align(
        alignment: Alignment.centerLeft,
        child: ActivityStatusChip(row: _row, isEs: _t.isEs));
    final content = widget.wide
        ? _t._cells(context, cells: [
            Text(_row.guestName, maxLines: 1, overflow: TextOverflow.ellipsis),
            Text(_row.villaName, maxLines: 1, overflow: TextOverflow.ellipsis),
            chip,
            _next(),
            _pending(),
            _action(),
          ])
        : _compact(context, chip);
    return FocusRing(
      borderRadius: KachavaTokens.radiusSm,
      child: InkWell(
        key: Key('activity-${_row.stayId}'),
        onTap: () => _t.onOpenStay(_row.stayId),
        child: content,
      ),
    );
  }

  Widget _compact(BuildContext context, Widget chip) => Container(
        padding: const EdgeInsets.symmetric(
            horizontal: KachavaTokens.space2, vertical: KachavaTokens.space2),
        decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: KachavaTokens.border))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(
                child: Text('${_row.guestName} · ${_row.villaName}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
              ),
              ActivityStatusChip(row: _row, isEs: _t.isEs),
            ]),
            const SizedBox(height: KachavaTokens.space1),
            _next(),
            Row(children: [Expanded(child: _pending()), _action()]),
          ],
        ),
      );
}
