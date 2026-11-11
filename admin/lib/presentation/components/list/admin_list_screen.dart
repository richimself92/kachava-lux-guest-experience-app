import 'package:flutter/material.dart';

import '../../../application/paged_list_controller.dart';
import '../../../core/admin_list_strings.dart';
import '../../../core/theme/kachava_tokens.dart';
import '../../../domain/realtime_change.dart';
import '../admin_data_table.dart';
import '../info_tooltip.dart';
import '../realtime_scope.dart';
import 'admin_detail_panel.dart';
import 'admin_list_parts.dart';
import 'admin_list_shortcuts.dart';
import 'admin_list_toolbar.dart';

/// Builds the detail (or create, when [item] is `null`) content. [close]
/// closes the side panel or pops the mobile sheet.
typedef AdminDetailBuilder<T> = Widget Function(
    BuildContext context, T? item, VoidCallback close);

/// Standard admin list (`ux-patterns.md` §1-2): header (title + ⓘ + one
/// primary action), toolbar, sortable table or compact rows, pagination,
/// loading/empty/no-results/error states and a detail panel (side panel at
/// >= [wideBreakpoint], full-screen sheet below it).
///
/// Keys: `list-<entity>`, `search-<entity>`, `row-<entity>-<id>`,
/// `pager-<entity>`, `primary-<entity>`.
class AdminListScreen<T> extends StatefulWidget {
  const AdminListScreen({
    super.key,
    required this.entity,
    required this.title,
    required this.controller,
    required this.columns,
    required this.rowId,
    required this.compactTitle,
    required this.emptyMessage,
    this.info,
    this.compactSubtitle,
    this.compactTrailing,
    this.compactContent,
    this.filters = const [],
    this.primaryActionLabel,
    this.onPrimaryAction,
    this.detailBuilder,
    this.detailWidth = AdminDetailPanel.width,
    this.initialDetail,
    this.onRowTap,
    this.isEs = false,
    this.realtimeTopics,
  });

  static const double wideBreakpoint = 840;

  final String entity;
  final String title;
  final String? info;
  final PagedListController<T> controller;
  final List<AdminTableColumn<T>> columns;
  final String Function(T item) rowId;
  final String Function(T item) compactTitle;
  final String Function(T item)? compactSubtitle;
  final Widget? Function(T item)? compactTrailing;

  /// Custom compact row body (replaces title + subtitle).
  final Widget Function(T item)? compactContent;
  final List<AdminListFilter> filters;

  /// One short line, e.g. "No villas yet".
  final String emptyMessage;

  /// Verb + noun, e.g. "New villa". Without [onPrimaryAction] it opens
  /// [detailBuilder] in create mode.
  final String? primaryActionLabel;
  final VoidCallback? onPrimaryAction;
  final AdminDetailBuilder<T>? detailBuilder;

  /// Side panel width on desktop (tabbed editors may need more than 420).
  final double detailWidth;

  /// Opened right after the first frame (e.g. a notification's target).
  final T? initialDetail;

  /// Replaces the detail panel on row tap (e.g. go to another screen).
  final ValueChanged<T>? onRowTap;
  final bool isEs;

  /// Real-time topics that reload this list (keeping query and page);
  /// defaults to [realtimeTopicsForList] of [entity].
  final Set<String>? realtimeTopics;

  @override
  State<AdminListScreen<T>> createState() => _AdminListScreenState<T>();
}

class _AdminListScreenState<T> extends State<AdminListScreen<T>>
    with AdminRealtimeRefresh<AdminListScreen<T>> {
  final FocusNode _searchFocus = FocusNode(debugLabel: 'list-search');

  /// Holds keyboard focus for the list shortcuts when no row/field has it.
  final FocusNode _listFocus =
      FocusNode(debugLabel: 'list', skipTraversal: true);
  T? _selected;
  bool _creating = false;
  FocusNode? _returnFocus;

  /// Whether the last layout had room for the side panel. The list may be
  /// narrower than the window (sidebar), so this, not the window width,
  /// decides between the side panel and the full-screen sheet.
  bool _wide = true;

  /// Bumped on every "New": each create opens a fresh, empty editor even
  /// when a create panel (or a record just saved from it) is still open.
  int _createGeneration = 0;

  PagedListController<T> get _c => widget.controller;
  AdminListStrings get _s => AdminListStrings(widget.isEs);
  bool get _panelOpen => _selected != null || _creating;

  @override
  void initState() {
    super.initState();
    _c.addListener(_syncSelected);
    if (_c.result == null) _c.load();
    final initial = widget.initialDetail;
    if (initial != null && widget.detailBuilder != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _open(initial);
      });
    }
  }

  @override
  void didUpdateWidget(AdminListScreen<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (identical(oldWidget.controller, _c)) return;
    oldWidget.controller.removeListener(_syncSelected);
    _c.addListener(_syncSelected);
  }

  @override
  void onRealtimeInvalidation(RealtimeInvalidation change) {
    final topics =
        widget.realtimeTopics ?? realtimeTopicsForList(widget.entity);
    if (change.touches(topics)) _c.refresh();
  }

  /// The newest copy of [item] on the current page (after a reload).
  T _fresh(T item) {
    final id = widget.rowId(item);
    for (final row in _c.items) {
      if (widget.rowId(row) == id) return row;
    }
    return item;
  }

  /// Keeps the open side panel on the reloaded row.
  void _syncSelected() {
    final selected = _selected;
    if (!mounted || selected == null) return;
    final fresh = _fresh(selected);
    if (!identical(fresh, selected)) setState(() => _selected = fresh);
  }

  @override
  void dispose() {
    _c.removeListener(_syncSelected);
    _searchFocus.dispose();
    _listFocus.dispose();
    super.dispose();
  }

  VoidCallback? get _primaryAction {
    if (widget.primaryActionLabel == null) return null;
    if (widget.onPrimaryAction != null) return widget.onPrimaryAction;
    return widget.detailBuilder == null ? null : () => _open(null);
  }

  void _open(T? item) {
    _returnFocus = FocusManager.instance.primaryFocus;
    if (_wide) {
      setState(() {
        _selected = item;
        _creating = item == null;
        if (item == null) _createGeneration++;
      });
      return;
    }
    Navigator.of(context).push(MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (route) => Scaffold(
        body: SafeArea(
          child: ListenableBuilder(
            listenable: _c,
            builder: (_, __) => widget.detailBuilder!(
                route,
                item == null ? null : _fresh(item),
                () => Navigator.of(route).pop()),
          ),
        ),
      ),
    ));
  }

  /// Safe after dispose (e.g. a toast action that runs after navigating).
  void _close() {
    if (!mounted) return;
    setState(() {
      _selected = null;
      _creating = false;
    });
    final back = _returnFocus;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      (back != null && back.context != null ? back : _listFocus).requestFocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final wide = constraints.maxWidth >= AdminListScreen.wideBreakpoint;
      _wide = wide;
      final list = _list(wide);
      final body = wide && _panelOpen && widget.detailBuilder != null
          ? Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Expanded(child: list),
              const VerticalDivider(width: 1),
              SizedBox(
                width: widget.detailWidth,
                child: KeyedSubtree(
                  key: ValueKey(_creating
                      ? 'new-$_createGeneration'
                      : widget.rowId(_selected as T)),
                  child: widget.detailBuilder!(
                      context, _creating ? null : _selected, _close),
                ),
              ),
            ])
          : list;
      return AdminListShortcuts(
        searchFocus: _searchFocus,
        onPrevious: _c.previousPage,
        onNext: _c.nextPage,
        child: Focus(
          key: Key('list-${widget.entity}'),
          focusNode: _listFocus,
          autofocus: true,
          child: body,
        ),
      );
    });
  }

  Widget _list(bool wide) => ListenableBuilder(
        listenable: _c,
        builder: (context, _) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _header(),
            AdminListToolbar<T>(
              entity: widget.entity,
              controller: _c,
              filters: widget.filters,
              sortColumns: [
                for (final c in widget.columns)
                  if (c.sortable) c
              ],
              searchFocus: _searchFocus,
              compact: !wide,
              isEs: widget.isEs,
            ),
            Expanded(child: _body(wide)),
            if (_c.result case final result? when !result.isEmpty)
              AdminPaginationBar(
                entity: widget.entity,
                result: result,
                query: _c.query,
                onPrevious: _c.previousPage,
                onNext: _c.nextPage,
                onPageSize: wide ? _c.setPageSize : null,
                isEs: widget.isEs,
              ),
          ],
        ),
      );

  Widget _header() {
    final action = _primaryAction;
    return Padding(
      padding: const EdgeInsets.fromLTRB(KachavaTokens.space4,
          KachavaTokens.space4, KachavaTokens.space4, KachavaTokens.space2),
      child: Row(children: [
        // Title + ⓘ take the free space so the primary action sits right.
        Expanded(
          child: Row(children: [
            Flexible(
              child: Text(widget.title,
                  key: Key('list-${widget.entity}-title'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.headlineSmall),
            ),
            if (widget.info != null) InfoTooltip(widget.info!),
          ]),
        ),
        if (action != null)
          FilledButton.icon(
            key: Key('primary-${widget.entity}'),
            onPressed: action,
            icon: const Icon(Icons.add, size: 18),
            label: Text(widget.primaryActionLabel!),
          ),
      ]),
    );
  }

  Widget _body(bool wide) {
    switch (_c.status) {
      case ListLoadStatus.loading:
        return AdminTableSkeleton(
            flexes: [for (final c in widget.columns) c.flex],
            compact: !wide,
            semanticLabel: _s.loading);
      case ListLoadStatus.empty:
        return Align(
          alignment: Alignment.topLeft,
          child: AdminStateLine(
            key: Key('list-${widget.entity}-empty'),
            message: widget.emptyMessage,
            actionLabel: widget.primaryActionLabel,
            onAction: _primaryAction,
          ),
        );
      case ListLoadStatus.noResults:
        return Align(
          alignment: Alignment.topLeft,
          child: AdminStateLine(
            key: Key('list-${widget.entity}-no-results'),
            message: _s.noResults,
            actionLabel: _s.clearFilters,
            onAction: _c.clearFilters,
          ),
        );
      case ListLoadStatus.error:
        return Align(
          alignment: Alignment.topLeft,
          child: AdminStateLine(
            key: Key('list-${widget.entity}-error'),
            message: _s.loadError,
            actionLabel: _s.retry,
            onAction: _c.retry,
            isError: true,
          ),
        );
      case ListLoadStatus.data:
        return AnimatedOpacity(
          opacity: _c.isRefreshing ? 0.5 : 1,
          duration: const Duration(milliseconds: 150),
          child: wide ? _table() : _compact(),
        );
    }
  }

  Widget _table() => AdminDataTable<T>(
        entity: widget.entity,
        columns: widget.columns,
        rows: _c.items,
        rowId: widget.rowId,
        sort: _c.query.sort,
        onSort: _c.toggleSort,
        onRowTap: _rowTap,
        selectedId: _selected == null ? null : widget.rowId(_selected as T),
        isEs: widget.isEs,
      );

  Widget _compact() => AdminCompactList<T>(
        entity: widget.entity,
        items: _c.items,
        rowId: widget.rowId,
        title: widget.compactTitle,
        subtitle: widget.compactSubtitle,
        trailing: widget.compactTrailing,
        content: widget.compactContent,
        onTap: _rowTap,
      );

  ValueChanged<T>? get _rowTap =>
      widget.onRowTap ?? (widget.detailBuilder == null ? null : _open);
}
