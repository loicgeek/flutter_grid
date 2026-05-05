typedef AggregationFn<V> = V? Function(
    List<dynamic> leafRows, List<dynamic> childRows);

class AggregationFunctions {
  const AggregationFunctions._();

  static num? sum(List<dynamic> leafRows, List<dynamic> childRows) {
    num total = 0;
    for (final row in leafRows) {
      final n = num.tryParse(row?.toString() ?? '');
      if (n != null) total += n;
    }
    return total;
  }

  static int count(List<dynamic> leafRows, List<dynamic> childRows) {
    return leafRows.length;
  }

  static dynamic min(List<dynamic> leafRows, List<dynamic> childRows) {
    if (leafRows.isEmpty) return null;
    dynamic minVal = leafRows.first;
    for (final row in leafRows.skip(1)) {
      if (row == null) continue;
      if (minVal == null || row.toString().compareTo(minVal.toString()) < 0) {
        minVal = row;
      }
    }
    return minVal;
  }

  static dynamic max(List<dynamic> leafRows, List<dynamic> childRows) {
    if (leafRows.isEmpty) return null;
    dynamic maxVal = leafRows.first;
    for (final row in leafRows.skip(1)) {
      if (row == null) continue;
      if (maxVal == null || row.toString().compareTo(maxVal.toString()) > 0) {
        maxVal = row;
      }
    }
    return maxVal;
  }

  static double? mean(List<dynamic> leafRows, List<dynamic> childRows) {
    if (leafRows.isEmpty) return null;
    num total = 0;
    int count = 0;
    for (final row in leafRows) {
      final n = num.tryParse(row?.toString() ?? '');
      if (n != null) {
        total += n;
        count++;
      }
    }
    return count == 0 ? null : total / count;
  }

  static int uniqueCount(List<dynamic> leafRows, List<dynamic> childRows) {
    return leafRows.toSet().length;
  }
}
