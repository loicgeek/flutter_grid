import 'package:flutter/material.dart';

import 'package:grid_flutter/grid_flutter.dart';
import '../theme/grid_theme.dart';

class GridAggregationFooter<T> extends StatelessWidget {
  final GridTableState<T> table;

  final Map<String, num>? columnWidths;

  const GridAggregationFooter({
    super.key,
    required this.table,
    this.columnWidths,
  });

  @override
  Widget build(BuildContext context) {
    final theme = GridTheme.of(context);
    final visibleCols = table.visibleColumns;

    final leafRows = table.allRows.where((r) => !r.isGrouped).toList();

    // Calculate left offsets
    final leftOffsets = <int, double>{};
    double currentOffset = 0;
    for (int i = 0; i < visibleCols.length; i++) {
      leftOffsets[i] = currentOffset;
      currentOffset += (columnWidths?[visibleCols[i].id] ??
              visibleCols[i].effectiveWidth ??
              theme.defaultColumnWidth)
          .toDouble();
    }
    final totalWidth = currentOffset;

    final cells = visibleCols.indexed.map((entry) {
      final i = entry.$1;
      final col = entry.$2;

      Widget content;
      if (col.def.aggregationFn != null) {
        final aggregatedValue = col.def.aggregationFn!(leafRows, const []);

        // Use aggregatedCell if provided
        if (col.def.aggregatedCell != null) {
          // Pass a context map since we don't have a CellModel
          final ctx = {'value': aggregatedValue, 'column': col};
          content = col.def.aggregatedCell!(ctx) as Widget;
        } else {
          content = Text(
            aggregatedValue?.toString() ?? '',
            style: const TextStyle(fontWeight: FontWeight.bold),
          );
        }
      } else {
        content = const SizedBox.shrink();
      }

      TextAlign textAlign = TextAlign.left;
      if (col.def.textAlignIndex == 1) textAlign = TextAlign.right;
      if (col.def.textAlignIndex == 2) textAlign = TextAlign.center;

      content = SizedBox(
        width: (columnWidths?[col.id] ??
                col.effectiveWidth ??
                theme.defaultColumnWidth)
            .toDouble(),
        height: theme.rowHeight,
        child: Align(
          alignment: textAlign == TextAlign.right
              ? Alignment.centerRight
              : textAlign == TextAlign.center
                  ? Alignment.center
                  : Alignment.centerLeft,
          child: Padding(
            padding: theme.cellPadding,
            child: content,
          ),
        ),
      );

      return Positioned(
        left: leftOffsets[i]!,
        child: content,
      );
    }).toList();

    return Container(
      height: theme.rowHeight,
      width: totalWidth,
      color: theme.alternateRowBackground ?? Colors.grey.shade100,
      child: Stack(children: cells),
    );
  }
}
