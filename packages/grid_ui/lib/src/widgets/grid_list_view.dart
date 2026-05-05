import 'package:flutter/material.dart';
import 'package:grid_core/grid_core.dart';

/// A simple list view wrapper for mobile rendering.
class GridListView<T> extends StatelessWidget {
  final List<RowModel<T>> rows;
  final Widget Function(BuildContext, RowModel<T>) rowBuilder;
  final void Function(RowModel<T>)? onRowTap;

  const GridListView({
    super.key,
    required this.rows,
    required this.rowBuilder,
    this.onRowTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: rows.length,
      itemBuilder: (context, index) {
        final row = rows[index];
        return InkWell(
          onTap: onRowTap != null ? () => onRowTap!(row) : null,
          child: rowBuilder(context, row),
        );
      },
    );
  }
}
