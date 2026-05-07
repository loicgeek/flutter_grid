import '../models/external_filter.dart';
import '../models/grid_state.dart';

// All command classes must be in the same library as the sealed class.
// They are defined here to keep the sealed hierarchy intact.

sealed class GridCommand {
  const GridCommand();

  bool get undoable => true;
  GridState? get prevState => null;
  GridCommand withPrevState(GridState state) => this;
}

// ---------------------------------------------------------------------------
// Sort commands
// ---------------------------------------------------------------------------

class SetSortCommand extends GridCommand {
  final List<SortEntry> sorting;
  @override
  final GridState? prevState;

  const SetSortCommand(this.sorting, {this.prevState});

  @override
  GridCommand withPrevState(GridState state) =>
      SetSortCommand(sorting, prevState: state);
}

class ToggleSortCommand extends GridCommand {
  final String columnId;
  final bool multi;
  @override
  final GridState? prevState;

  const ToggleSortCommand(this.columnId,
      {this.multi = false, this.prevState});

  @override
  GridCommand withPrevState(GridState state) =>
      ToggleSortCommand(columnId, multi: multi, prevState: state);
}

class ResetSortCommand extends GridCommand {
  @override
  final GridState? prevState;

  const ResetSortCommand({this.prevState});

  @override
  GridCommand withPrevState(GridState state) =>
      ResetSortCommand(prevState: state);
}

// ---------------------------------------------------------------------------
// Filter commands
// ---------------------------------------------------------------------------

class SetGlobalFilterCommand extends GridCommand {
  final String? filter;
  @override
  final GridState? prevState;

  const SetGlobalFilterCommand(this.filter, {this.prevState});

  @override
  GridCommand withPrevState(GridState state) =>
      SetGlobalFilterCommand(filter, prevState: state);
}

class SetColumnFilterCommand extends GridCommand {
  final String columnId;
  final dynamic value;
  @override
  final GridState? prevState;

  const SetColumnFilterCommand(this.columnId, this.value, {this.prevState});

  @override
  GridCommand withPrevState(GridState state) =>
      SetColumnFilterCommand(columnId, value, prevState: state);
}

class RemoveColumnFilterCommand extends GridCommand {
  final String columnId;
  @override
  final GridState? prevState;

  const RemoveColumnFilterCommand(this.columnId, {this.prevState});

  @override
  GridCommand withPrevState(GridState state) =>
      RemoveColumnFilterCommand(columnId, prevState: state);
}

class ClearAllFiltersCommand extends GridCommand {
  @override
  final GridState? prevState;

  const ClearAllFiltersCommand({this.prevState});

  @override
  GridCommand withPrevState(GridState state) =>
      ClearAllFiltersCommand(prevState: state);
}

// ---------------------------------------------------------------------------
// Pagination commands
// ---------------------------------------------------------------------------

class NextPageCommand extends GridCommand {
  @override
  final GridState? prevState;

  const NextPageCommand({this.prevState});

  @override
  bool get undoable => false;

  @override
  GridCommand withPrevState(GridState state) =>
      NextPageCommand(prevState: state);
}

class PreviousPageCommand extends GridCommand {
  @override
  final GridState? prevState;

  const PreviousPageCommand({this.prevState});

  @override
  bool get undoable => false;

  @override
  GridCommand withPrevState(GridState state) =>
      PreviousPageCommand(prevState: state);
}

class SetPageIndexCommand extends GridCommand {
  final int pageIndex;
  @override
  final GridState? prevState;

  const SetPageIndexCommand(this.pageIndex, {this.prevState});

  @override
  bool get undoable => false;

  @override
  GridCommand withPrevState(GridState state) =>
      SetPageIndexCommand(pageIndex, prevState: state);
}

class SetPageSizeCommand extends GridCommand {
  final int pageSize;
  @override
  final GridState? prevState;

  const SetPageSizeCommand(this.pageSize, {this.prevState});

  @override
  GridCommand withPrevState(GridState state) =>
      SetPageSizeCommand(pageSize, prevState: state);
}

// ---------------------------------------------------------------------------
// Selection commands
// ---------------------------------------------------------------------------

class ToggleRowSelectionCommand extends GridCommand {
  final String rowId;
  @override
  final GridState? prevState;

  const ToggleRowSelectionCommand(this.rowId, {this.prevState});

  @override
  GridCommand withPrevState(GridState state) =>
      ToggleRowSelectionCommand(rowId, prevState: state);
}

class ToggleAllRowsSelectedCommand extends GridCommand {
  final bool? value;
  @override
  final GridState? prevState;

  const ToggleAllRowsSelectedCommand({this.value, this.prevState});

  @override
  GridCommand withPrevState(GridState state) =>
      ToggleAllRowsSelectedCommand(value: value, prevState: state);
}

class ClearRowSelectionCommand extends GridCommand {
  @override
  final GridState? prevState;

  const ClearRowSelectionCommand({this.prevState});

  @override
  GridCommand withPrevState(GridState state) =>
      ClearRowSelectionCommand(prevState: state);
}

class SelectAllPagesCommand extends GridCommand {
  final bool value;
  @override
  final GridState? prevState;

  const SelectAllPagesCommand(this.value, {this.prevState});

  @override
  GridCommand withPrevState(GridState state) =>
      SelectAllPagesCommand(value, prevState: state);
}

// ---------------------------------------------------------------------------
// Row commands
// ---------------------------------------------------------------------------

enum RowPinPosition { top, bottom }

class SetRowExpandedCommand extends GridCommand {
  final String rowId;
  final bool expanded;
  @override
  final GridState? prevState;

  const SetRowExpandedCommand(this.rowId, this.expanded, {this.prevState});

  @override
  GridCommand withPrevState(GridState state) =>
      SetRowExpandedCommand(rowId, expanded, prevState: state);
}

class ToggleAllExpandedCommand extends GridCommand {
  final bool? value;
  @override
  final GridState? prevState;

  const ToggleAllExpandedCommand({this.value, this.prevState});

  @override
  GridCommand withPrevState(GridState state) =>
      ToggleAllExpandedCommand(value: value, prevState: state);
}

class PinRowCommand extends GridCommand {
  final String rowId;
  final RowPinPosition position;
  @override
  final GridState? prevState;

  const PinRowCommand(this.rowId, this.position, {this.prevState});

  @override
  GridCommand withPrevState(GridState state) =>
      PinRowCommand(rowId, position, prevState: state);
}

class UnpinRowCommand extends GridCommand {
  final String rowId;
  @override
  final GridState? prevState;

  const UnpinRowCommand(this.rowId, {this.prevState});

  @override
  GridCommand withPrevState(GridState state) =>
      UnpinRowCommand(rowId, prevState: state);
}

// ---------------------------------------------------------------------------
// Column commands
// ---------------------------------------------------------------------------

enum ColumnPinPosition { left, right }

class ToggleColumnVisibilityCommand extends GridCommand {
  final String columnId;
  @override
  final GridState? prevState;

  const ToggleColumnVisibilityCommand(this.columnId, {this.prevState});

  @override
  GridCommand withPrevState(GridState state) =>
      ToggleColumnVisibilityCommand(columnId, prevState: state);
}

class SetColumnVisibilityCommand extends GridCommand {
  final String columnId;
  final bool visible;
  @override
  final GridState? prevState;

  const SetColumnVisibilityCommand(this.columnId, this.visible,
      {this.prevState});

  @override
  GridCommand withPrevState(GridState state) =>
      SetColumnVisibilityCommand(columnId, visible, prevState: state);
}

class PinColumnCommand extends GridCommand {
  final String columnId;
  final ColumnPinPosition position;
  @override
  final GridState? prevState;

  const PinColumnCommand(this.columnId, this.position, {this.prevState});

  @override
  GridCommand withPrevState(GridState state) =>
      PinColumnCommand(columnId, position, prevState: state);
}

class UnpinColumnCommand extends GridCommand {
  final String columnId;
  @override
  final GridState? prevState;

  const UnpinColumnCommand(this.columnId, {this.prevState});

  @override
  GridCommand withPrevState(GridState state) =>
      UnpinColumnCommand(columnId, prevState: state);
}

class SetColumnOrderCommand extends GridCommand {
  final List<String> order;
  @override
  final GridState? prevState;

  const SetColumnOrderCommand(this.order, {this.prevState});

  @override
  GridCommand withPrevState(GridState state) =>
      SetColumnOrderCommand(order, prevState: state);
}

class SetColumnSizeCommand extends GridCommand {
  final String columnId;
  final double size;
  @override
  final GridState? prevState;

  const SetColumnSizeCommand(this.columnId, this.size, {this.prevState});

  @override
  GridCommand withPrevState(GridState state) =>
      SetColumnSizeCommand(columnId, size, prevState: state);
}

class ResetColumnSizingCommand extends GridCommand {
  @override
  final GridState? prevState;

  const ResetColumnSizingCommand({this.prevState});

  @override
  GridCommand withPrevState(GridState state) =>
      ResetColumnSizingCommand(prevState: state);
}

class SetGroupingCommand extends GridCommand {
  final List<String> grouping;
  @override
  final GridState? prevState;

  const SetGroupingCommand(this.grouping, {this.prevState});

  @override
  GridCommand withPrevState(GridState state) =>
      SetGroupingCommand(grouping, prevState: state);
}

class StartEditingCellCommand extends GridCommand {
  final String cellId;
  @override
  final GridState? prevState;

  const StartEditingCellCommand(this.cellId, {this.prevState});

  @override
  bool get undoable => false;

  @override
  GridCommand withPrevState(GridState state) =>
      StartEditingCellCommand(cellId, prevState: state);
}

class CommitEditCommand extends GridCommand {
  final String cellId;
  final dynamic value;
  @override
  final GridState? prevState;

  const CommitEditCommand(this.cellId, this.value, {this.prevState});

  @override
  GridCommand withPrevState(GridState state) =>
      CommitEditCommand(cellId, value, prevState: state);
}

class CancelEditCommand extends GridCommand {
  @override
  final GridState? prevState;

  const CancelEditCommand({this.prevState});

  @override
  bool get undoable => false;

  @override
  GridCommand withPrevState(GridState state) =>
      CancelEditCommand(prevState: state);
}

// ---------------------------------------------------------------------------
// External filter commands
// ---------------------------------------------------------------------------

/// Sets (or replaces) a single external filter for [field].
///
/// ```dart
/// controller.setExternalFilter(
///   'createdAt',
///   ExternalFilter.gte(DateTime(2024)),
/// );
/// ```
class SetExternalFilterCommand extends GridCommand {
  final String field;
  final ExternalFilter filter;
  @override
  final GridState? prevState;

  const SetExternalFilterCommand(this.field, this.filter, {this.prevState});

  @override
  GridCommand withPrevState(GridState state) =>
      SetExternalFilterCommand(field, filter, prevState: state);
}

/// Removes a single external filter by [field].
class ClearExternalFilterCommand extends GridCommand {
  final String field;
  @override
  final GridState? prevState;

  const ClearExternalFilterCommand(this.field, {this.prevState});

  @override
  GridCommand withPrevState(GridState state) =>
      ClearExternalFilterCommand(field, prevState: state);
}

/// Replaces **all** external filters at once.
///
/// Pass an empty map to clear everything:
/// ```dart
/// controller.dispatch(const SetAllExternalFiltersCommand({}));
/// ```
class SetAllExternalFiltersCommand extends GridCommand {
  final Map<String, ExternalFilter> filters;
  @override
  final GridState? prevState;

  const SetAllExternalFiltersCommand(this.filters, {this.prevState});

  @override
  GridCommand withPrevState(GridState state) =>
      SetAllExternalFiltersCommand(filters, prevState: state);
}
