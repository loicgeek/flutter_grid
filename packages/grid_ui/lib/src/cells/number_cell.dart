import 'package:flutter/material.dart';
import 'package:grid_core/grid_core.dart';

import 'cell_renderer.dart';

class NumberCellRenderer extends CellRenderer<num?> {
  const NumberCellRenderer();

  @override
  Set<ColumnType> get supportedTypes => {ColumnType.number};

  @override
  Widget render(CellContext<dynamic, Object?> ctx) {
    final value = ctx.value;
    final text = value == null ? '' : value.toString();
    return Text(
      text,
      style: const TextStyle(fontSize: 14),
      textAlign: TextAlign.right,
    );
  }

  @override
  Widget renderSkeleton(ColumnDef<dynamic, dynamic> def) {
    return Container(
      height: 14,
      width: 60,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}
