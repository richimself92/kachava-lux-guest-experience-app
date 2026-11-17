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

/// Items of one service (products, menus, options, vehicles) inline in the
/// service form: title + "New item", a short paginated table (photo, name,
/// price, status). [onOpen] opens the item form (`null` = new item).
class ServiceItemsSection extends StatefulWidget {
  const ServiceItemsSection({
    super.key,
    required this.deps,
    required this.serviceId,
    required this.kind,
    required this.onOpen,
    this.isEs = false,
  });

  final ServiceCatalogDeps deps;
  final String serviceId;
  final ServiceKind kind;
  final ValueChanged<ServiceItem?> onOpen;
  final bool isEs;

  @override
  State<ServiceItemsSection> createState() => _ServiceItemsSectionState();
}

class _ServiceItemsSectionState extends State<ServiceItemsSection> {
  late final PagedListController<ServiceItem> _list =
      PagedListController<ServiceItem>(
    fetch: (q) => widget.deps.services.listItems(widget.serviceId, q),
    initialQuery: const ListQuery(sort: ListSort('order'), pageSize: 10),
  );

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

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _list,
      builder: (context, _) => Column(
        key: const Key('svc-items-section'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ServiceItemsHeader(
            title: _s.itemsTitle(widget.kind),
            action: OutlinedButton.icon(
              key: const Key('items-new'),
              onPressed: () => widget.onOpen(null),
              icon: const Icon(Icons.add, size: 18),
              label: Text(_s.newItem),
            ),
          ),
          _body(),
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
          const SizedBox(height: KachavaTokens.space4),
        ],
      ),
    );
  }

  Widget _body() {
    final strings = AdminListStrings(widget.isEs);
    const row = AdminDataTable.rowHeight;
    return switch (_list.status) {
      ListLoadStatus.loading => SizedBox(
          height: row * 3,
          child: AdminTableSkeleton(
              flexes: const [1, 3, 2, 2],
              semanticLabel: strings.loading,
              rows: 3)),
      ListLoadStatus.empty ||
      ListLoadStatus.noResults =>
        AdminStateLine(key: const Key('items-empty'), message: _s.noItems),
      ListLoadStatus.error => AdminStateLine(
          key: const Key('items-error'),
          message: strings.loadError,
          actionLabel: strings.retry,
          onAction: _list.retry,
          isError: true),
      ListLoadStatus.data => SizedBox(
          height: row * (_list.items.length + 1) + 1,
          child: AdminDataTable<ServiceItem>(
            entity: 'items',
            columns: _columns(),
            rows: _list.items,
            rowId: (i) => i.id,
            sort: _list.query.sort,
            onSort: _list.toggleSort,
            onRowTap: widget.onOpen,
            isEs: widget.isEs,
          ),
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

/// Title of the inline items block with its action on the right.
class ServiceItemsHeader extends StatelessWidget {
  const ServiceItemsHeader({super.key, required this.title, this.action});

  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: KachavaTokens.space2),
        child: Row(children: [
          Expanded(
            child: Text(title,
                style: Theme.of(context).textTheme.titleMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ),
          if (action != null) action!,
        ]),
      );
}
