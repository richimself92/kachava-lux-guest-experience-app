import 'package:flutter/material.dart';

/// One table row: cell widgets plus an optional row key.
class AdminTableRow {
  const AdminTableRow({required this.cells, this.key});

  final List<Widget> cells;
  final LocalKey? key;
}

/// Thin [DataTable] wrapper: white, hairline row separators, no card border,
/// horizontal scroll on narrow widths and optional row taps.
class AdminDataTable extends StatelessWidget {
  const AdminDataTable({
    super.key,
    required this.columns,
    required this.rows,
    this.onRowTap,
  });

  final List<String> columns;
  final List<AdminTableRow> rows;

  /// Called with the row index when a row is tapped.
  final ValueChanged<int>? onRowTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(
              minWidth: constraints.hasBoundedWidth ? constraints.maxWidth : 0),
          child: DataTable(
            showCheckboxColumn: false,
            columns: [for (final c in columns) DataColumn(label: Text(c))],
            rows: [
              for (var i = 0; i < rows.length; i++)
                DataRow(
                  key: rows[i].key,
                  onSelectChanged:
                      onRowTap == null ? null : (_) => onRowTap!(i),
                  cells: [for (final cell in rows[i].cells) DataCell(cell)],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
