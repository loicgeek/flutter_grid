import 'dart:async';

import '../commands/grid_command.dart';
import '../middleware/grid_middleware.dart';
import '../models/column_def.dart';
import '../models/grid_state.dart';
import '../models/header_group.dart';
import '../models/row_model.dart';
import '../pipeline/row_model_pipeline.dart';
import 'grid_options.dart';

/// Central controller for a grid instance.
///
/// Holds all [GridState] and exposes typed methods for sorting, filtering,
/// pagination, selection, column management, and undo/redo. Notifies
/// listeners (e.g. [GridBuilder]) whenever state changes.
///
/// ```dart
/// final c = GridController<Person>(
///   options: GridOptions(columns: [...]),
///   initialState: const GridState(
///     pagination: PaginationState(pageSize: 20),
///   ),
/// );
/// c.setData(people);
/// c.toggleSort('name');
/// ```
class GridController<T> {
  final GridOptions<T> options;
  final List<GridMiddleware> middleware;

  GridState _state;
  final List<GridState> _undoStack = [];
  final List<GridState> _redoStack = [];
  bool _isDisposed = false;

  final StreamController<GridState> _stateController =
      StreamController<GridState>.broadcast();
  final List<void Function()> _listeners = [];

  GridController({
    required this.options,
    GridState? initialState,
    this.middleware = const [],
  }) : _state = initialState ?? const GridState() {
    for (final f in options.features) {
      f.init(this);
    }
  }

  GridState get state => _state;
  Stream<GridState> get stateStream => _stateController.stream;

  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  // --- Listener API (Listenable-compatible) ---

  void addListener(void Function() listener) {
    _listeners.add(listener);
  }

  void removeListener(void Function() listener) {
    _listeners.remove(listener);
  }

  void _notifyListeners() {
    if (_isDisposed) return;
    _stateController.add(_state);
    for (final l in _listeners) {
      l();
    }
  }

  // --- Dispatch ---

  void dispatch(GridCommand command) {
    if (_isDisposed) return;

    for (final m in middleware) {
      m.beforeDispatch(command, _state);
    }

    final prevState = _state;
    final cmd = command.withPrevState(prevState);
    final nextState = _reduce(_state, cmd);

    if (cmd.undoable && nextState != _state) {
      _undoStack.add(_state);
      _redoStack.clear();
    }

    _state = nextState;

    for (final m in middleware) {
      m.afterDispatch(cmd, prevState, _state);
    }

    _notifyListeners();
  }

  void undo() {
    if (_undoStack.isEmpty) return;
    _redoStack.add(_state);
    _state = _undoStack.removeLast();
    _notifyListeners();
  }

  void redo() {
    if (_redoStack.isEmpty) return;
    _undoStack.add(_state);
    _state = _redoStack.removeLast();
    _notifyListeners();
  }

  // --- State reducer ---

  static const _defaultMinColumnWidth = 80.0;

  Map<String, num> resolveColumnWidths(double availableWidth) {
    final cols = _buildColumns();

    double fixedWidth = 0;
    int autoCount = 0;

    for (final c in cols) {
      if (c.def.size == null) {
        autoCount++;
      } else {
        fixedWidth += c.def.size!;
      }
    }

    final remaining = (availableWidth - fixedWidth).clamp(0, double.infinity);
    final rawAutoWidth = autoCount == 0 ? 0.0 : remaining / autoCount;

    return {
      for (final c in cols)
        c.id: c.def.size != null
            ? c.def.size!.clamp(
                c.def.minSize ?? 0,
                c.def.maxSize ?? double.infinity,
              )
            : rawAutoWidth.clamp(
                c.def.minSize ?? _defaultMinColumnWidth,
                c.def.maxSize ?? double.infinity,
              ),
    };
  }

  GridState _reduce(GridState state, GridCommand command) {
    return switch (command) {
      // Sort
      SetSortCommand c => state.copyWith(sorting: c.sorting),
      ToggleSortCommand c => _toggleSort(state, c),
      ResetSortCommand _ => state.copyWith(sorting: []),

      // Filter
      SetGlobalFilterCommand c => c.filter == null || c.filter!.isEmpty
          ? state.copyWith(clearGlobalFilter: true)
          : state.copyWith(globalFilter: c.filter),
      SetColumnFilterCommand c => state.copyWith(
          columnFilters: {...state.columnFilters, c.columnId: c.value},
          pagination: state.pagination.copyWith(pageIndex: 0),
        ),
      RemoveColumnFilterCommand c => state.copyWith(
          columnFilters: Map.from(state.columnFilters)..remove(c.columnId),
        ),
      ClearAllFiltersCommand _ => state.copyWith(
          columnFilters: {},
          clearGlobalFilter: true,
        ),

      // Pagination
      NextPageCommand _ => state.copyWith(
          pagination: state.pagination
              .copyWith(pageIndex: state.pagination.pageIndex + 1),
        ),
      PreviousPageCommand _ => state.copyWith(
          pagination: state.pagination.copyWith(
              pageIndex: (state.pagination.pageIndex - 1).clamp(0, 999999)),
        ),
      SetPageIndexCommand c => state.copyWith(
          pagination: state.pagination.copyWith(pageIndex: c.pageIndex)),
      SetPageSizeCommand c => state.copyWith(
          pagination: PaginationState(pageIndex: 0, pageSize: c.pageSize),
        ),

      // Selection
      ToggleRowSelectionCommand c => _toggleRowSelection(state, c.rowId),
      ToggleAllRowsSelectedCommand c => _toggleAllRows(state, c.value),
      ClearRowSelectionCommand _ =>
        state.copyWith(rowSelection: {}, selectAllPages: false),
      SelectAllPagesCommand c => state.copyWith(selectAllPages: c.value),

      // Row expand/pin
      SetRowExpandedCommand c => state.copyWith(
          expanded: {...state.expanded, c.rowId: c.expanded},
        ),
      ToggleAllExpandedCommand c => _toggleAllExpanded(state, c.value),
      PinRowCommand c => _pinRow(state, c),
      UnpinRowCommand c => _unpinRow(state, c.rowId),

      // Column visibility
      ToggleColumnVisibilityCommand c => state.copyWith(
          columnVisibility: {
            ...state.columnVisibility,
            c.columnId: !(state.columnVisibility[c.columnId] ?? true),
          },
        ),
      SetColumnVisibilityCommand c => state.copyWith(
          columnVisibility: {
            ...state.columnVisibility,
            c.columnId: c.visible,
          },
        ),

      // Column pin
      PinColumnCommand c => _pinColumn(state, c),
      UnpinColumnCommand c => _unpinColumn(state, c.columnId),

      // Column order
      SetColumnOrderCommand c => state.copyWith(columnOrder: c.order),

      // Column sizing
      SetColumnSizeCommand c => state.copyWith(
          columnSizing: {...state.columnSizing, c.columnId: c.size},
        ),
      ResetColumnSizingCommand _ => state.copyWith(columnSizing: {}),

      // Grouping
      SetGroupingCommand c => state.copyWith(grouping: c.grouping),

      // Editing
      StartEditingCellCommand c => state.copyWith(editingCellId: c.cellId),
      CommitEditCommand _ => state.copyWith(clearEditingCell: true),
      CancelEditCommand _ => state.copyWith(clearEditingCell: true),
    };
  }

  GridState _toggleSort(GridState state, ToggleSortCommand cmd) {
    final existing =
        state.sorting.where((s) => s.columnId == cmd.columnId).firstOrNull;
    List<SortEntry> newSorting;

    if (existing == null) {
      // Not sorted — sort ascending
      final entry = SortEntry(columnId: cmd.columnId, descending: false);
      newSorting = cmd.multi ? [...state.sorting, entry] : [entry];
    } else if (!existing.descending) {
      // Ascending — go descending
      final entry = SortEntry(columnId: cmd.columnId, descending: true);
      newSorting = cmd.multi
          ? state.sorting
              .map((s) => s.columnId == cmd.columnId ? entry : s)
              .toList()
          : [entry];
    } else {
      // Descending — clear this sort
      newSorting =
          state.sorting.where((s) => s.columnId != cmd.columnId).toList();
    }
    return state.copyWith(sorting: newSorting);
  }

  GridState _toggleRowSelection(GridState state, String rowId) {
    final current = state.rowSelection[rowId] ?? false;
    if (!state.enableMultiRowSelection) {
      // Single select: clear others, set this one
      return state.copyWith(rowSelection: {rowId: !current});
    }
    return state.copyWith(
      rowSelection: {...state.rowSelection, rowId: !current},
    );
  }

  GridState _toggleAllRows(GridState state, bool? value) {
    // We don't have data here — caller should pre-fill rowIds.
    // For simple toggle: if value is null, determine from current state.
    // This is handled by the controller helper below.
    return state;
  }

  GridState _toggleAllExpanded(GridState state, bool? value) {
    // Caller handles this via helper — can't access data here.
    return state;
  }

  GridState _pinRow(GridState state, PinRowCommand cmd) {
    final top = List<String>.from(state.rowPinning.top)..remove(cmd.rowId);
    final bottom = List<String>.from(state.rowPinning.bottom)
      ..remove(cmd.rowId);
    if (cmd.position == RowPinPosition.top) {
      top.add(cmd.rowId);
    } else {
      bottom.add(cmd.rowId);
    }
    return state.copyWith(
        rowPinning: RowPinningState(top: top, bottom: bottom));
  }

  GridState _unpinRow(GridState state, String rowId) {
    return state.copyWith(
      rowPinning: RowPinningState(
        top: state.rowPinning.top.where((id) => id != rowId).toList(),
        bottom: state.rowPinning.bottom.where((id) => id != rowId).toList(),
      ),
    );
  }

  GridState _pinColumn(GridState state, PinColumnCommand cmd) {
    final left = List<String>.from(state.columnPinning.left)
      ..remove(cmd.columnId);
    final right = List<String>.from(state.columnPinning.right)
      ..remove(cmd.columnId);
    if (cmd.position == ColumnPinPosition.left) {
      left.add(cmd.columnId);
    } else {
      right.add(cmd.columnId);
    }
    return state.copyWith(
        columnPinning: ColumnPinningState(left: left, right: right));
  }

  GridState _unpinColumn(GridState state, String columnId) {
    return state.copyWith(
      columnPinning: ColumnPinningState(
        left: state.columnPinning.left.where((id) => id != columnId).toList(),
        right: state.columnPinning.right.where((id) => id != columnId).toList(),
      ),
    );
  }

  // --- Computed views ---

  List<ColumnInfo<T, Object?>> _buildColumns() {
    final flatCols = options.flatColumns;
    final order = _state.columnOrder.isNotEmpty
        ? _state.columnOrder
        : flatCols.map((c) => c.id).toList();

    return order
        .map((id) => flatCols.where((c) => c.id == id).firstOrNull)
        .whereType<ColumnDef<T, Object?>>()
        .map((col) {
      final visible = _state.columnVisibility[col.id] ?? true;
      return ColumnInfo<T, Object?>(
        def: col,
        id: col.id,
        isVisible: visible,
        isPinnedLeft: _state.columnPinning.left.contains(col.id),
        isPinnedRight: _state.columnPinning.right.contains(col.id),
        effectiveWidth: _state.columnSizing[col.id] ?? col.size,
        orderIndex: order.indexOf(col.id),
      );
    }).toList();
  }

  List<HeaderGroup<T>> _buildHeaderGroups(
      List<ColumnInfo<T, Object?>> columns) {
    final headers =
        columns.map((col) => Header<T>(id: col.id, column: col)).toList();
    return [HeaderGroup(id: 'headers', headers: headers, depth: 0)];
  }

  RowModelSet<T> _buildRowModels(List<T> data) {
    return RowModelPipeline<T>(
      state: _state,
      columns: options.flatColumns,
      controller: this,
      getRowId: options.getRowId,
      getSubRows: options.getSubRows,
    ).build(data);
  }

  // --- Public helpers ---

  List<ColumnInfo<T, Object?>> getAllColumns() => _buildColumns();

  List<ColumnInfo<T, Object?>> getVisibleColumns() =>
      _buildColumns().where((c) => c.isVisible).toList();

  List<ColumnInfo<T, Object?>> getLeftPinnedColumns() =>
      _buildColumns().where((c) => c.isPinnedLeft && c.isVisible).toList();

  List<ColumnInfo<T, Object?>> getRightPinnedColumns() =>
      _buildColumns().where((c) => c.isPinnedRight && c.isVisible).toList();

  List<ColumnInfo<T, Object?>> getCenterColumns() =>
      _buildColumns().where((c) => !c.isPinned && c.isVisible).toList();

  List<HeaderGroup<T>> getHeaderGroups() {
    final cols = _buildColumns();
    return _buildHeaderGroups(cols);
  }

  RowModelSet<T> getRowModels({List<T>? data}) {
    return _buildRowModels(data ?? _data);
  }

  List<T> _data = [];

  void setData(List<T> data) {
    _data = data;
    _notifyListeners();
  }

  /// Sets data and updates [pageCount] in a single notification.
  /// Use this from server-side datasources so the pagination widget
  /// reflects the correct total pages.
  void setDataWithPageCount(List<T> data, int pageCount) {
    _data = data;
    _state = _state.copyWith(pageCount: pageCount);
    _notifyListeners();
  }

  // --- Convenience dispatch methods ---

  void toggleSort(String columnId, {bool multi = false}) =>
      dispatch(ToggleSortCommand(columnId, multi: multi));

  void setSort(List<SortEntry> sorting) => dispatch(SetSortCommand(sorting));

  void resetSort() => dispatch(const ResetSortCommand());

  void setGlobalFilter(String? filter) =>
      dispatch(SetGlobalFilterCommand(filter));

  void setColumnFilter(String columnId, dynamic value) =>
      dispatch(SetColumnFilterCommand(columnId, value));

  void removeColumnFilter(String columnId) =>
      dispatch(RemoveColumnFilterCommand(columnId));

  void clearAllFilters() => dispatch(const ClearAllFiltersCommand());

  void nextPage() => dispatch(const NextPageCommand());

  void previousPage() => dispatch(const PreviousPageCommand());

  void setPageIndex(int index) => dispatch(SetPageIndexCommand(index));

  void setPageSize(int size) => dispatch(SetPageSizeCommand(size));

  void toggleRowSelection(String rowId) =>
      dispatch(ToggleRowSelectionCommand(rowId));

  void clearRowSelection() => dispatch(const ClearRowSelectionCommand());

  void toggleAllRowsSelected({bool? value}) {
    final rows = _buildRowModels(_data);
    final allSelected =
        rows.pageRows.every((r) => _state.rowSelection[r.id] == true);
    final target = value ?? !allSelected;
    final newSelection = Map<String, bool>.from(_state.rowSelection);
    for (final row in rows.pageRows) {
      newSelection[row.id] = target;
    }
    _state = _state.copyWith(rowSelection: newSelection, selectAllPages: false);
    _notifyListeners();
  }

  void selectAllPages(bool selected) {
    if (selected) {
      // Mark all current local rows as selected first
      final rows = _buildRowModels(_data);
      final newSelection = Map<String, bool>.from(_state.rowSelection);
      for (final row in rows.allRows) {
        newSelection[row.id] = true;
      }
      _state = _state.copyWith(rowSelection: newSelection);
    }
    dispatch(SelectAllPagesCommand(selected));
  }

  void toggleColumnVisibility(String columnId) =>
      dispatch(ToggleColumnVisibilityCommand(columnId));

  void setColumnVisibility(String columnId, bool visible) =>
      dispatch(SetColumnVisibilityCommand(columnId, visible));

  void pinColumn(String columnId, ColumnPinPosition position) =>
      dispatch(PinColumnCommand(columnId, position));

  void unpinColumn(String columnId) => dispatch(UnpinColumnCommand(columnId));

  void setColumnOrder(List<String> order) =>
      dispatch(SetColumnOrderCommand(order));

  void setColumnSize(String columnId, double size) =>
      dispatch(SetColumnSizeCommand(columnId, size));

  void resetColumnSizing() => dispatch(const ResetColumnSizingCommand());

  void pinRow(String rowId, String position) {
    final pos = position == 'top' ? RowPinPosition.top : RowPinPosition.bottom;
    dispatch(PinRowCommand(rowId, pos));
  }

  void unpinRow(String rowId) => dispatch(UnpinRowCommand(rowId));

  void toggleRowExpanded(String rowId) {
    final current = _state.expanded[rowId] ?? false;
    dispatch(SetRowExpandedCommand(rowId, !current));
  }

  void setGrouping(List<String> grouping) =>
      dispatch(SetGroupingCommand(grouping));

  void startEditingCell(String cellId) =>
      dispatch(StartEditingCellCommand(cellId));

  void cancelEdit() => dispatch(const CancelEditCommand());

  /// Executes a command optimistically and rolls it back if the [action] throws.
  Future<void> executeOptimistic(
    GridCommand command,
    Future<void> Function() action,
  ) async {
    dispatch(command);
    try {
      await action();
    } catch (e) {
      undo();
      rethrow;
    }
  }

  // Will be called by grid_flutter data sources
  void refresh() {
    _notifyListeners();
  }

  void dispose() {
    _isDisposed = true;
    for (final f in options.features) {
      f.dispose();
    }
    for (final m in middleware) {
      m.dispose();
    }
    _stateController.close();
    _listeners.clear();
  }
}
