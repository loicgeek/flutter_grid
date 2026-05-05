import '../functions/filter_functions.dart';
import '../models/column_def.dart';
import '../models/grid_state.dart';
import 'pipeline_stage.dart';

class FilterStage<T> extends PipelineStage<T> {
  @override
  List<T> apply(
      List<T> data, GridState state, List<ColumnDef<T, dynamic>> columns) {
    var result = data;

    // Global filter
    if (state.globalFilter != null && state.globalFilter!.isNotEmpty) {
      final filter = state.globalFilter!.toLowerCase();
      result = result.where((row) {
        for (final col in columns) {
          if (!col.enableGlobalFilter) continue;
          final value = col.accessorFn?.call(row);
          if (value != null && value.toString().toLowerCase().contains(filter)) {
            return true;
          }
        }
        return false;
      }).toList();
    }

    // Column filters
    if (state.columnFilters.isNotEmpty) {
      result = result.where((row) {
        for (final entry in state.columnFilters.entries) {
          final col = columns.where((c) => c.id == entry.key).firstOrNull;
          if (col == null) continue;
          final cellValue = col.accessorFn?.call(row);
          final filterValue = entry.value;

          if (col.filterFn != null) {
            if (!col.filterFn!(cellValue, filterValue)) return false;
          } else {
            // Auto-detect filter
            final fn = FilterFunctions.autoDetect(col.columnType);
            if (!fn(cellValue, filterValue)) return false;
          }
        }
        return true;
      }).toList();
    }

    return result;
  }
}
