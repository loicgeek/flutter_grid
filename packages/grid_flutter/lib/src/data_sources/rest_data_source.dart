import 'package:dio/dio.dart';
import 'package:grid_core/grid_core.dart';

/// A [GridDataSource] that fetches data from a REST API using [Dio].
class RestDataSource<T> extends GridDataSource<T> {
  final Dio dio;
  final String url;
  final T Function(Map<String, dynamic> json) fromJson;
  final Map<String, String> Function(GridQuery query)? extraParams;
  final String? totalCountHeader;
  final String? dataKey; // JSON key for the array, null = root is array

  RestDataSource({
    required this.dio,
    required this.url,
    required this.fromJson,
    this.extraParams,
    this.totalCountHeader = 'x-total-count',
    this.dataKey,
  });

  @override
  Future<GridPage<T>> fetch(GridQuery query) async {
    final params = query.toQueryParameters();
    if (extraParams != null) {
      params.addAll(extraParams!(query));
    }

    final response = await dio.get<dynamic>(url, queryParameters: params);

    final rawData = dataKey != null
        ? (response.data as Map<String, dynamic>)[dataKey]
        : response.data;

    final list = (rawData as List).cast<Map<String, dynamic>>();
    final items = list.map(fromJson).toList();

    // Parse total from header or response body
    int? totalItems;
    final headerVal = response.headers.value(totalCountHeader ?? '');
    if (headerVal != null) {
      totalItems = int.tryParse(headerVal);
    }
    if (totalItems == null && response.data is Map) {
      final dataMap = response.data as Map<String, dynamic>;
      totalItems = dataMap['total'] as int? ?? dataMap['totalItems'] as int?;
    }
    totalItems ??= items.length;

    return GridPage<T>(
      data: items,
      totalItems: totalItems,
      currentPage: query.pageIndex + 1,
      pageSize: query.pageSize,
    );
  }
}
