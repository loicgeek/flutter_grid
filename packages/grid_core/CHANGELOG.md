## 0.1.4 - 2026-05-07

* Internal release bump.

## 0.1.3 - 2026-05-07

* Internal release bump.

## 0.1.0

* Initial release.
* `GridController` with full sort / filter / paginate / group / select pipeline.
* `GridDataSource<T>` abstraction with `fetch`, `watch`, `insert`, `update`, `delete`.
* `GridPage<T>` and `GridQuery` models for server-side pagination.
* `GridState` with undo / redo stack.
* Composable opt-in features: `SortFeature`, `FilterFeature`, `PaginationFeature`,
  `SelectionFeature`, `ColumnPinningFeature`, `ColumnOrderingFeature`,
  `ColumnSizingFeature`, `ColumnVisibilityFeature`, `RowPinningFeature`,
  `GroupingFeature`, `ExpandingFeature`.
* `GridMiddleware` for command interception (logging, analytics, optimistic updates).
