import '../models/column_def.dart';
import '../models/grid_state.dart';
import '../models/row_model.dart';
import 'filter_stage.dart';
import 'paginate_stage.dart';
import 'sort_stage.dart';

class RowModelPipeline<T> {
  final GridState state;
  final List<ColumnDef<T, dynamic>> columns;
  final dynamic controller; // GridController<T> — dynamic to avoid circular ref
  final String Function(T row, int index)? getRowId;

  RowModelPipeline({
    required this.state,
    required this.columns,
    required this.controller,
    this.getRowId,
  });

  RowModelSet<T> build(List<T> data) {
    final allRows = _toRowModels(data);

    // Client-side pipeline
    List<T> filtered = data;
    if (!state.manualFiltering) {
      filtered = FilterStage<T>().apply(data, state, columns);
    }

    List<T> sorted = filtered;
    if (!state.manualSorting) {
      sorted = SortStage<T>().apply(filtered, state, columns);
    }

    final filteredRows = _toRowModels(sorted);

    List<T> paged = sorted;
    if (!state.manualPagination) {
      paged = PaginateStage<T>().apply(sorted, state, columns);
    }

    final pageRows = _toRowModels(paged, startIndex: state.manualPagination
        ? 0
        : state.pagination.pageIndex * state.pagination.pageSize);

    // Pinned rows
    final topPinned = allRows
        .where((r) => state.rowPinning.top.contains(r.id))
        .toList();
    final bottomPinned = allRows
        .where((r) => state.rowPinning.bottom.contains(r.id))
        .toList();

    final totalRows = filtered.length;
    final pageSize = state.pagination.pageSize;
    final totalPages = state.manualPagination
        ? (state.pageCount ?? 1)
        : ((totalRows + pageSize - 1) ~/ pageSize).clamp(1, 999999);

    return RowModelSet(
      allRows: allRows,
      filteredRows: filteredRows,
      pageRows: pageRows,
      topPinnedRows: topPinned,
      bottomPinnedRows: bottomPinned,
      totalRows: totalRows,
      totalPages: totalPages,
    );
  }

  List<RowModel<T>> _toRowModels(List<T> data, {int startIndex = 0}) {
    return data.indexed.map((entry) {
      final (i, row) = entry;
      final index = startIndex + i;
      final id = getRowId?.call(row, index) ?? '$index';
      return RowModel<T>(
        id: id,
        original: row,
        index: index,
        isSelected: state.rowSelection[id] ?? false,
        isExpanded: state.expanded[id] ?? false,
        isPinnedTop: state.rowPinning.top.contains(id),
        isPinnedBottom: state.rowPinning.bottom.contains(id),
        controller: controller,
      );
    }).toList();
  }
}
