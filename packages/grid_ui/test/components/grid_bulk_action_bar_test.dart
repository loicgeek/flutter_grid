import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grid_core/grid_core.dart';
import 'package:grid_ui/src/components/grid_bulk_action_bar.dart';
import 'package:grid_ui/src/theme/grid_theme.dart';

void main() {
  testWidgets(
      'GridBulkActionBar shows normal count and select all pages button when enabled',
      (WidgetTester tester) async {
    final controller = GridController<String>(
      options: GridOptions(
        columns: const [],
        features: [SelectionFeature(enableSelectAllPages: true)],
      ),
      initialState: const GridState(
        pagination: PaginationState(pageIndex: 0, pageSize: 2),
      ),
    );

    // Total 3 items. Page size 2. We select page 1 (2 items)
    controller.setData(['A', 'B', 'C']);
    controller.toggleRowSelection('0');
    controller.toggleRowSelection('1');

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GridTheme(
            data: const GridThemeData(),
            child: GridBulkActionBar<String>(
              controller: controller,
              actions: const [],
            ),
          ),
        ),
      ),
    );

    // Verify it says "2 items selected"
    expect(find.text('2 items selected'), findsOneWidget);

    // Verify cross pagination text is present
    expect(find.text('Select all 3 items across all pages'), findsOneWidget);

    // Tap it to select all pages
    await tester.tap(find.text('Select all 3 items across all pages'));
    await tester.pump();

    expect(controller.state.selectAllPages, true);
  });
}
