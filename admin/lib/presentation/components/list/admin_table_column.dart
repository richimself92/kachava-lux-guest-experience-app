import 'package:flutter/widgets.dart';

/// One table column: a short header, how to render the cell and, when the
/// backend can sort by it, the wire [sortField].
class AdminTableColumn<T> {
  const AdminTableColumn({
    required this.label,
    this.text,
    this.cell,
    this.sortField,
    this.numeric = false,
    this.flex = 2,
  }) : assert(text != null || cell != null, 'Provide text or cell');

  final String label;

  /// Plain text cell (ellipsis + tooltip when truncated).
  final String Function(T item)? text;

  /// Custom cell (e.g. a `StatusChip`).
  final Widget Function(T item)? cell;
  final String? sortField;

  /// Right-aligned numeric column.
  final bool numeric;
  final int flex;

  bool get sortable => sortField != null;
}

/// One filter shown in the toolbar ("Status: Active").
class AdminListFilter {
  const AdminListFilter({
    required this.key,
    required this.label,
    required this.options,
  });

  /// Wire query key, e.g. `status`.
  final String key;
  final String label;
  final List<AdminFilterOption> options;

  String? labelFor(String? value) =>
      options.where((o) => o.value == value).firstOrNull?.label;
}

/// A filter value and its short label.
class AdminFilterOption {
  const AdminFilterOption(this.value, this.label);

  final String value;
  final String label;
}
