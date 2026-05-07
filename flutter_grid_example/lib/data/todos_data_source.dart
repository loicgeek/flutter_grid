import 'dart:convert';

import 'package:ntech_grid/ntech_grid.dart';
import 'package:http/http.dart' as http;

import 'todo.dart';

/// Fetches todos from dummyjson.com, honouring external filters set by the
/// screen (status toggle, user-ID filter) via [GridQuery.externalFilters].
///
/// Supported external filter fields:
/// - `'completed'`  — [FilterOperator.eq] with a [bool] value
///                    → routes to `/todos/filter?completed=true/false`
/// - `'userId'`     — [FilterOperator.eq] with an [int] value
///                    → routes to `/todos/user/{userId}`
///
/// Both can be combined: the userId route is checked first; the completed
/// filter is applied client-side on top of the returned dataset because
/// the `/todos/user/{id}` endpoint does not support status filtering.
class TodosDataSource extends GridDataSource<Todo> {
  @override
  Future<GridPage<Todo>> fetch(GridQuery query) async {
    final completed = _completedFilter(query);
    final userId = _userIdFilter(query);

    final skip = query.pageIndex * query.pageSize;

    Uri uri;

    if (userId != null) {
      // /todos/user/{id} — all todos for a specific user (no server-side pagination)
      uri = Uri.parse('https://dummyjson.com/todos/user/$userId'
          '?limit=${query.pageSize}&skip=$skip');
    } else if (completed != null) {
      // /todos/filter?completed=true|false
      uri = Uri.parse('https://dummyjson.com/todos/filter'
          '?completed=$completed&limit=${query.pageSize}&skip=$skip');
    } else {
      // All todos
      uri = Uri.parse(
          'https://dummyjson.com/todos?limit=${query.pageSize}&skip=$skip');
    }

    final response = await http.get(uri);
    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    var todos = (json['todos'] as List)
        .map((e) => Todo.fromJson(e as Map<String, dynamic>))
        .toList();

    // When filtering by userId AND completed, apply the completed filter
    // client-side (the user endpoint doesn't support it server-side).
    if (userId != null && completed != null) {
      todos = todos.where((t) => t.completed == completed).toList();
    }

    final total = json['total'] as int? ?? todos.length;

    return GridPage(
      data: todos,
      totalItems: total,
      currentPage: query.pageIndex + 1,
      pageSize: query.pageSize,
    );
  }

  // ---------------------------------------------------------------------------

  /// Reads the `'completed'` external filter — returns `true`, `false`, or
  /// `null` (= no filter).
  bool? _completedFilter(GridQuery query) {
    final filter = query.externalFilters['completed'];
    if (filter == null) return null;
    final v = filter.value;
    if (v is bool) return v;
    if (v is String) return v.toLowerCase() == 'true';
    return null;
  }

  /// Reads the `'userId'` external filter — returns the int ID or `null`.
  int? _userIdFilter(GridQuery query) {
    final filter = query.externalFilters['userId'];
    if (filter == null) return null;
    final v = filter.value;
    if (v is int) return v;
    if (v is String) return int.tryParse(v);
    return null;
  }
}
