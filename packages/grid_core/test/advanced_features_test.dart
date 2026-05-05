import 'package:grid_core/grid_core.dart';
import 'package:test/test.dart';

class _Person {
  final String id;
  final String name;
  final int age;
  final String department;
  final String? email;
  final List<_Person> children;

  const _Person({
    required this.id,
    required this.name,
    required this.age,
    required this.department,
    this.email,
    this.children = const [],
  });
}

GridController<_Person> _makeController({
  List<GridFeature> features = const [],
}) {
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
      aggregationFn: (leafRows, childRows) {
        return leafRows.fold<int>(0, (sum, row) => (sum + row.original.age).toInt());
      },
    ),
    ColumnDef<_Person, String>.accessor(
      id: 'department',
      accessorFn: (p) => p.department,
      header: 'Department',
    ),
  ];

  final controller = GridController<_Person>(
    options: GridOptions(
      columns: columns,
      features: features,
      getRowId: (p, i) => p.id,
      getSubRows: (p) => p.children,
    ),
  );

  controller.setData([
    const _Person(
      id: '1',
      name: 'Alice',
      age: 30,
      department: 'Engineering',
      children: [
        _Person(id: '1a', name: 'Alice Jr', age: 5, department: 'N/A'),
      ],
    ),
    const _Person(id: '2', name: 'Bob', age: 25, department: 'HR'),
    const _Person(id: '3', name: 'Charlie', age: 35, department: 'Engineering'),
  ]);

  return controller;
}

void main() {
  group('Grouping Feature', () {
    test('SetGroupingCommand groups rows locally', () {
      final c = _makeController(features: [GroupingFeature()]);
      
      c.dispatch(const SetGroupingCommand(['department']));
      final rows = c.getRowModels().pageRows;
      
      // We should have 2 groups: Engineering and HR
      expect(rows.length, 2);
      expect(rows[0].isGrouped, true);
      expect(rows[0].groupingValue, 'Engineering');
      expect(rows[0].subRows.length, 2); // Alice, Charlie

      expect(rows[1].isGrouped, true);
      expect(rows[1].groupingValue, 'HR');
      expect(rows[1].subRows.length, 1); // Bob
    });

    test('Manual Grouping bypasses local grouping', () {
      final c = _makeController(features: [GroupingFeature(manual: true)]);
      
      c.dispatch(const SetGroupingCommand(['department']));
      final rows = c.getRowModels().pageRows;
      
      // Because it is manual, the rows are not grouped locally
      expect(rows.length, 3);
      expect(rows.any((r) => r.isGrouped), false);
    });
  });

  group('Expanding Feature', () {
    test('SetRowExpandedCommand reveals children', () {
      final c = _makeController(features: [ExpandingFeature()]);
      
      // Alice is at index 0, with 1 child
      c.dispatch(const SetRowExpandedCommand('1', true));
      final rows = c.getRowModels().pageRows;
      
      // 3 top-level + 1 child = 4
      expect(rows.length, 4);
      expect(rows[0].original.id, '1');
      expect(rows[1].original.id, '1a'); // The expanded child
      expect(rows[1].depth, 1);
    });
  });

  group('Pinning Features', () {
    test('PinRowCommand separates pinned rows', () {
      final c = _makeController(features: const [RowPinningFeature(keepPinnedRows: false)]);
      
      c.dispatch(const PinRowCommand('2', RowPinPosition.top));
      final rowModels = c.getRowModels();
      
      expect(rowModels.topPinnedRows.length, 1);
      expect(rowModels.topPinnedRows.first.original.id, '2');
      
      // It should be removed from the normal page rows if keepPinnedRows = false
      expect(rowModels.pageRows.length, 2); 
    });

    test('PinRowCommand keeps pinned rows if configured', () {
      final c = _makeController(features: const [RowPinningFeature(keepPinnedRows: true)]);
      
      c.dispatch(const PinRowCommand('2', RowPinPosition.top));
      final rowModels = c.getRowModels();
      
      expect(rowModels.topPinnedRows.length, 1);
      expect(rowModels.pageRows.length, 3); // Still in pageRows
    });

    test('PinColumnCommand segregates columns', () {
      final c = _makeController(features: [ColumnPinningFeature()]);
      
      c.dispatch(const PinColumnCommand('name', ColumnPinPosition.left));
      c.dispatch(const PinColumnCommand('department', ColumnPinPosition.right));
      
      final left = c.getLeftPinnedColumns();
      final right = c.getRightPinnedColumns();
      final center = c.getCenterColumns();
      
      expect(left.length, 1);
      expect(left.first.id, 'name');
      
      expect(right.length, 1);
      expect(right.first.id, 'department');
      
      expect(center.length, 1);
      expect(center.first.id, 'age');
    });
  });

  group('Optimistic Updates', () {
    test('executeOptimistic applies and rolls back on failure', () async {
      final c = _makeController();
      
      expect(c.state.sorting.isEmpty, true);
      
      try {
        await c.executeOptimistic(
          const SetSortCommand([SortEntry(columnId: 'name', descending: false)]),
          () async {
            // It should be applied immediately
            expect(c.state.sorting.length, 1);
            throw Exception('Network failure');
          },
        );
      } catch (_) {}

      // It should be rolled back
      expect(c.state.sorting.isEmpty, true);
    });

    test('executeOptimistic keeps command on success', () async {
      final c = _makeController();
      
      await c.executeOptimistic(
        const SetSortCommand([SortEntry(columnId: 'name', descending: false)]),
        () async {
          await Future.delayed(const Duration(milliseconds: 10));
        },
      );

      // Kept
      expect(c.state.sorting.length, 1);
    });
  });

  group('Selection Feature', () {
    test('SelectAllPagesCommand selects all across pages', () {
      final c = _makeController(features: [SelectionFeature()]);
      
      c.selectAllPages(true);
      expect(c.state.selectAllPages, true);
      
      // rowSelection should be populated
      expect(c.state.rowSelection.length, 3); // 3 parent rows
      expect(c.state.rowSelection.values.every((v) => v), true);
    });

    test('ClearRowSelectionCommand unselects all pages', () {
      final c = _makeController(features: [SelectionFeature()]);
      c.selectAllPages(true);
      expect(c.state.selectAllPages, true);

      c.clearRowSelection();
      expect(c.state.selectAllPages, false);
      expect(c.state.rowSelection.isEmpty, true);
    });
  });
}
