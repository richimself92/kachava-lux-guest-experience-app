import 'package:flutter/material.dart';

import '../../../application/list_query_store.dart';
import '../../../application/resort_settings_controller.dart';
import '../../../core/resort_time.dart';
import '../../../core/theme/kachava_tokens.dart';
import '../../../core/transport_strings.dart';
import '../../../domain/trip_repository.dart';
import '../../components/components.dart';
import 'providers_tab.dart';
import 'trips_tab.dart';

/// HOSPITALITY › Transportation: Trips · Providers · Services (link to the
/// catalog filtered by the Transportation section).
class TransportationWorkspace extends StatefulWidget {
  const TransportationWorkspace({
    super.key,
    required this.repositories,
    required this.resortSettings,
    required this.queries,
    required this.zoneResolver,
    required this.isEs,
    this.now = _utcNow,
    this.onOpenSettings,
    this.onOpenServices,
    this.openTripId,
  });

  final TransportRepositories repositories;
  final ResortSettingsController resortSettings;
  final ListQueryStore queries;
  final ZoneOffsetResolver zoneResolver;
  final bool isEs;

  /// Current instant (injected in tests).
  final DateTime Function() now;
  final VoidCallback? onOpenSettings;

  /// Opens Services filtered by Transportation; `null` while that screen is
  /// not available (the tab then shows only its line).
  final VoidCallback? onOpenServices;

  /// A trip to open in the Trips tab.
  final String? openTripId;

  static DateTime _utcNow() => DateTime.now().toUtc();

  @override
  State<TransportationWorkspace> createState() =>
      _TransportationWorkspaceState();
}

class _TransportationWorkspaceState extends State<TransportationWorkspace>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 3, vsync: this)
    ..addListener(_onTab);

  TransportStrings get _s => TransportStrings(widget.isEs);

  void _onTab() {
    if (!_tabs.indexIsChanging) setState(() {});
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('workspace-admin-transportation'),
      color: KachavaTokens.background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TabBar(
            controller: _tabs,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: KachavaTokens.text,
            unselectedLabelColor: KachavaTokens.textSecondary,
            indicatorColor: KachavaTokens.primary,
            dividerColor: KachavaTokens.border,
            tabs: [
              Tab(key: const Key('transport-tab-trips'), text: _s.trips),
              Tab(
                  key: const Key('transport-tab-providers'),
                  text: _s.providers),
              Tab(key: const Key('transport-tab-services'), text: _s.services),
            ],
          ),
          Expanded(child: _body()),
        ],
      ),
    );
  }

  /// Only the active tab is built; each list keeps its query in the store.
  Widget _body() => switch (_tabs.index) {
        0 => ListenableBuilder(
            listenable: widget.resortSettings,
            builder: (context, _) => _trips(),
          ),
        1 => ProvidersTab(
            repository: widget.repositories.providers,
            queries: widget.queries,
            isEs: widget.isEs,
          ),
        _ => Align(
            alignment: Alignment.topLeft,
            child: AdminStateLine(
              key: const Key('transport-services-line'),
              message: _s.servicesLine,
              actionLabel:
                  widget.onOpenServices == null ? null : _s.openServices,
              onAction: widget.onOpenServices,
            ),
          ),
      };

  Widget _trips() {
    final settings = widget.resortSettings;
    if (settings.status == ResortSettingsStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    return TripsTab(
      repositories: widget.repositories,
      settings: settings.settings,
      resortTime: ResortTime(
          timeZone: settings.settings?.timeZone, resolver: widget.zoneResolver),
      queries: widget.queries,
      now: widget.now,
      isEs: widget.isEs,
      onOpenSettings: widget.onOpenSettings,
      openTripId: widget.openTripId,
    );
  }
}
