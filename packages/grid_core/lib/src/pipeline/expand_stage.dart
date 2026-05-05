import '../models/column_def.dart';
import '../models/grid_state.dart';
import 'pipeline_stage.dart';

class ExpandStage<T> extends PipelineStage<T> {
  @override
  List<T> apply(
      List<T> data, GridState state, List<ColumnDef<T, dynamic>> columns) {
    // Expansion is handled at the RowModel level — flat data is not modified.
    return data;
  }
}
