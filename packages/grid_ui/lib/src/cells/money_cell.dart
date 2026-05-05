import 'package:flutter/material.dart';
import 'package:grid_core/grid_core.dart';

import 'cell_renderer.dart';

class MoneyCellRenderer extends CellRenderer<num?> {
  const MoneyCellRenderer();

  @override
  Set<ColumnType> get supportedTypes => {ColumnType.money};

  @override
  Widget render(CellContext<dynamic, Object?> ctx) {
    final value = ctx.value;
    final text =
        value == null || value is! num ? '' : (value).toStringAsFixed(2);
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
      width: 70,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}
