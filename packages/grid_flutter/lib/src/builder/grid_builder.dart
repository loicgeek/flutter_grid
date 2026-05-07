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
///
/// ## Fetch lifecycle
///
/// Every time the controller state changes (sort, filter, page, external
/// filters…) [GridBuilder] calls [GridDataSource.fetch] with a fresh
/// [GridQuery] built from the **latest** state.
///
/// ### Race-condition safety — epoch cancellation
///
/// Rapid successive changes (e.g. user applies a filter and immediately clicks
/// next-page before the first response arrives) are handled via an internal
/// epoch counter:
///
/// - Each new fetch increments `_epoch`.
/// - When a response arrives it checks whether its epoch still matches the
///   current one; if not, the response is silently discarded.
/// - The **last issued** fetch always wins — stale responses never overwrite
///   newer data.
///
/// This replaces the old `_isFetching` guard that used to silently drop
/// state changes that arrived while a fetch was in progress.
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
  // ── Epoch-based cancellation ──────────────────────────────────────────────
  //
  // Incremented on every fetch attempt. A response whose captured epoch no
  // longer matches _epoch is stale and discarded.
  int _epoch = 0;

  // ── Re-entrancy guard ─────────────────────────────────────────────────────
  //
  // setDataWithPageCountAndTotalItems() calls _notifyListeners() synchronously,
  // which would immediately trigger _onControllerChanged() → _fetch() → infinite
  // loop. We raise this flag before calling setData and check it at the top of
  // _onControllerChanged to break the cycle.
  bool _settingData = false;

  bool _isLoading = false;
  String? _error;
  StreamSubscription<List<T>>? _watchSub;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
    _fetch();
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
      _watchSub = null;
      _fetch();
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    _watchSub?.cancel();
    // Invalidate any in-flight fetch so its completion callback is a no-op.
    _epoch++;
    super.dispose();
  }

  void _onControllerChanged() {
    if (_settingData) return;
    if (mounted) {
      _fetch();
      setState(() {});
    }
  }

  // ── Core fetch ────────────────────────────────────────────────────────────

  Future<void> _fetch() async {
    final ds = widget.dataSource;
    if (ds == null) return;

    // Capture the epoch for this specific fetch attempt.
    // Any previously in-flight fetch now has a stale epoch and will be ignored
    // when it eventually completes.
    final epoch = ++_epoch;

    // Wire up streaming watch once (only if not already subscribed).
    if (_watchSub == null) {
      final watchStream = ds.watch(widget.controller.state.toQuery());
      if (watchStream != null) {
        _watchSub = watchStream.listen((data) {
          widget.controller.setData(data);
        });
      }
    }

    if (mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      // Snapshot the query from the **current** state at the moment this fetch
      // was triggered. Subsequent state changes will start a new fetch with a
      // higher epoch — their responses will win.
      final query = widget.controller.state.toQuery();
      final page = await ds.fetch(query);

      // Stale check — a newer fetch was started after us; discard our result.
      if (epoch != _epoch) return;

      _settingData = true;
      widget.controller.setDataWithPageCountAndTotalItems(
        page.data,
        page.computedTotalPages,
        totalItems: page.totalItems,
      );
      _settingData = false;

      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      // Discard errors from stale fetches too.
      if (epoch != _epoch) return;

      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString();
        });
      }
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

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
