// IMPORTANT: Pure Dart — no Flutter/dart:ui imports.
// Widget-returning callbacks use dynamic return type; cast to Widget in grid_ui.

import 'row_model.dart';

/// Hint for the default cell renderer to use.
enum ColumnType {
  text,
  number,
  money,
  date,
  datetime,
  boolean,
  badge,
  avatar,
  progress,
  link,
  display,
  custom,
}

/// Defines a column in the grid.
///
/// Use [ColumnDef.accessor] for data columns and [ColumnDef.display] for
/// UI-only columns (e.g. checkboxes, action buttons).
///
/// ```dart
/// ColumnDef<Person, String>.accessor(
///   id: 'name',
///   accessorFn: (p) => p.name,
///   header: 'Name',
///   size: 160,
/// )
/// ```
class ColumnDef<T, V> {
  final String id;
  final String? header;
  final V Function(T row)? accessorFn;
  final String? accessorKey;
  final dynamic Function(dynamic ctx)? cell; // Widget Function(CellContext) in grid_ui
  final dynamic Function(dynamic ctx)? headerWidget;
  final dynamic Function(dynamic ctx)? footer;
  final dynamic Function(dynamic ctx)? aggregatedCell;
  final dynamic Function(dynamic ctx)? editCell;

  // Sorting
  final bool enableSorting;
  final int Function(V? a, V? b)? sortingFn;

  // Filtering
  final bool enableFiltering;
  final bool Function(V? cellValue, dynamic filterValue)? filterFn;
  final bool enableGlobalFilter;

  // Grouping
  final bool enableGrouping;
  final V Function(T row)? getGroupingValue;
  final V? Function(List<RowModel<dynamic>> leafRows, List<RowModel<dynamic>> childRows)? aggregationFn;

  // Column features
  final bool enableSizing;
  final double? size;
  final double? minSize;
  final double? maxSize;
  final bool enableResizing;
  final bool enableHiding;
  final bool enableOrdering;
  final bool enablePinning;

  // Editing
  final bool enableEditing;
  final List<String? Function(V?)>? validators;

  // Appearance
  final ColumnType columnType;
  final int? textAlignIndex; // 0=left, 1=right, 2=center
  final dynamic headerIcon; // Widget? in grid_ui
  final String? tooltip;

  const ColumnDef._({
    required this.id,
    this.header,
    this.accessorFn,
    this.accessorKey,
    this.cell,
    this.headerWidget,
    this.footer,
    this.aggregatedCell,
    this.editCell,
    this.enableSorting = true,
    this.sortingFn,
    this.enableFiltering = true,
    this.filterFn,
    this.enableGlobalFilter = true,
    this.enableGrouping = false,
    this.getGroupingValue,
    this.aggregationFn,
    this.enableSizing = true,
    this.size,
    this.minSize,
    this.maxSize,
    this.enableResizing = false,
    this.enableHiding = true,
    this.enableOrdering = true,
    this.enablePinning = false,
    this.enableEditing = false,
    this.validators,
    this.columnType = ColumnType.text,
    this.textAlignIndex,
    this.headerIcon,
    this.tooltip,
  });

  factory ColumnDef.accessor({
    required String id,
    required V Function(T row) accessorFn,
    String? header,
    dynamic Function(dynamic ctx)? cell,
    dynamic Function(dynamic ctx)? headerWidget,
    dynamic Function(dynamic ctx)? footer,
    dynamic Function(dynamic ctx)? aggregatedCell,
    dynamic Function(dynamic ctx)? editCell,
    bool enableSorting = true,
    int Function(V? a, V? b)? sortingFn,
    bool enableFiltering = true,
    bool Function(V? cellValue, dynamic filterValue)? filterFn,
    bool enableGlobalFilter = true,
    bool enableGrouping = false,
    V Function(T row)? getGroupingValue,
    V? Function(List<RowModel<dynamic>>, List<RowModel<dynamic>>)? aggregationFn,
    bool enableSizing = true,
    double? size,
    double? minSize,
    double? maxSize,
    bool enableResizing = false,
    bool enableHiding = true,
    bool enableOrdering = true,
    bool enablePinning = false,
    bool enableEditing = false,
    List<String? Function(V?)>? validators,
    ColumnType columnType = ColumnType.text,
    int? textAlignIndex,
    dynamic headerIcon,
    String? tooltip,
  }) =>
      ColumnDef._(
        id: id,
        accessorFn: accessorFn,
        header: header,
        cell: cell,
        headerWidget: headerWidget,
        footer: footer,
        aggregatedCell: aggregatedCell,
        editCell: editCell,
        enableSorting: enableSorting,
        sortingFn: sortingFn,
        enableFiltering: enableFiltering,
        filterFn: filterFn,
        enableGlobalFilter: enableGlobalFilter,
        enableGrouping: enableGrouping,
        getGroupingValue: getGroupingValue,
        aggregationFn: aggregationFn,
        enableSizing: enableSizing,
        size: size,
        minSize: minSize,
        maxSize: maxSize,
        enableResizing: enableResizing,
        enableHiding: enableHiding,
        enableOrdering: enableOrdering,
        enablePinning: enablePinning,
        enableEditing: enableEditing,
        validators: validators,
        columnType: columnType,
        textAlignIndex: textAlignIndex,
        headerIcon: headerIcon,
        tooltip: tooltip,
      );

  factory ColumnDef.display({
    required String id,
    String? header,
    required dynamic Function(dynamic ctx) cell,
    dynamic Function(dynamic ctx)? headerWidget,
    double? size,
    bool enableHiding = false,
    bool enableOrdering = false,
    bool enablePinning = true,
  }) =>
      ColumnDef._(
        id: id,
        header: header,
        cell: cell,
        headerWidget: headerWidget,
        enableSorting: false,
        enableFiltering: false,
        enableGlobalFilter: false,
        enableGrouping: false,
        enableSizing: size != null,
        size: size,
        enableHiding: enableHiding,
        enableOrdering: enableOrdering,
        enablePinning: enablePinning,
        columnType: ColumnType.display,
        textAlignIndex: 2, // center
      );

  bool get isAccessor => accessorFn != null;
  bool get isDisplay => accessorFn == null;
}

class ColumnDefGroup<T> {
  final String id;
  final String header;
  final List<ColumnDef<T, dynamic>> columns;
  final dynamic Function(dynamic ctx)? headerWidget;

  const ColumnDefGroup({
    required this.id,
    required this.header,
    required this.columns,
    this.headerWidget,
  });
}
