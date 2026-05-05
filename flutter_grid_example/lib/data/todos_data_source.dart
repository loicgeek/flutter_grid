import 'dart:convert';

import 'package:grid_core/grid_core.dart';
import 'package:http/http.dart' as http;

import 'todo.dart';

class TodosDataSource extends GridDataSource<Todo> {
  @override
  Future<GridPage<Todo>> fetch(GridQuery query) async {
    final skip = query.pageIndex * query.pageSize;
    final uri = Uri.parse(
      'https://dummyjson.com/todos?limit=${query.pageSize}&skip=$skip',
    );

    final response = await http.get(uri);
    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final todos = (json['todos'] as List)
        .map((e) => Todo.fromJson(e as Map<String, dynamic>))
        .toList();
    final total = json['total'] as int;

    return GridPage(
      data: todos,
      totalItems: total,
      currentPage: query.pageIndex + 1,
      pageSize: query.pageSize,
    );
  }
}
