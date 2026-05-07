import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:grid_core/grid_core.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Loading behaviour
// ─────────────────────────────────────────────────────────────────────────────

/// Controls when [GridTableState.isLoading] is set to `true`.
enum GridLoadingBehavior {
  /// `isLoading` is `true` for **every** fetch, regardless of whether the
  /// table already holds rows. Use this when your builder completely replaces
  /// the table content with a spinner while new data loads. (default)
  always,

  /// `isLoading` is `true` **only** on the very first fetch, while no rows
  /// have been received yet. Once the table has data, subsequent fetches
  /// (page changes, filter changes, …) keep `isLoading = false` so the
  /// builder can continue to render the existing rows in the background while
  /// new data arrives — ideal for a subtle "refreshing" overlay instead of a
  /// full-screen spinner.
  whenEmpty,
}

// ─────────────────────────────────────────────────────────────────────────────
// GridTableState
// ─────────────────────────────────────────────────────────────────────────────

/// The state exposed to [GridBuilder]'s builder callback.
class GridTableState<T> {
  final GridController<T> controller;
  final GridState state;
  final RowModelSet<T> _rowModelSet;
  final List<ColumnInfo<T, Object?>> allColumns;
  final List<ColumnInfo<T, Object?>> visibleColumns;
  final List<ColumnInfo<T, Object?>> leftPinnedColumns;
  final List<ColumnInfo<T, Object?>> centerColumns;
  final List<ColumnInfo<T, Object?>> rightPinnedColumns;
  final List<HeaderGroup<T>> headerGroups;

  /// Whether a fetch is currently in flight.
  ///
  /// The exact semantics depend on [GridBuilder.loadingBehavior]:
  /// - [GridLoadingBehavior.always] — `true` for every fetch.
  /// - [GridLoadingBehavior.whenEmpty] — `true` only when [hasData] is `false`.
  final bool isLoading;

  /// `true` when [pageRows] contains at least one row from a previous fetch.
  ///
  /// Useful together with [isLoading] to decide between a full-screen spinner
  /// (first load) and a lightweight refresh indicator (subsequent loads):
  /// ```dart
  /// if (table.isLoading && !table.hasData) return const FullscreenSpinner();
  /// if (table.isLoading) return const RefreshBanner();
  /// ```
  final bool hasData;

  /// The raw error thrown by the last failed [GridDataSource.fetch] call,
  /// or `null` if the last fetch succeeded.
  ///
  /// Cast to the concrete type your data source throws, or call
  /// [errorMessage] for a plain string:
  /// ```dart
  /// if (table.error is DioException) { … }
  /// ```
  final Object? error;

  /// The [StackTrace] associated with [error], or `null`.
  final StackTrace? errorStackTrace;

  /// Re-issues the last fetch without changing any controller state.
  ///
  /// Typically wired to a "Retry" button shown when [error] is non-null:
  /// ```dart
  /// if (table.error != null)
  ///   ElevatedButton(onPressed: table.retry, child: const Text('Retry')),
  /// ```
  final VoidCallback retry;

  const GridTableState({
    required this.controller,
    required this.state,
    required RowModelSet<T> rowModelSet,
    required this.allColumns,
    required this.visibleColumns,
    required this.leftPinnedColumns,
    required this.centerColumns,
    required this.rightPinnedColumns,
    required this.headerGroups,
    required this.isLoading,
    required this.hasData,
    required this.retry,
    this.error,
    this.errorStackTrace,
  }) : _rowModelSet = rowModelSet;

  List<RowModel<T>> get pageRows => _rowModelSet.pageRows;
  List<RowModel<T>> get filteredRows => _rowModelSet.filteredRows;
  List<RowModel<T>> get allRows => _rowModelSet.allRows;
  List<RowModel<T>> get topPinnedRows => _rowModelSet.topPinnedRows;
  List<RowModel<T>> get bottomPinnedRows => _rowModelSet.bottomPinnedRows;
  int get totalRows => _rowModelSet.totalRows;
  int get totalPages => _rowModelSet.totalPages;

  /// Convenience getter — `error?.toString()` — for builders that only need
  /// a human-readable string.
  String? get errorMessage => error?.toString();
}

// ─────────────────────────────────────────────────────────────────────────────
// GridBuilder
// ─────────────────────────────────────────────────────────────────────────────

/// Connects a [GridController] (and optionally a [GridDataSource]) to the
/// widget tree, rebuilding whenever the controller notifies.
///
/// ## Fetch lifecycle
///
/// Every time the controller state changes (sort, filter, page, external
/// filters…) [GridBuilder] calls [GridDataSource.fetch] with a fresh
/// [GridQuery] built from the **latest** state.
///
/// ### Race-condition safety — epoch cancellation
///
/// Rapid successive changes (e.g. user applies a filter and immediately clicks
/// next-page before the first response arrives) are handled via an internal
/// epoch counter:
///
/// - Each new fetch increments `_epoch`.
/// - When a response arrives it checks whether its epoch still matches the
///   current one; if not, the response is silently discarded.
/// - The **last issued** fetch always wins — stale responses never overwrite
///   newer data.
///
/// ### Page revert on error
///
/// When [revertPageOnError] is `true` (the default) and a fetch fails,
/// [GridBuilder] automatically calls [GridController.setPageIndex] with the
/// page index of the last *successful* fetch. This prevents the controller
/// from being left on a page that has no loaded data. The revert triggers a
/// new fetch for the previous page, so the table recovers automatically.
class GridBuilder<T> extends StatefulWidget {
  final GridController<T> controller;
  final GridDataSource<T>? dataSource;
  final Widget Function(BuildContext context, GridTableState<T> table) builder;

  /// Controls when [GridTableState.isLoading] is set to `true`.
  /// Defaults to [GridLoadingBehavior.always].
  final GridLoadingBehavior loadingBehavior;

  /// Called whenever [GridDataSource.fetch] throws.
  ///
  /// Receives the raw error and its stack trace. Use this for logging,
  /// analytics, or showing a global snackbar. The builder still receives
  /// [GridTableState.error] for inline error UI.
  final void Function(Object error, StackTrace stackTrace)? onError;

  /// When `true` (the default), if a fetch fails [GridBuilder] resets the
  /// controller's page index back to the last successfully loaded page.
  ///
  /// This prevents the grid from being visually stuck on a page with no data.
  /// The revert triggers a new fetch automatically.
  final bool revertPageOnError;

  const GridBuilder({
    super.key,
    required this.controller,
    this.dataSource,
    required this.builder,
    this.loadingBehavior = GridLoadingBehavior.always,
    this.onError,
    this.revertPageOnError = true,
  });

  @override
  State<GridBuilder<T>> createState() => _GridBuilderState<T>();
}

class _GridBuilderState<T> extends State<GridBuilder<T>> {
  // ── Epoch-based cancellation ──────────────────────────────────────────────
  //
  // Incremented on every fetch attempt. A response whose captured epoch no
  // longer matches _epoch is stale and discarded.
  int _epoch = 0;

  // ── Re-entrancy guard ─────────────────────────────────────────────────────
  //
  // setDataWithPageCountAndTotalItems() calls _notifyListeners() synchronously,
  // which would immediately trigger _onControllerChanged() → _fetch() → infinite
  // loop. We raise this flag before calling setData and check it at the top of
  // _onControllerChanged to break the cycle.
  bool _settingData = false;

  bool _isLoading = false;
  Object? _error;
  StackTrace? _errorStackTrace;
  StreamSubscription<List<T>>? _watchSub;

  /// Set to `true` after the first successful fetch completes.
  ///
  /// Used by [GridLoadingBehavior.whenEmpty]: once any data has been received,
  /// subsequent fetches should not re-raise the full loading indicator even if
  /// the current filtered/paged view happens to be empty.
  bool _hasReceivedData = false;

  /// Page index of the last *successfully* completed fetch.
  /// Used to revert the controller page on error.
  int? _lastSuccessfulPageIndex;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
    _fetch();
  }

  @override
  void didUpdateWidget(GridBuilder<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onControllerChanged);
      widget.controller.addListener(_onControllerChanged);
    }
    if (oldWidget.dataSource != widget.dataSource) {
      _watchSub?.cancel();
      _watchSub = null;
      _fetch();
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    _watchSub?.cancel();
    // Invalidate any in-flight fetch so its completion callback is a no-op.
    _epoch++;
    super.dispose();
  }

  void _onControllerChanged() {
    if (_settingData) return;
    if (mounted) {
      _fetch();
      setState(() {});
    }
  }

  // ── Core fetch ────────────────────────────────────────────────────────────

  Future<void> _fetch() async {
    final ds = widget.dataSource;
    if (ds == null) return;

    // Capture the epoch for this specific fetch attempt.
    // Any previously in-flight fetch now has a stale epoch and will be ignored
    // when it eventually completes.
    final epoch = ++_epoch;

    // Wire up streaming watch once (only if not already subscribed).
    if (_watchSub == null) {
      final watchStream = ds.watch(widget.controller.state.toQuery());
      if (watchStream != null) {
        _watchSub = watchStream.listen((data) {
          widget.controller.setData(data);
        });
      }
    }

    if (mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
        _errorStackTrace = null;
      });
    }

    try {
      // Snapshot the query from the **current** state at the moment this fetch
      // was triggered. Subsequent state changes will start a new fetch with a
      // higher epoch — their responses will win.
      final query = widget.controller.state.toQuery();
      final page = await ds.fetch(query);

      // Stale check — a newer fetch was started after us; discard our result.
      if (epoch != _epoch) return;

      _settingData = true;
      widget.controller.setDataWithPageCountAndTotalItems(
        page.data,
        page.computedTotalPages,
        totalItems: page.totalItems,
      );
      _settingData = false;

      _hasReceivedData = true;
      _lastSuccessfulPageIndex = query.pageIndex;

      if (mounted) setState(() => _isLoading = false);
    } catch (e, st) {
      // Discard errors from stale fetches too.
      if (epoch != _epoch) return;

      // ── Page revert ─────────────────────────────────────────────────────
      // If the failed fetch was triggered by a page navigation (the current
      // page differs from the last page that successfully loaded), reset the
      // controller to that known-good page. The reset triggers a new fetch
      // automatically — the table self-heals without user intervention.
      final lastGoodPage = _lastSuccessfulPageIndex;
      final failedPage = widget.controller.state.pagination.pageIndex;
      if (widget.revertPageOnError &&
          lastGoodPage != null &&
          failedPage != lastGoodPage) {
        widget.controller.setPageIndex(lastGoodPage);
        // setPageIndex notifies listeners → _onControllerChanged → _fetch().
        // The new fetch will clear the error when it succeeds.
      }

      // ── onError callback ────────────────────────────────────────────────
      widget.onError?.call(e, st);

      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e;
          _errorStackTrace = st;
        });
      }
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  GridTableState<T> _buildTableState() {
    final c = widget.controller;
    final rowSet = c.getRowModels();
    final allCols = c.getAllColumns();
    final hasData = rowSet.pageRows.isNotEmpty;

    // Honour loadingBehavior: once any data has been successfully received,
    // suppress the loading flag for subsequent fetches in whenEmpty mode.
    // We use _hasReceivedData rather than hasData because applying a filter
    // can make the current local view appear empty even though the controller
    // still holds rows from the previous fetch.
    final effectiveIsLoading = _isLoading &&
        (widget.loadingBehavior == GridLoadingBehavior.always ||
            !_hasReceivedData);

    return GridTableState<T>(
      controller: c,
      state: c.state,
      rowModelSet: rowSet,
      allColumns: allCols,
      visibleColumns: c.getVisibleColumns(),
      leftPinnedColumns: c.getLeftPinnedColumns(),
      centerColumns: c.getCenterColumns(),
      rightPinnedColumns: c.getRightPinnedColumns(),
      headerGroups: c.getHeaderGroups(),
      isLoading: effectiveIsLoading,
      hasData: hasData,
      error: _error,
      errorStackTrace: _errorStackTrace,
      retry: _fetch,
    );
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _buildTableState());
  }
}
