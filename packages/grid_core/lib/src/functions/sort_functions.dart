import '../models/column_def.dart';

typedef SortFn<V> = int Function(V? a, V? b);

class SortFunctions {
  const SortFunctions._();

  static SortFn<dynamic> autoDetect(ColumnType type) {
    return switch (type) {
      ColumnType.number || ColumnType.money => numeric,
      ColumnType.date || ColumnType.datetime => datetime,
      ColumnType.boolean => basic,
      _ => alphanumeric,
    };
  }

  static int alphanumeric(dynamic a, dynamic b) {
    if (a == null && b == null) return 0;
    if (a == null) return -1;
    if (b == null) return 1;
    final aStr = a.toString();
    final bStr = b.toString();
    // Try numeric comparison
    final aNum = num.tryParse(aStr);
    final bNum = num.tryParse(bStr);
    if (aNum != null && bNum != null) return aNum.compareTo(bNum);
    return aStr.compareTo(bStr);
  }

  static int numeric(dynamic a, dynamic b) {
    if (a == null && b == null) return 0;
    if (a == null) return -1;
    if (b == null) return 1;
    final aNum = num.tryParse(a.toString()) ?? 0;
    final bNum = num.tryParse(b.toString()) ?? 0;
    return aNum.compareTo(bNum);
  }

  static int datetime(dynamic a, dynamic b) {
    if (a == null && b == null) return 0;
    if (a == null) return -1;
    if (b == null) return 1;
    final aDate = a is DateTime ? a : DateTime.tryParse(a.toString());
    final bDate = b is DateTime ? b : DateTime.tryParse(b.toString());
    if (aDate == null && bDate == null) return 0;
    if (aDate == null) return -1;
    if (bDate == null) return 1;
    return aDate.compareTo(bDate);
  }

  static int basic(dynamic a, dynamic b) {
    if (a == null && b == null) return 0;
    if (a == null) return -1;
    if (b == null) return 1;
    if (a == b) return 0;
    return a.toString().compareTo(b.toString());
  }
}
