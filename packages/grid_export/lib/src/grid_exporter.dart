import 'package:flutter/services.dart';
import 'package:grid_core/grid_core.dart';

/// Exports grid data to CSV or the system clipboard.
///
/// Usage:
/// ```dart
/// final exporter = GridExporter(controller: myController);
/// final csv = exporter.toCsv();
/// await exporter.copyToClipboard();
/// ```
class GridExporter<T> {
  final GridController<T> controller;

  /// Character used to separate columns. Defaults to comma.
  final String delimiter;

  /// Character used to quote fields containing the delimiter or line breaks.
  final String quote;

  const GridExporter({
    required this.controller,
    this.delimiter = ',',
    this.quote = '"',
  });

  /// Returns all visible column definitions in their current display order.
  List<ColumnDef<T, Object?>> _exportColumns(List<String>? columnIds) {
    final cols = controller.getVisibleColumns();
    if (columnIds == null) return cols.map((c) => c.def).toList();
    return columnIds
        .map((id) => cols.where((c) => c.id == id).firstOrNull?.def)
        .whereType<ColumnDef<T, Object?>>()
        .toList();
  }

  /// Builds a CSV string from all filtered rows (ignoring pagination).
  ///
  /// [includeHeaders] — whether to emit the header row (default true).
  /// [columnIds] — restrict export to these column IDs; null means all visible.
  /// [allRows] — when true, exports every filtered row instead of just the
  ///   current page. Defaults to true.
  String toCsv({
    bool includeHeaders = true,
    List<String>? columnIds,
    bool allRows = true,
  }) {
    final cols = _exportColumns(columnIds);
    if (cols.isEmpty) return '';

    final rows = allRows
        ? controller.getRowModels().filteredRows
        : controller.getRowModels().pageRows;

    final buffer = StringBuffer();

    if (includeHeaders) {
      buffer.writeln(
        cols.map((c) => _escape(c.header ?? c.id)).join(delimiter),
      );
    }

    for (final row in rows) {
      final line = cols.map((col) {
        final value = col.accessorFn?.call(row.original);
        return _escape(value?.toString() ?? '');
      }).join(delimiter);
      buffer.writeln(line);
    }

    return buffer.toString();
  }

  /// Copies the CSV export to the system clipboard.
  ///
  /// Returns the CSV string that was copied.
  Future<String> copyToClipboard({
    bool includeHeaders = true,
    List<String>? columnIds,
    bool allRows = true,
  }) async {
    final csv = toCsv(
      includeHeaders: includeHeaders,
      columnIds: columnIds,
      allRows: allRows,
    );
    await Clipboard.setData(ClipboardData(text: csv));
    return csv;
  }

  String _escape(String value) {
    final needsQuoting = value.contains(delimiter) ||
        value.contains(quote) ||
        value.contains('\n') ||
        value.contains('\r');
    if (!needsQuoting) return value;
    final escaped = value.replaceAll(quote, '$quote$quote');
    return '$quote$escaped$quote';
  }
}
