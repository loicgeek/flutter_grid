import 'grid_state.dart';

class GridQuery {
  final int pageIndex;
  final int pageSize;
  final List<SortEntry> sorting;
  final String? globalFilter;
  final Map<String, dynamic> columnFilters;
  final List<String> grouping;

  const GridQuery({
    this.pageIndex = 0,
    this.pageSize = 10,
    this.sorting = const [],
    this.globalFilter,
    this.columnFilters = const {},
    this.grouping = const [],
  });

  factory GridQuery.fromState(GridState state) => GridQuery(
        pageIndex: state.pagination.pageIndex,
        pageSize: state.pagination.pageSize,
        sorting: state.sorting,
        globalFilter: state.globalFilter,
        columnFilters: state.columnFilters,
        grouping: state.grouping,
      );

  Map<String, String> toQueryParameters() {
    final params = <String, String>{
      'page': '${pageIndex + 1}',
      'pageSize': '$pageSize',
    };
    if (sorting.isNotEmpty) {
      params['sort'] = sorting
          .map((s) => s.descending ? '-${s.columnId}' : s.columnId)
          .join(',');
    }
    if (globalFilter != null && globalFilter!.isNotEmpty) {
      params['q'] = globalFilter!;
    }
    for (final entry in columnFilters.entries) {
      params['filter[${entry.key}]'] = '${entry.value}';
    }
    if (grouping.isNotEmpty) {
      params['groupBy'] = grouping.join(',');
    }
    return params;
  }
}
