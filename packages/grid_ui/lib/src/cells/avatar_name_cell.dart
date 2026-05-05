import 'package:flutter/material.dart';
import 'package:grid_core/grid_core.dart';

import 'cell_renderer.dart';

class AvatarNameCellRenderer extends CellRenderer<dynamic> {
  const AvatarNameCellRenderer();

  @override
  Set<ColumnType> get supportedTypes => {ColumnType.avatar};

  @override
  Widget render(CellContext<dynamic, dynamic> ctx) {
    final value = ctx.value;
    String name = '';
    String? avatarUrl;

    if (value is Map) {
      name = value['name']?.toString() ?? '';
      avatarUrl = value['avatarUrl']?.toString();
    } else {
      name = value?.toString() ?? '';
    }

    final initials = name.isNotEmpty
        ? name.trim().split(' ').map((p) => p.isNotEmpty ? p[0] : '').take(2).join().toUpperCase()
        : '?';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 16,
          backgroundImage:
              avatarUrl != null ? NetworkImage(avatarUrl) : null,
          child: avatarUrl == null
              ? Text(initials, style: const TextStyle(fontSize: 12))
              : null,
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            name,
            style: const TextStyle(fontSize: 14),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  @override
  Widget renderSkeleton(ColumnDef<dynamic, dynamic> def) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          height: 14,
          width: 80,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ],
    );
  }
}
