import 'package:flutter/material.dart';
import 'package:grid_core/grid_core.dart';
import 'package:grid_flutter/grid_flutter.dart';

import '../slots/grid_slots.dart';

class BulkAction<T> {
  final String label;
  final IconData? icon;
  final void Function(List<RowModel<T>> selectedRows) onPressed;
  final Color? color;

  const BulkAction({
    required this.label,
    this.icon,
    required this.onPressed,
    this.color,
  });
}

class GridBulkActionBar<T> extends StatelessWidget {
  final GridController<T> controller;
  final List<BulkAction<T>> actions;

  const GridBulkActionBar({
    super.key,
    required this.controller,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _ControllerListenable(controller),
      builder: (context, _) {
        final selectedCount = controller.state.selectedCount;
        if (selectedCount == 0) return const SizedBox.shrink();

        final selectedRows = controller
            .getRowModels()
            .pageRows
            .where((r) => r.isSelected)
            .toList();

        return Container(
          color: Theme.of(context).colorScheme.primaryContainer,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Text(
                '$selectedCount selected',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 16),
              ...actions.map((action) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: TextButton.icon(
                      onPressed: () => action.onPressed(selectedRows),
                      icon: action.icon != null
                          ? Icon(action.icon, size: 16, color: action.color)
                          : const SizedBox.shrink(),
                      label: Text(
                        action.label,
                        style: TextStyle(color: action.color),
                      ),
                    ),
                  )),
              const Spacer(),
              TextButton(
                onPressed: () => controller.clearRowSelection(),
                child: const Text('Clear selection'),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Internal slot widget used in FlutterGrid to render the bulk action bar.
class GridBulkActionBarSlot<T> extends StatelessWidget {
  final GridController<T> controller;
  final GridSlots<T>? slots;
  final GridTableState<T> table;

  const GridBulkActionBarSlot({
    super.key,
    required this.controller,
    this.slots,
    required this.table,
  });

  @override
  Widget build(BuildContext context) {
    if (slots?.bulkActionBar != null) {
      return slots!.bulkActionBar!(context, table);
    }
    return const SizedBox.shrink();
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
