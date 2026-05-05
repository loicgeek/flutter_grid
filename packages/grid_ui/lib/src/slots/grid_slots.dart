import 'package:flutter/widgets.dart';
import 'package:grid_core/grid_core.dart';
import 'package:grid_flutter/grid_flutter.dart';

enum EmptyReason { noData, filtered, searched }

class GridEmptyContext {
  final EmptyReason reason;
  final VoidCallback? onClearFilters;

  const GridEmptyContext({required this.reason, this.onClearFilters});
}

/// Slot callbacks for customizing grid UI sections.
class GridSlots<T> {
  final Widget Function(BuildContext)? loadingState;
  final Widget Function(BuildContext, String error, VoidCallback onRetry)?
      errorState;
  final Widget Function(BuildContext, GridEmptyContext)? emptyState;
  final Widget Function(BuildContext, GridTableState<T>)? toolbar;
  final Widget Function(BuildContext, GridTableState<T>)? pagination;
  final Widget Function(BuildContext, GridTableState<T>)? bulkActionBar;
  final Widget Function(BuildContext, GridTableState<T>)? aggregationFooter;
  final Widget Function(BuildContext, RowModel<T> row)? rowLeading;
  final Widget Function(BuildContext, RowModel<T> row)? rowTrailing;

  const GridSlots({
    this.loadingState,
    this.errorState,
    this.emptyState,
    this.toolbar,
    this.pagination,
    this.bulkActionBar,
    this.aggregationFooter,
    this.rowLeading,
    this.rowTrailing,
  });
}
