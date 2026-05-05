import '../models/column_def.dart';
import '../models/grid_state.dart';

abstract class PipelineStage<T> {
  List<T> apply(
      List<T> data, GridState state, List<ColumnDef<T, dynamic>> columns);
}
