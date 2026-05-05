import 'package:flutter/material.dart';
import 'package:grid_core/grid_core.dart';

import 'cell_renderer.dart';
import 'highlight_text.dart';

class TextCellRenderer extends CellRenderer<String?> {
  const TextCellRenderer();

  @override
  Set<ColumnType> get supportedTypes =>
      {ColumnType.text, ColumnType.custom, ColumnType.display};

  @override
  Widget render(CellContext<dynamic, Object?> ctx) {
    final value = ctx.value?.toString() ?? '';
    final globalFilter = ctx.controller.state.globalFilter;
    return HighlightText(
      text: value,
      highlight: globalFilter,
      style: const TextStyle(fontSize: 14),
    );
  }

  @override
  Widget renderSkeleton(ColumnDef<dynamic, dynamic> def) {
    return Container(
      height: 14,
      width: (def.size ?? 120) * 0.7,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}
