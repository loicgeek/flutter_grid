import '../models/column_def.dart';
import '../models/grid_state.dart';
import 'pipeline_stage.dart';

class PaginateStage<T> extends PipelineStage<T> {
  @override
  List<T> apply(
      List<T> data, GridState state, List<ColumnDef<T, dynamic>> columns) {
    if (state.manualPagination) return data;

    final pageIndex = state.pagination.pageIndex;
    final pageSize = state.pagination.pageSize;
    final start = pageIndex * pageSize;
    if (start >= data.length) return [];
    final end = (start + pageSize).clamp(0, data.length);
    return data.sublist(start, end);
  }
}
