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
    initialQuery: const ListQuery(sort: _defaultSort, pageSize: 10),
  );

  final FocusNode _searchFocus = FocusNode();

  /// Server categories for the filter; `null` until loaded (or on error).
  List<String>? _categories;

  ServiceCatalogStrings get _s => ServiceCatalogStrings(widget.isEs);
  bool get _sourcing => widget.kind.itemFields.contains(ItemField.sourcing);

  @override
  void initState() {
    super.initState();
    _list.load();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final values =
          await widget.deps.services.listItemCategories(widget.serviceId);
      if (mounted) setState(() => _categories = values);
    } catch (_) {
      // No filter without server categories (never invented).
    }
  }

  @override
  void dispose() {
    _list.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  List<AdminListFilter> _filters() => [
        if (_categories case final values? when values.isNotEmpty)
          AdminListFilter(
            key: 'category',
            label: _s.category,
            options: [for (final c in values) AdminFilterOption(c, c)],
          ),
      ];

  Widget _toolbar() => LayoutBuilder(
        builder: (context, box) => AdminListToolbar<ServiceItem>(
          entity: 'items',
          controller: _list,
          filters: _filters(),
          sortColumns: [
            for (final c in _columns())
              if (c.sortField != null) c
          ],
          searchFocus: _searchFocus,
          compact: box.maxWidth < 520,
          isEs: widget.isEs,
        ),
      );

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
          if (_list.status != ListLoadStatus.empty) _toolbar(),
          _body(),
          if (_list.result case final result? when !result.isEmpty)
            LayoutBuilder(
              // Narrow screens drop the page size picker (it overflows).
              builder: (context, box) => AdminPaginationBar(
                entity: 'items',
                result: result,
                query: _list.query,
                onPrevious: _list.previousPage,
                onNext: _list.nextPage,
                onPageSize: box.maxWidth < 520 ? null : _list.setPageSize,
                isEs: widget.isEs,
              ),
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
      ListLoadStatus.empty =>
        AdminStateLine(key: const Key('items-empty'), message: _s.noItems),
      ListLoadStatus.noResults => AdminStateLine(
          key: const Key('items-no-results'), message: strings.noResults),
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
            rows: _rows(),
            rowId: (i) => i.id,
            sort: _list.query.sort,
            onSort: _list.toggleSort,
            onRowTap: widget.onOpen,
            isEs: widget.isEs,
          ),
        ),
    };
  }

  static const ListSort _defaultSort = ListSort('order');

  /// Fits "Desactivado" on one line plus the cell gap.
  static const double statusColumnWidth = 120;

  /// The default server order is `order` only: on that sort, active items
  /// come first (stable) so disabled legacy rows do not lead the page.
  List<ServiceItem> _rows() {
    final items = _list.items;
    if (_list.query.sort != _defaultSort) return items;
    return [
      ...items.where((i) => i.status == CatalogStatus.active),
      ...items.where((i) => i.status != CatalogStatus.active),
    ];
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
      if (_sourcing)
        AdminTableColumn(label: _s.sku, text: (i) => i.sku ?? '—', flex: 2),
      AdminTableColumn(label: _s.name, text: name, sortField: 'name', flex: 3),
      AdminTableColumn(
          label: _s.price,
          text: (i) => i.isPricedByOz && i.priceUSD != null
              ? _s.perOz(labels.dollars(i.priceUSD!))
              : labels.money(i.priceUSD),
          sortField: 'priceUSD',
          numeric: true),
      AdminTableColumn(
          label: _s.status,
          width: statusColumnWidth,
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
