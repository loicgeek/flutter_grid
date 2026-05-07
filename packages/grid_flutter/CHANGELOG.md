## 0.1.3 - 2026-05-07

* Internal release bump.

## 0.1.0

* Initial release.
* `GridBuilder<T>` — reactive widget that rebuilds on controller changes.
* `GridDataSource<T>` implementations: `MemoryDataSource`, `StreamDataSource`,
  `RestDataSource` (Dio-based, handles `x-total-count` header and body total).
* Fix: `_isFetching` guard prevents infinite re-fetch loop when `setData` triggers
  a listener notification.
* Fix: `GridBuilder` now propagates `GridPage.totalPages` to the controller via
  `setDataWithPageCount`, so server-side pagination displays the correct page count.
