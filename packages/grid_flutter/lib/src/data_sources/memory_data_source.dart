import 'package:grid_core/grid_core.dart';

/// An in-memory [GridDataSource] for testing or static data.
class MemoryDataSource<T> extends GridDataSource<T> {
  final List<T> items;

  MemoryDataSource({required this.items});

  @override
  Future<GridPage<T>> fetch(GridQuery query) async {
    return GridPage<T>(
      data: items,
      totalItems: items.length,
      currentPage: query.pageIndex + 1,
      pageSize: query.pageSize,
    );
  }
}
