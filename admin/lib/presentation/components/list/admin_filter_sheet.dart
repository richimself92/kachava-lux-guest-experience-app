import 'package:flutter/material.dart';

import '../../../application/paged_list_controller.dart';
import '../../../core/admin_list_strings.dart';
import '../../../core/theme/kachava_tokens.dart';
import '../../../domain/list_query.dart';
import 'admin_table_column.dart';

/// Bottom sheet with filters (and sort on mobile): edits a draft and applies
/// it in one request with "Apply"; "Clear" resets the draft.
Future<void> showAdminFilterSheet<T>({
  required BuildContext context,
  required String entity,
  required PagedListController<T> controller,
  required List<AdminListFilter> filters,
  required List<AdminTableColumn<T>> sortColumns,
  bool isEs = false,
}) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: KachavaTokens.background,
      builder: (_) => _AdminFilterSheet<T>(
        entity: entity,
        controller: controller,
        filters: filters,
        sortColumns: sortColumns,
        isEs: isEs,
      ),
    );

class _AdminFilterSheet<T> extends StatefulWidget {
  const _AdminFilterSheet({
    required this.entity,
    required this.controller,
    required this.filters,
    required this.sortColumns,
    required this.isEs,
  });

  final String entity;
  final PagedListController<T> controller;
  final List<AdminListFilter> filters;
  final List<AdminTableColumn<T>> sortColumns;
  final bool isEs;

  @override
  State<_AdminFilterSheet<T>> createState() => _AdminFilterSheetState<T>();
}

class _AdminFilterSheetState<T> extends State<_AdminFilterSheet<T>> {
  late final Map<String, String> _draft =
      Map.of(widget.controller.query.filters);
  late ListSort? _sort = widget.controller.query.sort;

  /// Bumped by "Clear" so the dropdowns rebuild with the reset draft.
  int _resets = 0;

  AdminListStrings get _s => AdminListStrings(widget.isEs);

  void _apply() {
    widget.controller.applyFiltersAndSort(Map.of(_draft), _sort);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        key: Key('filter-sheet-${widget.entity}'),
        padding: const EdgeInsets.fromLTRB(KachavaTokens.space6, 0,
            KachavaTokens.space6, KachavaTokens.space4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final f in widget.filters) ...[
              _dropdown<String>(
                key: Key('filter-sheet-${f.key}'),
                label: f.label,
                value: _draft[f.key],
                items: {
                  null: _s.all,
                  for (final o in f.options) o.value: o.label,
                },
                onChanged: (v) => setState(
                    () => v == null ? _draft.remove(f.key) : _draft[f.key] = v),
              ),
              const SizedBox(height: KachavaTokens.space4),
            ],
            if (widget.sortColumns.isNotEmpty) ..._sortControls(),
            Row(children: [
              TextButton(
                key: const Key('filter-sheet-clear'),
                onPressed: () => setState(() {
                  _draft.clear();
                  _sort = null;
                  _resets++;
                }),
                child: Text(_s.clear),
              ),
              const Spacer(),
              FilledButton(
                key: const Key('filter-sheet-apply'),
                onPressed: _apply,
                child: Text(_s.apply),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  List<Widget> _sortControls() => [
        _dropdown<String>(
          key: const Key('filter-sheet-sort'),
          label: _s.sort,
          value: _sort?.field,
          items: {
            null: _s.none,
            for (final c in widget.sortColumns) c.sortField!: c.label,
          },
          onChanged: (field) => setState(() => _sort = field == null
              ? null
              : ListSort(field, _sort?.direction ?? SortDirection.asc)),
        ),
        if (_sort != null) ...[
          const SizedBox(height: KachavaTokens.space2),
          SegmentedButton<SortDirection>(
            key: const Key('filter-sheet-direction'),
            segments: [
              ButtonSegment(
                  value: SortDirection.asc,
                  icon: const Icon(Icons.arrow_upward, size: 16),
                  label: Text(_s.ascending)),
              ButtonSegment(
                  value: SortDirection.desc,
                  icon: const Icon(Icons.arrow_downward, size: 16),
                  label: Text(_s.descending)),
            ],
            selected: {_sort!.direction},
            onSelectionChanged: (s) =>
                setState(() => _sort = ListSort(_sort!.field, s.first)),
          ),
        ],
        const SizedBox(height: KachavaTokens.space4),
      ];

  Widget _dropdown<V>({
    required Key key,
    required String label,
    required V? value,
    required Map<V?, String> items,
    required ValueChanged<V?> onChanged,
  }) =>
      KeyedSubtree(
        key: ValueKey((key, _resets)),
        child: DropdownButtonFormField<V?>(
          key: key,
          initialValue: value,
          decoration: InputDecoration(labelText: label, isDense: true),
          items: [
            for (final e in items.entries)
              DropdownMenuItem(value: e.key, child: Text(e.value)),
          ],
          onChanged: onChanged,
        ),
      );
}
