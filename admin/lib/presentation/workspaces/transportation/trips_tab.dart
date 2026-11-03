import 'package:flutter/material.dart';

import '../../../application/list_query_store.dart';
import '../../../application/paged_list_controller.dart';
import '../../../core/admin_i18n.dart';
import '../../../core/resort_time.dart';
import '../../../core/theme/kachava_tokens.dart';
import '../../../core/transport_strings.dart';
import '../../../domain/admin_settings.dart';
import '../../../domain/admin_trip.dart';
import '../../../domain/list_query.dart';
import '../../../domain/transport_provider.dart';
import '../../../domain/trip_repository.dart';
import '../../components/components.dart';
import 'trip_create_panel.dart';
import 'trip_detail_panel.dart';

/// Trips list: today + tomorrow by default (resort days), filters dates /
/// status / type / provider, search guest or flight, sort by pickup.
class TripsTab extends StatefulWidget {
  const TripsTab({
    super.key,
    required this.repositories,
    required this.settings,
    required this.resortTime,
    required this.queries,
    required this.now,
    required this.isEs,
    this.onOpenSettings,
  });

  /// [ListQueryStore] key of this list.
  static const String storeKey = 'trips';

  /// Enough to read a resort's providers at once (backend maximum).
  static const ListQuery providersQuery =
      ListQuery(pageSize: 100, sort: ListSort('name'));

  final TransportRepositories repositories;

  /// `null` when Settings failed to load (nothing is assumed).
  final AdminSettings? settings;
  final ResortTime resortTime;
  final ListQueryStore queries;
  final DateTime Function() now;
  final bool isEs;
  final VoidCallback? onOpenSettings;

  @override
  State<TripsTab> createState() => _TripsTabState();
}

class _TripsTabState extends State<TripsTab> {
  /// Resort day at open; `null` without a configured time zone.
  late final String? _today = widget.resortTime.dayOf(widget.now());

  late final PagedListController<AdminTrip> _list = PagedListController(
    fetch: widget.repositories.trips.list,
    initialQuery: ListQuery(
      sort: const ListSort('pickupAt'),
      filters: {
        if (_today case final day?)
          TripDateRange.filterKey:
              TripDateRange.presets(day).todayAndTomorrow.encode(),
      },
    ),
    store: widget.queries,
    storeKey: TripsTab.storeKey,
  )..addListener(_onList);

  List<TransportProvider> _providers = const [];
  bool _settingsRequired = false;

  TransportStrings get _s => TransportStrings(widget.isEs);

  @override
  void initState() {
    super.initState();
    _loadProviders();
  }

  @override
  void dispose() {
    _list
      ..removeListener(_onList)
      ..dispose();
    super.dispose();
  }

  void _onList() {
    final required = _list.error is SettingsRequiredException;
    if (required != _settingsRequired) {
      setState(() => _settingsRequired = required);
    }
  }

  /// Best effort: without it rows show no provider name and the filter has
  /// no options.
  Future<void> _loadProviders() async {
    try {
      final page =
          await widget.repositories.providers.list(TripsTab.providersQuery);
      if (mounted) setState(() => _providers = page.items);
    } catch (_) {
      // Keep the previous providers.
    }
  }

  String _providerName(String? id) =>
      _providers.where((p) => p.id == id).firstOrNull?.name ?? '';

  @override
  Widget build(BuildContext context) {
    final setup = _setupMessage();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (setup != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(KachavaTokens.space4,
                KachavaTokens.space2, KachavaTokens.space4, 0),
            child: SettingsSetupLink(
              key: const Key('trips-settings-missing'),
              message: setup,
              linkLabel: _s.setUpInSettings,
              onOpenSettings: widget.onOpenSettings ?? () {},
            ),
          ),
        Expanded(child: _listScreen()),
      ],
    );
  }

  /// One line when Settings miss what trips need (else `null`).
  String? _setupMessage() {
    if (_settingsRequired) {
      final details = (_list.error as SettingsRequiredException).details;
      return details.contains('timeZone')
          ? _s.timeZoneMissing
          : _s.settingsMissing;
    }
    final settings = widget.settings;
    if (settings == null) return null;
    if (settings.timeZone == null) return _s.timeZoneMissing;
    if (settings.transportAlertLeadHours == null) return _s.alertLeadMissing;
    return null;
  }

  Widget _listScreen() => AdminListScreen<AdminTrip>(
        entity: 'trips',
        title: _s.trips,
        info: _s.tripsInfo,
        controller: _list,
        columns: _columns(),
        rowId: (t) => t.id,
        compactTitle: (t) => '${t.guestName} · ${t.villaName}',
        compactSubtitle: (t) => [
          widget.resortTime.label(t.pickupAt, isEs: widget.isEs),
          _s.typeLabel(t.type),
          if (t.flight case final f?) f.number,
        ].join(' · '),
        compactTrailing: _statusCell,
        filters: _filters(),
        emptyMessage: _s.noTrips,
        primaryActionLabel: _s.newTrip,
        detailBuilder: _detail,
        isEs: widget.isEs,
      );

  Widget _detail(BuildContext context, AdminTrip? trip, VoidCallback close) {
    if (trip == null) {
      return TripCreatePanel(
        repositories: widget.repositories,
        settings: widget.settings,
        resortTime: widget.resortTime,
        providers: _providers,
        onClose: close,
        onCreated: (_) => _list.load(),
        onOpenSettings: widget.onOpenSettings,
        isEs: widget.isEs,
      );
    }
    return TripDetailPanel(
      trip: trip,
      repository: widget.repositories.trips,
      providers: _providers,
      resortTime: widget.resortTime,
      onClose: close,
      onChanged: _list.load,
      isEs: widget.isEs,
    );
  }

  Widget _statusCell(AdminTrip t) => Wrap(
        spacing: KachavaTokens.space1,
        runSpacing: KachavaTokens.space1,
        children: [
          StatusChip.fromStatus(t.status, isEs: widget.isEs),
          if (t.unconfirmedDue == true)
            Tooltip(
              message: _s.unconfirmedInfo,
              child: StatusChip(
                  key: Key('unconfirmed-${t.id}'),
                  label: _s.unconfirmed,
                  tone: StatusTone.error),
            ),
        ],
      );

  String _providerDriver(AdminTrip t) {
    final parts = [_providerName(t.providerId), t.driver?.name ?? '']
        .where((p) => p.isNotEmpty);
    return parts.isEmpty ? '—' : parts.join(' · ');
  }

  List<AdminTableColumn<AdminTrip>> _columns() => [
        AdminTableColumn(
            label: _s.pickup,
            text: (t) => widget.resortTime.label(t.pickupAt, isEs: widget.isEs),
            sortField: 'pickupAt'),
        AdminTableColumn(
            label: _s.guestVilla,
            text: (t) => '${t.guestName} · ${t.villaName}',
            flex: 3),
        AdminTableColumn(
            label: _s.type, text: (t) => _s.typeLabel(t.type), flex: 1),
        AdminTableColumn(
            label: _s.flight, text: (t) => t.flight?.number ?? '—', flex: 1),
        AdminTableColumn(label: _s.providerDriver, text: _providerDriver),
        AdminTableColumn(label: _s.status, cell: _statusCell, flex: 3),
      ];

  List<AdminListFilter> _filters() => [
        if (_today case final day?) _rangeFilter(day),
        AdminListFilter(
          key: 'status',
          label: _s.status,
          options: [
            for (final v in TripValues.statuses)
              AdminFilterOption(v, AdminI18n.statusLabel(v, widget.isEs)),
          ],
        ),
        AdminListFilter(
          key: 'type',
          label: _s.type,
          options: [
            for (final v in TripValues.types)
              AdminFilterOption(v, _s.typeLabel(v)),
          ],
        ),
        AdminListFilter(
          key: 'providerId',
          label: _s.provider,
          options: [
            for (final p in _providers) AdminFilterOption(p.id, p.name),
          ],
        ),
      ];

  /// Quick resort-day ranges; a stored range from another day keeps its
  /// own label ("Nov 4 – Nov 5").
  AdminListFilter _rangeFilter(String day) {
    final p = TripDateRange.presets(day);
    final options = [
      AdminFilterOption(p.todayAndTomorrow.encode(), _s.todayTomorrow),
      AdminFilterOption(p.today.encode(), _s.today),
      AdminFilterOption(p.tomorrow.encode(), _s.tomorrow),
      AdminFilterOption(p.next7Days.encode(), _s.next7Days),
      AdminFilterOption(p.last7Days.encode(), _s.last7Days),
    ];
    final current =
        TripDateRange.parse(_list.query.filters[TripDateRange.filterKey]);
    if (current != null && options.every((o) => o.value != current.encode())) {
      String label(String d) => ResortTime.dayLabel(d, isEs: widget.isEs);
      options.add(AdminFilterOption(
          current.encode(), '${label(current.from)} – ${label(current.to)}'));
    }
    return AdminListFilter(
        key: TripDateRange.filterKey, label: _s.dates, options: options);
  }
}
