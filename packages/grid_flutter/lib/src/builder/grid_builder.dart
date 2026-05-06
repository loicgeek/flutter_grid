import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:grid_core/grid_core.dart';

/// The state exposed to [GridBuilder]'s builder callback.
class GridTableState<T> {
  final GridController<T> controller;
  final GridState state;
  final RowModelSet<T> _rowModelSet;
  final List<ColumnInfo<T, Object?>> allColumns;
  final List<ColumnInfo<T, Object?>> visibleColumns;
  final List<ColumnInfo<T, Object?>> leftPinnedColumns;
  final List<ColumnInfo<T, Object?>> centerColumns;
  final List<ColumnInfo<T, Object?>> rightPinnedColumns;
  final List<HeaderGroup<T>> headerGroups;
  final bool isLoading;
  final String? error;

  const GridTableState({
    required this.controller,
    required this.state,
    required RowModelSet<T> rowModelSet,
    required this.allColumns,
    required this.visibleColumns,
    required this.leftPinnedColumns,
    required this.centerColumns,
    required this.rightPinnedColumns,
    required this.headerGroups,
    required this.isLoading,
    this.error,
  }) : _rowModelSet = rowModelSet;

  List<RowModel<T>> get pageRows => _rowModelSet.pageRows;
  List<RowModel<T>> get filteredRows => _rowModelSet.filteredRows;
  List<RowModel<T>> get allRows => _rowModelSet.allRows;
  List<RowModel<T>> get topPinnedRows => _rowModelSet.topPinnedRows;
  List<RowModel<T>> get bottomPinnedRows => _rowModelSet.bottomPinnedRows;
  int get totalRows => _rowModelSet.totalRows;
  int get totalPages => _rowModelSet.totalPages;
}

/// Connects a [GridController] (and optionally a [GridDataSource]) to the
/// widget tree, rebuilding whenever the controller notifies.
class GridBuilder<T> extends StatefulWidget {
  final GridController<T> controller;
  final GridDataSource<T>? dataSource;
  final Widget Function(BuildContext context, GridTableState<T> table) builder;

  const GridBuilder({
    super.key,
    required this.controller,
    this.dataSource,
    required this.builder,
  });

  @override
  State<GridBuilder<T>> createState() => _GridBuilderState<T>();
}

class _GridBuilderState<T> extends State<GridBuilder<T>> {
  bool _isLoading = false;
  String? _error;
  bool _isFetching = false;
  StreamSubscription<List<T>>? _watchSub;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
    _fetchIfNeeded();
  }

  @override
  void didUpdateWidget(GridBuilder<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onControllerChanged);
      widget.controller.addListener(_onControllerChanged);
    }
    if (oldWidget.dataSource != widget.dataSource) {
      _watchSub?.cancel();
      _fetchIfNeeded();
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    _watchSub?.cancel();
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) {
      _fetchIfNeeded();
      setState(() {});
    }
  }

  Future<void> _fetchIfNeeded() async {
    final ds = widget.dataSource;
    if (ds == null) return;
    // Guard against re-entrant calls triggered by setData/setDataWithPageCount
    // notifying listeners while a fetch is already in progress.
    if (_isFetching) return;

    // Try watch first (streaming)
    final watchStream = ds.watch(widget.controller.state.toQuery());
    if (watchStream != null && _watchSub == null) {
      _watchSub = watchStream.listen((data) {
        widget.controller.setData(data);
      });
    }

    _isFetching = true;
    if (mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }
    try {
      final query = widget.controller.state.toQuery();
      final page = await ds.fetch(query);
      widget.controller.setDataWithPageCountAndTotalItems(
        page.data,
        page.computedTotalPages,
        totalItems: page.totalItems,
      );
      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString();
        });
      }
    } finally {
      _isFetching = false;
    }
  }

  GridTableState<T> _buildTableState() {
    final c = widget.controller;
    final rowSet = c.getRowModels();
    final allCols = c.getAllColumns();
    return GridTableState<T>(
      controller: c,
      state: c.state,
      rowModelSet: rowSet,
      allColumns: allCols,
      visibleColumns: c.getVisibleColumns(),
      leftPinnedColumns: c.getLeftPinnedColumns(),
      centerColumns: c.getCenterColumns(),
      rightPinnedColumns: c.getRightPinnedColumns(),
      headerGroups: c.getHeaderGroups(),
      isLoading: _isLoading,
      error: _error,
    );
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _buildTableState());
  }
}
