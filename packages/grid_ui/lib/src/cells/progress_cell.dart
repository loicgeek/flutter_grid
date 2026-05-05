import 'package:flutter/material.dart';
import 'package:grid_core/grid_core.dart';

import 'cell_renderer.dart';

class ProgressCellRenderer extends CellRenderer<num?> {
  const ProgressCellRenderer();

  @override
  Set<ColumnType> get supportedTypes => {ColumnType.progress};

  @override
  Widget render(CellContext<dynamic, Object?> ctx) {
    final value = ctx.value;
    final progress = (value is num ? value : 0.0).clamp(0.0, 1.0);
    return Row(
      children: [
        Expanded(
          child: LinearProgressIndicator(
            value: progress.toDouble(),
            backgroundColor: Colors.grey[200],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${(progress * 100).round()}%',
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  @override
  Widget renderSkeleton(ColumnDef<dynamic, dynamic> def) {
    return Container(
      height: 8,
      width: 100,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
