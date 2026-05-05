import '../models/column_def.dart';
import '../models/grid_state.dart';
import 'pipeline_stage.dart';

class GroupStage<T> extends PipelineStage<T> {
  @override
  List<T> apply(
      List<T> data, GridState state, List<ColumnDef<T, dynamic>> columns) {
    // Grouping is handled at the RowModel level (sub-rows),
    // so at data level we just return as-is. The row model pipeline
    // builds grouped RowModels from the flat data.
    return data;
  }
}
