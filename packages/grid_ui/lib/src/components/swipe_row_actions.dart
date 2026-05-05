import 'package:flutter/material.dart';
import 'package:grid_core/grid_core.dart';

class SwipeAction<T> {
  final String label;
  final IconData icon;
  final Color color;
  final void Function(RowModel<T> row) onPressed;

  const SwipeAction({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
  });
}

class SwipeRowActions<T> extends StatelessWidget {
  final RowModel<T> row;
  final Widget child;
  final List<SwipeAction<T>> leadingActions;
  final List<SwipeAction<T>> trailingActions;

  const SwipeRowActions({
    super.key,
    required this.row,
    required this.child,
    this.leadingActions = const [],
    this.trailingActions = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(row.id),
      confirmDismiss: (direction) async {
        // Trigger the appropriate action without actually dismissing
        if (direction == DismissDirection.startToEnd &&
            leadingActions.isNotEmpty) {
          leadingActions.first.onPressed(row);
        } else if (direction == DismissDirection.endToStart &&
            trailingActions.isNotEmpty) {
          trailingActions.first.onPressed(row);
        }
        return false; // Never actually dismiss
      },
      background: leadingActions.isNotEmpty
          ? _buildActionBackground(
              context, leadingActions.first, Alignment.centerLeft)
          : null,
      secondaryBackground: trailingActions.isNotEmpty
          ? _buildActionBackground(
              context, trailingActions.first, Alignment.centerRight)
          : null,
      child: child,
    );
  }

  Widget _buildActionBackground(
      BuildContext context, SwipeAction<T> action, Alignment alignment) {
    return Container(
      color: action.color,
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(action.icon, color: Colors.white, size: 24),
          const SizedBox(height: 4),
          Text(action.label,
              style: const TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }
}
