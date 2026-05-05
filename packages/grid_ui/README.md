# grid_ui

Pre-built UI layer of [flutter_grid](https://pub.dev/packages/flutter_grid).

Ships `FlutterGrid`, `GridDataTable`, `GridTheme`, `GridSlots`, built-in cell
renderers, toolbar, search, pagination, and bulk-action bar.

## Part of flutter_grid

Most users should depend on the top-level package instead:

```yaml
dependencies:
  flutter_grid: ^0.1.0
```

```dart
import 'package:flutter_grid/flutter_grid.dart';
```

## Quick example

```dart
FlutterGrid<Person>(
  controller: _controller,
  fillWidth: true,
  striped: true,
  showToolbar: true,
  showPagination: true,
)
```

## Key exports

| Symbol | Description |
|---|---|
| `FlutterGrid<T>` | High-level grid: toolbar + table + pagination |
| `GridDataTable<T>` | Low-level animated table widget |
| `GridTheme` / `GridThemeData` | Full visual customisation |
| `GridSlots<T>` | Override toolbar, pagination, empty/error/loading state… |
| `GridPagination<T>` | Standalone pagination bar |
| `GridToolbar<T>` | Search field + column chooser |
| `GridSearchField<T>` | Debounced search input |
| `GridColumnChooser<T>` | Column visibility toggle popup |
| `HighlightText` | Text with filter-match highlighting |
| `ColumnType` | `text`, `number`, `money`, `date`, `boolean`, `badge`, `avatar`, `link`, `progress` |

## Documentation

Full documentation, theming guide, and slot examples are in the
[flutter_grid README](https://github.com/loicgeek/flutter_grid).

## License

MIT — see [LICENSE](LICENSE).
