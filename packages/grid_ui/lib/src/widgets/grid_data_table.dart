import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:grid_core/grid_core.dart';
import 'package:grid_flutter/grid_flutter.dart';

import '../slots/grid_data_row.dart';
import '../slots/grid_header_row.dart';
import '../slots/grid_slots.dart';
import '../theme/grid_theme.dart';

class GridDataTable<T> extends StatefulWidget {
  final GridController<T> controller;
  final GridTableState<T> table;
  final bool showColumnBorders;
  final bool striped;

  /// When true the table expands to fill available horizontal space.
  final bool fillWidth;

  final bool enableHapticFeedback;
  final double? rowHeight;
  final void Function(RowModel<T>)? onRowTap;
  final void Function(RowModel<T>)? onRowDoubleTap;
  final void Function(RowModel<T>)? onRowLongPress;
  final GridSlots<T>? slots;

  const GridDataTable({
    super.key,
    required this.controller,
    required this.table,
    this.showColumnBorders = false,
    this.striped = true,
    this.fillWidth = false,
    this.enableHapticFeedback = false,
    this.rowHeight,
    this.onRowTap,
    this.onRowDoubleTap,
    this.onRowLongPress,
    this.slots,
  });

  @override
  State<GridDataTable<T>> createState() => _GridDataTableState<T>();
}

class _GridDataTableState<T> extends State<GridDataTable<T>> {
  /// Key reused until a bulk-reset is needed, then replaced to force rebuild.
  var _listKey = GlobalKey<AnimatedListState>();

  final ScrollController _horizontalController = ScrollController();

  /// Shadow copy of the rows currently reflected in the AnimatedList.
  late List<RowModel<T>> _rows;

  static const _animDuration = Duration(milliseconds: 250);
  Map<String, num> columnWidths = {};

  @override
  void initState() {
    super.initState();
    _rows = List.from(widget.table.pageRows);
  }

  @override
  void dispose() {
    _horizontalController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(GridDataTable<T> old) {
    super.didUpdateWidget(old);
    final next = widget.table.pageRows;
    if (!_listsIdentical(_rows, next)) {
      _syncRows(next);
    }
  }

  // Compares IDs AND original references so that a sort (same IDs, different
  // originals at each position) is not treated as "no change".
  bool _listsIdentical(List<RowModel<T>> a, List<RowModel<T>> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id || !identical(a[i].original, b[i].original)) {
        return false;
      }
    }
    return true;
  }

  void _syncRows(List<RowModel<T>> next) {
    final oldIdList = _rows.map((r) => r.id).toList();
    final oldIdSet = oldIdList.toSet();
    final newIdSet = next.map((r) => r.id).toSet();

    final removedCount = oldIdList.where((id) => !newIdSet.contains(id)).length;
    final addedCount = next.where((r) => !oldIdSet.contains(r.id)).length;

    // Detect reordering: common items must be in the same relative order.
    final commonOld =
        _rows.where((r) => newIdSet.contains(r.id)).map((r) => r.id).toList();
    final commonNew =
        next.where((r) => oldIdSet.contains(r.id)).map((r) => r.id).toList();
    final reordered = commonOld.length != commonNew.length ||
        !_listsEqual(commonOld, commonNew);

    // Detect a pure content change: same IDs in the same order but different
    // originals (typical when row IDs are position-based and data is sorted).
    final contentChanged = !reordered &&
        removedCount == 0 &&
        addedCount == 0 &&
        _rows.length == next.length &&
        Iterable.generate(_rows.length)
            .any((i) => !identical(_rows[i].original, next[i].original));

    // Bulk reset for reorders, content changes, or many simultaneous changes.
    if (reordered || contentChanged || removedCount + addedCount > 5) {
      setState(() {
        _rows = List.from(next);
        _listKey = GlobalKey<AnimatedListState>();
      });
      return;
    }

    // Animated: remove missing rows (reverse order), then insert new rows.
    for (int i = _rows.length - 1; i >= 0; i--) {
      if (!newIdSet.contains(_rows[i].id)) {
        final removed = _rows[i];
        _rows.removeAt(i);
        _listKey.currentState?.removeItem(
          i,
          (ctx, anim) => _buildRow(removed, i,
              animation: anim, columnWidths: columnWidths),
          duration: _animDuration,
        );
      }
    }
    for (int i = 0; i < next.length; i++) {
      if (!oldIdSet.contains(next[i].id)) {
        _rows.insert(i, next[i]);
        _listKey.currentState?.insertItem(i, duration: _animDuration);
      }
    }
  }

  bool _listsEqual(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  Widget _buildRow(RowModel<T> row, int index,
      {Animation<double>? animation,
      bool? isLastRow,
      required Map<String, num> columnWidths}) {
    final theme = GridTheme.of(context);
    final visibleCols = widget.table.visibleColumns;

    Widget child = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        GridDataRow<T>(
          row: row,
          visibleColumns: visibleCols,
          controller: widget.controller,
          isStriped: widget.striped && index.isOdd,
          rowHeight: widget.rowHeight,
          enableHapticFeedback: widget.enableHapticFeedback,
          scrollController: _horizontalController,
          onTap: widget.onRowTap,
          onDoubleTap: widget.onRowDoubleTap,
          onLongPress: widget.onRowLongPress,
          columnWidths: columnWidths,
        ),
        if (widget.showColumnBorders && isLastRow == false)
          Divider(
            height: theme.borderWidth,
            thickness: theme.borderWidth,
            color: theme.borderColor,
          ),
      ],
    );

    if (animation != null) {
      child = SizeTransition(
        sizeFactor: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
        child: FadeTransition(opacity: animation, child: child),
      );
    }

    return child;
  }

  @override
  Widget build(BuildContext context) {
    final theme = GridTheme.of(context);
    final visibleCols = widget.table.visibleColumns;

    return LayoutBuilder(
      builder: (context, constraints) {
        double availableWidth = constraints.maxWidth;

        columnWidths = widget.controller.resolveColumnWidths(availableWidth);

        final headerHeight = widget.table.headerGroups.length *
                GridTheme.of(context).headerHeight +
            5;
        final totalWidth = columnWidths.values.fold<double>(
          0,
          (a, b) => a + b,
        );

        final effectiveWidth = widget.fillWidth
            ? math.max(totalWidth, constraints.maxWidth)
            : totalWidth;

        return ScrollConfiguration(
          behavior: NoBackGestureScrollBehavior(),
          child: SingleChildScrollView(
            controller: _horizontalController,
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: effectiveWidth,
              child: CustomScrollView(
                slivers: [
                  SliverPersistentHeader(
                    pinned: theme.pinnedHeader!,
                    delegate: _HeaderDelegate(
                      minHeight: headerHeight,
                      maxHeight: headerHeight,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          ...widget.table.headerGroups
                              .map((group) => GridHeaderRow<T>(
                                    group: group,
                                    controller: widget.controller,
                                    visibleColumns: visibleCols,
                                    columnWidths: columnWidths,
                                    scrollController: _horizontalController,
                                  )),
                          if (widget.showColumnBorders)
                            Divider(
                              height: theme.borderWidth,
                              thickness: theme.borderWidth,
                              color: theme.borderColor,
                            ),
                        ],
                      ),
                    ),
                  ),
                  if (widget.table.topPinnedRows.isNotEmpty)
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _buildRow(
                            widget.table.topPinnedRows[index], index,
                            isLastRow:
                                widget.table.topPinnedRows.length - 1 == index,
                            columnWidths: columnWidths),
                        childCount: widget.table.topPinnedRows.length,
                      ),
                    ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _buildRow(_rows[index], index,
                          isLastRow: _rows.length - 1 == index,
                          columnWidths: columnWidths),
                      childCount: _rows.length,
                    ),
                  ),
                  if (widget.table.bottomPinnedRows.isNotEmpty)
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _buildRow(
                            widget.table.bottomPinnedRows[index], index,
                            isLastRow:
                                widget.table.bottomPinnedRows.length - 1 ==
                                    index,
                            columnWidths: columnWidths),
                        childCount: widget.table.bottomPinnedRows.length,
                      ),
                    ),
                  SliverToBoxAdapter(
                    child: widget.slots?.aggregationFooter != null
                        ? widget.slots!.aggregationFooter!(
                            context, widget.table)
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _HeaderDelegate extends SliverPersistentHeaderDelegate {
  final double minHeight;
  final double maxHeight;
  final Widget child;

  _HeaderDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.child,
  });

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  bool shouldRebuild(_HeaderDelegate oldDelegate) {
    return oldDelegate.child != child ||
        oldDelegate.minHeight != minHeight ||
        oldDelegate.maxHeight != maxHeight;
  }
}

class NoBackGestureScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
      };
}
