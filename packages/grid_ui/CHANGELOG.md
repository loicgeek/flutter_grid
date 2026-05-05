## 0.1.0

* Initial release.
* `FlutterGrid<T>` — high-level widget with toolbar, filter bar, data table,
  and pagination. Accepts `dataSource` or `fetchData` callback.
* `GridDataTable<T>` — low-level animated table with pinned column support.
* `GridTheme` / `GridThemeData` — full visual customisation.
* `GridSlots<T>` — override any UI section (toolbar, pagination, empty state,
  error state, loading state, bulk-action bar, row leading/trailing).
* Built-in cell renderers: `TextCellRenderer`, `NumberCellRenderer`,
  `MoneyCellRenderer`, `DateCellRenderer`, `BadgeCellRenderer`,
  `BooleanCellRenderer`, `AvatarNameCellRenderer`, `LinkCellRenderer`,
  `ProgressCellRenderer`.
* `HighlightText` — highlights global-filter matches inline.
* `GridToolbar`, `GridSearchField`, `GridPagination`, `GridColumnChooser`,
  `GridFilterBar`, `GridBulkActionBar`.
