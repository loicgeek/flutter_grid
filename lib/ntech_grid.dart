/// Full-featured data table library for Flutter — TanStack Table-inspired.
///
/// ## Packages
/// - **grid_core** — Pure Dart headless table logic: models, state machine,
///   pipeline, [GridController].
/// - **grid_flutter** — Flutter bindings: [GridBuilder], data sources.
/// - **grid_ui** — Pre-built UI: [FlutterGrid], cells, theme, slots.
///
/// ## Quick start
/// ```dart
/// final controller = GridController<Person>(
///   options: GridOptions(columns: [
///     ColumnDef<Person, String>.accessor(
///       id: 'name', accessorFn: (p) => p.name, header: 'Name',
///     ),
///   ]),
/// )..setData(people);
///
/// FlutterGrid<Person>(controller: controller, fillWidth: true)
/// ```
library ntech_grid;

export 'package:grid_core/grid_core.dart';
export 'package:grid_flutter/grid_flutter.dart';
export 'package:grid_ui/grid_ui.dart';
