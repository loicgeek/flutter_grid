import '../models/column_def.dart';

typedef FilterFn<V> = bool Function(V? cellValue, dynamic filterValue);

class FilterFunctions {
  const FilterFunctions._();

  static FilterFn<dynamic> autoDetect(ColumnType type) {
    return switch (type) {
      ColumnType.number || ColumnType.money => inNumberRange,
      ColumnType.date || ColumnType.datetime => inDateRange,
      ColumnType.boolean => equals,
      _ => includesString,
    };
  }

  static bool includesString(dynamic cellValue, dynamic filterValue) {
    if (cellValue == null) return false;
    final cell = cellValue.toString().toLowerCase();
    final filter = filterValue?.toString().toLowerCase() ?? '';
    return cell.contains(filter);
  }

  static bool equalsString(dynamic cellValue, dynamic filterValue) {
    if (cellValue == null && filterValue == null) return true;
    return cellValue?.toString().toLowerCase() ==
        filterValue?.toString().toLowerCase();
  }

  static bool equals(dynamic cellValue, dynamic filterValue) {
    return cellValue == filterValue;
  }

  static bool inNumberRange(dynamic cellValue, dynamic filterValue) {
    if (cellValue == null) return false;
    final num? numValue = num.tryParse(cellValue.toString());
    if (numValue == null) return false;

    if (filterValue is List && filterValue.length == 2) {
      final min = filterValue[0] != null
          ? num.tryParse(filterValue[0].toString())
          : null;
      final max = filterValue[1] != null
          ? num.tryParse(filterValue[1].toString())
          : null;
      if (min != null && numValue < min) return false;
      if (max != null && numValue > max) return false;
      return true;
    }
    final num? filter = num.tryParse(filterValue?.toString() ?? '');
    return filter == null || numValue == filter;
  }

  static bool inDateRange(dynamic cellValue, dynamic filterValue) {
    if (cellValue == null) return false;
    DateTime? date;
    if (cellValue is DateTime) {
      date = cellValue;
    } else {
      date = DateTime.tryParse(cellValue.toString());
    }
    if (date == null) return false;

    if (filterValue is List && filterValue.length == 2) {
      final start =
          filterValue[0] is DateTime ? filterValue[0] as DateTime : null;
      final end =
          filterValue[1] is DateTime ? filterValue[1] as DateTime : null;
      if (start != null && date.isBefore(start)) return false;
      if (end != null && date.isAfter(end)) return false;
      return true;
    }
    return true;
  }

  static bool arrIncludes(dynamic cellValue, dynamic filterValue) {
    if (cellValue is List) {
      return cellValue.contains(filterValue);
    }
    return cellValue == filterValue;
  }

  static bool startsWith(dynamic cellValue, dynamic filterValue) {
    if (cellValue == null) return false;
    return cellValue
        .toString()
        .toLowerCase()
        .startsWith(filterValue?.toString().toLowerCase() ?? '');
  }
}
