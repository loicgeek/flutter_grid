import '../models/row_model.dart';

typedef AggregationFn<V> = V? Function(
    List<RowModel<dynamic>> leafRows, List<RowModel<dynamic>> childRows);

class AggregationFunctions {
  const AggregationFunctions._();

  static num? sum(List<RowModel<dynamic>> leafRows, List<RowModel<dynamic>> childRows) {
    // Cannot compute sum without a column accessor.
    // If needed, the function signature should accept the mapped values
    // or the ColumnDef itself.
    return null;
  }
}

