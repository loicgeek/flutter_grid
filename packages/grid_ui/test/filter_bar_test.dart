import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grid_core/grid_core.dart';
import 'package:grid_ui/src/components/grid_filter_bar.dart';

class _Item {
  final String name;
  final String category;
  const _Item(this.name, this.category);
}

GridController<_Item> _makeController() {
  final c = GridController<_Item>(
    options: GridOptions(
      columns: [
        ColumnDef<_Item, String>.accessor(
          id: 'name',
          accessorFn: (i) => i.name,
          header: 'Name',
        ),
        ColumnDef<_Item, String>.accessor(
          id: 'category',
          accessorFn: (i) => i.category,
          header: 'Category',
        ),
      ],
    ),
  );
  c.setData([
    const _Item('Alice', 'A'),
    const _Item('Bob', 'B'),
    const _Item('Charlie', 'A'),
  ]);
  return c;
}

Widget _wrap(Widget child) {
  // InkSparkle (default ≥Flutter 3.3) loads a GLSL shader that fails to decode
  // in the test VM. Use InkRipple (software-only) to keep Chip taps working.
  return MaterialApp(
    theme: ThemeData(splashFactory: InkRipple.splashFactory),
    home: Scaffold(body: child),
  );
}

void main() {
  group('GridFilterBar', () {
    testWidgets('hidden when no filters are active', (tester) async {
      final controller = _makeController();

      await tester.pumpWidget(_wrap(
        GridFilterBar<_Item>(controller: controller),
      ));

      // Should render nothing (SizedBox.shrink)
      expect(find.byType(Chip), findsNothing);
    });

    testWidgets('shows chip when column filter is set', (tester) async {
      final controller = _makeController();
      controller.setColumnFilter('category', 'A');

      await tester.pumpWidget(_wrap(
        GridFilterBar<_Item>(controller: controller),
      ));
      await tester.pump();

      expect(find.byType(Chip), findsOneWidget);
    });

    testWidgets('chip label includes column header and filter value',
        (tester) async {
      final controller = _makeController();
      controller.setColumnFilter('category', 'B');

      await tester.pumpWidget(_wrap(
        GridFilterBar<_Item>(controller: controller),
      ));
      await tester.pump();

      expect(find.textContaining('Category'), findsOneWidget);
      expect(find.textContaining('B'), findsWidgets);
    });

    testWidgets('shows multiple chips when multiple filters set', (tester) async {
      final controller = _makeController();
      controller.setColumnFilter('name', 'Alice');
      controller.setColumnFilter('category', 'A');

      await tester.pumpWidget(_wrap(
        GridFilterBar<_Item>(controller: controller),
      ));
      await tester.pump();

      expect(find.byType(Chip), findsNWidgets(2));
    });

    testWidgets('tapping chip delete removes the filter', (tester) async {
      final controller = _makeController();
      controller.setColumnFilter('category', 'A');

      await tester.pumpWidget(_wrap(
        GridFilterBar<_Item>(controller: controller),
      ));
      await tester.pump();

      expect(find.byType(Chip), findsOneWidget);

      // Tap delete icon on chip
      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();

      expect(controller.state.columnFilters.containsKey('category'), false);
    });

    testWidgets('hides chips after all filters are cleared', (tester) async {
      final controller = _makeController();
      controller.setColumnFilter('name', 'Alice');

      await tester.pumpWidget(_wrap(
        GridFilterBar<_Item>(controller: controller),
      ));
      await tester.pump();

      expect(find.byType(Chip), findsOneWidget);

      controller.clearAllFilters();
      await tester.pump();

      expect(find.byType(Chip), findsNothing);
    });

    testWidgets('updates reactively when filter added after initial build',
        (tester) async {
      final controller = _makeController();

      await tester.pumpWidget(_wrap(
        GridFilterBar<_Item>(controller: controller),
      ));
      await tester.pump();

      expect(find.byType(Chip), findsNothing);

      controller.setColumnFilter('name', 'Bob');
      await tester.pump();

      expect(find.byType(Chip), findsOneWidget);
    });
  });
}
