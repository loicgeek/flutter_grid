import 'package:flutter/material.dart';
import 'package:grid_core/grid_core.dart';

import 'cell_renderer.dart';

class LinkCellRenderer extends CellRenderer<dynamic> {
  const LinkCellRenderer();

  @override
  Set<ColumnType> get supportedTypes => {ColumnType.link};

  @override
  Widget render(CellContext<dynamic, dynamic> ctx) {
    final value = ctx.value;
    String label;
    String? url;

    if (value is Map) {
      label = value['label']?.toString() ?? value['url']?.toString() ?? '';
      url = value['url']?.toString();
    } else {
      label = value?.toString() ?? '';
      url = label;
    }

    return GestureDetector(
      onTap: () {
        // url_launcher not included per spec — just trigger a callback
        debugPrint('Link tapped: $url');
      },
      child: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          color: Colors.blue[700],
          decoration: TextDecoration.underline,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  @override
  Widget renderSkeleton(ColumnDef<dynamic, dynamic> def) {
    return Container(
      height: 14,
      width: 80,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}
