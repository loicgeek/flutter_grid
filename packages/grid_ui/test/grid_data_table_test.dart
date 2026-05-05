import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grid_core/grid_core.dart';
import 'package:grid_flutter/grid_flutter.dart';
import 'package:grid_ui/grid_ui.dart';

class _Item {
  final String label;
  const _Item(this.label);
}

GridController<_Item> _makeController({double colWidth = 100}) {
  final c = GridController<_Item>(
    options: GridOptions(
      columns: [
        ColumnDef<_Item, String>.accessor(
          id: 'label',
          accessorFn: (i) => i.label,
          header: 'Label',
          size: colWidth,
        ),
      ],
    ),
  );
  c.setData([const _Item('Row 1'), const _Item('Row 2')]);
  return c;
}

GridTableState<_Item> _buildTableState(GridController<_Item> c) {
  final rowSet = c.getRowModels();
  return GridTableState<_Item>(
    controller: c,
    state: c.state,
    rowModelSet: rowSet,
    allColumns: c.getAllColumns(),
    visibleColumns: c.getVisibleColumns(),
    leftPinnedColumns: c.getLeftPinnedColumns(),
    centerColumns: c.getCenterColumns(),
    rightPinnedColumns: c.getRightPinnedColumns(),
    headerGroups: c.getHeaderGroups(),
    isLoading: false,
  );
}

Widget _wrap(Widget child, {double screenWidth = 800}) {
  return MaterialApp(
    home: Scaffold(
      body: SizedBox(width: screenWidth, child: child),
    ),
  );
}

void main() {
  group('GridDataTable fillWidth', () {
    testWidgets('fillWidth=false: inner SizedBox matches total column width',
        (tester) async {
      const colWidth = 100.0;
      final controller = _makeController(colWidth: colWidth);
      final table = _buildTableState(controller);

      await tester.pumpWidget(_wrap(
        GridDataTable<_Item>(
          controller: controller,
          table: table,
          fillWidth: false,
        ),
        screenWidth: 800,
      ));

      final sizedBox = tester
          .widgetList<SizedBox>(find.byType(SizedBox))
          .firstWhere((b) => b.width == colWidth);
      expect(sizedBox.width, colWidth);
    });

    testWidgets(
        'fillWidth=true: inner SizedBox expands to screen width when columns are narrow',
        (tester) async {
      const colWidth = 100.0;
      const screenWidth = 800.0;
      final controller = _makeController(colWidth: colWidth);
      final table = _buildTableState(controller);

      await tester.pumpWidget(_wrap(
        GridDataTable<_Item>(
          controller: controller,
          table: table,
          fillWidth: true,
        ),
        screenWidth: screenWidth,
      ));

      // The SizedBox inside SingleChildScrollView should be at least screenWidth
      final sizedBoxes = tester
          .widgetList<SizedBox>(find.byType(SizedBox))
          .where((b) => b.width != null && b.width! >= screenWidth)
          .toList();
      expect(sizedBoxes, isNotEmpty);
    });

    testWidgets(
        'fillWidth=true: inner SizedBox uses total column width when wider than screen',
        (tester) async {
      const colWidth = 1200.0;
      const screenWidth = 800.0;
      final controller = _makeController(colWidth: colWidth);
      final table = _buildTableState(controller);

      await tester.pumpWidget(_wrap(
        GridDataTable<_Item>(
          controller: controller,
          table: table,
          fillWidth: true,
        ),
        screenWidth: screenWidth,
      ));

      final sizedBoxes = tester
          .widgetList<SizedBox>(find.byType(SizedBox))
          .where((b) => b.width == colWidth)
          .toList();
      expect(sizedBoxes, isNotEmpty);
    });
  });

  group('GridDataTable rendering', () {
    testWidgets('renders header text', (tester) async {
      final controller = _makeController();
      final table = _buildTableState(controller);

      await tester.pumpWidget(_wrap(
        GridDataTable<_Item>(
          controller: controller,
          table: table,
        ),
      ));

      expect(find.text('Label'), findsOneWidget);
    });

    testWidgets('renders all data rows', (tester) async {
      final controller = _makeController();
      final table = _buildTableState(controller);

      await tester.pumpWidget(_wrap(
        GridDataTable<_Item>(
          controller: controller,
          table: table,
        ),
      ));

      expect(find.text('Row 1'), findsOneWidget);
      expect(find.text('Row 2'), findsOneWidget);
    });

    testWidgets('calls onRowTap with the correct row', (tester) async {
      final controller = _makeController();
      final table = _buildTableState(controller);
      _Item? tapped;

      await tester.pumpWidget(_wrap(
        GridDataTable<_Item>(
          controller: controller,
          table: table,
          onRowTap: (row) => tapped = row.original,
        ),
      ));

      await tester.tap(find.text('Row 1'));
      expect(tapped?.label, 'Row 1');
    });

    testWidgets('re-renders rows after sort (position-based IDs bug regression)',
        (tester) async {
      // When rows have position-based IDs (the default), sorting changes the
      // original objects at each position without changing IDs. The table must
      // still update its displayed content.
      final controller = GridController<_Item>(
        options: GridOptions(
          columns: [
            ColumnDef<_Item, String>.accessor(
              id: 'label',
              accessorFn: (i) => i.label,
              header: 'Label',
              size: 200,
            ),
          ],
        ),
      );
      controller.setData([const _Item('B'), const _Item('A')]);

      Widget buildWithController() => _wrap(
            GridBuilder<_Item>(
              controller: controller,
              builder: (ctx, table) => GridDataTable<_Item>(
                controller: controller,
                table: table,
              ),
            ),
          );

      await tester.pumpWidget(buildWithController());
      await tester.pump();
      // Before sort: B appears before A
      final textsBefore = tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data)
          .where((t) => t == 'A' || t == 'B')
          .toList();
      expect(textsBefore.indexOf('B'), lessThan(textsBefore.indexOf('A')));

      // Sort ascending
      controller.toggleSort('label');
      await tester.pumpAndSettle();

      // After sort: A should appear before B
      final textsAfter = tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data)
          .where((t) => t == 'A' || t == 'B')
          .toList();
      expect(textsAfter.indexOf('A'), lessThan(textsAfter.indexOf('B')));
    });

    testWidgets('shows dividers between rows when showColumnBorders=true',
        (tester) async {
      final controller = _makeController();
      final table = _buildTableState(controller);

      await tester.pumpWidget(_wrap(
        GridDataTable<_Item>(
          controller: controller,
          table: table,
          showColumnBorders: true,
        ),
      ));

      // At least the header divider + one row divider
      expect(find.byType(Divider), findsWidgets);
    });
  });
}
