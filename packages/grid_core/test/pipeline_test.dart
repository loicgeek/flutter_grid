import 'package:grid_core/grid_core.dart';
import 'package:test/test.dart';

class _Item {
  final String id;
  final String name;
  final int score;
  final String category;

  const _Item({
    required this.id,
    required this.name,
    required this.score,
    required this.category,
  });
}

GridController<_Item> _makeController({
  GridState? initialState,
  List<GridFeature> features = const [],
}) {
  final columns = [
    ColumnDef<_Item, String>.accessor(
      id: 'name',
      accessorFn: (i) => i.name,
      header: 'Name',
    ),
    ColumnDef<_Item, int>.accessor(
      id: 'score',
      accessorFn: (i) => i.score,
      header: 'Score',
      columnType: ColumnType.number,
    ),
    ColumnDef<_Item, String>.accessor(
      id: 'category',
      accessorFn: (i) => i.category,
      header: 'Category',
    ),
  ];

  final c = GridController<_Item>(
    options: GridOptions(
      columns: columns,
      features: features,
      getRowId: (item, _) => item.id,
    ),
    initialState: initialState,
  );

  c.setData([
    const _Item(id: '1', name: 'Zara', score: 90, category: 'A'),
    const _Item(id: '2', name: 'Alice', score: 70, category: 'B'),
    const _Item(id: '3', name: 'Bob', score: 85, category: 'A'),
    const _Item(id: '4', name: 'Dave', score: 60, category: 'B'),
    const _Item(id: '5', name: 'Eve', score: 75, category: 'A'),
  ]);

  return c;
}

void main() {
  group('Pipeline — filter then sort order', () {
    test('filter is applied before sort', () {
      final c = _makeController();
      c.setColumnFilter('category', 'A');
      c.toggleSort('name');

      final rows = c.getRowModels().filteredRows;
      final names = rows.map((r) => r.original.name).toList();
      // Only category=A rows: Alice not included, only Zara, Bob, Eve
      expect(names, containsAll(['Zara', 'Bob', 'Eve']));
      expect(names, isNot(contains('Alice')));

      // Page rows should be sorted ascending by name
      final pageNames = c.getRowModels().pageRows.map((r) => r.original.name).toList();
      expect(pageNames, ['Bob', 'Eve', 'Zara']);
    });

    test('sort does not affect filteredRows count', () {
      final c = _makeController();
      c.setColumnFilter('category', 'B');
      c.toggleSort('score');

      final filtered = c.getRowModels().filteredRows;
      expect(filtered.length, 2); // Alice + Dave
    });

    test('global filter is applied before pagination', () {
      final c = _makeController(
        initialState: const GridState(
          pagination: PaginationState(pageIndex: 0, pageSize: 2),
        ),
      );
      // 'zara' only matches Zara's name — no other column has that substring
      c.setGlobalFilter('zara');

      final filtered = c.getRowModels().filteredRows;
      expect(filtered.length, 1);
      expect(filtered.first.original.name, 'Zara');

      final page = c.getRowModels().pageRows;
      expect(page.length, 1); // 1 item, one page
    });
  });

  group('Pipeline — server-side (manual) pagination', () {
    test('server-side mode does not re-paginate: all set data appears in pageRows', () {
      final c = GridController<_Item>(
        options: GridOptions(
          columns: [
            ColumnDef<_Item, String>.accessor(
              id: 'name',
              accessorFn: (i) => i.name,
            ),
          ],
          features: [PaginationFeature(mode: PaginationMode.serverSide)],
          getRowId: (item, _) => item.id,
        ),
        initialState: const GridState(
          manualPagination: true,
          pagination: PaginationState(pageIndex: 0, pageSize: 2),
        ),
      );

      // In server-side mode, whatever data we set IS the pre-paginated page
      c.setData([
        const _Item(id: '1', name: 'Alice', score: 1, category: 'A'),
        const _Item(id: '2', name: 'Bob', score: 2, category: 'A'),
      ]);

      expect(c.getRowModels().pageRows.length, 2);
    });
  });

  group('Pipeline — faceting via filteredRows', () {
    test('filteredRows reflects all items before pagination', () {
      final c = _makeController(
        initialState: const GridState(
          pagination: PaginationState(pageIndex: 0, pageSize: 2),
        ),
      );
      // 5 items total, page size 2 — filteredRows should have all 5
      expect(c.getRowModels().filteredRows.length, 5);
    });

    test('filteredRows respects active column filter', () {
      final c = _makeController();
      c.setColumnFilter('category', 'A');
      final filtered = c.getRowModels().filteredRows;
      expect(filtered.length, 3); // only Zara, Bob, Eve
      expect(filtered.every((r) => r.original.category == 'A'), true);
    });

    test('manual unique value computation from filteredRows', () {
      final c = _makeController();
      c.setColumnFilter('category', 'A');
      final rows = c.getRowModels().filteredRows;
      final categories = rows.map((r) => r.original.category).toSet();
      expect(categories, {'A'});
    });

    test('min/max score from filteredRows after category filter', () {
      final c = _makeController();
      c.setColumnFilter('category', 'A'); // scores: 90, 85, 75
      final rows = c.getRowModels().filteredRows;
      final scores = rows.map((r) => r.original.score).toList();
      expect(scores.reduce((a, b) => a < b ? a : b), 75);
      expect(scores.reduce((a, b) => a > b ? a : b), 90);
    });
  });

  group('Pipeline — row pinning interplay', () {
    test('pinned rows excluded from pageRows but in topPinnedRows', () {
      final c = _makeController(
        features: const [RowPinningFeature(keepPinnedRows: false)],
      );
      c.dispatch(const PinRowCommand('1', RowPinPosition.top));

      final models = c.getRowModels();
      expect(models.topPinnedRows.length, 1);
      expect(models.topPinnedRows.first.original.id, '1');
      expect(models.pageRows.any((r) => r.original.id == '1'), false);
    });
  });

  group('Pipeline — pagination boundary', () {
    test('last page shows remaining items', () {
      final c = _makeController(
        initialState: const GridState(
          pagination: PaginationState(pageIndex: 2, pageSize: 2),
        ),
      );
      // 5 items, page size 2 → page 3 has 1 item
      final page = c.getRowModels().pageRows;
      expect(page.length, 1);
    });

    test('out-of-range page returns empty', () {
      final c = _makeController(
        initialState: const GridState(
          pagination: PaginationState(pageIndex: 99, pageSize: 2),
        ),
      );
      final page = c.getRowModels().pageRows;
      expect(page.length, 0);
    });

    test('totalPages computed correctly', () {
      final c = _makeController(
        initialState: const GridState(
          pagination: PaginationState(pageIndex: 0, pageSize: 2),
        ),
      );
      expect(c.getRowModels().totalPages, 3); // ceil(5/2) = 3
    });
  });
}
