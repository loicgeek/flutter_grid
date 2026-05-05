# grid_export

Optional CSV export add-on for [ntech_grid](https://pub.dev/packages/ntech_grid).

Converts any `GridController` state (all filtered rows or the current page) into
a CSV / TSV string, and copies it to the system clipboard with a single call.

## Installation

```yaml
dependencies:
  ntech_grid: ^0.1.0      # main package
  grid_export: ^0.1.0       # this add-on
```

```dart
import 'package:grid_export/grid_export.dart';
```

## Usage

```dart
final exporter = GridExporter<Person>(controller: _controller);

// All filtered rows → CSV string
final csv = exporter.toCsv();

// Current page only, tab-separated
final tsv = GridExporter<Person>(
  controller: _controller,
  delimiter: '\t',
).toCsv(allRows: false);

// Copy to system clipboard
await exporter.copyToClipboard();

// Subset of columns, current page only
await exporter.copyToClipboard(
  allRows: false,
  columnIds: ['name', 'email', 'role'],
);
```

## `GridExporter` constructor

| Parameter | Type | Default | Description |
|---|---|---|---|
| `controller` | `GridController<T>` | required | Grid to export |
| `delimiter` | `String` | `','` | Column separator |
| `quote` | `String` | `'"'` | Quote character (RFC 4180) |

## `toCsv` / `copyToClipboard` options

| Option | Type | Default | Description |
|---|---|---|---|
| `includeHeaders` | `bool` | `true` | Include column header row |
| `columnIds` | `List<String>?` | all visible | Subset of columns to export |
| `allRows` | `bool` | `true` | `true` = all filtered rows; `false` = current page |

## License

MIT — see [LICENSE](LICENSE).
