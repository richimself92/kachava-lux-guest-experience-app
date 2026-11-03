import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../application/paged_list_controller.dart';
import '../../../core/admin_list_strings.dart';
import '../../../core/theme/kachava_tokens.dart';
import '../admin_data_table.dart';
import '../info_tooltip.dart';
import 'admin_list_parts.dart';
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
    this.filters = const [],
    this.primaryActionLabel,
    this.onPrimaryAction,
    this.detailBuilder,
    this.isEs = false,
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
  final List<AdminListFilter> filters;

  /// One short line, e.g. "No villas yet".
  final String emptyMessage;

  /// Verb + noun, e.g. "New villa". Without [onPrimaryAction] it opens
  /// [detailBuilder] in create mode.
  final String? primaryActionLabel;
  final VoidCallback? onPrimaryAction;
  final AdminDetailBuilder<T>? detailBuilder;
  final bool isEs;

  @override
  State<AdminListScreen<T>> createState() => _AdminListScreenState<T>();
}

class _AdminListScreenState<T> extends State<AdminListScreen<T>> {
  final FocusNode _searchFocus = FocusNode(debugLabel: 'list-search');

  /// Holds keyboard focus for the list shortcuts when no row/field has it.
  final FocusNode _listFocus =
      FocusNode(debugLabel: 'list', skipTraversal: true);
  T? _selected;
  bool _creating = false;
  FocusNode? _returnFocus;

  PagedListController<T> get _c => widget.controller;
  AdminListStrings get _s => AdminListStrings(widget.isEs);
  bool get _panelOpen => _selected != null || _creating;

  @override
  void initState() {
    super.initState();
    if (_c.result == null) _c.load();
  }

  @override
  void dispose() {
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
    final wide =
        MediaQuery.sizeOf(context).width >= AdminListScreen.wideBreakpoint;
    if (wide) {
      setState(() {
        _selected = item;
        _creating = item == null;
      });
      return;
    }
    Navigator.of(context).push(MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (route) => Scaffold(
        body: SafeArea(
          child: widget.detailBuilder!(
              route, item, () => Navigator.of(route).pop()),
        ),
      ),
    ));
  }

  void _close() {
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
      final list = _list(wide);
      final body = wide && _panelOpen && widget.detailBuilder != null
          ? Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Expanded(child: list),
              const VerticalDivider(width: 1),
              SizedBox(
                width: 420,
                child: KeyedSubtree(
                  key: ValueKey(
                      _creating ? 'new' : widget.rowId(_selected as T)),
                  child: widget.detailBuilder!(
                      context, _creating ? null : _selected, _close),
                ),
              ),
            ])
          : list;
      return _ListShortcuts(
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
        Flexible(
          child: Text(widget.title,
              key: Key('list-${widget.entity}-title'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.headlineSmall),
        ),
        if (widget.info != null) InfoTooltip(widget.info!),
        const Spacer(),
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
        onRowTap: widget.detailBuilder == null ? null : _open,
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
        onTap: widget.detailBuilder == null ? null : _open,
      );
}

/// `/` focuses search; PageUp/PageDown page the list. Disabled while typing
/// in a text field so the keys still reach it.
class _ListShortcuts extends StatelessWidget {
  const _ListShortcuts({
    required this.searchFocus,
    required this.onPrevious,
    required this.onNext,
    required this.child,
  });

  final FocusNode searchFocus;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.slash):
            _ListKeyIntent(_ListKey.search),
        SingleActivator(LogicalKeyboardKey.pageUp):
            _ListKeyIntent(_ListKey.previous),
        SingleActivator(LogicalKeyboardKey.pageDown):
            _ListKeyIntent(_ListKey.next),
      },
      child: Actions(
        actions: {
          _ListKeyIntent: _ListKeyAction((key) => switch (key) {
                _ListKey.search => searchFocus.requestFocus(),
                _ListKey.previous => onPrevious(),
                _ListKey.next => onNext(),
              }),
        },
        child: child,
      ),
    );
  }
}

enum _ListKey { search, previous, next }

class _ListKeyIntent extends Intent {
  const _ListKeyIntent(this.key);

  final _ListKey key;
}

class _ListKeyAction extends Action<_ListKeyIntent> {
  _ListKeyAction(this._run);

  final void Function(_ListKey key) _run;

  /// Not while a text field has focus (the key belongs to the text).
  @override
  bool isEnabled(_ListKeyIntent intent) {
    final focused = FocusManager.instance.primaryFocus?.context;
    return focused == null ||
        focused.findAncestorWidgetOfExactType<EditableText>() == null;
  }

  @override
  Object? invoke(_ListKeyIntent intent) {
    _run(intent.key);
    return null;
  }
}
