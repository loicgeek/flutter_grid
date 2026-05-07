import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grid_core/grid_core.dart';
import 'package:grid_ui/grid_ui.dart';

class _Person {
  final String name;
  final int age;
  const _Person(this.name, this.age);
}

GridController<_Person> _makeController() {
  final c = GridController<_Person>(
    options: GridOptions(
      columns: [
        ColumnDef<_Person, String>.accessor(
          id: 'name',
          accessorFn: (p) => p.name,
          header: 'Name',
          size: 120,
        ),
        ColumnDef<_Person, int>.accessor(
          id: 'age',
          accessorFn: (p) => p.age,
          header: 'Age',
          size: 80,
          columnType: ColumnType.number,
        ),
      ],
    ),
  );
  c.setData([
    const _Person('Alice', 30),
    const _Person('Bob', 25),
  ]);
  return c;
}

Widget _wrap(Widget child, {GridThemeData? themeData}) {
  return MaterialApp(
    // InkSparkle (the default in Flutter ≥3.3) loads a GLSL shader that cannot
    // be decoded in the test VM. Use the software-only InkRipple instead so
    // InkWell / GestureDetector taps work without crashing.
    theme: ThemeData(splashFactory: InkRipple.splashFactory),
    home: Scaffold(
      body:
          themeData != null ? GridTheme(data: themeData, child: child) : child,
    ),
  );
}

void main() {
  group('GridDataRow', () {
    late GridController<_Person> controller;
    late List<ColumnInfo<_Person, Object?>> visibleCols;
    late RowModel<_Person> row;

    setUp(() {
      controller = _makeController();
      visibleCols = controller.getVisibleColumns();
      row = controller.getRowModels().pageRows.first;
    });

    testWidgets('renders a cell for each visible column', (tester) async {
      await tester.pumpWidget(_wrap(
        GridDataRow<_Person>(
          row: row,
          visibleColumns: visibleCols,
          controller: controller,
          columnWidths: {},
        ),
      ));

      // GridDataRow uses a Stack (not Row) so that pinned columns can be
      // Positioned independently. Count leaf SizedBoxes by their column widths.
      final cellBoxes = tester
          .widgetList<SizedBox>(find.byType(SizedBox))
          .where((b) => b.width == 120 || b.width == 80)
          .toList();
      expect(cellBoxes.length, visibleCols.length);
    });

    testWidgets('uses rowBackground by default', (tester) async {
      const bgColor = Color(0xFFAABBCC);
      await tester.pumpWidget(_wrap(
        GridDataRow<_Person>(
          row: row,
          visibleColumns: visibleCols,
          controller: controller,
        ),
        themeData: GridThemeData(rowBackground: bgColor),
      ));

      expect(
        find.byWidgetPredicate(
          (w) => w is Container && w.color == bgColor,
        ),
        findsOneWidget,
      );
    });

    testWidgets('uses alternateRowBackground when isStriped', (tester) async {
      const altColor = Color(0xFF112233);
      await tester.pumpWidget(_wrap(
        GridDataRow<_Person>(
          row: row,
          visibleColumns: visibleCols,
          controller: controller,
          isStriped: true,
        ),
        themeData: GridThemeData(alternateRowBackground: altColor),
      ));

      expect(
        find.byWidgetPredicate(
          (w) => w is Container && w.color == altColor,
        ),
        findsOneWidget,
      );
    });

    testWidgets('uses selectedRowBackground when row is selected',
        (tester) async {
      const selColor = Color(0xFF334455);
      controller.toggleRowSelection(row.id);
      // Re-fetch row with updated selection state
      final selectedRow = controller.getRowModels().pageRows.first;

      await tester.pumpWidget(_wrap(
        GridDataRow<_Person>(
          row: selectedRow,
          visibleColumns: visibleCols,
          controller: controller,
        ),
        themeData: GridThemeData(selectedRowBackground: selColor),
      ));

      expect(
        find.byWidgetPredicate(
          (w) => w is Container && w.color == selColor,
        ),
        findsOneWidget,
      );
    });

    testWidgets('switches to hoverRowBackground on mouse enter',
        (tester) async {
      const hoverColor = Color(0xFF00FF00);
      const normalColor = Color(0xFFFFFFFF);

      await tester.pumpWidget(_wrap(
        GridDataRow<_Person>(
          row: row,
          visibleColumns: visibleCols,
          controller: controller,
        ),
        themeData: GridThemeData(
          rowBackground: normalColor,
          hoverRowBackground: hoverColor,
        ),
      ));

      // Before hover — normal background
      expect(
        find.byWidgetPredicate((w) => w is Container && w.color == normalColor),
        findsOneWidget,
      );

      // Simulate mouse hover
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(
        location: tester.getCenter(find.byType(GridDataRow<_Person>)),
      );
      addTearDown(gesture.removePointer);
      await tester.pump();

      // After hover — hover background
      expect(
        find.byWidgetPredicate((w) => w is Container && w.color == hoverColor),
        findsOneWidget,
      );
    });

    testWidgets('reverts to normal background on mouse exit', (tester) async {
      const hoverColor = Color(0xFF00FF00);
      const normalColor = Color(0xFFFFFFFF);

      await tester.pumpWidget(_wrap(
        GridDataRow<_Person>(
          row: row,
          visibleColumns: visibleCols,
          controller: controller,
        ),
        themeData: GridThemeData(
          rowBackground: normalColor,
          hoverRowBackground: hoverColor,
        ),
      ));

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(
        location: tester.getCenter(find.byType(GridDataRow<_Person>)),
      );
      addTearDown(gesture.removePointer);
      await tester.pump();

      // Move pointer out of the widget
      await gesture.moveTo(const Offset(2000, 2000));
      await tester.pump();

      expect(
        find.byWidgetPredicate((w) => w is Container && w.color == normalColor),
        findsOneWidget,
      );
    });

    testWidgets('hover ignored when hoverRowBackground is null',
        (tester) async {
      const normalColor = Color(0xFFFFFFFF);

      await tester.pumpWidget(_wrap(
        GridDataRow<_Person>(
          row: row,
          visibleColumns: visibleCols,
          controller: controller,
        ),
        themeData: GridThemeData(
          rowBackground: normalColor,
          // hoverRowBackground intentionally null
        ),
      ));

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(
        location: tester.getCenter(find.byType(GridDataRow<_Person>)),
      );
      addTearDown(gesture.removePointer);
      await tester.pump();

      // Background unchanged
      expect(
        find.byWidgetPredicate((w) => w is Container && w.color == normalColor),
        findsOneWidget,
      );
    });

    testWidgets('calls onTap when tapped', (tester) async {
      RowModel<_Person>? tapped;
      await tester.pumpWidget(_wrap(
        GridDataRow<_Person>(
          row: row,
          visibleColumns: visibleCols,
          controller: controller,
          onTap: (r) => tapped = r,
        ),
      ));

      await tester.tap(find.byType(GridDataRow<_Person>));
      expect(tapped?.original.name, 'Alice');
    });

    testWidgets('calls onDoubleTap when double-tapped', (tester) async {
      RowModel<_Person>? doubleTapped;
      await tester.pumpWidget(_wrap(
        GridDataRow<_Person>(
          row: row,
          visibleColumns: visibleCols,
          controller: controller,
          onDoubleTap: (r) => doubleTapped = r,
        ),
      ));

      await tester.tap(find.byType(GridDataRow<_Person>));
      await tester.pump(kDoubleTapMinTime);
      await tester.tap(find.byType(GridDataRow<_Person>));
      await tester.pumpAndSettle();
      expect(doubleTapped?.original.name, 'Alice');
    });

    testWidgets('hidden column is excluded from cells', (tester) async {
      controller.setColumnVisibility('age', false);
      final cols = controller.getVisibleColumns();

      await tester.pumpWidget(_wrap(
        GridDataRow<_Person>(
          row: row,
          visibleColumns: cols,
          controller: controller,
        ),
      ));

      // Only the 'name' column (width 120) remains; 'age' (width 80) is hidden.
      final cellBoxes = tester
          .widgetList<SizedBox>(find.byType(SizedBox))
          .where((b) => b.width == 120 || b.width == 80)
          .toList();
      expect(cellBoxes.length, 1);
    });
  });
}
