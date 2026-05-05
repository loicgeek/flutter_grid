import 'package:flutter/material.dart';
import 'package:grid_core/grid_core.dart';

import 'cell_renderer.dart';

class BooleanCellRenderer extends CellRenderer<bool?> {
  const BooleanCellRenderer();

  @override
  Set<ColumnType> get supportedTypes => {ColumnType.boolean};

  @override
  Widget render(CellContext<dynamic, Object?> ctx) {
    final value = ctx.value;
    if (value == null) return const SizedBox.shrink();
    final checked = value is bool ? value : false;
    return Icon(
      checked ? Icons.check_circle_outline : Icons.cancel_outlined,
      size: 18,
      color: checked ? Colors.green : Colors.red,
    );
  }

  @override
  Widget renderSkeleton(ColumnDef<dynamic, dynamic> def) {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        shape: BoxShape.circle,
      ),
    );
  }
}
