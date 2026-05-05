import 'package:flutter/material.dart';
import 'package:grid_core/grid_core.dart';

/// Flutter-layer context passed to cell builder callbacks.
class CellContext<T, V> {
  final CellModel<T, V> cell;
  final BuildContext buildContext;
  final GridController<T> controller;

  V? get value => cell.value;
  RowModel<T> get row => cell.row;
  ColumnInfo<T, V> get column => cell.column;

  const CellContext({
    required this.cell,
    required this.buildContext,
    required this.controller,
  });
}

/// Base class for all cell renderers.
abstract class CellRenderer<V> {
  const CellRenderer();

  Set<ColumnType> get supportedTypes;

  Widget render(CellContext<dynamic, V> ctx);

  Widget renderSkeleton(ColumnDef<dynamic, dynamic> def);
}
