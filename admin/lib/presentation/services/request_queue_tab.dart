import 'package:flutter/material.dart';

import '../../application/list_query_store.dart';
import '../../application/paged_list_controller.dart';
import '../../core/admin_i18n.dart';
import '../../core/request_strings.dart';
import '../../core/resort_time.dart';
import '../../domain/admin_trip.dart' show TripDateRange;
import '../../domain/list_query.dart';
import '../../domain/service_catalog_enums.dart';
import '../../domain/service_request.dart';
import '../components/components.dart';
import 'request_detail_panel.dart';

/// "Requests" tab of Experiences / Dining / Wellness: the section's guest
/// bookings and orders, server-paged. Default: open requests, earliest first.
class RequestQueueTab extends StatefulWidget {
  const RequestQueueTab({
    super.key,
    required this.section,
    required this.repository,
    required this.queries,
    required this.today,
    required this.isEs,
  });

  /// [ListQueryStore] key of the queue of [section].
  static String storeKey(ServiceSection section) =>
      'requests-${section.wire.toLowerCase()}';

  static const ListQuery initialQuery = ListQuery(
    sort: ListSort('at'),
    filters: {'status': RequestStatusValues.open},
  );

  final ServiceSection section;
  final ServiceRequestRepository repository;
  final ListQueryStore? queries;

  /// Resort day (`YYYY-MM-DD`) for the date presets; `null` without a zone.
  final String? today;
  final bool isEs;

  @override
  State<RequestQueueTab> createState() => _RequestQueueTabState();
}

class _RequestQueueTabState extends State<RequestQueueTab> {
  late final PagedListController<ServiceRequest> _list = PagedListController(
    fetch: (query) => widget.repository.list(widget.section, query),
    initialQuery: RequestQueueTab.initialQuery,
    store: widget.queries,
    storeKey: widget.queries == null
        ? null
        : RequestQueueTab.storeKey(widget.section),
  );

  RequestStrings get _s => RequestStrings(widget.isEs);

  @override
  void dispose() {
    _list.dispose();
    super.dispose();
  }

  String _service(ServiceRequest r) => r.serviceName.of(isEs: widget.isEs);

  Widget _status(ServiceRequest r) =>
      StatusChip.fromStatus(r.status, isEs: widget.isEs);

  @override
  Widget build(BuildContext context) {
    return AdminListScreen<ServiceRequest>(
      entity: 'requests-${widget.section.wire.toLowerCase()}',
      title: _s.requests,
      info: _s.requestsInfo,
      controller: _list,
      columns: [
        AdminTableColumn(
            label: _s.guestVilla,
            text: (r) => '${r.guestName} · ${r.villaName}',
            flex: 3),
        AdminTableColumn(label: _s.service, text: _service, flex: 3),
        AdminTableColumn(
            label: _s.dateTime,
            text: (r) => requestWhen(r, widget.isEs),
            sortField: 'at'),
        AdminTableColumn(
            label: _s.guestsQty,
            text: (r) => '${r.quantity}',
            numeric: true,
            flex: 1),
        AdminTableColumn(label: _s.status, cell: _status),
      ],
      rowId: (r) => r.id,
      compactTitle: (r) => '${r.guestName} · ${r.villaName}',
      compactSubtitle: (r) => '${_service(r)} · ${requestWhen(r, widget.isEs)}',
      compactTrailing: _status,
      filters: _filters(),
      emptyMessage: _s.noRequests,
      detailBuilder: (context, request, close) => request == null
          ? const SizedBox.shrink()
          : RequestDetailPanel(
              request: request,
              repository: widget.repository,
              onClose: close,
              onChanged: _list.load,
              isEs: widget.isEs,
            ),
      isEs: widget.isEs,
    );
  }

  List<AdminListFilter> _filters() => [
        AdminListFilter(key: 'status', label: _s.status, options: [
          AdminFilterOption(RequestStatusValues.open, _s.open),
          for (final v in RequestStatusValues.all)
            AdminFilterOption(v, AdminI18n.statusLabel(v, widget.isEs)),
        ]),
        if (widget.today case final day?) _rangeFilter(day),
      ];

  /// Quick resort-day ranges; a stored range keeps its own label.
  AdminListFilter _rangeFilter(String day) {
    final p = TripDateRange.presets(day);
    final options = [
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
