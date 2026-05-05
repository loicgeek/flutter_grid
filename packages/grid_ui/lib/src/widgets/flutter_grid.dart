import 'package:flutter/material.dart';
import 'package:grid_core/grid_core.dart';
import 'package:grid_flutter/grid_flutter.dart';

import '../components/grid_bulk_action_bar.dart';
import '../components/grid_filter_bar.dart';
import '../slots/grid_empty_state.dart';
import '../slots/grid_error_state.dart';
import '../slots/grid_loading_state.dart';
import '../slots/grid_pagination.dart';
import '../slots/grid_slots.dart';
import '../slots/grid_toolbar.dart';
import 'grid_data_table.dart';

/// The main high-level grid widget.
///
/// [FlutterGrid] wires a [GridController] to the full UI stack: toolbar,
/// filter bar, bulk-action bar, data table (or mobile list), and pagination.
///
/// ```dart
/// FlutterGrid<Person>(
///   controller: controller,
///   fillWidth: true,
///   striped: true,
///   enableHapticFeedback: true,
///   onRowTap: (row) => controller.toggleRowSelection(row.id),
/// )
/// ```
class FlutterGrid<T> extends StatefulWidget {
  final GridController<T> controller;
  final GridDataSource<T>? dataSource;
  final Future<GridPage<T>> Function(GridQuery query)? fetchData;

  final GridSlots<T>? slots;
  final Widget Function(BuildContext, RowModel<T>)? rowBuilder;

  final bool showToolbar;
  final bool showFilterBar;
  final bool showPagination;
  final bool showColumnBorders;
  final bool striped;

  /// When true the table expands to fill available horizontal space.
  final bool fillWidth;

  /// When true the grid sizes itself to its content height so it can be
  /// embedded inside a parent scrollable (e.g. [ListView],
  /// [SingleChildScrollView], [CustomScrollView]).
  ///
  /// The sticky header and internal vertical scroll are disabled; the parent
  /// scroll view controls the viewport.
  final bool shrinkWrap;

  /// When true fires [HapticFeedback.lightImpact] when a row becomes selected.
  final bool enableHapticFeedback;

  final double? rowHeight;
  final double breakpoint;

  final void Function(RowModel<T>)? onRowTap;
  final void Function(RowModel<T>)? onRowDoubleTap;
  final void Function(RowModel<T>)? onRowLongPress;

  const FlutterGrid({
    super.key,
    required this.controller,
    this.dataSource,
    this.fetchData,
    this.slots,
    this.rowBuilder,
    this.showToolbar = true,
    this.showFilterBar = true,
    this.showPagination = true,
    this.showColumnBorders = false,
    this.striped = true,
    this.fillWidth = false,
    this.shrinkWrap = false,
    this.enableHapticFeedback = false,
    this.rowHeight,
    this.breakpoint = 600,
    this.onRowTap,
    this.onRowDoubleTap,
    this.onRowLongPress,
  });

  @override
  State<FlutterGrid<T>> createState() => _FlutterGridState<T>();
}

class _FlutterGridState<T> extends State<FlutterGrid<T>> {
  GridDataSource<T>? _dataSource;

  @override
  void initState() {
    super.initState();
    _dataSource = widget.dataSource ??
        (widget.fetchData != null
            ? _FetchDataSource<T>(widget.fetchData!)
            : null);
  }

  @override
  Widget build(BuildContext context) {
    return GridBuilder<T>(
      controller: widget.controller,
      dataSource: _dataSource,
      builder: (context, table) {
        // Loading state (only when no data yet)
        if (table.isLoading && table.pageRows.isEmpty) {
          return widget.slots?.loadingState?.call(context) ??
              GridLoadingState(columns: widget.controller.options.flatColumns);
        }

        // Error state (only when no data to show)
        if (table.error != null && table.pageRows.isEmpty) {
          return widget.slots?.errorState
                  ?.call(context, table.error!, widget.controller.refresh) ??
              GridErrorState(
                error: table.error!,
                onRetry: widget.controller.refresh,
              );
        }

        final body = _buildBody(context, table);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize:
              widget.shrinkWrap ? MainAxisSize.min : MainAxisSize.max,
          children: [
            // Toolbar
            if (widget.showToolbar)
              widget.slots?.toolbar?.call(context, table) ??
                  GridToolbar(controller: widget.controller),

            // Filter chips bar
            if (widget.showFilterBar)
              GridFilterBar(controller: widget.controller),

            // Bulk action bar
            GridBulkActionBarSlot(
              controller: widget.controller,
              slots: widget.slots,
              table: table,
            ),

            // Body — expanded when the grid owns its scroll, intrinsic when
            // embedded in a parent scrollable.
            if (widget.shrinkWrap) body else Expanded(child: body),

            // Pagination
            if (widget.showPagination)
              widget.slots?.pagination?.call(context, table) ??
                  GridPagination(controller: widget.controller),
          ],
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, GridTableState<T> table) {
    final width = MediaQuery.of(context).size.width;
    final isSmall = width < widget.breakpoint;

    if (table.pageRows.isEmpty) {
      final reason = table.state.hasActiveFilters
          ? EmptyReason.filtered
          : (table.state.globalFilter?.isNotEmpty == true
              ? EmptyReason.searched
              : EmptyReason.noData);
      final ctx = GridEmptyContext(
        reason: reason,
        onClearFilters: table.state.hasActiveFilters
            ? widget.controller.clearAllFilters
            : null,
      );
      return widget.slots?.emptyState?.call(context, ctx) ??
          GridEmptyState(ctx: ctx);
    }

    if (isSmall && widget.rowBuilder != null) {
      return _buildMobileList(context, table);
    }

    return _buildDesktopTable(context, table);
  }

  Widget _buildMobileList(BuildContext context, GridTableState<T> table) {
    return ListView.builder(
      itemCount: table.pageRows.length,
      itemBuilder: (context, index) {
        final row = table.pageRows[index];
        return InkWell(
          onTap: widget.onRowTap != null ? () => widget.onRowTap!(row) : null,
          onDoubleTap: widget.onRowDoubleTap != null
              ? () => widget.onRowDoubleTap!(row)
              : null,
          onLongPress: widget.onRowLongPress != null
              ? () => widget.onRowLongPress!(row)
              : null,
          child: widget.rowBuilder!(context, row),
        );
      },
    );
  }

  Widget _buildDesktopTable(BuildContext context, GridTableState<T> table) {
    return GridDataTable<T>(
      controller: widget.controller,
      table: table,
      showColumnBorders: widget.showColumnBorders,
      striped: widget.striped,
      fillWidth: widget.fillWidth,
      shrinkWrap: widget.shrinkWrap,
      enableHapticFeedback: widget.enableHapticFeedback,
      rowHeight: widget.rowHeight,
      onRowTap: widget.onRowTap,
      onRowDoubleTap: widget.onRowDoubleTap,
      onRowLongPress: widget.onRowLongPress,
      slots: widget.slots,
    );
  }
}

/// Adapts a fetchData callback to [GridDataSource].
class _FetchDataSource<T> extends GridDataSource<T> {
  final Future<GridPage<T>> Function(GridQuery query) fetchData;

  _FetchDataSource(this.fetchData);

  @override
  Future<GridPage<T>> fetch(GridQuery query) => fetchData(query);
}
