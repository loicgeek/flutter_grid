import 'package:flutter/material.dart';

import 'grid_slots.dart';

class GridEmptyState extends StatelessWidget {
  final GridEmptyContext ctx;

  const GridEmptyState({super.key, required this.ctx});

  @override
  Widget build(BuildContext context) {
    return switch (ctx.reason) {
      EmptyReason.noData => _buildNoData(context),
      EmptyReason.filtered => _buildFiltered(context),
      EmptyReason.searched => _buildSearched(context),
    };
  }

  Widget _buildNoData(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.table_rows_outlined,
              size: 48, color: Colors.grey[400]),
          const SizedBox(height: 12),
          Text('No data available',
              style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 4),
          Text('There are no records to display.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  )),
        ],
      ),
    );
  }

  Widget _buildFiltered(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.filter_alt_off_outlined,
              size: 48, color: Colors.grey[400]),
          const SizedBox(height: 12),
          Text('No matching results',
              style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 4),
          Text('Try adjusting or clearing your filters.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  )),
          if (ctx.onClearFilters != null) ...[
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: ctx.onClearFilters,
              icon: const Icon(Icons.clear_all, size: 16),
              label: const Text('Clear filters'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSearched(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_outlined,
              size: 48, color: Colors.grey[400]),
          const SizedBox(height: 12),
          Text('No search results',
              style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 4),
          Text('No records matched your search query.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  )),
        ],
      ),
    );
  }
}
