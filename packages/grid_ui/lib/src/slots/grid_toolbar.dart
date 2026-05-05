import 'package:flutter/material.dart';
import 'package:grid_core/grid_core.dart';

import '../components/grid_column_chooser.dart';
import '../components/grid_search_field.dart';

class GridToolbar<T> extends StatelessWidget {
  final GridController<T> controller;
  final Widget? leading;
  final List<Widget>? actions;
  final bool showSearch;
  final bool showColumnChooser;

  const GridToolbar({
    super.key,
    required this.controller,
    this.leading,
    this.actions,
    this.showSearch = true,
    this.showColumnChooser = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          if (leading != null) leading!,
          if (showSearch) ...[
            Expanded(child: GridSearchField(controller: controller)),
          ] else
            const Spacer(),
          if (showColumnChooser) GridColumnChooser(controller: controller),
          if (actions != null) ...actions!,
        ],
      ),
    );
  }
}
