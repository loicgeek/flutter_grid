import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grid_core/grid_core.dart';
import 'package:grid_flutter/grid_flutter.dart';
import 'package:grid_ui/src/slots/grid_aggregation_footer.dart';
import 'package:grid_ui/src/theme/grid_theme.dart';

void main() {
  testWidgets('GridAggregationFooter calculates and displays aggregation values', (WidgetTester tester) async {
    final columns = [
      ColumnDef<int, int>.accessor(
        id: 'val',
        accessorFn: (r) => r,
        size: 100,
        aggregationFn: (leafRows, childRows) {
          return leafRows.fold<int>(0, (sum, row) => sum + (row.original as int));
        },
        aggregatedCell: (ctx) => Text('Sum: ${ctx['value']}'),
      ),
      ColumnDef<int, int>.accessor(
        id: 'none',
        accessorFn: (r) => r,
        size: 50,
      )
    ];

    final controller = GridController<int>(
      options: GridOptions(columns: columns),
    );
    
    // Total sum should be 1 + 2 + 3 = 6
    controller.setData([1, 2, 3]);

    final rowSet = controller.getRowModels();
    final tableState = GridTableState<int>(
      controller: controller,
      state: controller.state,
      rowModelSet: rowSet,
      allColumns: controller.getAllColumns(),
      visibleColumns: controller.getVisibleColumns(),
      leftPinnedColumns: controller.getLeftPinnedColumns(),
      centerColumns: controller.getCenterColumns(),
      rightPinnedColumns: controller.getRightPinnedColumns(),
      headerGroups: const [],
      isLoading: false,
      hasData: rowSet.pageRows.isNotEmpty,
      retry: () {},
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GridTheme(
            data: const GridThemeData(),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: GridAggregationFooter<int>(
                table: tableState,
              ),
            ),
          ),
        ),
      ),
    );

    // It should render the aggregated text
    expect(find.text('Sum: 6'), findsOneWidget);
  });
}
