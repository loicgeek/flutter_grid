import 'package:flutter/material.dart';
import 'package:grid_flutter/grid_flutter.dart';

class GridAggregationFooter<T> extends StatelessWidget {
  final GridTableState<T> table;

  const GridAggregationFooter({super.key, required this.table});

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
