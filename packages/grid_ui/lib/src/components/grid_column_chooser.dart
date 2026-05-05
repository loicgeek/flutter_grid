import 'package:flutter/material.dart';
import 'package:grid_core/grid_core.dart';

class GridColumnChooser<T> extends StatelessWidget {
  final GridController<T> controller;

  const GridColumnChooser({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.view_column_outlined),
      tooltip: 'Columns',
      onPressed: () => _showDialog(context),
    );
  }

  void _showDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Columns'),
        content: ListenableBuilder(
          listenable: _ControllerListenable(controller),
          builder: (context, _) {
            final hidableCols = controller.options.flatColumns
                .where((c) => c.enableHiding)
                .toList();
            return SizedBox(
              width: 300,
              child: ListView(
                shrinkWrap: true,
                children: hidableCols.map((col) {
                  final visible =
                      controller.state.columnVisibility[col.id] ?? true;
                  return CheckboxListTile(
                    title: Text(col.header ?? col.id),
                    value: visible,
                    onChanged: (_) =>
                        controller.toggleColumnVisibility(col.id),
                  );
                }).toList(),
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
}

class _ControllerListenable extends ChangeNotifier {
  final GridController<dynamic> controller;

  _ControllerListenable(this.controller) {
    controller.addListener(_onChange);
  }

  void _onChange() => notifyListeners();

  @override
  void dispose() {
    controller.removeListener(_onChange);
    super.dispose();
  }
}
