import 'column_def.dart';

/// Represents a processed column with state applied.
class ColumnInfo<T, V> {
  final ColumnDef<T, V> def;
  final String id;
  final bool isVisible;
  final bool isPinnedLeft;
  final bool isPinnedRight;
  final double effectiveWidth;
  final int orderIndex;

  const ColumnInfo({
    required this.def,
    required this.id,
    required this.isVisible,
    required this.isPinnedLeft,
    required this.isPinnedRight,
    required this.effectiveWidth,
    required this.orderIndex,
  });

  bool get isPinned => isPinnedLeft || isPinnedRight;
}

/// A cell value in a row.
class CellModel<T, V> {
  final RowModel<T> row;
  final ColumnInfo<T, V> column;
  final V? value;

  const CellModel({
    required this.row,
    required this.column,
    required this.value,
  });

  String get cellId => '${row.id}_${column.id}';
}

/// A processed row model.
class RowModel<T> {
  final String id;
  final T original;
  final int index;
  final int originalIndex;
  final bool isSelected;
  final bool isExpanded;
  final bool isPinnedTop;
  final bool isPinnedBottom;
  final List<RowModel<T>> subRows;
  final int depth;
  final RowModel<T>? parentRow;
  
  final bool isGrouped;
  final bool isAggregated;
  final String? groupingColumnId;
  final dynamic groupingValue;

  // Controller reference — set after construction by pipeline
  final dynamic
      _controller; // GridController<T> — dynamic to avoid circular import in pipeline

  RowModel({
    required this.id,
    required this.original,
    required this.index,
    this.originalIndex = -1,
    this.isSelected = false,
    this.isExpanded = false,
    this.isPinnedTop = false,
    this.isPinnedBottom = false,
    this.subRows = const [],
    this.depth = 0,
    this.parentRow,
    this.isGrouped = false,
    this.isAggregated = false,
    this.groupingColumnId,
    this.groupingValue,
    dynamic controller,
  }) : _controller = controller;

  RowModel<T> copyWith({
    String? id,
    T? original,
    int? index,
    int? originalIndex,
    bool? isSelected,
    bool? isExpanded,
    bool? isPinnedTop,
    bool? isPinnedBottom,
    List<RowModel<T>>? subRows,
    int? depth,
    RowModel<T>? parentRow,
    bool? isGrouped,
    bool? isAggregated,
    String? groupingColumnId,
    dynamic groupingValue,
    dynamic controller,
  }) {
    return RowModel<T>(
      id: id ?? this.id,
      original: original ?? this.original,
      index: index ?? this.index,
      originalIndex: originalIndex ?? this.originalIndex,
      isSelected: isSelected ?? this.isSelected,
      isExpanded: isExpanded ?? this.isExpanded,
      isPinnedTop: isPinnedTop ?? this.isPinnedTop,
      isPinnedBottom: isPinnedBottom ?? this.isPinnedBottom,
      subRows: subRows ?? this.subRows,
      depth: depth ?? this.depth,
      parentRow: parentRow ?? this.parentRow,
      isGrouped: isGrouped ?? this.isGrouped,
      isAggregated: isAggregated ?? this.isAggregated,
      groupingColumnId: groupingColumnId ?? this.groupingColumnId,
      groupingValue: groupingValue ?? this.groupingValue,
      controller: controller ?? _controller,
    );
  }

  List<CellModel<T, dynamic>> getVisibleCells(
      List<ColumnInfo<T, Object?>> columns) {
    return columns.where((col) => col.isVisible).map((col) {
      final value = col.def.accessorFn?.call(original);
      return CellModel<T, dynamic>(row: this, column: col, value: value);
    }).toList();
  }

  void toggleSelected() {
    _controller?.toggleRowSelection(id);
  }

  void toggleExpanded() {
    _controller?.toggleRowExpanded(id);
  }

  void pinTop() {
    _controller?.pinRow(id, 'top');
  }

  void pinBottom() {
    _controller?.pinRow(id, 'bottom');
  }

  void unpin() {
    _controller?.unpinRow(id);
  }
}

/// The result set of processed rows.
class RowModelSet<T> {
  final List<RowModel<T>> allRows;
  final List<RowModel<T>> filteredRows;
  final List<RowModel<T>> pageRows;
  final List<RowModel<T>> topPinnedRows;
  final List<RowModel<T>> bottomPinnedRows;
  final int totalRows;
  final int totalPages;

  const RowModelSet({
    required this.allRows,
    required this.filteredRows,
    required this.pageRows,
    required this.topPinnedRows,
    required this.bottomPinnedRows,
    required this.totalRows,
    required this.totalPages,
  });
}
