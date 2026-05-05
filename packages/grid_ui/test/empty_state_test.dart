import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grid_ui/src/slots/grid_empty_state.dart';
import 'package:grid_ui/src/slots/grid_slots.dart';

Widget _wrap(Widget child) {
  return MaterialApp(home: Scaffold(body: child));
}

void main() {
  group('GridEmptyState', () {
    testWidgets('noData reason shows "No data available"', (tester) async {
      await tester.pumpWidget(_wrap(
        GridEmptyState(
          ctx: const GridEmptyContext(reason: EmptyReason.noData),
        ),
      ));
      expect(find.text('No data available'), findsOneWidget);
    });

    testWidgets('filtered reason shows "No matching results"', (tester) async {
      await tester.pumpWidget(_wrap(
        GridEmptyState(
          ctx: const GridEmptyContext(reason: EmptyReason.filtered),
        ),
      ));
      expect(find.text('No matching results'), findsOneWidget);
    });

    testWidgets('searched reason shows "No search results"', (tester) async {
      await tester.pumpWidget(_wrap(
        GridEmptyState(
          ctx: const GridEmptyContext(reason: EmptyReason.searched),
        ),
      ));
      expect(find.text('No search results'), findsOneWidget);
    });

    testWidgets('filtered shows clear-filter button when callback provided',
        (tester) async {
      bool cleared = false;
      await tester.pumpWidget(_wrap(
        GridEmptyState(
          ctx: GridEmptyContext(
            reason: EmptyReason.filtered,
            onClearFilters: () => cleared = true,
          ),
        ),
      ));

      expect(find.text('Clear filters'), findsOneWidget);
      await tester.tap(find.text('Clear filters'));
      expect(cleared, isTrue);
    });

    testWidgets(
        'filtered shows no clear-filter button when callback is null',
        (tester) async {
      await tester.pumpWidget(_wrap(
        GridEmptyState(
          ctx: const GridEmptyContext(reason: EmptyReason.filtered),
        ),
      ));
      expect(find.text('Clear filters'), findsNothing);
    });

    testWidgets('noData shows an icon', (tester) async {
      await tester.pumpWidget(_wrap(
        GridEmptyState(
          ctx: const GridEmptyContext(reason: EmptyReason.noData),
        ),
      ));
      expect(find.byType(Icon), findsOneWidget);
    });
  });
}
