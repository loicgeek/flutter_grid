# flutter_grid

A full-featured, TanStack Table–inspired data grid for Flutter.  
Sorting, filtering, pagination, grouping, selection, pinning, editing — all composable via opt-in features.

---

## Table of contents

1. [Installation](#installation)
2. [Package layout](#package-layout)
3. [Quick start](#quick-start)
4. [Columns](#columns)
5. [Features](#features)
6. [Data sources](#data-sources)
7. [Sorting](#sorting)
8. [Filtering](#filtering)
9. [Pagination](#pagination)
10. [Row selection](#row-selection)
11. [Column management](#column-management)
12. [Row pinning](#row-pinning)
13. [Grouping & aggregation](#grouping--aggregation)
14. [Expanding rows](#expanding-rows)
15. [Cell renderers](#cell-renderers)
16. [Custom theme](#custom-theme)
17. [Slots — customise any UI section](#slots--customise-any-ui-section)
18. [Low-level: GridBuilder](#low-level-gridbuildert)
19. [Mobile layout](#mobile-layout)
20. [CSV export](#csv-export-grid_export)
21. [Middleware](#middleware)
22. [FlutterGrid parameter reference](#fluttergrid-parameter-reference)
23. [GridController API reference](#gridcontroller-api-reference)

---

## Installation

```yaml
dependencies:
  ntech_grid: ^0.1.0

  # Optional: CSV export
  grid_export: ^0.1.0
```

Or with local paths during development:

```yaml
dependencies:
  ntech_grid:
    path: ../flutter_grid        # path to your local clone

  grid_export:
    path: ../flutter_grid/packages/grid_export
```

```dart
import 'package:ntech_grid/ntech_grid.dart';
// Optional:
import 'package:grid_export/grid_export.dart';
```

---

## Package layout

```
ntech_grid  (package name)  ← meta-package, re-exports everything
  packages/
    grid_core/               ← pure Dart: models, state, pipeline, controller
    grid_flutter/            ← Flutter bindings: GridBuilder, data sources
    grid_ui/                 ← pre-built UI: FlutterGrid, cells, theme, slots
    grid_export/             ← opt-in: CSV export and clipboard copy
  flutter_grid_example/      ← demo app (6 screens)
```

---

## Quick start

```dart
class Person {
  final String name;
  final int age;
  final String role;
  Person({required this.name, required this.age, required this.role});
}

class MyPage extends StatefulWidget {
  const MyPage({super.key});
  @override
  State<MyPage> createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> {
  late final GridController<Person> _controller;

  @override
  void initState() {
    super.initState();
    _controller = GridController<Person>(
      options: GridOptions(
        columns: [
          ColumnDef<Person, String>.accessor(
            id: 'name',
            header: 'Name',
            accessorFn: (p) => p.name,
          ),
          ColumnDef<Person, int>.accessor(
            id: 'age',
            header: 'Age',
            accessorFn: (p) => p.age,
            columnType: ColumnType.number,
            textAlignIndex: 1,  // right-align
          ),
          ColumnDef<Person, String>.accessor(
            id: 'role',
            header: 'Role',
            accessorFn: (p) => p.role,
          ),
        ],
      ),
    )..setData(people);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FlutterGrid<Person>(
      controller: _controller,
      fillWidth: true,
      striped: true,
    );
  }
}
```

---

## Columns

### Accessor column (data-bound)

```dart
ColumnDef<T, V>.accessor({
  required String id,           // unique column key
  required V Function(T) accessorFn,
  String? header,               // header label
  Widget Function(CellContext<T, V>)? cell,  // custom cell widget
  Widget Function(dynamic ctx)? headerWidget, // custom header widget
  Widget Function(dynamic ctx)? footer,
  // Sorting
  bool enableSorting = true,
  int Function(V? a, V? b)? sortingFn,     // custom comparator
  // Filtering
  bool enableFiltering = true,
  bool enableGlobalFilter = true,
  bool Function(V? value, dynamic filter)? filterFn, // custom predicate
  // Grouping
  bool enableGrouping = false,
  V Function(T)? getGroupingValue,
  V? Function(List<RowModel>, List<RowModel>)? aggregationFn,
  Widget Function(dynamic ctx)? aggregatedCell,
  // Editing
  bool enableEditing = false,
  Widget Function(dynamic ctx)? editCell,
  List<String? Function(V?)>? validators,
  // Sizing & layout
  double? size,
  double? minSize,
  double? maxSize,
  bool enableSizing = true,
  bool enableResizing = false,
  // Visibility & order
  bool enableHiding = true,
  bool enableOrdering = true,
  bool enablePinning = false,
  // Visual
  ColumnType columnType = ColumnType.text,
  int? textAlignIndex,   // 0 = left, 1 = right, 2 = center
  Widget? headerIcon,
  String? tooltip,
})
```

### Display column (no data, e.g. action buttons)

```dart
ColumnDef<T, dynamic>.display({
  required String id,
  String? header,
  required Widget Function(CellContext<T, dynamic>) cell,
  Widget Function(dynamic ctx)? headerWidget,
  double? size,
  bool enableHiding = false,
  bool enableOrdering = false,
  bool enablePinning = true,
})
```

### Column groups (spanning headers)

```dart
GridOptions(
  columns: [
    ColumnDefGroup<Person>(
      id: 'identity',
      header: 'Identity',
      columns: [
        ColumnDef<Person, String>.accessor(id: 'firstName', ...),
        ColumnDef<Person, String>.accessor(id: 'lastName', ...),
      ],
    ),
    ColumnDef<Person, String>.accessor(id: 'role', ...),
  ],
)
```

### Custom cell renderer

`cell` receives a `CellContext<T, V>` giving access to the row, value, column, and controller:

```dart
ColumnDef<Order, String>.accessor(
  id: 'status',
  accessorFn: (o) => o.status,
  header: 'Status',
  cell: (ctx) {
    final status = ctx.value;
    return Chip(
      label: Text(status ?? ''),
      backgroundColor: status == 'paid'
          ? Colors.green.shade100
          : Colors.orange.shade100,
    );
  },
)
```

### Built-in column types

Set `columnType` to get automatic rendering without writing a `cell`:

| `ColumnType` | Renders as |
|---|---|
| `text` | Plain text (highlights global filter matches) |
| `number` | Right-aligned integer |
| `money` | Right-aligned, 2 decimal places |
| `date` | `DD/MM/YYYY` |
| `datetime` | `DD/MM/YYYY HH:mm` |
| `boolean` | ✓ green / ✗ red icon |
| `badge` | Pill badge (accepts `BadgeConfig` or plain string) |
| `avatar` | Avatar + name (accepts `{name, avatarUrl?}` or string) |
| `link` | Tappable blue link (accepts `{label, url}` or string) |
| `progress` | Linear bar + % (accepts `0.0–1.0`) |

```dart
ColumnDef<Employee, double>.accessor(
  id: 'completion',
  header: 'Progress',
  accessorFn: (e) => e.completion,  // 0.0 – 1.0
  columnType: ColumnType.progress,
),
ColumnDef<Employee, bool>.accessor(
  id: 'active',
  header: 'Active',
  accessorFn: (e) => e.isActive,
  columnType: ColumnType.boolean,
),
```

---

## Features

All features are opt-in. Pass them to `GridOptions.features`:

```dart
GridOptions(
  columns: [...],
  features: [
    SortFeature(enableMultiSort: true),
    FilterFeature(),
    PaginationFeature(defaultPageSize: 20),
    SelectionFeature(),
    ColumnPinningFeature(),
    ColumnOrderingFeature(),
    ColumnSizingFeature(),
    ColumnVisibilityFeature(),
    RowPinningFeature(),
    GroupingFeature(),
    ExpandingFeature(),
  ],
)
```

### Feature reference

| Feature class | Key options |
|---|---|
| `SortFeature` | `enableMultiSort`, `manual` |
| `FilterFeature` | `enableGlobalFilter`, `enableColumnFilters`, `manual` |
| `PaginationFeature` | `mode` (`clientSide`/`serverSide`/`infinite`), `defaultPageSize`, `pageSizeOptions` |
| `SelectionFeature` | `enableMultiRowSelection`, `enableSelectAll`, `enableSelectAllPages` |
| `ColumnPinningFeature` | — |
| `ColumnOrderingFeature` | — |
| `ColumnSizingFeature` | `resizeMode` (`onChange`/`onEnd`) |
| `ColumnVisibilityFeature` | `defaultVisibility` |
| `RowPinningFeature` | `keepPinnedRows` |
| `GroupingFeature` | `manual`, `groupedColumnMode` (`reorder`/`remove`/`none`), `enableGrouping` |
| `ExpandingFeature` | `manual`, `paginateExpandedRows`, `expandOnRowClick`, `autoExpandDepth` |

---

## Data sources

### In-memory

```dart
controller.setData(myList);

// Reload after a mutation
final updated = [...myList, newItem];
controller.setData(updated);
```

### `fetchData` callback (simplest server-side approach)

`FlutterGrid` accepts a `fetchData` callback that is called automatically whenever the grid state changes (page, sort, filter):

```dart
FlutterGrid<Product>(
  controller: controller,
  fetchData: (GridQuery query) async {
    final res = await api.getProducts(
      page:     query.pageIndex,
      pageSize: query.pageSize,
      sort:     query.sorting.firstOrNull?.columnId,
      desc:     query.sorting.firstOrNull?.descending ?? false,
      search:   query.globalFilter,
    );
    return GridPage(
      data:        res.items,
      totalItems:  res.total,
      currentPage: res.page,
      pageSize:    res.pageSize,
    );
  },
)
```

> Enable `manualPagination: true` in `initialState` so the grid doesn't re-slice
> the current page client-side on top of server-side results.

### `GridDataSource<T>` (repository pattern)

For full control — insert, update, delete, streaming — extend `GridDataSource`:

```dart
class ProductsDataSource extends GridDataSource<Product> {
  @override
  Future<GridPage<Product>> fetch(GridQuery query) async {
    final skip = query.pageIndex * query.pageSize;
    final json = await http.get(
      Uri.parse('/api/products?limit=${query.pageSize}&skip=$skip'),
    );
    return GridPage(
      data:        (json['items'] as List).map(Product.fromJson).toList(),
      totalItems:  json['total'] as int,
      currentPage: query.pageIndex + 1,
      pageSize:    query.pageSize,
    );
  }

  @override
  Future<Product?> insert(Product item) => api.createProduct(item);

  @override
  Future<Product?> update(Product item) => api.updateProduct(item);

  @override
  Future<bool> delete(dynamic id) => api.deleteProduct(id as String);
}
```

```dart
FlutterGrid<Product>(
  controller: _controller,
  dataSource: ProductsDataSource(),
)
```

### `StreamDataSource` (real-time)

```dart
FlutterGrid<Message>(
  controller: _controller,
  dataSource: StreamDataSource(
    streamBuilder: (query) => firestore
      .collection('messages')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(Message.fromDoc).toList()),
  ),
)
```

### `GridQuery` fields

`GridQuery` is passed to `fetch()` / `fetchData()`:

| Field | Type | Description |
|---|---|---|
| `pageIndex` | `int` | 0-based page index |
| `pageSize` | `int` | Rows per page |
| `sorting` | `List<SortEntry>` | Each entry has `columnId` + `descending` |
| `globalFilter` | `String?` | Search box text |
| `columnFilters` | `Map<String, dynamic>` | Per-column filter values |
| `grouping` | `List<String>` | Active grouping column IDs |

```dart
// Convert to standard HTTP params
final params = query.toQueryParameters();
// → {'page': '1', 'pageSize': '10', 'sort': '-name', 'q': 'flutter'}
```

---

## Sorting

Enable with `SortFeature`. Columns are sortable by default (`enableSorting: true`).

```dart
// Single-column sort (click column header in UI)
controller.toggleSort('name');

// Multi-column sort
controller.toggleSort('role');   // add second sort column
controller.setSort([
  SortEntry(columnId: 'role', descending: false),
  SortEntry(columnId: 'name', descending: true),
]);

// Reset
controller.resetSort();
```

**Custom sort function:**

```dart
ColumnDef<Person, String>.accessor(
  id: 'name',
  accessorFn: (p) => p.name,
  sortingFn: (a, b) => a!.toLowerCase().compareTo(b!.toLowerCase()),
)
```

**Multi-sort** — hold Shift while clicking a header, or pass `enableMultiSort: true` to `SortFeature` and the toolbar will surface shift-click behaviour.

---

## Filtering

Enable with `FilterFeature`. The toolbar shows a global search field automatically.

```dart
// Global search (all text columns)
controller.setGlobalFilter('flutter');
controller.setGlobalFilter(null); // clear

// Per-column filter
controller.setColumnFilter('status', 'active');
controller.removeColumnFilter('status');

// Clear everything
controller.clearAllFilters();
```

**Custom filter predicate per column:**

```dart
ColumnDef<Order, double>.accessor(
  id: 'amount',
  accessorFn: (o) => o.amount,
  filterFn: (value, filter) {
    final min = (filter as Map)['min'] as double?;
    final max = filter['max'] as double?;
    if (value == null) return false;
    if (min != null && value < min) return false;
    if (max != null && value > max) return false;
    return true;
  },
)

// Apply:
controller.setColumnFilter('amount', {'min': 100.0, 'max': 500.0});
```

---

## Pagination

### Client-side

```dart
GridController<T>(
  options: GridOptions(
    columns: [...],
    features: [PaginationFeature(defaultPageSize: 20)],
  ),
)..setData(allRows);
```

### Server-side

Pass `manualPagination: true` so the grid doesn't re-slice the data it receives:

```dart
GridController<T>(
  options: GridOptions(
    columns: [...],
    features: [PaginationFeature(mode: PaginationMode.serverSide)],
  ),
  initialState: const GridState(
    manualPagination: true,
    pagination: PaginationState(pageSize: 10),
  ),
)
```

Then wire data via `dataSource` or `fetchData` — the framework calls `fetch()` automatically when the user changes page or page size.

### Manual pagination controls

```dart
controller.nextPage();
controller.previousPage();
controller.setPageIndex(3);   // 0-based
controller.setPageSize(50);
```

---

## Row selection

Enable with `SelectionFeature`.

```dart
GridOptions(
  features: [
    SelectionFeature(
      enableMultiRowSelection: true,
      enableSelectAll:        true,
      enableSelectAllPages:   true,   // "select all N rows" banner
    ),
  ],
)
```

```dart
// In onRowTap:
controller.toggleRowSelection(row.id);

// Programmatic:
controller.toggleAllRowsSelected();          // toggle page
controller.toggleAllRowsSelected(value: true); // force-select page
controller.selectAllPages(true);             // mark cross-page selection
controller.clearRowSelection();

// Read state:
final selected = controller.state.hasSelection;   // bool
final count    = controller.state.selectedCount;  // int
final ids      = controller.state.rowSelection    // Map<String,bool>
    .entries.where((e) => e.value).map((e) => e.key);
```

**Custom row ID** — by default the index is used. Provide `getRowId` to use your model's ID:

```dart
GridOptions(
  getRowId: (person, _) => person.id,
  columns: [...],
)
```

---

## Column management

### Visibility

```dart
GridOptions(features: [ColumnVisibilityFeature()])

controller.toggleColumnVisibility('email');
controller.setColumnVisibility('phone', false);
// The toolbar's column chooser button appears automatically.
```

### Pinning

```dart
GridOptions(features: [ColumnPinningFeature()])

// Mark a column as pinnable in its definition:
ColumnDef<T, String>.accessor(id: 'actions', enablePinning: true, ...)

// Pin/unpin:
controller.pinColumn('actions', ColumnPinPosition.right);
controller.pinColumn('name',    ColumnPinPosition.left);
controller.unpinColumn('actions');
```

### Ordering (drag-to-reorder)

```dart
GridOptions(features: [ColumnOrderingFeature()])

controller.setColumnOrder(['id', 'name', 'role', 'actions']);
```

### Resizing

```dart
GridOptions(features: [ColumnSizingFeature(resizeMode: ColumnResizeMode.onEnd)])

// Column definitions set initial and min/max sizes:
ColumnDef<T, String>.accessor(
  id: 'description',
  enableResizing: true,
  size: 200,
  minSize: 80,
  maxSize: 400,
)

// Programmatic:
controller.setColumnSize('description', 300);
controller.resetColumnSizing();
```

---

## Row pinning

```dart
GridOptions(
  getRowId: (item, _) => item.id,
  features: [RowPinningFeature(keepPinnedRows: true)],
)

// Pin the first row at the top:
controller.pinRow(someRow.id, 'top');
controller.pinRow(anotherRow.id, 'bottom');
controller.unpinRow(someRow.id);
```

Pinned rows are exposed via `GridTableState.topPinnedRows` and `bottomPinnedRows`.

---

## Grouping & aggregation

```dart
GridOptions(
  features: [
    GroupingFeature(
      groupedColumnMode: GroupedColumnMode.reorder, // move grouped cols first
    ),
  ],
  columns: [
    ColumnDef<Sale, String>.accessor(
      id: 'region',
      accessorFn: (s) => s.region,
      enableGrouping: true,
    ),
    ColumnDef<Sale, double>.accessor(
      id: 'revenue',
      header: 'Revenue',
      accessorFn: (s) => s.revenue,
      columnType: ColumnType.money,
      aggregationFn: (leafRows, _) =>
          leafRows.fold(0.0, (sum, r) => sum + (r.original as Sale).revenue),
      aggregatedCell: (ctx) {
        final val = (ctx as CellContext<Sale, double>).value;
        return Text('\$${val?.toStringAsFixed(0) ?? '–'}',
            style: const TextStyle(fontWeight: FontWeight.w700));
      },
    ),
  ],
)

// Activate grouping:
controller.setGrouping(['region']);
controller.setGrouping([]);  // clear
```

---

## Expanding rows

For tree data or master/detail layouts.

```dart
GridOptions(
  getSubRows: (item) => item.children,  // null or empty = leaf
  features: [
    ExpandingFeature(
      expandOnRowClick: false,     // expand via chevron icon in cell
      autoExpandDepth: 1,          // auto-expand the first level
    ),
  ],
)

// Programmatic:
controller.toggleRowExpanded(row.id);
```

Render the expand chevron in a cell:

```dart
ColumnDef<Item, String>.accessor(
  id: 'name',
  accessorFn: (i) => i.name,
  cell: (ctx) {
    final row = ctx.row;
    return Row(children: [
      SizedBox(width: row.depth * 16),  // indent
      if (row.subRows.isNotEmpty)
        IconButton(
          icon: Icon(row.isExpanded
              ? Icons.expand_less
              : Icons.expand_more),
          onPressed: () => ctx.controller.toggleRowExpanded(row.id),
        ),
      Text(ctx.value ?? ''),
    ]);
  },
)
```

---

## Cell renderers

### `CellContext<T, V>`

Every `cell` callback receives a `CellContext`:

```dart
cell: (ctx) {
  ctx.value       // V? — the cell value from accessorFn
  ctx.row         // RowModel<T>
  ctx.row.original  // T — the original data object
  ctx.column      // ColumnInfo<T, V>
  ctx.controller  // GridController<T>
  ctx.buildContext  // BuildContext
}
```

### Pre-built standalone widgets

```dart
// Highlight search matches in any text widget
HighlightText(
  text: 'Hello Flutter world',
  highlight: controller.state.globalFilter,
)

// Use inside a cell alongside other widgets
cell: (ctx) => Row(children: [
  const Icon(Icons.person, size: 16),
  const SizedBox(width: 6),
  HighlightText(
    text: ctx.value ?? '',
    highlight: ctx.controller.state.globalFilter,
  ),
])
```

---

## Custom theme

Wrap any ancestor widget with `GridTheme` to override defaults:

```dart
GridTheme(
  data: GridThemeData(
    headerBackground:      const Color(0xFF1E293B),
    headerForeground:      Colors.white,
    headerTextStyle:       const TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.8,
    ),
    headerHeight:          44,
    rowHeight:             56,
    rowBackground:         Colors.white,
    alternateRowBackground: const Color(0xFFF8FAFC),
    hoverRowBackground:    const Color(0xFFF1F5F9),
    selectedRowBackground: const Color(0xFFEFF6FF),
    borderColor:           const Color(0xFFE2E8F0),
    borderWidth:           1,
    pinnedColumnBackground: Colors.white,
    cellPadding:           const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    headerPadding:         const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  ),
  child: FlutterGrid<T>(controller: _controller),
)
```

`GridThemeData.fromTheme(Theme.of(context))` derives all values from your Material theme automatically — useful as a starting point:

```dart
GridTheme(
  data: GridThemeData.fromTheme(Theme.of(context)).copyWith(
    rowHeight: 64,
    headerHeight: 40,
  ),
  child: FlutterGrid<T>(controller: _controller),
)
```

---

## Slots — customise any UI section

`GridSlots` lets you override any section of `FlutterGrid` without rebuilding the whole grid:

```dart
FlutterGrid<T>(
  controller: _controller,
  slots: GridSlots<T>(
    // Replace the toolbar completely
    toolbar: (context, table) => MyCustomToolbar(controller: table.controller),

    // Custom pagination
    pagination: (context, table) => MyPagination(
      page:        table.state.pagination.pageIndex + 1,
      totalPages:  table.totalPages,
      onPrev:      () => table.controller.previousPage(),
      onNext:      () => table.controller.nextPage(),
    ),

    // Custom empty state
    emptyState: (context, emptyCtx) => Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.inbox_outlined, size: 48, color: Colors.grey),
        const SizedBox(height: 8),
        Text(emptyCtx.reason == EmptyReason.searched
            ? 'No results for your search'
            : 'No data yet'),
        if (emptyCtx.onClearFilters != null)
          TextButton(
            onPressed: emptyCtx.onClearFilters,
            child: const Text('Clear filters'),
          ),
      ]),
    ),

    // Custom loading skeleton
    loadingState: (context) => const Center(child: CircularProgressIndicator()),

    // Custom error state
    errorState: (context, error, retry) => Column(children: [
      Text('Error: $error'),
      ElevatedButton(onPressed: retry, child: const Text('Retry')),
    ]),

    // Per-row trailing widget (e.g. action menu)
    rowTrailing: (context, row) => PopupMenuButton<String>(
      onSelected: (action) { /* … */ },
      itemBuilder: (_) => const [
        PopupMenuItem(value: 'edit',   child: Text('Edit')),
        PopupMenuItem(value: 'delete', child: Text('Delete')),
      ],
    ),

    // Bulk-action banner (appears when rows are selected)
    bulkActionBar: (context, table) => Container(
      padding: const EdgeInsets.all(12),
      color: Colors.indigo.shade50,
      child: Row(children: [
        Text('${table.state.selectedCount} selected'),
        const Spacer(),
        ElevatedButton(
          onPressed: () { /* delete selected */ },
          child: const Text('Delete'),
        ),
      ]),
    ),
  ),
)
```

---

## Low-level: `GridBuilder<T>`

Use `GridBuilder` when you need full control over the rendered widget tree (custom table layout, ListView, etc.):

```dart
GridBuilder<Person>(
  controller: _controller,
  dataSource: myDataSource,   // optional
  builder: (context, table) {
    // table.isLoading   — bool
    // table.error       — String?
    // table.pageRows    — List<RowModel<T>> for the current page
    // table.totalRows   — int (total filtered rows)
    // table.totalPages  — int
    // table.state       — GridState (sort, filter, pagination, …)
    // table.visibleColumns — List<ColumnInfo<T, Object?>>

    if (table.isLoading) return const CircularProgressIndicator();
    if (table.error != null) return Text('Error: ${table.error}');

    return ListView.builder(
      itemCount: table.pageRows.length,
      itemBuilder: (_, i) {
        final row = table.pageRows[i];
        return ListTile(
          title:    Text(row.original.name),
          subtitle: Text(row.original.role),
          selected: row.isSelected,
          onTap:    () => _controller.toggleRowSelection(row.id),
        );
      },
    );
  },
)
```

### `GridTableState<T>` fields

| Field | Type | Description |
|---|---|---|
| `controller` | `GridController<T>` | The grid controller |
| `state` | `GridState` | Full current state snapshot |
| `pageRows` | `List<RowModel<T>>` | Rows on the current page |
| `filteredRows` | `List<RowModel<T>>` | All filtered (pre-paginated) rows |
| `allRows` | `List<RowModel<T>>` | All rows (no filter, no pagination) |
| `topPinnedRows` | `List<RowModel<T>>` | Rows pinned to the top |
| `bottomPinnedRows` | `List<RowModel<T>>` | Rows pinned to the bottom |
| `visibleColumns` | `List<ColumnInfo<T, Object?>>` | Visible, ordered columns |
| `leftPinnedColumns` | `List<ColumnInfo<T, Object?>>` | Pinned-left columns |
| `centerColumns` | `List<ColumnInfo<T, Object?>>` | Unpinned centre columns |
| `rightPinnedColumns` | `List<ColumnInfo<T, Object?>>` | Pinned-right columns |
| `totalRows` | `int` | Total filtered row count |
| `totalPages` | `int` | Total page count |
| `isLoading` | `bool` | Data source fetch in progress |
| `error` | `String?` | Last fetch error message |

---

## Mobile layout

`FlutterGrid` falls back to a custom `rowBuilder` when the screen width is below `breakpoint` (default `600`):

```dart
FlutterGrid<Person>(
  controller: _controller,
  breakpoint: 600,
  rowBuilder: (context, row) {
    final p = row.original;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        title:    Text(p.name),
        subtitle: Text(p.role),
        trailing: Text('${p.age} yo'),
        onTap:    () => _controller.toggleRowSelection(row.id),
      ),
    );
  },
)
```

---

## CSV export (`grid_export`)

```dart
import 'package:grid_export/grid_export.dart';

final exporter = GridExporter<Person>(controller: _controller);

// All filtered rows → CSV string
final csv = exporter.toCsv();

// Current page only, tab-separated
final tsv = GridExporter<Person>(
  controller: _controller,
  delimiter: '\t',
).toCsv(allRows: false);

// Copy to clipboard directly
await exporter.copyToClipboard();
await exporter.copyToClipboard(
  allRows: false,           // current page only
  columnIds: ['name', 'role'],  // subset of columns
);
```

---

## Middleware

Intercept every state mutation — useful for logging, analytics, or optimistic updates.

```dart
class AuditMiddleware extends GridMiddleware {
  @override
  void afterDispatch(
    GridCommand command,
    GridState prevState,
    GridState nextState,
  ) {
    print('[Grid] ${command.runtimeType}: '
        '${prevState.pagination.pageIndex} → ${nextState.pagination.pageIndex}');
  }
}

GridController<T>(
  options: GridOptions(columns: [...]),
  middleware: [
    AuditMiddleware(),
    LoggingMiddleware(verbose: true),
    AnalyticsMiddleware(onEvent: (name, props) => analytics.track(name, props)),
  ],
)
```

### Optimistic updates

```dart
controller.executeOptimistic(
  ToggleRowSelectionCommand(row.id),
  () async {
    await api.setSelected(row.id, true);
    // If this throws, the command is automatically rolled back.
  },
);
```

---

## FlutterGrid parameter reference

| Parameter | Type | Default | Description |
|---|---|---|---|
| `controller` | `GridController<T>` | required | Grid state and data |
| `dataSource` | `GridDataSource<T>?` | — | Repository pattern data source |
| `fetchData` | `Future<GridPage<T>> Function(GridQuery)?` | — | Inline fetch callback |
| `slots` | `GridSlots<T>?` | — | Override any UI section |
| `rowBuilder` | `Widget Function(BuildContext, RowModel<T>)?` | — | Mobile/card row layout |
| `showToolbar` | `bool` | `true` | Global search + column chooser |
| `showFilterBar` | `bool` | `true` | Active-filter chip bar |
| `showPagination` | `bool` | `true` | Page controls + size picker |
| `showColumnBorders` | `bool` | `false` | Vertical column dividers |
| `striped` | `bool` | `true` | Alternate row background |
| `fillWidth` | `bool` | `false` | Expand table to fill width |
| `enableHapticFeedback` | `bool` | `false` | `HapticFeedback.lightImpact()` on selection |
| `rowHeight` | `double?` | theme `52.0` | Override row height |
| `breakpoint` | `double` | `600` | Width below which `rowBuilder` is used |
| `onRowTap` | `void Function(RowModel<T>)?` | — | Row single-tap callback |
| `onRowDoubleTap` | `void Function(RowModel<T>)?` | — | Row double-tap callback |
| `onRowLongPress` | `void Function(RowModel<T>)?` | — | Row long-press callback |

---

## GridController API reference

### Data

```dart
controller.setData(List<T> data);
controller.setDataWithPageCount(List<T> data, int pageCount); // server-side
controller.refresh();
controller.dispose();
```

### Sorting

```dart
controller.toggleSort('columnId', multi: false);
controller.setSort([SortEntry(columnId: 'name', descending: true)]);
controller.resetSort();
```

### Filtering

```dart
controller.setGlobalFilter('query');
controller.setColumnFilter('status', 'active');
controller.removeColumnFilter('status');
controller.clearAllFilters();
```

### Pagination

```dart
controller.nextPage();
controller.previousPage();
controller.setPageIndex(2);   // 0-based
controller.setPageSize(25);
```

### Selection

```dart
controller.toggleRowSelection(rowId);
controller.toggleAllRowsSelected();
controller.toggleAllRowsSelected(value: true);
controller.selectAllPages(true);
controller.clearRowSelection();
```

### Columns

```dart
controller.toggleColumnVisibility('email');
controller.setColumnVisibility('email', false);
controller.pinColumn('actions', ColumnPinPosition.right);
controller.unpinColumn('actions');
controller.setColumnOrder(['id', 'name', 'email', 'actions']);
controller.setColumnSize('name', 200);
controller.resetColumnSizing();
```

### Rows

```dart
controller.pinRow(rowId, 'top');     // or 'bottom'
controller.unpinRow(rowId);
controller.toggleRowExpanded(rowId);
```

### Grouping

```dart
controller.setGrouping(['region']);
controller.setGrouping([]);   // clear
```

### Undo / redo

```dart
controller.canUndo  // bool
controller.canRedo  // bool
controller.undo();
controller.redo();
```

### Reading state

```dart
final state = controller.state;
state.pagination.pageIndex   // int (0-based)
state.pagination.pageSize    // int
state.sorting                // List<SortEntry>
state.globalFilter           // String?
state.columnFilters          // Map<String, dynamic>
state.hasActiveFilters       // bool
state.hasSelection           // bool
state.selectedCount          // int
state.rowSelection           // Map<String, bool>
state.grouping               // List<String>

// Convert to HTTP parameters for server-side queries
state.toQuery().toQueryParameters()
// → {'page': '1', 'pageSize': '10', 'sort': '-name', 'q': 'flutter'}
```

---

## Disable vertical bounce on Flutter Web

Prevent the browser page from bouncing when the user scrolls inside the grid:

```html
<!-- web/index.html -->
<style>
  html, body { overscroll-behavior: none; }
</style>
```

---

## Running the example app

```sh
cd flutter_grid_example
flutter pub get
flutter run
```

Six demo screens are available via the bottom navigation bar: Basic, Selection, Animated, Export, Features, Clients (server-side pagination), and Todos (live API with `GridDataSource`).

---

## License

MIT
