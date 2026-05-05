# grid_core

Headless, pure-Dart core of [flutter_grid](https://pub.dev/packages/flutter_grid).

Contains the controller, state machine, column definitions, sort/filter/paginate/group pipeline, and the `GridDataSource` abstraction — **no Flutter dependency**.

## Part of flutter_grid

Most users should depend on the top-level package instead:

```yaml
dependencies:
  flutter_grid: ^0.1.0
```

```dart
import 'package:flutter_grid/flutter_grid.dart';
```

Use `grid_core` directly only if you need the headless logic without any UI layer (e.g. a pure-Dart server, unit tests, or a custom renderer).

## Key exports

| Symbol | Description |
|---|---|
| `GridController<T>` | Central state controller |
| `GridOptions<T>` | Column definitions + feature list |
| `GridState` | Immutable state snapshot |
| `ColumnDef<T, V>` | Column definition (accessor / display) |
| `GridDataSource<T>` | Abstract fetch / watch / CRUD interface |
| `GridPage<T>` | Paginated response model |
| `GridQuery` | Query parameters (page, sort, filter…) |
| `GridFeature` subclasses | `SortFeature`, `FilterFeature`, `PaginationFeature`, `SelectionFeature`, `ColumnPinningFeature`, `ColumnOrderingFeature`, `ColumnSizingFeature`, `ColumnVisibilityFeature`, `RowPinningFeature`, `GroupingFeature`, `ExpandingFeature` |
| `GridMiddleware` | Command interception (logging, analytics) |

## Documentation

Full documentation, code samples, and the feature reference are in the
[flutter_grid README](https://github.com/loicgeek/flutter_grid).

## License

MIT — see [LICENSE](LICENSE).
