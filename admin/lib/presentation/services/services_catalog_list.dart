import 'package:flutter/material.dart';

import '../../application/list_query_store.dart';
import '../../application/paged_list_controller.dart';
import '../../application/service_catalog_deps.dart';
import '../../core/admin_i18n.dart';
import '../../core/service_catalog_labels.dart';
import '../../core/service_catalog_strings.dart';
import '../../domain/admin_service.dart';
import '../../domain/staff_member.dart';
import '../../domain/list_query.dart';
import '../../domain/paged_result.dart';
import '../components/components.dart';
import 'catalog_thumb.dart';
import 'service_editor.dart';

/// The service catalog table (`ux-patterns.md` §8): cover, name, section,
/// use, price and status; search, filters (section, status, use), sort
/// (order, name) and pages. With [section] it is a section view: the
/// section is fixed and its column and filter disappear.
class ServicesCatalogList extends StatefulWidget {
  const ServicesCatalogList({
    super.key,
    required this.deps,
    required this.title,
    this.section,
    this.queryStore,
    this.staff = const [],
    this.isEs = false,
  });

  final ServiceCatalogDeps deps;
  final String title;
  final ServiceSection? section;
  final ListQueryStore? queryStore;
  final List<StaffMember> staff;
  final bool isEs;

  static const double editorWidth = 560;

  @override
  State<ServicesCatalogList> createState() => _ServicesCatalogListState();
}

class _ServicesCatalogListState extends State<ServicesCatalogList> {
  late final PagedListController<AdminService> _list =
      PagedListController<AdminService>(
    fetch: _fetch,
    initialQuery: const ListQuery(sort: ListSort('order')),
    store: widget.queryStore,
    storeKey: widget.section == null
        ? 'services'
        : 'services-${widget.section!.wire}',
  );

  ServiceCatalogStrings get _s => ServiceCatalogStrings(widget.isEs);
  ServiceCatalogLabels get _l => ServiceCatalogLabels(widget.isEs);

  Future<PagedResult<AdminService>> _fetch(ListQuery query) {
    final section = widget.section;
    return widget.deps.services.list(
        section == null ? query : query.withFilter('section', section.wire));
  }

  @override
  void dispose() {
    _list.dispose();
    super.dispose();
  }

  String _name(AdminService s) {
    final own = s.name.of(isEs: widget.isEs);
    return own.isNotEmpty ? own : s.name.of(isEs: !widget.isEs);
  }

  @override
  Widget build(BuildContext context) => AdminListScreen<AdminService>(
        entity: 'services',
        title: widget.title,
        info: widget.section == null ? _s.servicesInfo : null,
        controller: _list,
        columns: _columns(),
        filters: _filters(),
        rowId: (s) => s.id,
        compactTitle: _name,
        compactSubtitle: (s) => '${_l.section(s.section)} · ${_l.price(s)}',
        compactTrailing: (s) =>
            StatusChip.fromStatus(s.status.wire, isEs: widget.isEs),
        emptyMessage: _s.noServices,
        primaryActionLabel: _s.newService,
        detailWidth: ServicesCatalogList.editorWidth,
        detailBuilder: (context, service, close) => ServiceEditor(
          deps: widget.deps,
          service: service,
          section: widget.section,
          staff: widget.staff,
          isEs: widget.isEs,
          onClose: close,
          onSaved: _list.load,
        ),
        isEs: widget.isEs,
      );

  List<AdminTableColumn<AdminService>> _columns() => [
        AdminTableColumn(
          label: _s.order,
          sortField: 'order',
          flex: 1,
          cell: (s) =>
              CatalogThumb(url: s.cover?.url, label: '${_s.order} ${s.order}'),
        ),
        AdminTableColumn(
            label: _s.name, text: _name, sortField: 'name', flex: 3),
        if (widget.section == null)
          AdminTableColumn(
              label: _s.section, text: (s) => _l.section(s.section)),
        AdminTableColumn(label: _s.use, text: (s) => _l.usage(s.usageType)),
        AdminTableColumn(label: _s.price, text: _l.price, flex: 2),
        AdminTableColumn(
          label: _s.status,
          cell: (s) => StatusChip.fromStatus(s.status.wire, isEs: widget.isEs),
        ),
      ];

  List<AdminListFilter> _filters() => [
        if (widget.section == null)
          AdminListFilter(key: 'section', label: _s.section, options: [
            for (final x in ServiceSection.values)
              AdminFilterOption(x.wire, _l.section(x))
          ]),
        AdminListFilter(key: 'status', label: _s.status, options: [
          for (final x in CatalogStatus.values)
            AdminFilterOption(
                x.wire, AdminI18n.statusLabel(x.wire, widget.isEs))
        ]),
        AdminListFilter(key: 'usageType', label: _s.use, options: [
          for (final x in UsageType.values)
            AdminFilterOption(x.wire, _l.usage(x))
        ]),
      ];
}
