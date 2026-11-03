import 'package:flutter/material.dart';

import '../../core/admin_list_strings.dart';
import '../../core/theme/kachava_tokens.dart';
import '../../domain/list_query.dart';
import 'focus_ring.dart';
import 'list/admin_table_column.dart';

export 'list/admin_table_column.dart';

/// Material 3 style data table (`ux-patterns.md` §1.3): white, hairline row
/// separators, 48px rows, sticky header, sortable headers (one active sort),
/// focusable rows (Enter opens), max 6 columns, ellipsis + tooltip.
///
/// Needs a bounded height: rows scroll under the fixed header.
class AdminDataTable<T> extends StatelessWidget {
  const AdminDataTable({
    super.key,
    required this.entity,
    required this.columns,
    required this.rows,
    required this.rowId,
    this.sort,
    this.onSort,
    this.onRowTap,
    this.selectedId,
    this.isEs = false,
  }) : assert(columns.length <= maxColumns, 'Max 6 visible columns');

  static const int maxColumns = 6;
  static const double rowHeight = 48;

  /// Key prefix: rows are `row-<entity>-<id>`.
  final String entity;
  final List<AdminTableColumn<T>> columns;
  final List<T> rows;
  final String Function(T item) rowId;
  final ListSort? sort;
  final ValueChanged<String>? onSort;
  final ValueChanged<T>? onRowTap;
  final String? selectedId;
  final bool isEs;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: Key('table-$entity'),
      children: [
        _AdminTableHeader<T>(
            columns: columns,
            sort: sort,
            onSort: onSort,
            strings: AdminListStrings(isEs),
            entity: entity),
        const Divider(),
        Expanded(
          child: ListView.builder(
            itemExtent: rowHeight,
            itemCount: rows.length,
            itemBuilder: (context, i) => _row(rows[i]),
          ),
        ),
      ],
    );
  }

  Widget _row(T item) {
    final id = rowId(item);
    final selected = id == selectedId;
    return FocusRing(
      borderRadius: KachavaTokens.radiusSm,
      child: Material(
        color: selected ? KachavaTokens.surface : KachavaTokens.background,
        child: InkWell(
          key: Key('row-$entity-$id'),
          onTap: onRowTap == null ? null : () => onRowTap!(item),
          child: DecoratedBox(
            decoration: const BoxDecoration(
                border:
                    Border(bottom: BorderSide(color: KachavaTokens.border))),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: KachavaTokens.space4),
              child: Row(children: [
                for (final c in columns)
                  Expanded(flex: c.flex, child: _cell(c, item)),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _cell(AdminTableColumn<T> column, T item) {
    final align = column.numeric ? Alignment.centerRight : Alignment.centerLeft;
    final child = column.cell != null
        ? column.cell!(item)
        : TruncatedText(column.text!(item),
            textAlign: column.numeric ? TextAlign.right : TextAlign.left);
    return Padding(
      padding: const EdgeInsets.only(right: KachavaTokens.space4),
      child: Align(alignment: align, child: child),
    );
  }
}

class _AdminTableHeader<T> extends StatelessWidget {
  const _AdminTableHeader({
    required this.columns,
    required this.sort,
    required this.onSort,
    required this.strings,
    required this.entity,
  });

  final List<AdminTableColumn<T>> columns;
  final ListSort? sort;
  final ValueChanged<String>? onSort;
  final AdminListStrings strings;
  final String entity;

  static const TextStyle _style = TextStyle(
      fontSize: 12,
      height: 16 / 12,
      fontWeight: FontWeight.w500,
      color: KachavaTokens.textSecondary);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AdminDataTable.rowHeight,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: KachavaTokens.space4),
        child: Row(children: [
          for (final c in columns)
            Expanded(
              flex: c.flex,
              child: Padding(
                padding: const EdgeInsets.only(right: KachavaTokens.space4),
                child: Align(
                  alignment:
                      c.numeric ? Alignment.centerRight : Alignment.centerLeft,
                  child: c.sortable && onSort != null
                      ? _sortButton(c)
                      : Text(c.label,
                          style: _style,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                ),
              ),
            ),
        ]),
      ),
    );
  }

  Widget _sortButton(AdminTableColumn<T> column) {
    final active = sort?.field == column.sortField ? sort : null;
    final semantics = switch (active?.direction) {
      SortDirection.asc => strings.sortedAscending(column.label),
      SortDirection.desc => strings.sortedDescending(column.label),
      null => strings.sortBy(column.label),
    };
    return Semantics(
      button: true,
      label: semantics,
      excludeSemantics: true,
      child: FocusRing(
        borderRadius: KachavaTokens.radiusSm,
        child: InkWell(
          key: Key('sort-$entity-${column.sortField}'),
          borderRadius: BorderRadius.circular(KachavaTokens.radiusSm),
          onTap: () => onSort!(column.sortField!),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 40),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Flexible(
                child: Text(column.label,
                    style: active == null
                        ? _style
                        : _style.copyWith(color: KachavaTokens.text),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
              const SizedBox(width: KachavaTokens.space1),
              Icon(
                active?.direction == SortDirection.desc
                    ? Icons.arrow_downward
                    : Icons.arrow_upward,
                size: 16,
                color:
                    active == null ? KachavaTokens.border : KachavaTokens.text,
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

/// One-line 14/20 text with an ellipsis; shows the full text in a tooltip
/// only when it is actually truncated.
class TruncatedText extends StatelessWidget {
  const TruncatedText(this.text,
      {super.key, this.style, this.textAlign = TextAlign.left});

  final String text;
  final TextStyle? style;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    final effective = style ?? Theme.of(context).textTheme.bodyMedium!;
    return LayoutBuilder(builder: (context, constraints) {
      final label = Text(text,
          style: effective,
          maxLines: 1,
          textAlign: textAlign,
          overflow: TextOverflow.ellipsis);
      final painter = TextPainter(
        text: TextSpan(text: text, style: effective),
        maxLines: 1,
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
      )..layout(maxWidth: constraints.maxWidth);
      final truncated = painter.didExceedMaxLines;
      painter.dispose();
      return truncated ? Tooltip(message: text, child: label) : label;
    });
  }
}
