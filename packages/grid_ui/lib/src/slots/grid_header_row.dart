import 'package:flutter/material.dart';
import 'package:grid_core/grid_core.dart';

import '../components/grid_sort_indicator.dart';
import '../theme/grid_theme.dart';
import 'header_context.dart';

class GridHeaderRow<T> extends StatelessWidget {
  final HeaderGroup<T> group;
  final GridController<T> controller;
  final ScrollController? scrollController;

  /// Visible columns in display order, used to compute widths for span headers.
  final List<ColumnInfo<T, Object?>> visibleColumns;

  final Map<String, num>? columnWidths;

  const GridHeaderRow({
    super.key,
    required this.group,
    required this.controller,
    required this.visibleColumns,
    this.scrollController,
    this.columnWidths,
  });

  @override
  Widget build(BuildContext context) {
    final theme = GridTheme.of(context);
    final cells = <Widget>[];

    // Calculate total width and left offsets
    final leftOffsets = <int, double>{};
    double currentOffset = 0;
    for (int i = 0; i < visibleColumns.length; i++) {
      leftOffsets[i] = currentOffset;
      currentOffset +=
          columnWidths?[visibleColumns[i].id] ?? theme.defaultColumnWidth;
    }
    final totalWidth = currentOffset;

    int visibleCursor = 0;

    for (final header in group.headers) {
      if (header.column != null) {
        if (!header.column!.isVisible) continue;

        final col = header.column!;
        final sorting = controller.state.sorting;
        final sortEntry =
            sorting.where((s) => s.columnId == col.id).firstOrNull;
        final sortIndex = sortEntry == null ? null : sorting.indexOf(sortEntry);

        String sortLabel = '';
        if (sortEntry != null) {
          sortLabel =
              ', sorted ${sortEntry.descending ? 'descending' : 'ascending'}';
        }

        // Use custom header widget if provided, otherwise default text+sort.
        Widget headerContent;
        if (col.def.headerWidget != null) {
          final hCtx = HeaderContext(
            column: col,
            controller: controller,
            buildContext: context,
          );
          headerContent = col.def.headerWidget!(hCtx) as Widget;
        } else {
          headerContent = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (col.def.headerIcon != null) ...[
                col.def.headerIcon as Widget,
                const SizedBox(width: 4),
              ],
              Flexible(
                child: Text(
                  col.def.header ?? col.id,
                  style: theme.headerTextStyle,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (col.def.enableSorting) ...[
                const SizedBox(width: 4),
                GridSortIndicator(
                  isAscending: sortEntry != null && !sortEntry.descending,
                  isDescending: sortEntry != null && sortEntry.descending,
                  sortIndex: sortIndex,
                ),
              ],
            ],
          );
        }

        Widget content = Semantics(
          label: '${col.def.header ?? col.id} column header$sortLabel',
          button: col.def.enableSorting,
          child: GestureDetector(
            onTap: col.def.enableSorting
                ? () => controller.toggleSort(col.id)
                : null,
            child: SizedBox(
              width: (columnWidths?[col.id] ??
                      col.effectiveWidth ??
                      theme.defaultColumnWidth)
                  .toDouble(),
              height: theme.headerHeight,
              child: Padding(
                padding: theme.headerPadding,
                child: headerContent,
              ),
            ),
          ),
        );

        final i = visibleCursor;

        if (!col.isPinned || scrollController == null) {
          cells.add(Positioned(
            left: leftOffsets[i]!,
            child: content,
          ));
        } else {
          cells.add(AnimatedBuilder(
            animation: scrollController!,
            builder: (context, child) {
              double offset = leftOffsets[i]!;
              final scrollOffset =
                  scrollController!.hasClients ? scrollController!.offset : 0.0;

              BoxShadow? shadow;
              if (col.isPinnedLeft) {
                offset = offset < scrollOffset ? scrollOffset : offset;
                if (offset == scrollOffset) {
                  shadow = const BoxShadow(
                    color: Colors.black12,
                    offset: Offset(2, 0),
                    blurRadius: 4,
                  );
                }
              } else if (col.isPinnedRight) {
                final maxScroll = scrollController!.hasClients
                    ? scrollController!.position.maxScrollExtent
                    : 0.0;
                final maxLeft = totalWidth -
                    (totalWidth - leftOffsets[i]!) +
                    (scrollOffset - maxScroll);
                offset = offset > maxLeft ? maxLeft : offset;
                if (offset == maxLeft) {
                  shadow = const BoxShadow(
                    color: Colors.black12,
                    offset: Offset(-2, 0),
                    blurRadius: 4,
                  );
                }
              }

              return Positioned(
                left: offset,
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.headerBackground,
                    boxShadow: shadow != null ? [shadow] : null,
                  ),
                  child: child,
                ),
              );
            },
            child: content,
          ));
        }
        visibleCursor++;
      } else {
        // Group (span) header
        double width = 0;
        final startIdx = visibleCursor;
        final end =
            (visibleCursor + header.colSpan).clamp(0, visibleColumns.length);
        for (int i = visibleCursor; i < end; i++) {
          width += (columnWidths?[visibleColumns[i].id] ??
                  visibleColumns[i].effectiveWidth ??
                  theme.defaultColumnWidth)
              .toDouble();
        }
        visibleCursor = end;

        Widget content = Semantics(
          label: '${header.group?.header ?? ''} column group',
          child: SizedBox(
            width: width,
            height: theme.headerHeight,
            child: Padding(
              padding: theme.headerPadding,
              child: Text(
                header.group?.header ?? '',
                style: theme.headerTextStyle,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        );
        cells.add(Positioned(left: leftOffsets[startIdx]!, child: content));
      }
    }

    return Container(
      height: theme.headerHeight,
      width: totalWidth,
      color: theme.headerBackground,
      child: Stack(children: cells),
    );
  }
}
