import 'package:flutter/material.dart';
import 'package:grid_core/grid_core.dart';

class GridPagination<T> extends StatelessWidget {
  final GridController<T> controller;
  final List<int> pageSizeOptions;

  const GridPagination({
    super.key,
    required this.controller,
    this.pageSizeOptions = const [5, 10, 20, 50, 100],
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _ControllerListenable(controller),
      builder: (context, _) {
        final state = controller.state;
        final pageRows = controller.getRowModels();
        final currentPage = state.pagination.pageIndex + 1;
        final totalPages = pageRows.totalPages;
        final pageSize = state.pagination.pageSize;
        final totalRows = pageRows.totalRows;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Text(
                '$totalRows rows',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurfaceVariant,
                    ),
              ),
              const SizedBox(width: 16),
              DropdownButton<int>(
                value: pageSizeOptions.contains(pageSize)
                    ? pageSize
                    : pageSizeOptions.first,
                underline: const SizedBox.shrink(),
                items: pageSizeOptions
                    .map((s) => DropdownMenuItem(
                          value: s,
                          child: Text('$s / page'),
                        ))
                    .toList(),
                onChanged: (v) {
                  if (v != null) controller.setPageSize(v);
                },
              ),
              const Spacer(),
              Text(
                'Page $currentPage of $totalPages',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.first_page),
                onPressed: currentPage > 1
                    ? () => controller.setPageIndex(0)
                    : null,
              ),
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: currentPage > 1
                    ? () => controller.previousPage()
                    : null,
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: currentPage < totalPages
                    ? () => controller.nextPage()
                    : null,
              ),
              IconButton(
                icon: const Icon(Icons.last_page),
                onPressed: currentPage < totalPages
                    ? () => controller.setPageIndex(totalPages - 1)
                    : null,
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Adapts [GridController] to [Listenable] for [ListenableBuilder].
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
