import 'package:flutter/material.dart';
import 'package:grid_core/grid_core.dart';

import '../components/grid_sort_indicator.dart';
import '../theme/grid_theme.dart';
import 'header_context.dart';

class GridHeaderRow<T> extends StatelessWidget {
  final HeaderGroup<T> group;
  final GridController<T> controller;

  /// Visible columns in display order, used to compute widths for span headers.
  final List<ColumnInfo<T, Object?>> visibleColumns;

  const GridHeaderRow({
    super.key,
    required this.group,
    required this.controller,
    required this.visibleColumns,
  });

  @override
  Widget build(BuildContext context) {
    final theme = GridTheme.of(context);
    final cells = <Widget>[];
    int visibleCursor = 0;

    for (final header in group.headers) {
      if (header.column != null) {
        if (!header.column!.isVisible) continue;

        final col = header.column!;
        final sorting = controller.state.sorting;
        final sortEntry =
            sorting.where((s) => s.columnId == col.id).firstOrNull;
        final sortIndex =
            sortEntry == null ? null : sorting.indexOf(sortEntry);

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
            children: [
              if (col.def.headerIcon != null) ...[
                col.def.headerIcon as Widget,
                const SizedBox(width: 4),
              ],
              Expanded(
                child: Text(
                  col.def.header ?? col.id,
                  style: theme.headerTextStyle,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (col.def.enableSorting)
                GridSortIndicator(
                  isAscending: sortEntry != null && !sortEntry.descending,
                  isDescending: sortEntry != null && sortEntry.descending,
                  sortIndex: sortIndex,
                ),
            ],
          );
        }

        cells.add(
          Semantics(
            label: '${col.def.header ?? col.id} column header$sortLabel',
            button: col.def.enableSorting,
            child: GestureDetector(
              onTap: col.def.enableSorting
                  ? () => controller.toggleSort(col.id)
                  : null,
              child: SizedBox(
                width: col.effectiveWidth,
                child: Padding(
                  padding: theme.headerPadding,
                  child: headerContent,
                ),
              ),
            ),
          ),
        );
        visibleCursor++;
      } else {
        // Group (span) header
        double width = 0;
        final end =
            (visibleCursor + header.colSpan).clamp(0, visibleColumns.length);
        for (int i = visibleCursor; i < end; i++) {
          width += visibleColumns[i].effectiveWidth;
        }
        visibleCursor = end;

        cells.add(
          Semantics(
            label: '${header.group?.header ?? ''} column group',
            child: SizedBox(
              width: width,
              child: Padding(
                padding: theme.headerPadding,
                child: Text(
                  header.group?.header ?? '',
                  style: theme.headerTextStyle,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
        );
      }
    }

    return Container(
      height: theme.headerHeight,
      color: theme.headerBackground,
      child: Row(children: cells),
    );
  }
}
