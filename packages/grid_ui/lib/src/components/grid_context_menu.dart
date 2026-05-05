import 'package:flutter/material.dart';
import 'package:grid_core/grid_core.dart';

class GridContextAction<T> {
  final String label;
  final IconData icon;
  final void Function(RowModel<T> row) onPressed;

  const GridContextAction({
    required this.label,
    required this.icon,
    required this.onPressed,
  });
}

class GridContextMenu<T> extends StatelessWidget {
  final RowModel<T> row;
  final Widget child;
  final List<GridContextAction<T>> actions;

  const GridContextMenu({
    super.key,
    required this.row,
    required this.child,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () => _showMenu(context),
      child: child,
    );
  }

  void _showMenu(BuildContext context) {
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    showMenu<void>(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromLTWH(0, 0, 200, 200),
        Offset.zero & overlay.size,
      ),
      items: actions
          .map(
            (action) => PopupMenuItem<void>(
              onTap: () => action.onPressed(row),
              child: ListTile(
                leading: Icon(action.icon),
                title: Text(action.label),
                dense: true,
              ),
            ),
          )
          .toList(),
    );
  }
}
