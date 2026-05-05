import 'package:flutter/material.dart';
import 'package:grid_core/grid_core.dart';

import '../skeleton/skeleton_row.dart';

class GridLoadingState extends StatelessWidget {
  final List<ColumnDef<dynamic, dynamic>> columns;

  const GridLoadingState({super.key, required this.columns});

  @override
  Widget build(BuildContext context) =>
      GridSkeletonLoader(columns: columns);
}
