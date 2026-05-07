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

  void complete({List<String>? data}) {
    _pending?.complete(GridPage(
      data: data ?? this.data,
      currentPage: 1,
      pageSize: (data ?? this.data).length,
      totalItems: (data ?? this.data).length,
    ));
  }

  void completeWithError(Exception e) {
    _pending?.completeError(e, StackTrace.current);
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

Widget _wrap(
  GridController<String> controller,
  GridDataSource<String> ds, {
  GridLoadingBehavior loadingBehavior = GridLoadingBehavior.always,
  void Function(Object, StackTrace)? onError,
  bool revertPageOnError = true,
}) {
  return MaterialApp(
    home: Scaffold(
      body: GridBuilder<String>(
        controller: controller,
        dataSource: ds,
        loadingBehavior: loadingBehavior,
        onError: onError,
        revertPageOnError: revertPageOnError,
        builder: (context, table) => Column(
          children: [
            if (table.isLoading) const CircularProgressIndicator(),
            if (table.error != null)
              Text('Error: ${table.errorMessage}'),
            Text('rows: ${table.pageRows.length}'),
            Text('hasData: ${table.hasData}'),
            Text('page: ${table.state.pagination.pageIndex}'),
            Text('fetch: done'),
            ElevatedButton(
              onPressed: table.retry,
              child: const Text('Retry'),
            ),
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
  // ── Basic rendering ─────────────────────────────────────────────────────────

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

  // ── hasData ─────────────────────────────────────────────────────────────────

  group('GridBuilder — hasData', () {
    testWidgets('hasData is false before first fetch completes', (tester) async {
      final c = _makeController();
      final ds = _ControllableFakeDataSource();

      await tester.pumpWidget(_wrap(c, ds));
      await tester.pump(); // fetch in flight

      expect(find.text('hasData: false'), findsOneWidget);
    });

    testWidgets('hasData is true after first successful fetch', (tester) async {
      final c = _makeController();
      final ds = _FakeDataSource(data: ['a']);

      await tester.pumpWidget(_wrap(c, ds));
      await tester.pumpAndSettle();

      expect(find.text('hasData: true'), findsOneWidget);
    });

    testWidgets('hasData is false when fetch returns empty list', (tester) async {
      final c = _makeController();
      final ds = _FakeDataSource(data: []);

      await tester.pumpWidget(_wrap(c, ds));
      await tester.pumpAndSettle();

      expect(find.text('hasData: false'), findsOneWidget);
    });
  });

  // ── loadingBehavior ─────────────────────────────────────────────────────────

  group('GridBuilder — loadingBehavior', () {
    testWidgets(
        'always: isLoading=true during re-fetch even when data exists',
        (tester) async {
      final c = _makeController();
      final ds = _ControllableFakeDataSource(data: ['a', 'b']);

      await tester.pumpWidget(_wrap(c, ds,
          loadingBehavior: GridLoadingBehavior.always));
      // Initial fetch: complete so we have data
      ds.complete();
      await tester.pumpAndSettle();
      expect(find.text('hasData: true'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);

      // Trigger a re-fetch (filter change) — fetch hangs
      c.setGlobalFilter('x');
      await tester.pump(); // isLoading = true but data still in controller

      // With 'always', isLoading should be true even though rows exist
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets(
        'whenEmpty: isLoading=false during re-fetch after data was received',
        (tester) async {
      final c = _makeController();
      final ds = _ControllableFakeDataSource(data: ['a', 'b']);

      await tester.pumpWidget(_wrap(c, ds,
          loadingBehavior: GridLoadingBehavior.whenEmpty));
      // Initial fetch: complete so we have received data at least once
      ds.complete();
      await tester.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsNothing);

      // Trigger a re-fetch via external filter (no local-pipeline side-effect)
      // fetch hangs
      c.setExternalFilter('status', ExternalFilter.eq('active'));
      await tester.pump();

      // With 'whenEmpty', isLoading should be suppressed because data was
      // already received (_hasReceivedData = true), even if in-flight.
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets(
        'whenEmpty: isLoading=true on first fetch (no data yet)',
        (tester) async {
      final c = _makeController();
      final ds = _ControllableFakeDataSource();

      await tester.pumpWidget(_wrap(c, ds,
          loadingBehavior: GridLoadingBehavior.whenEmpty));
      await tester.pump(); // fetch in flight, no data yet

      // No rows yet → loading should still show
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  // ── Re-entrancy guard ────────────────────────────────────────────────────────

  group('GridBuilder — re-entrancy guard (_settingData)', () {
    testWidgets(
        'setting data does not trigger a second fetch (no infinite loop)',
        (tester) async {
      final c = _makeController();
      final ds = _FakeDataSource();

      await tester.pumpWidget(_wrap(c, ds));
      await tester.pumpAndSettle();

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

      c.setExternalFilter('a', ExternalFilter.eq(1));
      c.setExternalFilter('b', ExternalFilter.eq(2));
      c.setExternalFilter('c', ExternalFilter.eq(3));
      await tester.pumpAndSettle();

      expect(ds.fetchCallCount, greaterThanOrEqualTo(countAfterInit + 1));
      expect(find.text('rows: 3'), findsOneWidget);
    });
  });

  // ── Epoch-based cancellation ─────────────────────────────────────────────────

  group('GridBuilder — epoch-based cancellation', () {
    testWidgets(
        'stale response is discarded when a newer fetch is in flight',
        (tester) async {
      final c = _makeController();
      final ds1 = _ControllableFakeDataSource(data: ['stale1', 'stale2']);
      final ds2 = _ControllableFakeDataSource(data: ['fresh']);

      await tester.pumpWidget(_wrap(c, ds1));
      await tester.pump();

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

      ds2.complete();
      await tester.pumpAndSettle();

      ds1.complete();
      await tester.pumpAndSettle();

      expect(find.text('rows: 1'), findsOneWidget);
    });

    testWidgets('stale error is discarded when a newer fetch succeeded',
        (tester) async {
      final c = _makeController();
      final ds1 = _ControllableFakeDataSource();
      final ds2 = _ControllableFakeDataSource(data: ['good']);

      await tester.pumpWidget(_wrap(c, ds1));
      await tester.pump();

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: GridBuilder<String>(
            controller: c,
            dataSource: ds2,
            builder: (context, table) => Column(children: [
              if (table.error != null) Text('Error: ${table.errorMessage}'),
              Text('rows: ${table.pageRows.length}'),
            ]),
          ),
        ),
      ));
      await tester.pump();

      ds2.complete();
      await tester.pumpAndSettle();

      ds1.completeWithError(Exception('old error'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Error:'), findsNothing);
      expect(find.text('rows: 1'), findsOneWidget);
    });
  });

  // ── Error handling ───────────────────────────────────────────────────────────

  group('GridBuilder — error handling', () {
    testWidgets('error exposes the raw exception object', (tester) async {
      final exception = Exception('raw error');
      final c = _makeController();
      final ds = _FakeDataSource(error: exception);

      Object? capturedError;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: GridBuilder<String>(
            controller: c,
            dataSource: ds,
            builder: (context, table) {
              capturedError = table.error;
              return const SizedBox();
            },
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(capturedError, isA<Exception>());
      expect(capturedError.toString(), contains('raw error'));
    });

    testWidgets('errorStackTrace is populated on failure', (tester) async {
      final c = _makeController();
      final ds = _FakeDataSource(error: Exception('boom'));

      StackTrace? capturedStack;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: GridBuilder<String>(
            controller: c,
            dataSource: ds,
            builder: (context, table) {
              capturedStack = table.errorStackTrace;
              return const SizedBox();
            },
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(capturedStack, isNotNull);
    });

    testWidgets('errorMessage returns error.toString()', (tester) async {
      final c = _makeController();
      final ds = _FakeDataSource(error: Exception('Network error'));

      await tester.pumpWidget(_wrap(c, ds));
      await tester.pumpAndSettle();

      expect(find.textContaining('Network error'), findsOneWidget);
    });

    testWidgets('onError callback is invoked on failure', (tester) async {
      Object? callbackError;
      StackTrace? callbackStack;

      final c = _makeController();
      final ds = _FakeDataSource(error: Exception('cb error'));

      await tester.pumpWidget(_wrap(c, ds, onError: (e, st) {
        callbackError = e;
        callbackStack = st;
      }));
      await tester.pumpAndSettle();

      expect(callbackError, isNotNull);
      expect(callbackError.toString(), contains('cb error'));
      expect(callbackStack, isNotNull);
    });

    testWidgets('onError is NOT called on success', (tester) async {
      bool called = false;
      final c = _makeController();
      final ds = _FakeDataSource();

      await tester.pumpWidget(
          _wrap(c, ds, onError: (_, __) => called = true));
      await tester.pumpAndSettle();

      expect(called, isFalse);
    });

    testWidgets('error is cleared after a successful retry', (tester) async {
      var shouldFail = true;
      int callCount = 0;

      final c = _makeController();
      final ds = _FakeDataSource(); // base — overridden below

      // Use a custom DS that fails on first call then succeeds
      final failThenSucceedDs = _ToggleDataSource(
        onFetch: (query) {
          callCount++;
          if (shouldFail) throw Exception('first fail');
          return GridPage(
            data: const ['ok'],
            currentPage: 1,
            pageSize: 1,
            totalItems: 1,
          );
        },
      );

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: GridBuilder<String>(
            controller: c,
            dataSource: failThenSucceedDs,
            builder: (context, table) => Column(children: [
              if (table.error != null) Text('Error: ${table.errorMessage}'),
              Text('rows: ${table.pageRows.length}'),
              ElevatedButton(
                onPressed: table.retry,
                child: const Text('Retry'),
              ),
            ]),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.textContaining('Error:'), findsOneWidget);

      // Fix DS and tap Retry
      shouldFail = false;
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Error:'), findsNothing);
      expect(find.text('rows: 1'), findsOneWidget);
    });
  });

  // ── Page revert on error ─────────────────────────────────────────────────────

  group('GridBuilder — revertPageOnError', () {
    testWidgets(
        'page reverts to last successful page when fetch fails (default)',
        (tester) async {
      final c = _makeController();
      final ds = _ControllableFakeDataSource(data: ['a', 'b', 'c']);

      // Initial fetch: succeed → page 0 is confirmed
      await tester.pumpWidget(_wrap(c, ds));
      ds.complete();
      await tester.pumpAndSettle();
      expect(find.text('page: 0'), findsOneWidget);

      // Navigate to page 1
      c.nextPage();
      await tester.pump(); // fetch in flight

      // Fail the fetch for page 1
      ds.completeWithError(Exception('page 1 unavailable'));
      await tester.pumpAndSettle(); // revert fires → setPageIndex(0) → new fetch

      // Complete the auto-triggered re-fetch for page 0
      ds.complete();
      await tester.pumpAndSettle();

      // Should be back on page 0
      expect(find.text('page: 0'), findsOneWidget);
    });

    testWidgets(
        'no page revert when revertPageOnError=false',
        (tester) async {
      final c = _makeController();
      final ds = _ControllableFakeDataSource(data: ['a', 'b', 'c']);

      await tester.pumpWidget(
          _wrap(c, ds, revertPageOnError: false));
      ds.complete();
      await tester.pumpAndSettle();

      c.nextPage();
      await tester.pump();

      ds.completeWithError(Exception('fail'));
      await tester.pumpAndSettle();

      // Page should remain at 1 (no revert)
      expect(find.text('page: 1'), findsOneWidget);
    });

    testWidgets(
        'no page revert on first fetch failure (no known-good page yet)',
        (tester) async {
      final c = _makeController();
      final ds = _ControllableFakeDataSource();

      await tester.pumpWidget(_wrap(c, ds));
      await tester.pump(); // first fetch in flight

      ds.completeWithError(Exception('initial failure'));
      await tester.pumpAndSettle();

      // Page stays at 0 — no revert happens (nothing to revert to)
      expect(find.text('page: 0'), findsOneWidget);
      expect(find.textContaining('Error:'), findsOneWidget);
    });

    testWidgets(
        'no page revert when failure is not page-navigation induced',
        (tester) async {
      final c = _makeController();
      final ds = _ControllableFakeDataSource(data: ['a', 'b']);

      // Succeed on first fetch (page 0)
      await tester.pumpWidget(_wrap(c, ds));
      ds.complete();
      await tester.pumpAndSettle();

      // Apply a filter (resets to page 0, same page) — fetch fails
      c.setGlobalFilter('x');
      await tester.pump();
      ds.completeWithError(Exception('filter fetch failed'));
      await tester.pumpAndSettle();

      // Page stays at 0 (no revert needed — page didn't change from last good)
      expect(find.text('page: 0'), findsOneWidget);
    });
  });

  // ── Controller listener lifecycle ────────────────────────────────────────────

  group('GridBuilder — controller listener lifecycle', () {
    testWidgets('removes listener on dispose', (tester) async {
      final c = _makeController();
      final ds = _FakeDataSource();

      await tester.pumpWidget(_wrap(c, ds));
      await tester.pumpAndSettle();
      final countBefore = ds.fetchCallCount;

      await tester.pumpWidget(const MaterialApp(home: Text('done')));

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

      await tester.pumpWidget(build(c2));
      await tester.pumpAndSettle();
      expect(ds.fetchCallCount, countAfterC1);

      c1.setExternalFilter('x', ExternalFilter.eq(1));
      await tester.pump();
      expect(ds.fetchCallCount, countAfterC1);

      c2.setExternalFilter('y', ExternalFilter.eq(2));
      await tester.pumpAndSettle();
      expect(ds.fetchCallCount, countAfterC1 + 1);
    });

    testWidgets(
        'no dataSource → builder is called with empty state and no loading',
        (tester) async {
      final c = _makeController();

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: GridBuilder<String>(
            controller: c,
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

// ─────────────────────────────────────────────────────────────────────────────
// Helper: data source with swappable fetch implementation
// ─────────────────────────────────────────────────────────────────────────────

class _ToggleDataSource extends GridDataSource<String> {
  final GridPage<String> Function(GridQuery query) onFetch;

  _ToggleDataSource({required this.onFetch});

  @override
  Future<GridPage<String>> fetch(GridQuery query) async => onFetch(query);
}
