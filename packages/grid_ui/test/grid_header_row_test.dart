import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grid_core/grid_core.dart';
import 'package:grid_ui/grid_ui.dart';

class _Person {
  final String name;
  final int age;
  const _Person(this.name, this.age);
}

ColumnInfo<_Person, Object?> _makeCol(String id, double width,
    {bool visible = true}) {
  return ColumnInfo<_Person, Object?>(
    def: ColumnDef<_Person, String>.accessor(
      id: id,
      accessorFn: (p) => p.name,
      header: id,
      size: width,
    ),
    id: id,
    isVisible: visible,
    isPinnedLeft: false,
    isPinnedRight: false,
    effectiveWidth: width,
    orderIndex: 0,
  );
}

GridController<_Person> _makeController() {
  return GridController<_Person>(
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
        ),
      ],
    ),
  );
}

Widget _wrap(Widget child, {GridThemeData? themeData}) {
  return MaterialApp(
    home: Scaffold(
      body: themeData != null
          ? GridTheme(data: themeData, child: child)
          : child,
    ),
  );
}

void main() {
  group('GridHeaderRow', () {
    late GridController<_Person> controller;

    setUp(() {
      controller = _makeController();
      controller.setData([const _Person('Alice', 30)]);
    });

    testWidgets('renders header text for each visible leaf column',
        (tester) async {
      final visibleCols = controller.getVisibleColumns();
      final group = controller.getHeaderGroups().first;

      await tester.pumpWidget(_wrap(
        SizedBox(
          width: 800,
          child: GridHeaderRow<_Person>(
            group: group,
            controller: controller,
            visibleColumns: visibleCols,
          ),
        ),
      ));

      expect(find.text('Name'), findsOneWidget);
      expect(find.text('Age'), findsOneWidget);
    });

    testWidgets('skips hidden column headers', (tester) async {
      controller.setColumnVisibility('age', false);
      final visibleCols = controller.getVisibleColumns();
      final group = controller.getHeaderGroups().first;

      await tester.pumpWidget(_wrap(
        SizedBox(
          width: 800,
          child: GridHeaderRow<_Person>(
            group: group,
            controller: controller,
            visibleColumns: visibleCols,
          ),
        ),
      ));

      expect(find.text('Name'), findsOneWidget);
      expect(find.text('Age'), findsNothing);
    });

    testWidgets('leaf header SizedBox width equals column effectiveWidth',
        (tester) async {
      final visibleCols = controller.getVisibleColumns();
      final group = controller.getHeaderGroups().first;

      await tester.pumpWidget(_wrap(
        SizedBox(
          width: 800,
          child: GridHeaderRow<_Person>(
            group: group,
            controller: controller,
            visibleColumns: visibleCols,
          ),
        ),
      ));

      // The SizedBox wrapping the 'Name' header cell should be 120 wide
      final sizedBoxes = tester
          .widgetList<SizedBox>(find.byType(SizedBox))
          .where((b) => b.width != null)
          .toList();

      expect(sizedBoxes.any((b) => b.width == 120), isTrue);
      expect(sizedBoxes.any((b) => b.width == 80), isTrue);
    });

    testWidgets('group header spans sum of colSpan visible column widths',
        (tester) async {
      // Build a header group manually with a span header covering 2 columns.
      final col1 = _makeCol('a', 100);
      final col2 = _makeCol('b', 150);
      final visibleCols = [col1, col2];

      final spanGroup = HeaderGroup<_Person>(
        id: 'grp',
        depth: 0,
        headers: [
          Header<_Person>(
            id: 'group_ab',
            colSpan: 2,
            group: const ColumnDefGroup<_Person>(
              id: 'ab',
              header: 'AB Group',
              columns: [],
            ),
          ),
        ],
      );

      await tester.pumpWidget(_wrap(
        SizedBox(
          width: 800,
          child: GridHeaderRow<_Person>(
            group: spanGroup,
            controller: controller,
            visibleColumns: visibleCols,
          ),
        ),
      ));

      // The span header text should be visible
      expect(find.text('AB Group'), findsOneWidget);

      // The SizedBox for the span header should be 100+150 = 250
      final sizedBoxes = tester
          .widgetList<SizedBox>(find.byType(SizedBox))
          .where((b) => b.width == 250)
          .toList();
      expect(sizedBoxes, isNotEmpty);
    });

    testWidgets('group header with partial colSpan clamps to available columns',
        (tester) async {
      final col1 = _makeCol('a', 100);
      final visibleCols = [col1]; // only 1 column, colSpan=3

      final spanGroup = HeaderGroup<_Person>(
        id: 'grp',
        depth: 0,
        headers: [
          Header<_Person>(
            id: 'wide',
            colSpan: 3,
            group: const ColumnDefGroup<_Person>(
              id: 'wide',
              header: 'Wide',
              columns: [],
            ),
          ),
        ],
      );

      await tester.pumpWidget(_wrap(
        SizedBox(
          width: 800,
          child: GridHeaderRow<_Person>(
            group: spanGroup,
            controller: controller,
            visibleColumns: visibleCols,
          ),
        ),
      ));

      // Should render without throwing; width clamped to available (100)
      expect(find.text('Wide'), findsOneWidget);
    });

    testWidgets('tapping sortable header toggles sort', (tester) async {
      final visibleCols = controller.getVisibleColumns();
      final group = controller.getHeaderGroups().first;

      await tester.pumpWidget(_wrap(
        SizedBox(
          width: 800,
          child: GridHeaderRow<_Person>(
            group: group,
            controller: controller,
            visibleColumns: visibleCols,
          ),
        ),
      ));

      expect(controller.state.sorting, isEmpty);
      await tester.tap(find.text('Name'));
      expect(controller.state.sorting.length, 1);
      expect(controller.state.sorting.first.columnId, 'name');
    });
  });
}
