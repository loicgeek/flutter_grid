import '../functions/sort_functions.dart';
import '../models/column_def.dart';
import '../models/grid_state.dart';
import 'pipeline_stage.dart';

class SortStage<T> extends PipelineStage<T> {
  @override
  List<T> apply(
      List<T> data, GridState state, List<ColumnDef<T, dynamic>> columns) {
    if (state.sorting.isEmpty) return data;

    final result = List<T>.from(data);
    result.sort((a, b) {
      for (final sortEntry in state.sorting) {
        final col =
            columns.where((c) => c.id == sortEntry.columnId).firstOrNull;
        if (col == null) continue;

        final aVal = col.accessorFn?.call(a);
        final bVal = col.accessorFn?.call(b);

        final int cmp;
        if (col.sortingFn != null) {
          cmp = col.sortingFn!(aVal, bVal);
        } else {
          final fn = SortFunctions.autoDetect(col.columnType);
          cmp = fn(aVal, bVal);
        }

        if (cmp != 0) {
          return sortEntry.descending ? -cmp : cmp;
        }
      }
      return 0;
    });
    return result;
  }
}
