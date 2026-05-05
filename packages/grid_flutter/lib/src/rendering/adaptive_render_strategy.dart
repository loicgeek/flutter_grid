import 'package:flutter/widgets.dart';
import 'package:grid_core/grid_core.dart';

import '../builder/grid_builder.dart';

enum RenderStrategy { table, list, card }

/// Selects a render strategy based on screen width.
class AdaptiveRenderStrategy {
  final double mobileBreakpoint;
  final double tabletBreakpoint;

  const AdaptiveRenderStrategy({
    this.mobileBreakpoint = 600,
    this.tabletBreakpoint = 1024,
  });

  RenderStrategy resolve(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < mobileBreakpoint) return RenderStrategy.list;
    if (width < tabletBreakpoint) return RenderStrategy.card;
    return RenderStrategy.table;
  }
}

/// Widget that selects between mobile list and desktop table based on width.
class AdaptiveGridRenderer<T> extends StatelessWidget {
  final GridTableState<T> table;
  final double breakpoint;
  final Widget Function(BuildContext, GridTableState<T>) tableBuilder;
  final Widget Function(BuildContext, GridTableState<T>) listBuilder;

  const AdaptiveGridRenderer({
    super.key,
    required this.table,
    required this.tableBuilder,
    required this.listBuilder,
    this.breakpoint = 600,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < breakpoint) {
      return listBuilder(context, table);
    }
    return tableBuilder(context, table);
  }
}

/// Renders each row as a [RowModel]-driven widget.
class GridRowRenderer<T> extends StatelessWidget {
  final RowModel<T> row;
  final Widget Function(BuildContext, RowModel<T>) builder;

  const GridRowRenderer({
    super.key,
    required this.row,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) => builder(context, row);
}
