# Changelog

All notable changes to `flutter_grid` are documented here.

## 0.2.0 — 2026-05-04

### Added

#### grid_ui
- **`fillWidth`** — `GridDataTable` and `FlutterGrid` now accept `fillWidth: bool`
  (default `false`). When `true` the table stretches to fill available horizontal
  space; when columns are wider than the viewport the table still scrolls.
- **Column span headers** — `GridHeaderRow` now renders group headers correctly:
  width is computed as the sum of `colSpan` consecutive visible columns.
  Hidden leaf-column headers are skipped automatically.
- **Hover row** — `GridDataRow` highlights the hovered row using
  `GridThemeData.hoverRowBackground`. Selection always takes priority.
- **Animated insert / remove** — `GridDataTable` is now a `StatefulWidget` backed
  by `AnimatedList`. Single-row insertions and deletions animate with a
  `SizeTransition` + `FadeTransition`. Bulk changes (sort, filter, page) reset
  instantly without animation.
- **Semantics** — `GridDataRow` and `GridHeaderRow` cells are wrapped in
  `Semantics` nodes with `label`, `selected`, and `button` properties.
- **Haptic feedback** — `GridDataRow` and `FlutterGrid` accept
  `enableHapticFeedback: bool` (default `false`). When `true`,
  `HapticFeedback.lightImpact()` fires the moment a row transitions to selected.

#### grid_core
- `ColumnDef`, `GridController`, `GridThemeData` — dartdoc comments added to
  all public APIs.

#### grid_export (new package)
- `GridExporter<T>` — converts any `GridController` to CSV.
  - `toCsv({includeHeaders, columnIds, allRows})` — returns a `String`.
  - `copyToClipboard(...)` — writes CSV to the system clipboard and returns the
    string. Uses `flutter/services.dart` — no extra dependencies.
  - Configurable `delimiter` (default `,`) and `quote` (default `"`).
  - Proper RFC 4180 quoting for values containing the delimiter, quotes, or
    line-breaks.

#### GridThemeData
- `hoverRowBackground` — color applied when the pointer is over a row.
  `GridThemeData.fromTheme` derives it from `onSurface` at 4 % opacity.

### Changed
- `GridHeaderRow` now requires a `visibleColumns` parameter (was implicit).
  `GridDataTable` passes `table.visibleColumns` automatically.
- `GridDataRow` is now a `StatefulWidget` (was `StatelessWidget`). Existing
  usages are unaffected.

### Example app
- Complete rewrite of `flutter_grid_example` with five screens:
  - **Basic** — full table with sort, filter, column visibility, pagination.
  - **Selection** — multi-row select, bulk action bar, haptic feedback.
  - **Animated** — live insert / remove demo.
  - **Export** — CSV preview and clipboard copy via `grid_export`.
  - **Features** — column pinning, custom cells, dark custom theme.

---

## 0.1.0 — initial release

- `grid_core`: headless pipeline, sort, filter, pagination, grouping, selection,
  column pinning/ordering/sizing/visibility, row pinning, expand, undo/redo.
- `grid_flutter`: `GridBuilder`, `MemoryDataSource`, `RestDataSource`,
  `StreamDataSource`, `PersistenceMiddleware`.
- `grid_ui`: `FlutterGrid`, `GridDataTable`, `GridHeaderRow`, `GridDataRow`,
  built-in cell renderers (text, number, money, date, boolean, badge, avatar,
  progress, link), skeleton loading, toolbar, filter bar, pagination, bulk
  action bar, column chooser, context menu, swipe row actions.
