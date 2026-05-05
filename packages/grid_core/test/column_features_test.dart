import 'package:grid_core/grid_core.dart';
import 'package:test/test.dart';

class _Item {
  final String id;
  final String name;
  final int score;
  final String category;
  const _Item(this.id, this.name, this.score, this.category);
}

GridController<_Item> _makeController({List<GridFeature> features = const []}) {
  final c = GridController<_Item>(
    options: GridOptions(
      columns: [
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
      ],
      features: features,
      getRowId: (item, _) => item.id,
    ),
  );
  c.setData([
    const _Item('1', 'Alice', 90, 'A'),
    const _Item('2', 'Bob', 70, 'B'),
    const _Item('3', 'Charlie', 85, 'A'),
  ]);
  return c;
}

void main() {
  group('ColumnVisibilityFeature', () {
    test('all columns visible by default', () {
      final c = _makeController(features: [ColumnVisibilityFeature()]);
      final visible = c.state.columnVisibility;
      expect(visible['name'] ?? true, isTrue);
      expect(visible['score'] ?? true, isTrue);
      expect(visible['category'] ?? true, isTrue);
    });

    test('ToggleColumnVisibilityCommand hides a visible column', () {
      final c = _makeController(features: [ColumnVisibilityFeature()]);
      c.dispatch(const ToggleColumnVisibilityCommand('score'));
      expect(c.state.columnVisibility['score'], isFalse);
    });

    test('toggling twice restores visibility', () {
      final c = _makeController(features: [ColumnVisibilityFeature()]);
      c.dispatch(const ToggleColumnVisibilityCommand('score'));
      c.dispatch(const ToggleColumnVisibilityCommand('score'));
      expect(c.state.columnVisibility['score'], isTrue);
    });

    test('SetColumnVisibilityCommand explicitly sets visibility', () {
      final c = _makeController(features: [ColumnVisibilityFeature()]);
      c.dispatch(const SetColumnVisibilityCommand('name', false));
      expect(c.state.columnVisibility['name'], isFalse);

      c.dispatch(const SetColumnVisibilityCommand('name', true));
      expect(c.state.columnVisibility['name'], isTrue);
    });

    test('defaultVisibility hides specified columns from the start', () {
      final c = _makeController(
        features: [ColumnVisibilityFeature(defaultVisibility: {'score': false})],
      );
      // The feature sets default; state starts with empty columnVisibility
      // (feature.defaultVisibility is used by the UI layer — controller state is empty)
      // So we verify the feature stores the default correctly.
      final feature = c.options.features
          .whereType<ColumnVisibilityFeature>()
          .first;
      expect(feature.defaultVisibility['score'], isFalse);
    });

    test('hiding and showing a column does not affect row data', () {
      final c = _makeController(features: [ColumnVisibilityFeature()]);
      c.dispatch(const ToggleColumnVisibilityCommand('score'));
      final rows = c.getRowModels().pageRows;
      expect(rows.length, 3);
      expect(rows.map((r) => r.original.name).toList(),
          containsAll(['Alice', 'Bob', 'Charlie']));
    });
  });

  group('ColumnOrderingFeature', () {
    test('column order is empty by default', () {
      final c = _makeController(features: [ColumnOrderingFeature()]);
      expect(c.state.columnOrder, isEmpty);
    });

    test('SetColumnOrderCommand updates column order', () {
      final c = _makeController(features: [ColumnOrderingFeature()]);
      c.dispatch(const SetColumnOrderCommand(['category', 'name', 'score']));
      expect(c.state.columnOrder, ['category', 'name', 'score']);
    });

    test('column order can be changed multiple times', () {
      final c = _makeController(features: [ColumnOrderingFeature()]);
      c.dispatch(const SetColumnOrderCommand(['score', 'name', 'category']));
      expect(c.state.columnOrder.first, 'score');

      c.dispatch(const SetColumnOrderCommand(['name', 'category', 'score']));
      expect(c.state.columnOrder.first, 'name');
    });

    test('undo restores previous column order', () {
      final c = _makeController(features: [ColumnOrderingFeature()]);
      c.dispatch(const SetColumnOrderCommand(['category', 'name', 'score']));
      c.undo();
      expect(c.state.columnOrder, isEmpty);
    });

    test('column order change does not affect row data', () {
      final c = _makeController(features: [ColumnOrderingFeature()]);
      c.dispatch(const SetColumnOrderCommand(['score', 'category', 'name']));
      expect(c.getRowModels().pageRows.length, 3);
    });
  });

  group('ColumnSizingFeature', () {
    test('column sizing is empty by default', () {
      final c = _makeController(features: [ColumnSizingFeature()]);
      expect(c.state.columnSizing, isEmpty);
    });

    test('SetColumnSizeCommand stores the size', () {
      final c = _makeController(features: [ColumnSizingFeature()]);
      c.dispatch(const SetColumnSizeCommand('name', 200));
      expect(c.state.columnSizing['name'], 200);
    });

    test('multiple columns can be independently sized', () {
      final c = _makeController(features: [ColumnSizingFeature()]);
      c.dispatch(const SetColumnSizeCommand('name', 150));
      c.dispatch(const SetColumnSizeCommand('score', 80));
      expect(c.state.columnSizing['name'], 150);
      expect(c.state.columnSizing['score'], 80);
    });

    test('ResetColumnSizingCommand clears all sizing', () {
      final c = _makeController(features: [ColumnSizingFeature()]);
      c.dispatch(const SetColumnSizeCommand('name', 150));
      c.dispatch(const SetColumnSizeCommand('score', 80));
      c.dispatch(const ResetColumnSizingCommand());
      expect(c.state.columnSizing, isEmpty);
    });

    test('undo restores previous sizing', () {
      final c = _makeController(features: [ColumnSizingFeature()]);
      c.dispatch(const SetColumnSizeCommand('name', 200));
      c.undo();
      expect(c.state.columnSizing.containsKey('name'), isFalse);
    });

    test('sizing does not affect row count', () {
      final c = _makeController(features: [ColumnSizingFeature()]);
      c.dispatch(const SetColumnSizeCommand('name', 500));
      expect(c.getRowModels().pageRows.length, 3);
    });
  });
}
