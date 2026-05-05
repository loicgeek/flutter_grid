import 'package:flutter/widgets.dart';
import 'package:grid_core/grid_core.dart';

/// Context passed to [ColumnDef.headerWidget] builders.
///
/// ```dart
/// ColumnDef.display(
///   id: 'select',
///   headerWidget: (ctx) {
///     final h = ctx as HeaderContext<MyRow>;
///     return Checkbox(
///       value: ...,
///       onChanged: (_) => h.controller.toggleAllRowsSelected(),
///     );
///   },
/// )
/// ```
class HeaderContext<T> {
  final ColumnInfo<T, Object?> column;
  final GridController<T> controller;
  final BuildContext buildContext;

  const HeaderContext({
    required this.column,
    required this.controller,
    required this.buildContext,
  });
}
