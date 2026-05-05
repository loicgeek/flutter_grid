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
