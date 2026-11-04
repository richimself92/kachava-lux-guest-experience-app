import 'package:flutter/material.dart';

import '../../../application/list_query_store.dart';
import '../../../application/paged_list_controller.dart';
import '../../../core/admin_i18n.dart';
import '../../../core/resort_time.dart';
import '../../../core/stay_strings.dart';
import '../../../core/transport_strings.dart';
import '../../../domain/admin_catalog_repositories.dart';
import '../../../domain/admin_trip.dart';
import '../../../domain/admin_villa.dart';
import '../../../domain/guest_profile.dart';
import '../../../domain/list_query.dart';
import '../../../domain/reservation.dart';
import '../../../domain/staff_member.dart';
import '../../components/components.dart';
import '../operations_scope.dart';
import 'reservation_create_panel.dart';
import 'reservation_detail_panel.dart';

/// GUEST OPERATIONS › Reservations: Guest, Villa, Arrival, Departure,
/// Status, Resort Host; filters status / villa / dates, guest search, sort
/// by arrival or departure, pages; "+ New reservation"; detail with
/// Summary, Preferences, Trips and Folio.
class ReservationsScreen extends StatefulWidget {
  const ReservationsScreen({
    super.key,
    required this.reservations,
    required this.guests,
    required this.villas,
    required this.queries,
    required this.staff,
    required this.isEs,
    this.today,
    this.openId,
    this.onOpenTrips,
    this.onOpenTrip,
  });

  static const String storeKey = 'reservations';
  static const ListQuery villasQuery =
      ListQuery(pageSize: 100, sort: ListSort('name'));

  final ReservationRepository reservations;
  final GuestRepository guests;
  final VillaRepository villas;
  final ListQueryStore queries;
  final List<StaffMember> staff;
  final bool isEs;

  /// Resort day `YYYY-MM-DD`; `null` without a time zone (no date presets).
  final String? today;

  /// A stay to open on arrival (dashboard row, notification).
  final String? openId;

  /// Transportation filtered by the stay's guest.
  final ValueChanged<ReservationRow>? onOpenTrips;
  final ValueChanged<String>? onOpenTrip;

  @override
  State<ReservationsScreen> createState() => _ReservationsScreenState();
}

class _ReservationsScreenState extends State<ReservationsScreen> {
  late final PagedListController<ReservationRow> _list = PagedListController(
    fetch: widget.reservations.list,
    initialQuery: const ListQuery(sort: ListSort('checkIn')),
    store: widget.queries,
    storeKey: ReservationsScreen.storeKey,
  );
  List<AdminVilla> _villas = const [];

  StayStrings get _s => StayStrings(widget.isEs);

  @override
  void initState() {
    super.initState();
    _loadVillas();
  }

  @override
  void dispose() {
    _list.dispose();
    super.dispose();
  }

  /// Best effort: without villas the filter and the picker are empty. Walks
  /// every page so no villa is missing from the picker.
  Future<void> _loadVillas() async {
    try {
      final all = <AdminVilla>[];
      var query = ReservationsScreen.villasQuery;
      while (true) {
        final page = await widget.villas.list(query);
        all.addAll(page.items);
        if (page.items.isEmpty || all.length >= page.total) break;
        query = query.withPage(query.page + 1);
      }
      if (mounted) setState(() => _villas = all);
    } catch (error) {
      debugPrint('Villas unavailable: $error');
    }
  }

  String _day(String? day) =>
      day == null ? '—' : ResortTime.dayLabel(day, isEs: widget.isEs);

  @override
  Widget build(BuildContext context) => OpenRecordLoader<ReservationRow>(
        id: widget.openId,
        load: (id) async => (await widget.reservations.get(id)).row,
        builder: (context, initial) => _screen(initial),
      );

  Widget _screen(ReservationRow? initial) => AdminListScreen<ReservationRow>(
        key: const Key('workspace-admin-stays'),
        entity: 'reservations',
        title: _s.reservations,
        controller: _list,
        columns: _columns(),
        rowId: (r) => r.id,
        compactTitle: (r) => r.guestName,
        compactSubtitle: (r) =>
            '${r.villaName} · ${_s.range(r.checkIn, r.checkOut)}',
        compactTrailing: (r) =>
            StatusChip.fromStatus(r.status, isEs: widget.isEs),
        filters: _filters(),
        emptyMessage: _s.noReservations,
        primaryActionLabel: _s.newReservation,
        detailBuilder: _detail,
        initialDetail: initial,
        isEs: widget.isEs,
      );

  Widget _detail(
      BuildContext context, ReservationRow? row, VoidCallback close) {
    if (row == null) {
      return ReservationCreatePanel(
        repository: widget.reservations,
        villas: widget.villas,
        today: widget.today,
        onClose: close,
        onCreated: (_) => _list.load(),
        isEs: widget.isEs,
      );
    }
    return ReservationDetailPanel(
      row: row,
      reservations: widget.reservations,
      guests: widget.guests,
      staff: widget.staff,
      onClose: close,
      onChanged: _list.load,
      onOpenTrips: widget.onOpenTrips,
      onOpenTrip: widget.onOpenTrip,
      isEs: widget.isEs,
    );
  }

  List<AdminTableColumn<ReservationRow>> _columns() => [
        AdminTableColumn(label: _s.guest, text: (r) => r.guestName, flex: 3),
        AdminTableColumn(label: _s.villa, text: (r) => r.villaName),
        AdminTableColumn(
            label: _s.checkInDate,
            text: (r) => _day(r.checkIn),
            sortField: 'checkIn'),
        AdminTableColumn(
            label: _s.checkOutDate,
            text: (r) => _day(r.checkOut),
            sortField: 'checkOut'),
        AdminTableColumn(
            label: _s.status,
            cell: (r) => StatusChip.fromStatus(r.status, isEs: widget.isEs)),
        AdminTableColumn(
            label: _s.resortHost,
            text: (r) => r.resortHostName ?? _s.unassigned),
      ];

  List<AdminListFilter> _filters() => [
        AdminListFilter(key: 'status', label: _s.status, options: [
          for (final v in StayValues.statuses)
            AdminFilterOption(v, AdminI18n.statusLabel(v, widget.isEs)),
        ]),
        AdminListFilter(key: 'villaId', label: _s.villa, options: [
          for (final v in _villas) AdminFilterOption(v.id, v.name),
        ]),
        if (widget.today case final day?) _rangeFilter(day),
      ];

  AdminListFilter _rangeFilter(String day) {
    final t = TransportStrings(widget.isEs);
    final p = TripDateRange.presets(day);
    final options = [
      AdminFilterOption(p.today.encode(), t.today),
      AdminFilterOption(p.tomorrow.encode(), t.tomorrow),
      AdminFilterOption(p.next7Days.encode(), t.next7Days),
      AdminFilterOption(p.last7Days.encode(), t.last7Days),
    ];
    final current =
        TripDateRange.parse(_list.query.filters[TripDateRange.filterKey]);
    if (current != null && options.every((o) => o.value != current.encode())) {
      options.add(AdminFilterOption(
          current.encode(), _s.range(current.from, current.to)));
    }
    return AdminListFilter(
        key: TripDateRange.filterKey, label: _s.dates, options: options);
  }
}
