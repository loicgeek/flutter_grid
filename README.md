# flutter_grid

A full-featured, TanStack Table–inspired data grid for Flutter.

## Features

| Feature | Status |
|---|---|
| Sorting (multi-column, undo/redo) | ✅ |
| Filtering (global + per-column) | ✅ |
| Pagination (client-side) | ✅ |
| Column visibility | ✅ |
| Column pinning (left / right) | ✅ |
| Column ordering | ✅ |
| Row selection (single / multi) | ✅ |
| Row pinning (top / bottom) | ✅ |
| Row grouping & aggregation | ✅ |
| Expanding rows | ✅ |
| Animated insert / remove | ✅ |
| Hover row highlight | ✅ |
| Haptic feedback on selection | ✅ |
| Fill-width table | ✅ |
| Column span headers | ✅ |
| Accessibility (Semantics) | ✅ |
| CSV export + clipboard | ✅ (`grid_export`) |
| Custom cell renderers | ✅ |
| Custom theme | ✅ |
| Remote / streaming data sources | ✅ |
| Mobile card / list view | ✅ |

---

## Quick start

```dart
dependencies:
  flutter_grid:
    path: ../flutter_grid          # or pub.dev version
```

```dart
import 'package:flutter_grid/flutter_grid.dart';

final controller = GridController<Person>(
  options: GridOptions(
    columns: [
      ColumnDef<Person, String>.accessor(
        id: 'name',
        accessorFn: (p) => p.name,
        header: 'Name',
      ),
      ColumnDef<Person, int>.accessor(
        id: 'age',
        accessorFn: (p) => p.age,
        header: 'Age',
        columnType: ColumnType.number,
        textAlignIndex: 1,
      ),
    ],
  ),
)..setData(people);

@override
Widget build(BuildContext context) {
  return FlutterGrid<Person>(
    controller: controller,
    fillWidth: true,
    striped: true,
    enableHapticFeedback: true,
  );
}
```

---

## Package layout

```
flutter_grid/           ← meta-package (re-exports everything)
packages/
  grid_core/            ← pure Dart: models, state, pipeline, controller
  grid_flutter/         ← Flutter bindings: GridBuilder, GridScope, data sources
  grid_ui/              ← pre-built UI: FlutterGrid, cells, theme, slots
  grid_export/          ← opt-in: CSV export and clipboard copy
flutter_grid_example/   ← demo app
```

---

## FlutterGrid parameters

| Parameter | Type | Default | Description |
|---|---|---|---|
| `controller` | `GridController<T>` | required | State and data source |
| `fillWidth` | `bool` | `false` | Expand to fill horizontal space |
| `striped` | `bool` | `true` | Alternate row background |
| `showToolbar` | `bool` | `true` | Search field + column chooser |
| `showFilterBar` | `bool` | `true` | Active filter chips |
| `showPagination` | `bool` | `true` | Page controls + size picker |
| `showColumnBorders` | `bool` | `false` | Horizontal row dividers |
| `rowHeight` | `double?` | theme default | Override per-row height |
| `enableHapticFeedback` | `bool` | `false` | `HapticFeedback.lightImpact()` on selection |
| `breakpoint` | `double` | `600` | Width below which `rowBuilder` is used |
| `onRowTap` | callback | — | Row tap handler |
| `onRowDoubleTap` | callback | — | Row double-tap handler |
| `onRowLongPress` | callback | — | Row long-press handler |
| `slots` | `GridSlots<T>?` | — | Override any UI slot |
| `rowBuilder` | builder | — | Mobile card / custom row layout |

---

## Disable vertical bounce scroll

On Flutter Web, prevent the browser and the grid from bouncing when you scroll the grid:

```html
<style>
  html, body {
    overscroll-behavior-x: none;
  }
</style>
```

## GridController API

```dart
// Data
controller.setData(list);
controller.refresh();

// Sort
controller.toggleSort('columnId');
controller.setSort([SortEntry(columnId: 'name', descending: false)]);
controller.resetSort();

// Filter
controller.setGlobalFilter('query');
controller.setColumnFilter('columnId', value);
controller.clearAllFilters();

// Pagination
controller.nextPage();
controller.previousPage();
controller.setPageIndex(2);
controller.setPageSize(20);

// Selection
controller.toggleRowSelection(rowId);
controller.toggleAllRowsSelected();
controller.clearRowSelection();

// Column
controller.setColumnVisibility('columnId', false);
controller.pinColumn('columnId', ColumnPinPosition.left);
controller.setColumnOrder(['id1', 'id2', 'id3']);
controller.setColumnSize('columnId', 200);

// Undo / redo
controller.undo();
controller.redo();
```

---

## CSV Export (`grid_export`)

```dart
import 'package:grid_export/grid_export.dart';

final exporter = GridExporter<Person>(controller: controller);

// Export all filtered rows to CSV string
final csv = exporter.toCsv();

// Copy directly to system clipboard
await exporter.copyToClipboard();

// Export current page only, tab-separated
final tsv = GridExporter<Person>(
  controller: controller,
  delimiter: '\t',
).toCsv(allRows: false);
```

---

## Custom theme

```dart
GridTheme(
  data: GridThemeData(
    headerBackground: Colors.indigo.shade800,
    rowBackground: Colors.white,
    alternateRowBackground: Colors.indigo.shade50,
    hoverRowBackground: Colors.indigo.withValues(alpha: 0.08),
    selectedRowBackground: Colors.indigo.withValues(alpha: 0.15),
    borderColor: Colors.indigo.shade100,
    rowHeight: 52,
    headerHeight: 48,
  ),
  child: FlutterGrid<Person>(controller: controller),
)
```

---

## Data sources

### In-memory
```dart
controller.setData(myList);
```

### Fetch (REST / GraphQL)
```dart
FlutterGrid<Person>(
  controller: controller,
  fetchData: (query) async {
    final res = await api.getPersons(
      page: query.pageIndex,
      pageSize: query.pageSize,
      sort: query.sort,
      filter: query.globalFilter,
    );
    return GridPage(
      data: res.items,
      currentPage: res.page,
      totalPages: res.totalPages,
      pageSize: res.pageSize,
      totalItems: res.total,
    );
  },
)
```

### Streaming
```dart
FlutterGrid<Person>(
  controller: controller,
  dataSource: StreamDataSource(stream: myStream),
)
```

---

## Running the example app

```sh
cd flutter_grid_example
flutter pub get
flutter run
```

---

## License

MIT
