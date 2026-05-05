import 'package:grid_core/grid_core.dart';

/// A [GridDataSource] backed by a [Stream] of lists.
class StreamDataSource<T> extends GridDataSource<T> {
  final Stream<List<T>> stream;
  List<T> _lastData = [];

  StreamDataSource({required this.stream});

  @override
  Future<GridPage<T>> fetch(GridQuery query) async {
    return GridPage<T>(
      data: _lastData,
      totalItems: _lastData.length,
      currentPage: query.pageIndex + 1,
      pageSize: query.pageSize,
    );
  }

  @override
  Stream<List<T>>? watch(GridQuery query) {
    return stream.map((data) {
      _lastData = data;
      return data;
    });
  }
}
