import 'package:flutter/material.dart';

import '../../../application/paged_list_controller.dart';
import '../../../core/admin_list_strings.dart';
import '../../../core/theme/kachava_tokens.dart';
import '../focus_ring.dart';
import 'admin_filter_sheet.dart';
import 'admin_table_column.dart';

/// Search + filters + active-filter summary (`ux-patterns.md` §1.2 / §2).
///
/// Desktop: 320px search, <= 3 inline filter chips ("Status: Active"), extra
/// filters behind "Filters". Mobile: search icon that expands, one "Filters"
/// button (filters + sort in a bottom sheet).
class AdminListToolbar<T> extends StatefulWidget {
  const AdminListToolbar({
    super.key,
    required this.entity,
    required this.controller,
    required this.filters,
    required this.sortColumns,
    required this.searchFocus,
    required this.compact,
    this.isEs = false,
  });

  static const int maxInlineFilters = 3;

  final String entity;
  final PagedListController<T> controller;
  final List<AdminListFilter> filters;

  /// Sortable columns offered in the mobile sheet.
  final List<AdminTableColumn<T>> sortColumns;
  final FocusNode searchFocus;
  final bool compact;
  final bool isEs;

  @override
  State<AdminListToolbar<T>> createState() => _AdminListToolbarState<T>();
}

class _AdminListToolbarState<T> extends State<AdminListToolbar<T>> {
  late final TextEditingController _search =
      TextEditingController(text: widget.controller.searchText);
  bool _searchOpen = false;

  AdminListStrings get _s => AdminListStrings(widget.isEs);
  PagedListController<T> get _c => widget.controller;

  @override
  void initState() {
    super.initState();
    _c.addListener(_syncSearch);
    _searchOpen = _search.text.isNotEmpty;
  }

  @override
  void dispose() {
    _c.removeListener(_syncSearch);
    _search.dispose();
    super.dispose();
  }

  /// Keeps the box in sync when filters are cleared elsewhere.
  void _syncSearch() {
    if (_search.text != _c.searchText) _search.text = _c.searchText;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _c,
      builder: (context, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: KachavaTokens.space4,
                vertical: KachavaTokens.space2),
            child: widget.compact ? _compactRow() : _wideRow(),
          ),
          if (_c.query.hasActiveFilters) _activeSummary(),
        ],
      ),
    );
  }

  Widget _wideRow() {
    final inline =
        widget.filters.take(AdminListToolbar.maxInlineFilters).toList();
    final extra =
        widget.filters.skip(AdminListToolbar.maxInlineFilters).toList();
    return Wrap(
      spacing: KachavaTokens.space2,
      runSpacing: KachavaTokens.space2,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(width: 320, child: _searchField()),
        for (final f in inline)
          _FilterChipMenu(
            key: Key('filter-${widget.entity}-${f.key}'),
            filter: f,
            value: _c.query.filters[f.key],
            allLabel: _s.all,
            onSelected: (v) => _c.setFilter(f.key, v),
          ),
        if (extra.isNotEmpty) _filtersButton(extra, showSort: false),
      ],
    );
  }

  Widget _compactRow() {
    return Row(children: [
      if (_searchOpen)
        Expanded(child: _searchField(autofocus: true))
      else ...[
        IconButton(
          key: Key('search-${widget.entity}-open'),
          tooltip: _s.search,
          icon: const Icon(Icons.search),
          onPressed: () => setState(() => _searchOpen = true),
        ),
        const Spacer(),
      ],
      const SizedBox(width: KachavaTokens.space2),
      _filtersButton(widget.filters, showSort: true),
    ]);
  }

  Widget _searchField({bool autofocus = false}) {
    return SizedBox(
      height: 40,
      child: TextField(
        key: Key('search-${widget.entity}'),
        controller: _search,
        focusNode: widget.searchFocus,
        autofocus: autofocus,
        onChanged: _c.search,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: _s.search,
          isDense: true,
          contentPadding: EdgeInsets.zero,
          prefixIcon: const Icon(Icons.search, size: 20),
          suffixIcon: _search.text.isEmpty
              ? null
              : IconButton(
                  key: Key('search-${widget.entity}-clear'),
                  tooltip: _s.clearSearch,
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () {
                    _search.clear();
                    _c.search('');
                  },
                ),
        ),
      ),
    );
  }

  Widget _filtersButton(List<AdminListFilter> filters,
      {required bool showSort}) {
    final count =
        filters.where((f) => _c.query.filters.containsKey(f.key)).length;
    return Badge(
      isLabelVisible: count > 0,
      label: Text('$count'),
      child: OutlinedButton.icon(
        key: Key('filters-${widget.entity}'),
        icon: const Icon(Icons.tune, size: 18),
        label: Text(_s.filters),
        onPressed: () => showAdminFilterSheet<T>(
          context: context,
          entity: widget.entity,
          controller: _c,
          filters: filters,
          sortColumns: showSort ? widget.sortColumns : const [],
          isEs: widget.isEs,
        ),
      ),
    );
  }

  Widget _activeSummary() {
    final query = _c.query;
    final chips = <Widget>[
      if (query.q.isNotEmpty)
        _removableChip('“${query.q}”', 'q', _c.clearSearchOnly),
      for (final f in widget.filters)
        if (query.filters[f.key] case final value?)
          _removableChip('${f.label}: ${f.labelFor(value) ?? value}', f.key,
              () => _c.setFilter(f.key, null)),
      TextButton(
        key: Key('clear-filters-${widget.entity}'),
        onPressed: _c.clearFilters,
        child: Text(_s.clearAll),
      ),
    ];
    const padding = EdgeInsets.fromLTRB(
        KachavaTokens.space4, 0, KachavaTokens.space4, KachavaTokens.space2);
    if (widget.compact) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: padding,
        child: Row(children: [
          for (final c in chips)
            Padding(
                padding: const EdgeInsets.only(right: KachavaTokens.space2),
                child: c),
        ]),
      );
    }
    return Padding(
      padding: padding,
      child: Wrap(
          spacing: KachavaTokens.space2,
          runSpacing: KachavaTokens.space2,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: chips),
    );
  }

  Widget _removableChip(String label, String key, VoidCallback onRemove) =>
      InputChip(
        key: Key('active-filter-${widget.entity}-$key'),
        label: Text(label),
        onDeleted: onRemove,
        deleteButtonTooltipMessage: _s.clear,
      );
}

/// Dropdown chip: "Status" when unset, "Status: Active" when set.
class _FilterChipMenu extends StatelessWidget {
  const _FilterChipMenu({
    super.key,
    required this.filter,
    required this.value,
    required this.allLabel,
    required this.onSelected,
  });

  final AdminListFilter filter;
  final String? value;
  final String allLabel;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    final current = filter.labelFor(value);
    final label = current == null ? filter.label : '${filter.label}: $current';
    return FocusRing(
      borderRadius: KachavaTokens.radiusMd,
      child: PopupMenuButton<String>(
        tooltip: '',
        onSelected: (v) => onSelected(v.isEmpty ? null : v),
        itemBuilder: (_) => [
          PopupMenuItem(value: '', child: Text(allLabel)),
          for (final o in filter.options)
            CheckedPopupMenuItem(
                value: o.value,
                checked: o.value == value,
                child: Text(o.label)),
        ],
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: KachavaTokens.space3),
          decoration: BoxDecoration(
            color: current == null
                ? KachavaTokens.background
                : KachavaTokens.surface,
            border: Border.all(color: KachavaTokens.inputBorder),
            borderRadius: BorderRadius.circular(KachavaTokens.radiusMd),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(label, style: Theme.of(context).textTheme.labelLarge),
            const Icon(Icons.arrow_drop_down, size: 20),
          ]),
        ),
      ),
    );
  }
}
