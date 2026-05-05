import 'package:flutter/material.dart';
import 'package:grid_core/grid_core.dart';

class GridFilterBar<T> extends StatelessWidget {
  final GridController<T> controller;

  const GridFilterBar({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _ControllerListenable(controller),
      builder: (context, _) {
        final filters = controller.state.columnFilters;
        if (filters.isEmpty) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Wrap(
            spacing: 8,
            runSpacing: 4,
            children: filters.entries.map((entry) {
              final col = controller.options.flatColumns
                  .where((c) => c.id == entry.key)
                  .firstOrNull;
              final label = col?.header ?? entry.key;
              return _FilterChip(
                label: '$label: ${entry.value}',
                onRemove: () =>
                    controller.removeColumnFilter(entry.key),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;

  const _FilterChip({required this.label, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      deleteIcon: const Icon(Icons.close, size: 14),
      onDeleted: onRemove,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
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
