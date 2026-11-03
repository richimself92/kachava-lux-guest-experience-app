import 'package:flutter/material.dart';

import '../../application/paged_list_controller.dart';
import '../../application/service_catalog_deps.dart';
import '../../core/admin_list_strings.dart';
import '../../core/service_catalog_labels.dart';
import '../../core/service_catalog_strings.dart';
import '../../core/theme/kachava_tokens.dart';
import '../../domain/admin_service.dart';
import '../../domain/list_query.dart';
import '../components/components.dart';
import 'catalog_thumb.dart';
import 'service_item_editor.dart';

/// Items of one service: paginated table (photo, name, price, status) and
/// a nested form to add, edit and activate/deactivate an item.
class ServiceItemsTab extends StatefulWidget {
  const ServiceItemsTab({
    super.key,
    required this.deps,
    required this.serviceId,
    required this.kind,
    this.isEs = false,
  });

  final ServiceCatalogDeps deps;
  final String serviceId;
  final ServiceKind kind;
  final bool isEs;

  @override
  State<ServiceItemsTab> createState() => _ServiceItemsTabState();
}

class _ServiceItemsTabState extends State<ServiceItemsTab> {
  late final PagedListController<ServiceItem> _list =
      PagedListController<ServiceItem>(
    fetch: (q) => widget.deps.services.listItems(widget.serviceId, q),
    initialQuery: const ListQuery(sort: ListSort('order')),
  );
  ServiceItem? _editing;
  bool _creating = false;

  ServiceCatalogStrings get _s => ServiceCatalogStrings(widget.isEs);

  @override
  void initState() {
    super.initState();
    _list.load();
  }

  @override
  void dispose() {
    _list.dispose();
    super.dispose();
  }

  void _open(ServiceItem? item) => setState(() {
        _editing = item;
        _creating = item == null;
      });

  void _closeEditor() => setState(() {
        _editing = null;
        _creating = false;
      });

  @override
  Widget build(BuildContext context) {
    if (_creating || _editing != null) {
      return ServiceItemEditor(
        key: ValueKey(_editing?.id ?? 'new-item'),
        deps: widget.deps,
        serviceId: widget.serviceId,
        kind: widget.kind,
        item: _editing,
        isEs: widget.isEs,
        onClose: _closeEditor,
        onSaved: _list.load,
      );
    }
    return ListenableBuilder(
      listenable: _list,
      builder: (context, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(KachavaTokens.space4),
            child: Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                key: const Key('items-new'),
                onPressed: () => _open(null),
                icon: const Icon(Icons.add, size: 18),
                label: Text(_s.newItem),
              ),
            ),
          ),
          Expanded(child: _body()),
          if (_list.result case final result? when !result.isEmpty)
            AdminPaginationBar(
              entity: 'items',
              result: result,
              query: _list.query,
              onPrevious: _list.previousPage,
              onNext: _list.nextPage,
              onPageSize: _list.setPageSize,
              isEs: widget.isEs,
            ),
        ],
      ),
    );
  }

  Widget _body() {
    final strings = AdminListStrings(widget.isEs);
    return switch (_list.status) {
      ListLoadStatus.loading => AdminTableSkeleton(
          flexes: const [1, 3, 2, 2], semanticLabel: strings.loading, rows: 4),
      ListLoadStatus.empty || ListLoadStatus.noResults => Align(
          alignment: Alignment.topLeft,
          child: AdminStateLine(
              key: const Key('items-empty'),
              message: _s.noItems,
              actionLabel: _s.newItem,
              onAction: () => _open(null)),
        ),
      ListLoadStatus.error => Align(
          alignment: Alignment.topLeft,
          child: AdminStateLine(
              key: const Key('items-error'),
              message: strings.loadError,
              actionLabel: strings.retry,
              onAction: _list.retry,
              isError: true),
        ),
      ListLoadStatus.data => AdminDataTable<ServiceItem>(
          entity: 'items',
          columns: _columns(),
          rows: _list.items,
          rowId: (i) => i.id,
          sort: _list.query.sort,
          onSort: _list.toggleSort,
          onRowTap: _open,
          isEs: widget.isEs,
        ),
    };
  }

  List<AdminTableColumn<ServiceItem>> _columns() {
    final labels = ServiceCatalogLabels(widget.isEs);
    String name(ServiceItem i) => i.name.of(isEs: widget.isEs).isNotEmpty
        ? i.name.of(isEs: widget.isEs)
        : i.name.of(isEs: !widget.isEs);
    return [
      AdminTableColumn(
          label: _s.photo,
          flex: 1,
          cell: (i) => CatalogThumb(url: i.image?.url, label: name(i))),
      AdminTableColumn(label: _s.name, text: name, sortField: 'name', flex: 3),
      AdminTableColumn(
          label: _s.price,
          text: (i) => labels.money(i.priceUSD),
          sortField: 'priceUSD',
          numeric: true),
      AdminTableColumn(
          label: _s.status,
          cell: (i) => StatusChip.fromStatus(i.status.wire, isEs: widget.isEs)),
    ];
  }
}
