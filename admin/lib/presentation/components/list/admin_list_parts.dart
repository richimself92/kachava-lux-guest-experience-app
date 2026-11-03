import 'package:flutter/material.dart';

import '../../../core/admin_list_strings.dart';
import '../../../core/theme/kachava_tokens.dart';
import '../../../domain/list_query.dart';
import '../../../domain/paged_result.dart';
import '../admin_data_table.dart';
import '../focus_ring.dart';

/// "Rows per page 25 · 1–25 of 132 · ‹ ›" (`ux-patterns.md` §1.4).
class AdminPaginationBar extends StatelessWidget {
  const AdminPaginationBar({
    super.key,
    required this.entity,
    required this.result,
    required this.query,
    required this.onPrevious,
    required this.onNext,
    this.onPageSize,
    this.isEs = false,
  });

  final String entity;
  final PagedResult<Object?> result;
  final ListQuery query;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  /// `null` hides the page size selector (mobile keeps 25).
  final ValueChanged<int>? onPageSize;
  final bool isEs;

  @override
  Widget build(BuildContext context) {
    final s = AdminListStrings(isEs);
    final secondary = Theme.of(context)
        .textTheme
        .bodySmall
        ?.copyWith(color: KachavaTokens.textSecondary);
    return Container(
      key: Key('pager-$entity'),
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: KachavaTokens.space2),
      decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: KachavaTokens.border))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (onPageSize != null) ...[
            Text(s.rowsPerPage, style: secondary),
            const SizedBox(width: KachavaTokens.space2),
            DropdownButton<int>(
              key: Key('pager-$entity-size'),
              value: query.pageSize,
              underline: const SizedBox.shrink(),
              items: [
                for (final size in ListQuery.pageSizes)
                  DropdownMenuItem(value: size, child: Text('$size')),
              ],
              onChanged: (size) => size == null ? null : onPageSize!(size),
            ),
            const SizedBox(width: KachavaTokens.space6),
          ],
          Semantics(
            liveRegion: true,
            child: Text(
                s.range(result.rangeStart, result.rangeEnd, result.total),
                key: Key('pager-$entity-range'),
                style: secondary),
          ),
          const SizedBox(width: KachavaTokens.space2),
          _pagerButton(Key('pager-$entity-prev'), Icons.chevron_left,
              s.previousPage, result.hasPrevious ? onPrevious : null),
          _pagerButton(Key('pager-$entity-next'), Icons.chevron_right,
              s.nextPage, result.hasNext ? onNext : null),
        ],
      ),
    );
  }

  Widget _pagerButton(
          Key key, IconData icon, String label, VoidCallback? onPressed) =>
      IconButton(
        key: key,
        tooltip: label,
        constraints: const BoxConstraints.tightFor(width: 44, height: 44),
        icon: Icon(icon),
        onPressed: onPressed,
      );
}

/// Gray placeholder rows on the same column grid (no spinner-only loading).
class AdminTableSkeleton extends StatelessWidget {
  const AdminTableSkeleton({
    super.key,
    required this.flexes,
    required this.semanticLabel,
    this.rows = 8,
    this.compact = false,
  });

  final List<int> flexes;
  final String semanticLabel;
  final int rows;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final height = compact ? 64.0 : AdminDataTable.rowHeight;
    return Semantics(
      key: const Key('list-skeleton'),
      label: semanticLabel,
      child: ExcludeSemantics(
        child: ListView.builder(
          physics: const NeverScrollableScrollPhysics(),
          itemCount: rows,
          itemExtent: height,
          itemBuilder: (_, __) => Container(
            padding:
                const EdgeInsets.symmetric(horizontal: KachavaTokens.space4),
            decoration: const BoxDecoration(
                border:
                    Border(bottom: BorderSide(color: KachavaTokens.border))),
            child: Row(children: [
              for (final flex in compact ? const [1] : flexes)
                Expanded(
                  flex: flex,
                  child: Padding(
                    padding: const EdgeInsets.only(right: KachavaTokens.space6),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        height: 12,
                        decoration: BoxDecoration(
                          color: KachavaTokens.surface,
                          borderRadius:
                              BorderRadius.circular(KachavaTokens.radiusSm),
                        ),
                      ),
                    ),
                  ),
                ),
            ]),
          ),
        ),
      ),
    );
  }
}

/// Mobile list row (min 64px): bold primary line + trailing chip, gray
/// secondary line (`ux-patterns.md` §2).
class AdminCompactList<T> extends StatelessWidget {
  const AdminCompactList({
    super.key,
    required this.entity,
    required this.items,
    required this.rowId,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  final String entity;
  final List<T> items;
  final String Function(T item) rowId;
  final String Function(T item) title;
  final String Function(T item)? subtitle;
  final Widget? Function(T item)? trailing;
  final ValueChanged<T>? onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return ListView.builder(
      key: Key('compact-$entity'),
      itemCount: items.length,
      itemBuilder: (context, i) {
        final item = items[i];
        final second = subtitle?.call(item) ?? '';
        final trail = trailing?.call(item);
        return FocusRing(
          borderRadius: KachavaTokens.radiusSm,
          child: InkWell(
            key: Key('row-$entity-${rowId(item)}'),
            onTap: onTap == null ? null : () => onTap!(item),
            child: Container(
              constraints: const BoxConstraints(minHeight: 64),
              padding: const EdgeInsets.symmetric(
                  horizontal: KachavaTokens.space4,
                  vertical: KachavaTokens.space2),
              decoration: const BoxDecoration(
                  border:
                      Border(bottom: BorderSide(color: KachavaTokens.border))),
              child: Row(children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TruncatedText(title(item),
                          style: text.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w700)),
                      if (second.isNotEmpty)
                        TruncatedText(second,
                            style: text.bodyMedium
                                ?.copyWith(color: KachavaTokens.textSecondary)),
                    ],
                  ),
                ),
                if (trail != null) ...[
                  const SizedBox(width: KachavaTokens.space2),
                  trail,
                ],
              ]),
            ),
          ),
        );
      },
    );
  }
}

/// One line plus one action: "No villas yet · New villa",
/// "No results · Clear filters", "Couldn't load · Retry".
class AdminStateLine extends StatelessWidget {
  const AdminStateLine({
    super.key,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.isError = false,
  });

  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context)
        .textTheme
        .bodyMedium
        ?.copyWith(color: KachavaTokens.textSecondary);
    return Padding(
      padding: const EdgeInsets.all(KachavaTokens.space6),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: KachavaTokens.space3,
        runSpacing: KachavaTokens.space2,
        children: [
          if (isError)
            const Icon(Icons.error_outline,
                size: 18, color: KachavaTokens.error),
          Text(message, style: style),
          if (actionLabel != null && onAction != null)
            OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
        ],
      ),
    );
  }
}
