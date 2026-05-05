import 'package:grid_core/grid_core.dart';

/// A [GridDataSource] backed by a [Stream] of lists.
class StreamDataSource<T> extends GridDataSource<T> {
  final Stream<List<T>> Function(GridQuery query) streamBuilder;
  List<T> _lastData = [];

  StreamDataSource({required this.streamBuilder});

  @override
  Future<GridPage<T>> fetch(GridQuery query) async {
    // If we haven't received any data yet from the stream, we just return empty or wait for first event.
    // For simplicity, we return what we have (or empty).
    return GridPage<T>(
      data: _lastData,
      totalItems: _lastData.length,
      currentPage: query.pageIndex + 1,
      pageSize: query.pageSize,
    );
  }

  @override
  Stream<List<T>>? watch(GridQuery query) {
    return streamBuilder(query).map((data) {
      _lastData = data;
      return data;
    });
  }
}
