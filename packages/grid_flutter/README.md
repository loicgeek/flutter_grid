# grid_flutter

Flutter bindings layer of [ntech_grid](https://pub.dev/packages/ntech_grid).

Provides `GridBuilder` (reactive widget), ready-made `GridDataSource`
implementations, and the `GridPage` / `GridQuery` pipeline for server-side
pagination.

## Part of ntech_grid

Most users should depend on the top-level package instead:

```yaml
dependencies:
  ntech_grid: ^0.1.0
```

```dart
import 'package:ntech_grid/ntech_grid.dart';
```

Use `grid_flutter` directly only if you need the Flutter bindings without the
pre-built UI widgets from `grid_ui`.

## Key exports

| Symbol | Description |
|---|---|
| `GridBuilder<T>` | Reactive widget — rebuilds on controller changes, drives `dataSource` |
| `MemoryDataSource<T>` | In-memory list source |
| `StreamDataSource<T>` | Real-time stream source (Firebase, WebSocket…) |
| `RestDataSource<T>` | HTTP/Dio source with `x-total-count` / body total support |

## GridBuilder usage

```dart
GridBuilder<Person>(
  controller: _controller,
  dataSource: myDataSource,
  builder: (context, table) {
    if (table.isLoading) return const CircularProgressIndicator();
    if (table.error != null) return Text('Error: ${table.error}');
    return ListView.builder(
      itemCount: table.pageRows.length,
      itemBuilder: (_, i) => ListTile(title: Text(table.pageRows[i].original.name)),
    );
  },
)
```

## Documentation

Full documentation and code samples are in the
[flutter_grid README](https://github.com/loicgeek/flutter_grid).

## License

MIT — see [LICENSE](LICENSE).
