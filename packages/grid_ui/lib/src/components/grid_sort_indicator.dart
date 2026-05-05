import 'package:flutter/material.dart';

class GridSortIndicator extends StatelessWidget {
  final bool isAscending;
  final bool isDescending;
  final int? sortIndex;

  const GridSortIndicator({
    super.key,
    required this.isAscending,
    required this.isDescending,
    this.sortIndex,
  });

  @override
  Widget build(BuildContext context) {
    if (!isAscending && !isDescending) {
      return const Icon(Icons.unfold_more, size: 16, color: Colors.grey);
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isAscending ? Icons.arrow_upward : Icons.arrow_downward,
          size: 14,
        ),
        if (sortIndex != null && sortIndex! > 0)
          Text('${sortIndex! + 1}', style: const TextStyle(fontSize: 10)),
      ],
    );
  }
}
