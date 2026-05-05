import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:grid_core/grid_core.dart';

import '../cells/cell_renderer.dart';
import '../cells/cell_renderer_registry.dart';
import '../theme/grid_theme.dart';

class GridDataRow<T> extends StatefulWidget {
  final RowModel<T> row;
  final List<ColumnInfo<T, Object?>> visibleColumns;
  final GridController<T> controller;
  final bool isStriped;
  final double? rowHeight;
  final ScrollController? scrollController;

  /// Fire [HapticFeedback.lightImpact] when this row transitions to selected.
  final bool enableHapticFeedback;

  final void Function(RowModel<T>)? onTap;
  final void Function(RowModel<T>)? onDoubleTap;
  final void Function(RowModel<T>)? onLongPress;

  const GridDataRow({
    super.key,
    required this.row,
    required this.visibleColumns,
    required this.controller,
    this.isStriped = false,
    this.rowHeight,
    this.scrollController,
    this.enableHapticFeedback = false,
    this.onTap,
    this.onDoubleTap,
    this.onLongPress,
  });

  @override
  State<GridDataRow<T>> createState() => _GridDataRowState<T>();
}

class _GridDataRowState<T> extends State<GridDataRow<T>> {
  bool _hovered = false;

  @override
  void didUpdateWidget(GridDataRow<T> old) {
    super.didUpdateWidget(old);
    if (widget.enableHapticFeedback &&
        widget.row.isSelected &&
        !old.row.isSelected) {
      HapticFeedback.lightImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = GridTheme.of(context);
    Color? bg;
    if (widget.row.isSelected) {
      bg = theme.selectedRowBackground;
    } else if (_hovered && theme.hoverRowBackground != null) {
      bg = theme.hoverRowBackground;
    } else if (widget.isStriped) {
      bg = theme.alternateRowBackground;
    } else {
      bg = theme.rowBackground;
    }

    final cells = widget.row.getVisibleCells(widget.visibleColumns);

    // Calculate left offsets
    final leftOffsets = <int, double>{};
    double currentOffset = 0;
    for (int i = 0; i < widget.visibleColumns.length; i++) {
      leftOffsets[i] = currentOffset;
      currentOffset += widget.visibleColumns[i].effectiveWidth;
    }
    final totalWidth = currentOffset;

    return Semantics(
      label: 'Row ${widget.row.index + 1}',
      selected: widget.row.isSelected,
      button: widget.onTap != null,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: InkWell(
          onTap: widget.onTap != null ? () => widget.onTap!(widget.row) : null,
          onDoubleTap: widget.onDoubleTap != null
              ? () => widget.onDoubleTap!(widget.row)
              : null,
          onLongPress: widget.onLongPress != null
              ? () => widget.onLongPress!(widget.row)
              : null,
          child: Container(
            height: widget.rowHeight ?? theme.rowHeight,
            width: totalWidth,
            color: bg,
            child: Stack(
              children: cells.indexed.map((entry) {
                final i = entry.$1;
                final cell = entry.$2;
                final col = cell.column;
                Widget cellWidget;

                if (col.def.cell != null) {
                  final ctx = CellContext(
                    cell: cell,
                    buildContext: context,
                    controller: widget.controller,
                  );
                  cellWidget = col.def.cell!(ctx) as Widget;
                } else {
                  final ctx = CellContext(
                    cell: cell,
                    buildContext: context,
                    controller: widget.controller,
                  );
                  cellWidget = CellRendererRegistry.instance.renderCell(ctx);
                }

                TextAlign textAlign = TextAlign.left;
                if (col.def.textAlignIndex == 1) textAlign = TextAlign.right;
                if (col.def.textAlignIndex == 2) textAlign = TextAlign.center;

                Widget content = Semantics(
                  label: '${col.def.header ?? col.id}: ${cell.value}',
                  child: SizedBox(
                    width: col.effectiveWidth,
                    height: widget.rowHeight ?? theme.rowHeight,
                    child: Align(
                      alignment: textAlign == TextAlign.right
                          ? Alignment.centerRight
                          : textAlign == TextAlign.center
                              ? Alignment.center
                              : Alignment.centerLeft,
                      child: Padding(
                        padding: theme.cellPadding,
                        child: cellWidget,
                      ),
                    ),
                  ),
                );

                if (!col.isPinned || widget.scrollController == null) {
                  return Positioned(
                    left: leftOffsets[i]!,
                    child: content,
                  );
                }

                return AnimatedBuilder(
                  animation: widget.scrollController!,
                  builder: (context, child) {
                    double offset = leftOffsets[i]!;
                    final scrollOffset = widget.scrollController!.hasClients
                        ? widget.scrollController!.offset
                        : 0.0;

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
                      final maxScroll = widget.scrollController!.hasClients
                          ? widget.scrollController!.position.maxScrollExtent
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
                          color: bg,
                          boxShadow: shadow != null ? [shadow] : null,
                        ),
                        child: child,
                      ),
                    );
                  },
                  child: content,
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}
