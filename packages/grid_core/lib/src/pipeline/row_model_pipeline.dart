import '../models/column_def.dart';
import '../models/grid_state.dart';
import '../models/row_model.dart';
import 'filter_stage.dart';
import 'sort_stage.dart';

class RowModelPipeline<T> {
  final GridState state;
  final List<ColumnDef<T, dynamic>> columns;
  final dynamic controller; // GridController<T> — dynamic to avoid circular ref
  final String Function(T row, int index)? getRowId;
  final List<T> Function(T row)? getSubRows;

  RowModelPipeline({
    required this.state,
    required this.columns,
    required this.controller,
    this.getRowId,
    this.getSubRows,
  });

  RowModelSet<T> build(List<T> data) {
    final allRawRows = _toRowModels(data, depth: 0);

    // 1. Filtering
    List<T> filtered = data;
    if (!state.manualFiltering) {
      filtered = FilterStage<T>().apply(data, state, columns);
    }

    // 2. Sorting
    List<T> sorted = filtered;
    if (!state.manualSorting) {
      sorted = SortStage<T>().apply(filtered, state, columns);
    }

    final filteredRows = _toRowModels(sorted, depth: 0);

    // 3. Grouping
    List<RowModel<T>> groupedRows;
    final groupingFeature = controller.options.features
        .where((f) => f.featureId == 'grouping')
        .firstOrNull; // Could cast to GroupingFeature if imported
    final isManualGrouping = groupingFeature?.manual ?? false;

    if (state.grouping.isNotEmpty && !isManualGrouping) {
      groupedRows = _applyGrouping(sorted, columns);
    } else {
      groupedRows = _toRowModels(sorted, depth: 0);
    }

    // 4. Expanding
    List<RowModel<T>> expandedRows = _applyExpanding(groupedRows);

    // 5. Pagination
    List<RowModel<T>> pageRows = expandedRows;
    if (!state.manualPagination) {
      final pageSize = state.pagination.pageSize;
      final pageIndex = state.pagination.pageIndex;
      final startIndex = pageIndex * pageSize;
      if (startIndex < expandedRows.length) {
        pageRows = expandedRows.skip(startIndex).take(pageSize).toList();
      } else {
        pageRows = [];
      }
    }

    // Pinned rows (search across all possible rows if needed, or just top-level)
    final topPinned = allRawRows
        .where((r) => state.rowPinning.top.contains(r.id))
        .toList();
    final bottomPinned = allRawRows
        .where((r) => state.rowPinning.bottom.contains(r.id))
        .toList();

    final totalRows = expandedRows.length;
    final pageSize = state.pagination.pageSize;
    final totalPages = state.manualPagination
        ? (state.pageCount ?? 1)
        : ((totalRows + pageSize - 1) ~/ pageSize).clamp(1, 999999);

    return RowModelSet(
      allRows: expandedRows,
      filteredRows: filteredRows,
      pageRows: pageRows,
      topPinnedRows: topPinned,
      bottomPinnedRows: bottomPinned,
      totalRows: totalRows,
      totalPages: totalPages,
    );
  }

  List<RowModel<T>> _applyGrouping(List<T> data, List<ColumnDef<T, dynamic>> columns) {
    final groupColId = state.grouping.first;
    final groupCol = columns.where((c) => c.id == groupColId).firstOrNull;
    if (groupCol?.accessorFn == null) return _toRowModels(data, depth: 0);

    final groups = <dynamic, List<T>>{};
    for (final row in data) {
      final key = groupCol!.getGroupingValue?.call(row) ?? groupCol.accessorFn!(row);
      groups[key] = [...(groups[key] ?? []), row];
    }

    final result = <RowModel<T>>[];
    var idx = 0;
    for (final entry in groups.entries) {
      final subRows = _toRowModels(entry.value, depth: 1);
      final id = 'group:$groupColId:${entry.key}';
      
      final groupRow = RowModel<T>(
        id: id,
        original: entry.value.first, // representative
        index: idx++,
        originalIndex: -1,
        isGrouped: true,
        groupingColumnId: groupColId,
        groupingValue: entry.key,
        subRows: subRows,
        isExpanded: state.expanded[id] ?? false,
        controller: controller,
      );
      
      result.add(groupRow);

      if (groupRow.isExpanded) {
        result.addAll(subRows);
      }
    }

    return result;
  }

  List<RowModel<T>> _applyExpanding(List<RowModel<T>> rows) {
    if (getSubRows == null) return rows;

    final result = <RowModel<T>>[];
    for (final row in rows) {
      result.add(row);
      if (row.isExpanded && !row.isGrouped) { // Grouped rows already expanded above
        final subData = getSubRows!(row.original);
        if (subData.isNotEmpty) {
          final subRows = _toRowModels(subData, depth: row.depth + 1);
          result.addAll(_applyExpanding(subRows)); // Recursive
        }
      }
    }
    return result;
  }

  List<RowModel<T>> _toRowModels(List<T> data, {int startIndex = 0, int depth = 0}) {
    return data.indexed.map((entry) {
      final (i, row) = entry;
      final index = startIndex + i;
      final id = getRowId?.call(row, index) ?? '$index';
      return RowModel<T>(
        id: id,
        original: row,
        index: index,
        originalIndex: index,
        depth: depth,
        isSelected: state.rowSelection[id] ?? false,
        isExpanded: state.expanded[id] ?? false,
        isPinnedTop: state.rowPinning.top.contains(id),
        isPinnedBottom: state.rowPinning.bottom.contains(id),
        controller: controller,
      );
    }).toList();
  }
}
