import 'package:flutter/material.dart';
import 'package:grid_core/grid_core.dart';

import 'cell_renderer.dart';

class DateCellRenderer extends CellRenderer<dynamic> {
  const DateCellRenderer();

  @override
  Set<ColumnType> get supportedTypes => {ColumnType.date, ColumnType.datetime};

  String _format(dynamic value, bool includeTime) {
    if (value == null) return '';
    final DateTime? date = value is DateTime
        ? value
        : DateTime.tryParse(value.toString());
    if (date == null) return value.toString();
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    final y = date.year;
    if (!includeTime) return '$d/$m/$y';
    final h = date.hour.toString().padLeft(2, '0');
    final min = date.minute.toString().padLeft(2, '0');
    return '$d/$m/$y $h:$min';
  }

  @override
  Widget render(CellContext<dynamic, dynamic> ctx) {
    final isDatetime = ctx.column.def.columnType == ColumnType.datetime;
    return Text(
      _format(ctx.value, isDatetime),
      style: const TextStyle(fontSize: 14),
    );
  }

  @override
  Widget renderSkeleton(ColumnDef<dynamic, dynamic> def) {
    return Container(
      height: 14,
      width: 90,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}
