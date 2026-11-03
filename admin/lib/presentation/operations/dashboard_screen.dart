import 'package:flutter/material.dart';

import '../../core/admin_list_strings.dart';
import '../../core/resort_time.dart';
import '../../core/stay_strings.dart';
import '../../core/theme/kachava_tokens.dart';
import '../../domain/dashboard_view.dart';
import '../../domain/trip_repository.dart';
import '../components/components.dart';
import 'dashboard_parts.dart';

/// Dashboard (plan v2): "Overview" + resort-day pill, six KPI tiles with
/// their formula in ⓘ, and "Today's activity" (≤ 8 rows, "View all").
/// A missing time zone is one line that leads to Settings.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    super.key,
    required this.repository,
    required this.isEs,
    required this.onOpenStay,
    required this.onViewAll,
    required this.onOpenSettings,
  });

  final DashboardRepository repository;
  final bool isEs;
  final ValueChanged<String> onOpenStay;
  final VoidCallback onViewAll;
  final VoidCallback onOpenSettings;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  DashboardView? _view;
  Object? _error;
  bool _loading = true;

  StayStrings get _s => StayStrings(widget.isEs);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final view = await widget.repository.fetch();
      if (mounted) setState(() => _view = view);
    } catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const Key('workspace-admin-overview'),
      padding: const EdgeInsets.all(KachavaTokens.space6),
      children: [
        _header(context),
        const SizedBox(height: KachavaTokens.space4),
        ..._body(),
      ],
    );
  }

  Widget _header(BuildContext context) {
    final day = _view?.resortDate;
    return Row(children: [
      Expanded(
        child: Text(_s.overview,
            key: const Key('dashboard-title'),
            style: Theme.of(context).textTheme.headlineSmall),
      ),
      if (day != null)
        TodayPill(
          key: const Key('dashboard-today'),
          label: '${_s.today} · ${ResortTime.dayLabel(day, isEs: widget.isEs)}',
        ),
    ]);
  }

  List<Widget> _body() {
    final view = _view;
    if (_error is SettingsRequiredException) {
      return [
        SettingsSetupLink(
          key: const Key('dashboard-settings-missing'),
          message: _s.timeZoneMissing,
          linkLabel: _s.setUpInSettings,
          onOpenSettings: widget.onOpenSettings,
        ),
      ];
    }
    if (_error != null) {
      final l = AdminListStrings(widget.isEs);
      return [
        AdminStateLine(
          key: const Key('dashboard-error'),
          message: l.loadError,
          actionLabel: l.retry,
          onAction: _load,
          isError: true,
        ),
      ];
    }
    if (view == null) {
      return [if (_loading) const LinearProgressIndicator()];
    }
    return [
      DashboardKpiGrid(kpis: view.kpis, isEs: widget.isEs),
      const SizedBox(height: KachavaTokens.space8),
      TodaysActivityTable(
        view: view,
        isEs: widget.isEs,
        onOpenStay: widget.onOpenStay,
        onViewAll: widget.onViewAll,
      ),
    ];
  }
}
