import 'package:flutter/material.dart';

import '../../core/theme/kachava_tokens.dart';

/// MUJI hairline grid: cells on a `line` background with 1px gaps, so the
/// background shows through as even dividing rules. Each cell is `surface`;
/// cells in a row share the tallest height and empty slots stay `surface`.
class HairlineGrid extends StatelessWidget {
  const HairlineGrid({
    super.key,
    required this.children,
    this.columnsFor = defaultColumns,
  });

  final List<Widget> children;

  /// Number of columns for the available width.
  final int Function(double width) columnsFor;

  /// 3 columns on desktop, 2 on tablets and most phones, 1 below 360px.
  static int defaultColumns(double width) => width >= 720
      ? 3
      : width >= 360
          ? 2
          : 1;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final columns = columnsFor(constraints.maxWidth).clamp(1, 12);
      return ColoredBox(
        color: KachavaTokens.line,
        child: Padding(
          padding: const EdgeInsets.all(1),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: _rows(columns),
          ),
        ),
      );
    });
  }

  List<Widget> _rows(int columns) {
    final rows = <Widget>[];
    for (var start = 0; start < children.length; start += columns) {
      if (rows.isNotEmpty) rows.add(const SizedBox(height: 1));
      rows.add(IntrinsicHeight(child: _row(start, columns)));
    }
    return rows;
  }

  Widget _row(int start, int columns) {
    final cells = <Widget>[];
    for (var i = start; i < start + columns; i++) {
      if (cells.isNotEmpty) cells.add(const SizedBox(width: 1));
      cells.add(Expanded(
        child: ColoredBox(
          key: const Key('hairline-cell'),
          color: KachavaTokens.surface,
          child: i < children.length ? children[i] : null,
        ),
      ));
    }
    return Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: cells);
  }
}
