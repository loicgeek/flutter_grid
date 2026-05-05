import 'package:grid_core/grid_core.dart';
import 'package:test/test.dart';

class _Person {
  final String name;
  final int age;
  final String? email;

  const _Person({required this.name, required this.age, this.email});
}

GridController<_Person> _makeController() {
  final columns = [
    ColumnDef<_Person, String>.accessor(
      id: 'name',
      accessorFn: (p) => p.name,
      header: 'Name',
    ),
    ColumnDef<_Person, int>.accessor(
      id: 'age',
      accessorFn: (p) => p.age,
      header: 'Age',
      columnType: ColumnType.number,
    ),
    ColumnDef<_Person, String?>.accessor(
      id: 'email',
      accessorFn: (p) => p.email,
      header: 'Email',
    ),
  ];

  final controller = GridController<_Person>(
    options: GridOptions(columns: columns),
  );
  controller.setData([
    const _Person(name: 'Alice', age: 30, email: 'alice@example.com'),
    const _Person(name: 'Bob', age: 25, email: 'bob@example.com'),
    const _Person(name: 'Charlie', age: 35, email: 'charlie@example.com'),
    const _Person(name: 'Dave', age: 22, email: 'dave@example.com'),
    const _Person(name: 'Eve', age: 28, email: 'eve@example.com'),
  ]);
  return controller;
}

void main() {
  group('Sort', () {
    test('single column ascending', () {
      final c = _makeController();
      c.toggleSort('name');
      expect(c.state.sorting.length, 1);
      expect(c.state.sorting.first.columnId, 'name');
      expect(c.state.sorting.first.descending, false);

      final rows = c.getRowModels().pageRows;
      final names = rows.map((r) => r.original.name).toList();
      expect(names, ['Alice', 'Bob', 'Charlie', 'Dave', 'Eve']);
    });

    test('toggleSort cycling: asc -> desc -> none', () {
      final c = _makeController();

      // First toggle: ascending
      c.toggleSort('name');
      expect(c.state.sorting.first.descending, false);

      // Second toggle: descending
      c.toggleSort('name');
      expect(c.state.sorting.first.descending, true);

      // Third toggle: cleared
      c.toggleSort('name');
      expect(c.state.sorting.isEmpty, true);
    });

    test('single column descending', () {
      final c = _makeController();
      c.toggleSort('age'); // asc
      c.toggleSort('age'); // desc

      final rows = c.getRowModels().pageRows;
      final ages = rows.map((r) => r.original.age).toList();
      expect(ages.first, 35);
      expect(ages.last, 22);
    });
  });

  group('Filter', () {
    test('global filter narrows rows', () {
      final c = _makeController();
      c.setGlobalFilter('ali');
      final rows = c.getRowModels().filteredRows;
      expect(rows.length, 1);
      expect(rows.first.original.name, 'Alice');
    });

    test('clear global filter restores all rows', () {
      final c = _makeController();
      c.setGlobalFilter('ali');
      c.setGlobalFilter(null);
      expect(c.getRowModels().filteredRows.length, 5);
    });

    test('column filter', () {
      final c = _makeController();
      c.setColumnFilter('name', 'Bob');
      final rows = c.getRowModels().filteredRows;
      expect(rows.length, 1);
      expect(rows.first.original.name, 'Bob');
    });

    test('hasActiveFilters true when filter set', () {
      final c = _makeController();
      expect(c.state.hasActiveFilters, false);
      c.setGlobalFilter('x');
      expect(c.state.hasActiveFilters, true);
      c.clearAllFilters();
      expect(c.state.hasActiveFilters, false);
    });
  });

  group('Pagination', () {
    late GridController<_Person> c;

    setUp(() {
      c = GridController<_Person>(
        options: GridOptions(
          columns: [
            ColumnDef<_Person, String>.accessor(
              id: 'name',
              accessorFn: (p) => p.name,
            ),
          ],
        ),
        initialState: const GridState(
          pagination: PaginationState(pageIndex: 0, pageSize: 2),
        ),
      );
      c.setData([
        const _Person(name: 'A', age: 1),
        const _Person(name: 'B', age: 2),
        const _Person(name: 'C', age: 3),
        const _Person(name: 'D', age: 4),
        const _Person(name: 'E', age: 5),
      ]);
    });

    test('first page has 2 rows', () {
      expect(c.getRowModels().pageRows.length, 2);
    });

    test('nextPage advances page index', () {
      c.nextPage();
      expect(c.state.pagination.pageIndex, 1);
      expect(c.getRowModels().pageRows.length, 2);
    });

    test('previousPage decrements page index', () {
      c.nextPage();
      c.previousPage();
      expect(c.state.pagination.pageIndex, 0);
    });

    test('previousPage does not go below 0', () {
      c.previousPage();
      expect(c.state.pagination.pageIndex, 0);
    });

    test('totalPages computed correctly', () {
      expect(c.getRowModels().totalPages, 3);
    });

    test('last page has 1 row', () {
      c.setPageIndex(2);
      expect(c.getRowModels().pageRows.length, 1);
    });
  });

  group('Commands and undo/redo', () {
    test('SetSortCommand is recorded in undo stack', () {
      final c = _makeController();
      expect(c.canUndo, false);
      c.dispatch(const SetSortCommand([SortEntry(columnId: 'name', descending: false)]));
      expect(c.canUndo, true);
    });

    test('undo reverts sort', () {
      final c = _makeController();
      c.dispatch(const SetSortCommand([SortEntry(columnId: 'name', descending: false)]));
      expect(c.state.sorting.length, 1);
      c.undo();
      expect(c.state.sorting.isEmpty, true);
    });

    test('redo re-applies sort', () {
      final c = _makeController();
      c.dispatch(const SetSortCommand([SortEntry(columnId: 'name', descending: false)]));
      c.undo();
      c.redo();
      expect(c.state.sorting.length, 1);
    });

    test('pagination commands are not undoable', () {
      final c = _makeController();
      c.nextPage();
      expect(c.canUndo, false);
    });
  });
}
