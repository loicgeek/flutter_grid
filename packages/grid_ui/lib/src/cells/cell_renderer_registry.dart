import 'package:flutter/material.dart';
import 'package:grid_core/grid_core.dart';

import 'avatar_name_cell.dart';
import 'badge_cell.dart';
import 'boolean_cell.dart';
import 'cell_renderer.dart';
import 'date_cell.dart';
import 'link_cell.dart';
import 'money_cell.dart';
import 'number_cell.dart';
import 'progress_cell.dart';
import 'text_cell.dart';

/// Registry mapping [ColumnType] to [CellRenderer].
class CellRendererRegistry {
  CellRendererRegistry._();

  static final CellRendererRegistry instance = CellRendererRegistry._()
    .._register(const TextCellRenderer())
    .._register(const NumberCellRenderer())
    .._register(const MoneyCellRenderer())
    .._register(const DateCellRenderer())
    .._register(const BooleanCellRenderer())
    .._register(const BadgeCellRenderer())
    .._register(const AvatarNameCellRenderer())
    .._register(const ProgressCellRenderer())
    .._register(const LinkCellRenderer());

  final Map<ColumnType, CellRenderer<dynamic>> _renderers = {};

  void _register(CellRenderer<dynamic> renderer) {
    for (final type in renderer.supportedTypes) {
      _renderers[type] = renderer;
    }
  }

  void register(CellRenderer<dynamic> renderer) => _register(renderer);

  Widget renderCell<R, V>(CellContext<R, V> ctx) {
    final renderer = _renderers[ctx.column.def.columnType];
    if (renderer == null) {
      return Text(ctx.value?.toString() ?? '');
    }
    final value = ctx.value;

    return renderer.render(
      CellContext<R, Object?>(
        cell: CellModel<R, Object?>(
          row: ctx.cell.row,
          column: ctx.cell.column as ColumnInfo<R, Object?>,
          value: value,
        ),
        buildContext: ctx.buildContext,
        controller: ctx.controller,
      ),
    );
  }

  Widget renderSkeleton(ColumnDef<dynamic, dynamic> def) {
    final renderer = _renderers[def.columnType];
    if (renderer == null) {
      return Container(
        height: 16,
        width: 80,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(4),
        ),
      );
    }
    return renderer.renderSkeleton(def);
  }
}
