import 'column_def.dart';
import 'row_model.dart';

class HeaderGroup<T> {
  final String id;
  final List<Header<T>> headers;
  final int depth;

  const HeaderGroup({
    required this.id,
    required this.headers,
    required this.depth,
  });
}

class Header<T> {
  final String id;
  final ColumnInfo<T, Object?>? column; // null for group headers
  final ColumnDefGroup<T>? group;
  final int colSpan;
  final int rowSpan;
  final bool isPlaceholder;

  const Header({
    required this.id,
    this.column,
    this.group,
    this.colSpan = 1,
    this.rowSpan = 1,
    this.isPlaceholder = false,
  });
}
