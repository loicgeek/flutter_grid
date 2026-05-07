import 'external_filter.dart';
import 'grid_query.dart';

class SortEntry {
  final String columnId;
  final bool descending;

  const SortEntry({required this.columnId, required this.descending});

  SortEntry copyWith({String? columnId, bool? descending}) => SortEntry(
        columnId: columnId ?? this.columnId,
        descending: descending ?? this.descending,
      );

  @override
  bool operator ==(Object other) =>
      other is SortEntry &&
      other.columnId == columnId &&
      other.descending == descending;

  @override
  int get hashCode => Object.hash(columnId, descending);
}

class PaginationState {
  final int pageIndex;
  final int pageSize;

  const PaginationState({
    this.pageIndex = 0,
    this.pageSize = 10,
  });

  PaginationState copyWith({
    int? pageIndex,
    int? pageSize,
  }) =>
      PaginationState(
        pageIndex: pageIndex ?? this.pageIndex,
        pageSize: pageSize ?? this.pageSize,
      );

  @override
  bool operator ==(Object other) =>
      other is PaginationState &&
      other.pageIndex == pageIndex &&
      other.pageSize == pageSize;

  @override
  int get hashCode => Object.hash(pageIndex, pageSize);
}

class ColumnPinningState {
  final List<String> left;
  final List<String> right;

  const ColumnPinningState({this.left = const [], this.right = const []});

  ColumnPinningState copyWith({List<String>? left, List<String>? right}) =>
      ColumnPinningState(
        left: left ?? this.left,
        right: right ?? this.right,
      );
}

class RowPinningState {
  final List<String> top;
  final List<String> bottom;

  const RowPinningState({this.top = const [], this.bottom = const []});

  RowPinningState copyWith({List<String>? top, List<String>? bottom}) =>
      RowPinningState(
        top: top ?? this.top,
        bottom: bottom ?? this.bottom,
      );
}

class GridState {
  final List<SortEntry> sorting;
  final bool manualSorting;
  final Map<String, dynamic> columnFilters;
  final String? globalFilter;
  final bool manualFiltering;
  final PaginationState pagination;
  final bool manualPagination;
  final int? pageCount;
  final int? totalItems;
  final Map<String, bool> rowSelection;
  final bool enableMultiRowSelection;
  final bool selectAllPages;
  final Map<String, bool> columnVisibility;
  final List<String> columnOrder;
  final ColumnPinningState columnPinning;
  final Map<String, double> columnSizing;
  final Map<String, bool> expanded;
  final RowPinningState rowPinning;
  final List<String> grouping;
  final String? editingCellId;

  /// Filters set externally (e.g. from a date-picker or filter form outside
  /// the grid widget). They are passed to every [GridDataSource.fetch] call
  /// and are not affected by [ClearAllFiltersCommand] — clear them explicitly
  /// with [ClearExternalFiltersCommand] or [ClearAllExternalFiltersCommand].
  ///
  /// Key = API field name (e.g. `'createdAt'`).
  /// Value = typed filter with operator (e.g. `ExternalFilter.gte(date)`).
  final Map<String, ExternalFilter> externalFilters;

  const GridState({
    this.sorting = const [],
    this.manualSorting = false,
    this.columnFilters = const {},
    this.globalFilter,
    this.manualFiltering = false,
    this.pagination = const PaginationState(),
    this.manualPagination = false,
    this.pageCount,
    this.totalItems,
    this.rowSelection = const {},
    this.enableMultiRowSelection = true,
    this.selectAllPages = false,
    this.columnVisibility = const {},
    this.columnOrder = const [],
    this.columnPinning = const ColumnPinningState(),
    this.columnSizing = const {},
    this.expanded = const {},
    this.rowPinning = const RowPinningState(),
    this.grouping = const [],
    this.editingCellId,
    this.externalFilters = const {},
  });

  GridState copyWith({
    List<SortEntry>? sorting,
    bool? manualSorting,
    Map<String, dynamic>? columnFilters,
    String? globalFilter,
    bool clearGlobalFilter = false,
    bool? manualFiltering,
    PaginationState? pagination,
    bool? manualPagination,
    int? pageCount,
    int? totalItems,
    Map<String, bool>? rowSelection,
    bool? enableMultiRowSelection,
    bool? selectAllPages,
    Map<String, bool>? columnVisibility,
    List<String>? columnOrder,
    ColumnPinningState? columnPinning,
    Map<String, double>? columnSizing,
    Map<String, bool>? expanded,
    RowPinningState? rowPinning,
    List<String>? grouping,
    String? editingCellId,
    bool clearEditingCell = false,
    Map<String, ExternalFilter>? externalFilters,
    bool clearExternalFilters = false,
  }) {
    return GridState(
      sorting: sorting ?? this.sorting,
      manualSorting: manualSorting ?? this.manualSorting,
      columnFilters: columnFilters ?? this.columnFilters,
      globalFilter:
          clearGlobalFilter ? null : (globalFilter ?? this.globalFilter),
      manualFiltering: manualFiltering ?? this.manualFiltering,
      pagination: pagination ?? this.pagination,
      manualPagination: manualPagination ?? this.manualPagination,
      pageCount: pageCount ?? this.pageCount,
      totalItems: totalItems ?? this.totalItems,
      rowSelection: rowSelection ?? this.rowSelection,
      enableMultiRowSelection:
          enableMultiRowSelection ?? this.enableMultiRowSelection,
      selectAllPages: selectAllPages ?? this.selectAllPages,
      columnVisibility: columnVisibility ?? this.columnVisibility,
      columnOrder: columnOrder ?? this.columnOrder,
      columnPinning: columnPinning ?? this.columnPinning,
      columnSizing: columnSizing ?? this.columnSizing,
      expanded: expanded ?? this.expanded,
      rowPinning: rowPinning ?? this.rowPinning,
      grouping: grouping ?? this.grouping,
      editingCellId:
          clearEditingCell ? null : (editingCellId ?? this.editingCellId),
      externalFilters: clearExternalFilters
          ? const {}
          : (externalFilters ?? this.externalFilters),
    );
  }

  GridQuery toQuery() => GridQuery.fromState(this);

  String? get sortString {
    if (sorting.isEmpty) return null;
    final entry = sorting.first;
    return entry.descending ? '-${entry.columnId}' : entry.columnId;
  }

  bool get hasActiveFilters =>
      columnFilters.isNotEmpty || (globalFilter?.isNotEmpty == true);

  bool get hasSelection => rowSelection.values.any((v) => v);

  int get selectedCount => rowSelection.values.where((v) => v).length;
}
