import 'external_filter.dart';
import 'grid_state.dart';

class GridQuery {
  final int pageIndex;
  final int pageSize;
  final List<SortEntry> sorting;
  final String? globalFilter;
  final Map<String, dynamic> columnFilters;
  final List<String> grouping;

  /// External filters set by the caller (date pickers, form fields, etc.).
  /// These carry typed [FilterOperator]s and are serialised by
  /// [toQueryParameters] according to [paramFormat].
  final Map<String, ExternalFilter> externalFilters;

  /// Controls how [externalFilters] are encoded as query-parameter keys.
  /// Defaults to [QueryParamFormat.brackets] → `filter[field][gte]=value`.
  final QueryParamFormat paramFormat;

  const GridQuery({
    this.pageIndex = 0,
    this.pageSize = 10,
    this.sorting = const [],
    this.globalFilter,
    this.columnFilters = const {},
    this.grouping = const [],
    this.externalFilters = const {},
    this.paramFormat = QueryParamFormat.brackets,
  });

  factory GridQuery.fromState(
    GridState state, {
    QueryParamFormat paramFormat = QueryParamFormat.brackets,
  }) =>
      GridQuery(
        pageIndex: state.pagination.pageIndex,
        pageSize: state.pagination.pageSize,
        sorting: state.sorting,
        globalFilter: state.globalFilter,
        columnFilters: state.columnFilters,
        grouping: state.grouping,
        externalFilters: state.externalFilters,
        paramFormat: paramFormat,
      );

  /// Builds a flat `Map<String, String>` suitable for Dio / http query params.
  ///
  /// External filters are serialised with their operators, e.g.:
  /// ```
  /// ExternalFilter.gte(date)  →  filter[createdAt][gte]=2024-01-01T00:00:00.000Z
  /// ExternalFilter.between([from, to])  →  filter[date][gte]=… & filter[date][lte]=…
  /// ExternalFilter.inList([a, b])  →  filter[status][in]=a,b
  /// ```
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

    // External filters — typed with operators
    for (final entry in externalFilters.entries) {
      final pairs = entry.value.toParams(entry.key, format: paramFormat);
      params.addAll(pairs);
    }

    return params;
  }

  /// Returns a copy of this query with the given fields overridden.
  GridQuery copyWith({
    int? pageIndex,
    int? pageSize,
    List<SortEntry>? sorting,
    String? globalFilter,
    Map<String, dynamic>? columnFilters,
    List<String>? grouping,
    Map<String, ExternalFilter>? externalFilters,
    QueryParamFormat? paramFormat,
  }) =>
      GridQuery(
        pageIndex: pageIndex ?? this.pageIndex,
        pageSize: pageSize ?? this.pageSize,
        sorting: sorting ?? this.sorting,
        globalFilter: globalFilter ?? this.globalFilter,
        columnFilters: columnFilters ?? this.columnFilters,
        grouping: grouping ?? this.grouping,
        externalFilters: externalFilters ?? this.externalFilters,
        paramFormat: paramFormat ?? this.paramFormat,
      );
}
