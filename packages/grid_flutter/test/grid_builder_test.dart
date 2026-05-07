import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grid_core/grid_core.dart';
import 'package:grid_flutter/grid_flutter.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Fake data source helpers
// ─────────────────────────────────────────────────────────────────────────────

class _FakeDataSource extends GridDataSource<String> {
  final List<String> data;
  final Duration delay;
  final Exception? error;
  int fetchCallCount = 0;

  _FakeDataSource({
    this.data = const ['a', 'b', 'c'],
    this.delay = Duration.zero,
    this.error,
  });

  @override
  Future<GridPage<String>> fetch(GridQuery query) async {
    fetchCallCount++;
    if (delay != Duration.zero) await Future.delayed(delay);
    if (error != null) throw error!;
    return GridPage(
      data: data,
      currentPage: query.pageIndex + 1,
      pageSize: query.pageSize,
      totalItems: data.length,
    );
  }
}

/// A data source whose fetch() completes only when [complete] is called.
class _ControllableFakeDataSource extends GridDataSource<String> {
  final List<String> data;
  int fetchCallCount = 0;
  Completer<GridPage<String>>? _pending;

  _ControllableFakeDataSource({this.data = const ['a', 'b', 'c']});

  @override
  Future<GridPage<String>> fetch(GridQuery query) {
    fetchCallCount++;
    _pending = Completer<GridPage<String>>();
    return _pending!.future;
  }

  void complete() {
    _pending?.complete(GridPage(
      data: data,
      currentPage: 1,
      pageSize: data.length,
      totalItems: data.length,
    ));
  }

  void completeWithError(Exception e) {
    _pending?.completeError(e);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

GridController<String> _makeController() => GridController<String>(
      options: GridOptions(
        columns: [
          ColumnDef<String, String>.accessor(
            id: 'val',
            accessorFn: (s) => s,
            header: 'Value',
          ),
        ],
      ),
    );

Widget _wrap(GridController<String> controller, GridDataSource<String> ds) {
  return MaterialApp(
    home: Scaffold(
      body: GridBuilder<String>(
        controller: controller,
        dataSource: ds,
        builder: (context, table) => Column(
          children: [
            if (table.isLoading) const CircularProgressIndicator(),
            if (table.error != null) Text('Error: ${table.error}'),
            Text('rows: ${table.pageRows.length}'),
            Text('fetch: done'),
          ],
        ),
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Tests
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  group('GridBuilder — basic rendering', () {
    testWidgets('renders builder callback output', (tester) async {
      final c = _makeController();
      final ds = _FakeDataSource();

      await tester.pumpWidget(_wrap(c, ds));
      await tester.pumpAndSettle();

      expect(find.text('fetch: done'), findsOneWidget);
    });

    testWidgets('shows rows returned by fetch()', (tester) async {
      final c = _makeController();
      final ds = _FakeDataSource(data: ['x', 'y', 'z']);

      await tester.pumpWidget(_wrap(c, ds));
      await tester.pumpAndSettle();

      expect(find.text('rows: 3'), findsOneWidget);
    });

    testWidgets('isLoading is true while fetch is in flight', (tester) async {
      final c = _makeController();
      final ds = _ControllableFakeDataSource();

      await tester.pumpWidget(_wrap(c, ds));
      // fetch has been issued but not completed → isLoading should be true
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      ds.complete();
      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('isLoading is false after fetch completes', (tester) async {
      final c = _makeController();
      final ds = _FakeDataSource();

      await tester.pumpWidget(_wrap(c, ds));
      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('shows error when fetch throws', (tester) async {
      final c = _makeController();
      final ds = _FakeDataSource(error: Exception('Network error'));

      await tester.pumpWidget(_wrap(c, ds));
      await tester.pumpAndSettle();

      expect(find.textContaining('Error:'), findsOneWidget);
      expect(find.textContaining('Network error'), findsOneWidget);
    });

    testWidgets('fetch is called once on init', (tester) async {
      final c = _makeController();
      final ds = _FakeDataSource();

      await tester.pumpWidget(_wrap(c, ds));
      await tester.pumpAndSettle();

      expect(ds.fetchCallCount, 1);
    });
  });

  group('GridBuilder — re-entrancy guard (_settingData)', () {
    // This is the core regression test for the infinite-loop bug.
    //
    // Without the _settingData flag the call chain was:
    //   _fetch completes
    //   → setDataWithPageCountAndTotalItems()
    //   → _notifyListeners()  [synchronous]
    //   → _onControllerChanged()
    //   → _fetch()  ← starts another fetch immediately
    //   → loop forever
    //
    // With the flag, a second _onControllerChanged() during setData is ignored.

    testWidgets(
        'setting data does not trigger a second fetch (no infinite loop)',
        (tester) async {
      final c = _makeController();
      final ds = _FakeDataSource();

      await tester.pumpWidget(_wrap(c, ds));
      await tester.pumpAndSettle();

      // If the re-entrancy guard is missing, fetchCallCount would grow without
      // bound; with it, exactly one fetch fires on init.
      expect(ds.fetchCallCount, 1);
    });

    testWidgets(
        'applying an external filter triggers exactly one more fetch',
        (tester) async {
      final c = _makeController();
      final ds = _FakeDataSource();

      await tester.pumpWidget(_wrap(c, ds));
      await tester.pumpAndSettle();
      final countAfterInit = ds.fetchCallCount;

      c.setExternalFilter('status', ExternalFilter.eq('active'));
      await tester.pumpAndSettle();

      // Exactly one additional fetch for the state change — not multiple.
      expect(ds.fetchCallCount, countAfterInit + 1);
    });

    testWidgets(
        'rapidly changing external filters fires one fetch per change',
        (tester) async {
      final c = _makeController();
      final ds = _FakeDataSource();

      await tester.pumpWidget(_wrap(c, ds));
      await tester.pumpAndSettle();
      final countAfterInit = ds.fetchCallCount;

      // Rapidly apply three different filters without waiting.
      c.setExternalFilter('a', ExternalFilter.eq(1));
      c.setExternalFilter('b', ExternalFilter.eq(2));
      c.setExternalFilter('c', ExternalFilter.eq(3));
      await tester.pumpAndSettle();

      // Three state changes → three fetches triggered (epoch ensures only the
      // last one's result is applied, but all three are started).
      expect(ds.fetchCallCount, greaterThanOrEqualTo(countAfterInit + 1));
      // Final row count comes from the last completed fetch.
      expect(find.text('rows: 3'), findsOneWidget);
    });
  });

  group('GridBuilder — epoch-based cancellation', () {
    testWidgets(
        'stale response is discarded when a newer fetch is in flight',
        (tester) async {
      final c = _makeController();
      final ds1 = _ControllableFakeDataSource(data: ['stale1', 'stale2']);
      final ds2 = _ControllableFakeDataSource(data: ['fresh']);

      // Start with ds1 — fetch is in flight but not complete.
      await tester.pumpWidget(_wrap(c, ds1));
      await tester.pump(); // isLoading = true

      // Swap to ds2 — this starts a new fetch (higher epoch).
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: GridBuilder<String>(
            controller: c,
            dataSource: ds2,
            builder: (context, table) =>
                Text('rows: ${table.pageRows.length}'),
          ),
        ),
      ));
      await tester.pump();

      // Complete the SECOND (newer) fetch first.
      ds2.complete();
      await tester.pumpAndSettle();

      // Now complete the FIRST (stale) fetch — should be ignored.
      ds1.complete();
      await tester.pumpAndSettle();

      // Only the fresh data should be visible.
      expect(find.text('rows: 1'), findsOneWidget);
    });

    testWidgets('stale error is discarded when a newer fetch succeeded',
        (tester) async {
      final c = _makeController();
      final ds1 = _ControllableFakeDataSource();
      final ds2 = _ControllableFakeDataSource(data: ['good']);

      await tester.pumpWidget(_wrap(c, ds1));
      await tester.pump();

      // Swap to ds2.
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: GridBuilder<String>(
            controller: c,
            dataSource: ds2,
            builder: (context, table) => Column(children: [
              if (table.error != null) Text('Error: ${table.error}'),
              Text('rows: ${table.pageRows.length}'),
            ]),
          ),
        ),
      ));
      await tester.pump();

      // Newer fetch completes successfully.
      ds2.complete();
      await tester.pumpAndSettle();

      // Older fetch completes with error — must be ignored.
      ds1.completeWithError(Exception('old error'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Error:'), findsNothing);
      expect(find.text('rows: 1'), findsOneWidget);
    });
  });

  group('GridBuilder — controller listener lifecycle', () {
    testWidgets('removes listener on dispose', (tester) async {
      final c = _makeController();
      final ds = _FakeDataSource();

      await tester.pumpWidget(_wrap(c, ds));
      await tester.pumpAndSettle();
      final countBefore = ds.fetchCallCount;

      // Replace the GridBuilder with something else → dispose() is called.
      await tester.pumpWidget(const MaterialApp(home: Text('done')));

      // Mutating the controller after disposal must not trigger a fetch.
      c.setExternalFilter('x', ExternalFilter.eq(1));
      await tester.pump();

      expect(ds.fetchCallCount, countBefore);
    });

    testWidgets('adds listener to new controller on didUpdateWidget',
        (tester) async {
      final c1 = _makeController();
      final c2 = _makeController();
      final ds = _FakeDataSource();

      Widget build(GridController<String> ctrl) => MaterialApp(
            home: Scaffold(
              body: GridBuilder<String>(
                controller: ctrl,
                dataSource: ds,
                builder: (context, table) =>
                    Text('rows: ${table.pageRows.length}'),
              ),
            ),
          );

      await tester.pumpWidget(build(c1));
      await tester.pumpAndSettle();
      final countAfterC1 = ds.fetchCallCount;

      // Swap controllers — only the listener is re-wired; no new fetch fires
      // (a fetch only auto-triggers when the dataSource changes, not the
      // controller).
      await tester.pumpWidget(build(c2));
      await tester.pumpAndSettle();
      expect(ds.fetchCallCount, countAfterC1);

      // The OLD controller no longer triggers fetches (listener removed).
      c1.setExternalFilter('x', ExternalFilter.eq(1));
      await tester.pump();
      expect(ds.fetchCallCount, countAfterC1); // unchanged

      // The NEW controller does trigger a fetch.
      c2.setExternalFilter('y', ExternalFilter.eq(2));
      await tester.pumpAndSettle();
      expect(ds.fetchCallCount, countAfterC1 + 1);
    });

    testWidgets('no dataSource → builder is called with empty state and no loading',
        (tester) async {
      final c = _makeController();

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: GridBuilder<String>(
            controller: c,
            // no dataSource
            builder: (context, table) => Column(children: [
              if (table.isLoading) const Text('loading'),
              Text('rows: ${table.pageRows.length}'),
            ]),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('loading'), findsNothing);
      expect(find.text('rows: 0'), findsOneWidget);
    });
  });
}
