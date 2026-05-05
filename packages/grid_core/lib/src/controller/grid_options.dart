import '../models/column_def.dart';
import '../features/grid_feature.dart';

class GridOptions<T> {
  final List<Object> columns; // List<ColumnDef<T,dynamic>> | List<ColumnDefGroup<T>>
  final List<GridFeature> features;
  final String Function(T row, int index)? getRowId;
  final bool debugMode;

  const GridOptions({
    required this.columns,
    this.features = const [],
    this.getRowId,
    this.debugMode = false,
  });

  /// Returns a flat list of all leaf ColumnDefs (unwrapping groups).
  List<ColumnDef<T, dynamic>> get flatColumns {
    final result = <ColumnDef<T, dynamic>>[];
    for (final col in columns) {
      if (col is ColumnDef<T, dynamic>) {
        result.add(col);
      } else if (col is ColumnDefGroup<T>) {
        result.addAll(col.columns);
      }
    }
    return result;
  }

  /// Returns original columns (may include groups).
  List<ColumnDefGroup<T>> get columnGroups {
    return columns.whereType<ColumnDefGroup<T>>().toList();
  }
}
