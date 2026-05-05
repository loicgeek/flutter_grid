import 'package:flutter/material.dart';
import 'package:grid_core/grid_core.dart';

class GridCardView<T> extends StatelessWidget {
  final List<RowModel<T>> rows;
  final Widget Function(BuildContext, RowModel<T>) rowBuilder;
  final int crossAxisCount;
  final double childAspectRatio;

  const GridCardView({
    super.key,
    required this.rows,
    required this.rowBuilder,
    this.crossAxisCount = 2,
    this.childAspectRatio = 1.5,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: childAspectRatio,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      padding: const EdgeInsets.all(8),
      itemCount: rows.length,
      itemBuilder: (context, index) => rowBuilder(context, rows[index]),
    );
  }
}
