import 'package:flutter/material.dart';
import 'package:grid_core/grid_core.dart';

import 'cell_renderer.dart';

class BadgeConfig {
  final String? label;
  final Color backgroundColor;
  final Color? borderColor;
  final Color? textColor;

  const BadgeConfig({
    this.label,
    required this.backgroundColor,
    this.borderColor,
    this.textColor,
  });
}

class BadgeCellRenderer extends CellRenderer<dynamic> {
  const BadgeCellRenderer();

  @override
  Set<ColumnType> get supportedTypes => {ColumnType.badge};

  @override
  Widget render(CellContext<dynamic, dynamic> ctx) {
    final value = ctx.value;
    String label;
    Color bg;
    Color? border;
    Color? textColor;

    if (value is BadgeConfig) {
      label = value.label ?? '';
      bg = value.backgroundColor;
      border = value.borderColor;
      textColor = value.textColor;
    } else {
      label = value?.toString() ?? '';
      bg = Colors.blueGrey.shade100;
      textColor = Colors.blueGrey.shade800;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: border != null ? Border.all(color: border) : null,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: textColor ?? Colors.white,
        ),
      ),
    );
  }

  @override
  Widget renderSkeleton(ColumnDef<dynamic, dynamic> def) {
    return Container(
      height: 22,
      width: 60,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}
