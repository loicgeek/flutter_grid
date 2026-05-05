import '../models/grid_page.dart';
import '../models/grid_query.dart';

abstract class GridDataSource<T> {
  Future<GridPage<T>> fetch(GridQuery query);

  Stream<List<T>>? watch(GridQuery query) => null;

  Future<T?> insert(T item) async => null;

  Future<T?> update(T item) async => null;

  Future<bool> delete(dynamic id) async => false;
}
