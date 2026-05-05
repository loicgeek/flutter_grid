# flutter_grid — Technical Specification
> Version 1.0 — Document de référence pour le développement  
> À destination de Claude Code / Codex — Toutes les décisions d'architecture sont prises. Implémenter exactement comme spécifié.

---

## Table des matières

1. [Vision & Philosophie](#1-vision--philosophie)
2. [Structure des packages](#2-structure-des-packages)
3. [Arborescence fichiers complète](#3-arborescence-fichiers-complète)
4. [Couche 1 — grid_core (Pure Dart)](#4-couche-1--grid_core-pure-dart)
5. [Couche 2 — grid_flutter (Flutter bindings)](#5-couche-2--grid_flutter-flutter-bindings)
6. [Couche 3 — grid_ui (Components)](#6-couche-3--grid_ui-components)
7. [Système de Commands](#7-système-de-commands)
8. [Middleware Chain](#8-middleware-chain)
9. [Row Model Pipeline](#9-row-model-pipeline)
10. [Feature Modules — Spécification complète](#10-feature-modules--spécification-complète)
11. [Cell Renderer Registry](#11-cell-renderer-registry)
12. [Slot System — UI Composition](#12-slot-system--ui-composition)
13. [GridDataSource — Data abstraction](#13-griddatasource--data-abstraction)
14. [GridTheme — Theming system](#14-gridtheme--theming-system)
15. [UX Patterns — Implémentation](#15-ux-patterns--implémentation)
16. [Adaptive Rendering Strategy](#16-adaptive-rendering-strategy)
17. [Persistence Middleware](#17-persistence-middleware)
18. [Migration depuis AppPaginatedTable](#18-migration-depuis-apppaginatedtable)
19. [Tests — Stratégie complète](#19-tests--stratégie-complète)
20. [Phases de développement](#20-phases-de-développement)
21. [pubspec.yaml — Dépendances](#21-pubspecyaml--dépendances)

---

## 1. Vision & Philosophie

### 1.1 Objectif

`flutter_grid` est une bibliothèque Flutter de tableaux de données qui vise la parité fonctionnelle avec TanStack Table v8, tout en allant au-delà sur les dimensions mobile, UX, et architecture Dart-native. Elle est conçue pour remplacer `AppPaginatedTable` dans les projets ChairWatch v5 et Neero, et être publiée sur pub.dev.

### 1.2 Principes directeurs

| # | Principe | Description |
|---|---|---|
| P1 | **Headless core, UI opinionée par défaut** | Le core est du Dart pur (testable sans Flutter). La couche UI est belle et opinionée, mais chaque zone est remplaçable par un slot. |
| P2 | **Dart-native, pas un port JS** | Sealed classes pour les états, extension types pour la type-safety, null safety agressive, Streams natifs. L'API se sent comme du Flutter idiomatique. |
| P3 | **Mobile-first, pas mobile-compatible** | Swipe actions, long-press menus, pull-to-refresh, haptic feedback sont des citoyens de première classe. |
| P4 | **Composabilité par slots** | Remplacer n'importe quelle zone (toolbar, header, empty state, footer) par un widget custom sans réécrire le tableau. |
| P5 | **Commands, pas mutations directes** | Toute action passe par un `GridCommand`. Offre undo/redo, logging, analytics, et tests triviaux. |
| P6 | **Adaptive rendering automatique** | `<100` rows → full render. `100–1000` → windowed. `>1000` → virtualized. Zéro configuration. |
| P7 | **Persistence native** | `persistenceKey: 'my_table'` → sort, filtres, colonnes visibles, largeurs restaurés automatiquement. |
| P8 | **Reactive data sources** | Support natif des Streams pour les sources realtime (Supabase, Firebase, WebSocket). |

### 1.3 Ce que cette lib n'est pas

- **Pas un port 1:1 de TanStack** — l'API est inspirée mais Dart-native
- **Pas une lib de charts** — utilisez fl_chart ou syncfusion pour ça
- **Pas un ORM** — la lib consomme des données, elle ne les gère pas
- **Pas opinionée sur le state manager** — compatible BLoC, Riverpod, GetX, setState

---

## 2. Structure des packages

```
flutter_packages/
├── grid_core/           # Pure Dart — zéro dépendance Flutter
│   └── pubspec.yaml     # environment: sdk: '>=3.3.0'
│
├── grid_flutter/        # Flutter bindings — bridge core ↔ widgets
│   └── pubspec.yaml     # depends on: grid_core, flutter
│
├── grid_ui/             # Components opinionés — Material + custom
│   └── pubspec.yaml     # depends on: grid_flutter, grid_core, flutter
│
└── flutter_grid/        # Meta-package — re-export tout
    └── pubspec.yaml     # depends on: grid_core, grid_flutter, grid_ui
```

**Règle absolue** : `grid_core` ne doit JAMAIS importer `flutter/*` ou `dart:ui`. Seuls `dart:core`, `dart:async`, `dart:collection`, `dart:math` sont autorisés.

---

## 3. Arborescence fichiers complète

### 3.1 grid_core

```
flutter_packages/grid_core/
├── lib/
│   ├── grid_core.dart                    # barrel export
│   └── src/
│       ├── models/
│       │   ├── column_def.dart           # ColumnDef<T,V>
│       │   ├── grid_state.dart           # GridState (immutable)
│       │   ├── row_model.dart            # RowModel<T>, CellModel<T,V>
│       │   ├── header_group.dart         # HeaderGroup, Header
│       │   ├── pagination_state.dart     # PaginationState
│       │   ├── sort_entry.dart           # SortEntry
│       │   ├── grid_page.dart            # GridPage<T> (response wrapper)
│       │   └── grid_query.dart           # GridQuery (request params)
│       │
│       ├── controller/
│       │   ├── grid_controller.dart      # GridController<T>
│       │   └── grid_options.dart         # GridOptions<T>
│       │
│       ├── commands/
│       │   ├── grid_command.dart         # sealed class GridCommand
│       │   ├── sort_commands.dart
│       │   ├── filter_commands.dart
│       │   ├── pagination_commands.dart
│       │   ├── selection_commands.dart
│       │   ├── column_commands.dart
│       │   └── row_commands.dart
│       │
│       ├── middleware/
│       │   ├── grid_middleware.dart      # abstract GridMiddleware
│       │   ├── logging_middleware.dart
│       │   └── analytics_middleware.dart
│       │
│       ├── pipeline/
│       │   ├── pipeline_stage.dart       # abstract PipelineStage<T>
│       │   ├── filter_stage.dart
│       │   ├── sort_stage.dart
│       │   ├── group_stage.dart
│       │   ├── expand_stage.dart
│       │   └── paginate_stage.dart
│       │
│       ├── features/
│       │   ├── grid_feature.dart         # abstract GridFeature
│       │   ├── sort_feature.dart
│       │   ├── filter_feature.dart
│       │   ├── pagination_feature.dart
│       │   ├── selection_feature.dart
│       │   ├── column_visibility_feature.dart
│       │   ├── column_ordering_feature.dart
│       │   ├── column_pinning_feature.dart
│       │   ├── column_sizing_feature.dart
│       │   ├── row_pinning_feature.dart
│       │   ├── grouping_feature.dart
│       │   ├── expanding_feature.dart
│       │   └── row_dnd_feature.dart
│       │
│       ├── functions/
│       │   ├── filter_functions.dart     # FilterFn registry
│       │   ├── sort_functions.dart       # SortFn registry
│       │   └── aggregation_functions.dart# AggregationFn registry
│       │
│       └── data_source/
│           └── grid_data_source.dart     # abstract GridDataSource<T>
│
└── test/
    ├── models/
    ├── pipeline/
    ├── commands/
    └── features/
```

### 3.2 grid_flutter

```
flutter_packages/grid_flutter/
├── lib/
│   ├── grid_flutter.dart
│   └── src/
│       ├── scope/
│       │   ├── grid_scope.dart           # InheritedWidget
│       │   └── grid_provider.dart        # Provider wrapper
│       │
│       ├── builder/
│       │   └── grid_builder.dart         # GridBuilder<T> (headless widget)
│       │
│       ├── adapters/
│       │   ├── bloc_adapter.dart         # BlocGridAdapter
│       │   └── riverpod_adapter.dart     # RiverpodGridAdapter
│       │
│       ├── middleware/
│       │   └── persistence_middleware.dart # SharedPreferences
│       │
│       ├── rendering/
│       │   ├── adaptive_render_strategy.dart
│       │   └── virtualization_controller.dart
│       │
│       └── data_sources/
│           ├── rest_data_source.dart     # Dio-based
│           ├── stream_data_source.dart   # Stream-based realtime
│           └── memory_data_source.dart   # In-memory list
│
└── test/
```

### 3.3 grid_ui

```
flutter_packages/grid_ui/
├── lib/
│   ├── grid_ui.dart
│   └── src/
│       ├── widgets/
│       │   ├── flutter_grid.dart          # FlutterGrid<T> — main widget
│       │   ├── grid_list_view.dart        # Mobile list mode
│       │   ├── grid_card_view.dart        # Card grid mode
│       │   └── grid_data_table.dart       # Desktop table mode
│       │
│       ├── slots/
│       │   ├── grid_slots.dart            # GridSlots configuration
│       │   ├── grid_toolbar.dart          # Default toolbar
│       │   ├── grid_header_row.dart       # Default headers
│       │   ├── grid_data_row.dart         # Default rows
│       │   ├── grid_pagination.dart       # Default pagination
│       │   ├── grid_empty_state.dart      # Smart empty states
│       │   ├── grid_loading_state.dart    # Skeleton loader
│       │   ├── grid_error_state.dart      # Error + retry
│       │   └── grid_aggregation_footer.dart
│       │
│       ├── components/
│       │   ├── grid_filter_bar.dart       # Active filter chips
│       │   ├── grid_bulk_action_bar.dart  # Bulk selection bar
│       │   ├── grid_column_chooser.dart   # Column visibility popover
│       │   ├── grid_sort_indicator.dart   # Sort icon + index
│       │   ├── grid_search_field.dart     # Debounced search input
│       │   ├── swipe_row_actions.dart     # Mobile swipe
│       │   └── grid_context_menu.dart     # Long-press menu
│       │
│       ├── cells/
│       │   ├── cell_renderer.dart         # abstract CellRenderer
│       │   ├── cell_renderer_registry.dart
│       │   ├── text_cell.dart
│       │   ├── number_cell.dart
│       │   ├── money_cell.dart
│       │   ├── date_cell.dart
│       │   ├── boolean_cell.dart
│       │   ├── badge_cell.dart
│       │   ├── avatar_name_cell.dart
│       │   ├── progress_cell.dart
│       │   ├── link_cell.dart
│       │   └── highlight_text.dart        # Search term highlighting
│       │
│       ├── skeleton/
│       │   ├── skeleton_row.dart
│       │   └── skeleton_cell.dart         # Type-aware skeleton shapes
│       │
│       └── theme/
│           ├── grid_theme.dart
│           ├── grid_theme_data.dart
│           └── grid_color_scheme.dart
│
└── test/
```

---

## 4. Couche 1 — grid_core (Pure Dart)

### 4.1 ColumnDef<T, V>

```dart
// flutter_packages/grid_core/lib/src/models/column_def.dart

/// Type-safe column definition.
/// T = row type, V = cell value type
class ColumnDef<T, V> {
  final String id;
  final String? header;                        // Texte header (null = utiliser id)
  final V Function(T row)? accessorFn;         // Null = display column
  final String? accessorKey;                   // Shorthand pour accessorFn via reflection (évité — préférer accessorFn)
  final Widget Function(CellContext<T, V> ctx)? cell; // Custom cell renderer
  final Widget Function(HeaderContext<T> ctx)? headerWidget; // Custom header widget
  final Widget Function(FooterContext<T> ctx)? footer;
  final Widget Function(CellContext<T, V> ctx)? aggregatedCell;
  final Widget Function(CellContext<T, V> ctx)? editCell;    // Inline edit widget

  // --- Sorting ---
  final bool enableSorting;
  final SortFn<V>? sortingFn;                  // Null = auto-detect par type

  // --- Filtering ---
  final bool enableFiltering;
  final FilterFn<V>? filterFn;                 // Null = auto-detect par type
  final bool enableGlobalFilter;

  // --- Grouping ---
  final bool enableGrouping;
  final V Function(T row)? getGroupingValue;   // Override grouping value
  final AggregationFn<V>? aggregationFn;

  // --- Column features ---
  final bool enableSizing;
  final double? size;                          // Taille initiale en pixels
  final double? minSize;                       // Min 40px si null
  final double? maxSize;                       // Max double.infinity si null
  final bool enableResizing;
  final bool enableHiding;                     // false = ne peut pas être caché
  final bool enableOrdering;
  final bool enablePinning;

  // --- Editing ---
  final bool enableEditing;
  final List<Validator<V>>? validators;

  // --- Appearance ---
  final ColumnType columnType;                 // Hint pour skeleton + renderer auto
  final TextAlign? textAlign;
  final Widget? headerIcon;
  final String? tooltip;

  const ColumnDef._({
    required this.id,
    this.header,
    this.accessorFn,
    this.accessorKey,
    this.cell,
    this.headerWidget,
    this.footer,
    this.aggregatedCell,
    this.editCell,
    this.enableSorting = true,
    this.sortingFn,
    this.enableFiltering = true,
    this.filterFn,
    this.enableGlobalFilter = true,
    this.enableGrouping = false,
    this.getGroupingValue,
    this.aggregationFn,
    this.enableSizing = true,
    this.size,
    this.minSize,
    this.maxSize,
    this.enableResizing = false,
    this.enableHiding = true,
    this.enableOrdering = true,
    this.enablePinning = false,
    this.enableEditing = false,
    this.validators,
    this.columnType = ColumnType.text,
    this.textAlign,
    this.headerIcon,
    this.tooltip,
  });

  /// Accessor column — a une valeur extraite du row
  factory ColumnDef.accessor({
    required String id,
    required V Function(T row) accessorFn,
    String? header,
    Widget Function(CellContext<T, V> ctx)? cell,
    Widget Function(HeaderContext<T> ctx)? headerWidget,
    Widget Function(FooterContext<T> ctx)? footer,
    Widget Function(CellContext<T, V> ctx)? aggregatedCell,
    Widget Function(CellContext<T, V> ctx)? editCell,
    bool enableSorting = true,
    SortFn<V>? sortingFn,
    bool enableFiltering = true,
    FilterFn<V>? filterFn,
    bool enableGlobalFilter = true,
    bool enableGrouping = false,
    V Function(T row)? getGroupingValue,
    AggregationFn<V>? aggregationFn,
    bool enableSizing = true,
    double? size,
    double? minSize,
    double? maxSize,
    bool enableResizing = false,
    bool enableHiding = true,
    bool enableOrdering = true,
    bool enablePinning = false,
    bool enableEditing = false,
    List<Validator<V>>? validators,
    ColumnType columnType = ColumnType.text,
    TextAlign? textAlign,
    Widget? headerIcon,
    String? tooltip,
  }) => ColumnDef._(
    id: id,
    accessorFn: accessorFn,
    header: header,
    cell: cell,
    headerWidget: headerWidget,
    footer: footer,
    aggregatedCell: aggregatedCell,
    editCell: editCell,
    enableSorting: enableSorting,
    sortingFn: sortingFn,
    enableFiltering: enableFiltering,
    filterFn: filterFn,
    enableGlobalFilter: enableGlobalFilter,
    enableGrouping: enableGrouping,
    getGroupingValue: getGroupingValue,
    aggregationFn: aggregationFn,
    enableSizing: enableSizing,
    size: size,
    minSize: minSize,
    maxSize: maxSize,
    enableResizing: enableResizing,
    enableHiding: enableHiding,
    enableOrdering: enableOrdering,
    enablePinning: enablePinning,
    enableEditing: enableEditing,
    validators: validators,
    columnType: columnType,
    textAlign: textAlign,
    headerIcon: headerIcon,
    tooltip: tooltip,
  );

  /// Display column — pas de valeur, UI pure (ex: actions, checkbox)
  factory ColumnDef.display({
    required String id,
    String? header,
    required Widget Function(CellContext<T, dynamic> ctx) cell,
    Widget Function(HeaderContext<T> ctx)? headerWidget,
    double? size,
    bool enableHiding = false,
    bool enableOrdering = false,
    bool enablePinning = true,
    TextAlign textAlign = TextAlign.center,
  }) => ColumnDef._(
    id: id,
    header: header,
    cell: cell as Widget Function(CellContext<T, V> ctx),
    headerWidget: headerWidget,
    enableSorting: false,
    enableFiltering: false,
    enableGlobalFilter: false,
    enableGrouping: false,
    enableSizing: size != null,
    size: size,
    enableHiding: enableHiding,
    enableOrdering: enableOrdering,
    enablePinning: enablePinning,
    columnType: ColumnType.display,
    textAlign: textAlign,
  );

  /// Group column — header uniquement, regroupe des colonnes enfants
  factory ColumnDef.group({
    required String id,
    required String header,
    required List<ColumnDef<T, dynamic>> columns,
    Widget Function(HeaderContext<T> ctx)? headerWidget,
  }) {
    // Implémentation via ColumnDefGroup (voir header_group.dart)
    throw UnimplementedError('Use ColumnDefGroup directly');
  }

  bool get isAccessor => accessorFn != null;
  bool get isDisplay => accessorFn == null;
}

/// Groupe de colonnes (multi-level headers)
class ColumnDefGroup<T> {
  final String id;
  final String header;
  final List<ColumnDef<T, dynamic>> columns;
  final Widget Function(HeaderContext<T> ctx)? headerWidget;

  const ColumnDefGroup({
    required this.id,
    required this.header,
    required this.columns,
    this.headerWidget,
  });
}

/// Type hint pour l'auto-detection du renderer et du skeleton shape
enum ColumnType {
  text,
  number,
  money,
  date,
  datetime,
  boolean,
  badge,
  avatar,
  progress,
  link,
  display,
  custom,
}
```

### 4.2 GridState

```dart
// flutter_packages/grid_core/lib/src/models/grid_state.dart

/// État complet et immutable du tableau.
/// Chaque modification produit une nouvelle instance (copyWith).
class GridState {
  // --- Sorting ---
  final List<SortEntry> sorting;
  final bool manualSorting;

  // --- Filtering ---
  final Map<String, dynamic> columnFilters;  // { colId: filterValue }
  final String? globalFilter;
  final bool manualFiltering;

  // --- Pagination ---
  final PaginationState pagination;
  final bool manualPagination;
  final int? pageCount;                       // Requis si manualPagination = true

  // --- Selection ---
  final Map<String, bool> rowSelection;       // { rowId: true }
  final bool enableMultiRowSelection;

  // --- Column features ---
  final Map<String, bool> columnVisibility;   // { colId: false } = caché
  final List<String> columnOrder;             // Ordre complet des IDs
  final ColumnPinningState columnPinning;
  final Map<String, double> columnSizing;     // { colId: widthPx }

  // --- Row features ---
  final Map<String, bool> expanded;           // { rowId: true }
  final RowPinningState rowPinning;
  final List<String> grouping;                // [ colId, ... ] multi-level

  // --- Editing ---
  final String? editingCellId;                // '$rowId:$colId'

  const GridState({
    this.sorting = const [],
    this.manualSorting = false,
    this.columnFilters = const {},
    this.globalFilter,
    this.manualFiltering = false,
    this.pagination = const PaginationState(),
    this.manualPagination = false,
    this.pageCount,
    this.rowSelection = const {},
    this.enableMultiRowSelection = true,
    this.columnVisibility = const {},
    this.columnOrder = const [],
    this.columnPinning = const ColumnPinningState(),
    this.columnSizing = const {},
    this.expanded = const {},
    this.rowPinning = const RowPinningState(),
    this.grouping = const [],
    this.editingCellId,
  });

  GridState copyWith({
    List<SortEntry>? sorting,
    bool? manualSorting,
    Map<String, dynamic>? columnFilters,
    String? globalFilter,
    bool clearGlobalFilter = false,
    bool? manualFiltering,
    PaginationState? pagination,
    bool? manualPagination,
    int? pageCount,
    Map<String, bool>? rowSelection,
    bool? enableMultiRowSelection,
    Map<String, bool>? columnVisibility,
    List<String>? columnOrder,
    ColumnPinningState? columnPinning,
    Map<String, double>? columnSizing,
    Map<String, bool>? expanded,
    RowPinningState? rowPinning,
    List<String>? grouping,
    String? editingCellId,
    bool clearEditingCell = false,
  }) {
    return GridState(
      sorting: sorting ?? this.sorting,
      manualSorting: manualSorting ?? this.manualSorting,
      columnFilters: columnFilters ?? this.columnFilters,
      globalFilter: clearGlobalFilter ? null : (globalFilter ?? this.globalFilter),
      manualFiltering: manualFiltering ?? this.manualFiltering,
      pagination: pagination ?? this.pagination,
      manualPagination: manualPagination ?? this.manualPagination,
      pageCount: pageCount ?? this.pageCount,
      rowSelection: rowSelection ?? this.rowSelection,
      enableMultiRowSelection: enableMultiRowSelection ?? this.enableMultiRowSelection,
      columnVisibility: columnVisibility ?? this.columnVisibility,
      columnOrder: columnOrder ?? this.columnOrder,
      columnPinning: columnPinning ?? this.columnPinning,
      columnSizing: columnSizing ?? this.columnSizing,
      expanded: expanded ?? this.expanded,
      rowPinning: rowPinning ?? this.rowPinning,
      grouping: grouping ?? this.grouping,
      editingCellId: clearEditingCell ? null : (editingCellId ?? this.editingCellId),
    );
  }

  /// Retourne les paramètres pour une requête API server-side
  GridQuery toQuery() => GridQuery.fromState(this);

  /// Retourne une string de sort compatible avec l'API ChairWatch
  /// Ex: "-date" pour desc, "name" pour asc
  String? get sortString {
    if (sorting.isEmpty) return null;
    return sorting.map((s) => s.desc ? '-${s.id}' : s.id).join(',');
  }

  bool get hasActiveFilters =>
      columnFilters.isNotEmpty || (globalFilter != null && globalFilter!.isNotEmpty);

  bool get hasSelection => rowSelection.values.any((v) => v);
  int get selectedCount => rowSelection.values.where((v) => v).length;
}

class PaginationState {
  final int pageIndex;  // 0-based
  final int pageSize;

  const PaginationState({
    this.pageIndex = 0,
    this.pageSize = 10,
  });

  int get page => pageIndex + 1;  // 1-based pour les APIs

  PaginationState copyWith({int? pageIndex, int? pageSize}) =>
    PaginationState(
      pageIndex: pageIndex ?? this.pageIndex,
      pageSize: pageSize ?? this.pageSize,
    );
}

class ColumnPinningState {
  final List<String> left;
  final List<String> right;

  const ColumnPinningState({
    this.left = const [],
    this.right = const [],
  });

  ColumnPinningState copyWith({List<String>? left, List<String>? right}) =>
    ColumnPinningState(left: left ?? this.left, right: right ?? this.right);
}

class RowPinningState {
  final List<String> top;
  final List<String> bottom;

  const RowPinningState({
    this.top = const [],
    this.bottom = const [],
  });
}

class SortEntry {
  final String id;
  final bool desc;

  const SortEntry({required this.id, this.desc = false});

  SortEntry copyWith({String? id, bool? desc}) =>
    SortEntry(id: id ?? this.id, desc: desc ?? this.desc);

  @override
  bool operator ==(Object other) =>
    identical(this, other) || (other is SortEntry && other.id == id && other.desc == desc);

  @override
  int get hashCode => Object.hash(id, desc);
}
```

### 4.3 GridController<T>

```dart
// flutter_packages/grid_core/lib/src/controller/grid_controller.dart

class GridController<T> extends ChangeNotifier {
  late GridState _state;
  final GridOptions<T> options;
  final List<GridMiddleware> _middleware;
  final _commandHistory = <GridCommand>[];
  final _redoStack = <GridCommand>[];
  int _epoch = 0;

  // Données courantes
  List<T> _data = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _error;

  // Row models calculés (lazy, invalidés par les commands)
  RowModelSet<T>? _cachedRowModels;
  List<ColumnInfo<T>>? _cachedColumns;

  GridController({
    required this.options,
    GridState? initialState,
    List<GridMiddleware> middleware = const [],
  }) : _middleware = middleware {
    _state = initialState ?? _buildInitialState();
  }

  // --- Getters ---
  GridState get state => _state;
  List<T> get rawData => List.unmodifiable(_data);
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get error => _error;
  List<GridCommand> get commandHistory => List.unmodifiable(_commandHistory);
  bool get canUndo => _commandHistory.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  // --- Command dispatch ---
  void dispatch(GridCommand command) {
    // Passer par le middleware chain
    GridCommand effectiveCommand = command;
    for (final mw in _middleware) {
      effectiveCommand = mw.beforeDispatch(effectiveCommand, _state) ?? effectiveCommand;
    }

    final prevState = _state;
    _state = _applyCommand(effectiveCommand, _state);
    _invalidateCache();

    // History pour undo/redo
    if (command.undoable) {
      _commandHistory.add(command.withPrevState(prevState));
      _redoStack.clear();
    }

    // After middleware
    for (final mw in _middleware) {
      mw.afterDispatch(effectiveCommand, prevState, _state);
    }

    notifyListeners();
  }

  void undo() {
    if (!canUndo) return;
    final command = _commandHistory.removeLast();
    _redoStack.add(command);
    _state = command.prevState!;
    _invalidateCache();
    notifyListeners();
  }

  void redo() {
    if (!canRedo) return;
    final command = _redoStack.removeLast();
    _commandHistory.add(command);
    _state = _applyCommand(command, _state);
    _invalidateCache();
    notifyListeners();
  }

  // --- Data management ---
  void setData(List<T> data) {
    _data = data;
    _invalidateCache();
    notifyListeners();
  }

  void appendData(List<T> newData) {
    _data = [..._data, ...newData];
    _invalidateCache();
    notifyListeners();
  }

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void setLoadingMore(bool loading) {
    _isLoadingMore = loading;
    notifyListeners();
  }

  void setError(String? error) {
    _error = error;
    _isLoading = false;
    notifyListeners();
  }

  void setPageCount(int count) {
    _state = _state.copyWith(pageCount: count);
    notifyListeners();
  }

  // --- Row model access ---
  RowModelSet<T> getRowModels() {
    _cachedRowModels ??= _buildRowModels();
    return _cachedRowModels!;
  }

  /// Retourne les lignes de la page courante
  List<RowModel<T>> getPageRows() => getRowModels().pageRows;

  /// Lignes pinnées en haut
  List<RowModel<T>> getTopPinnedRows() => getRowModels().topPinnedRows;

  /// Lignes pinnées en bas
  List<RowModel<T>> getBottomPinnedRows() => getRowModels().bottomPinnedRows;

  /// Header groups (multi-level)
  List<HeaderGroup<T>> getHeaderGroups() {
    _cachedColumns ??= _buildColumns();
    return _buildHeaderGroups(_cachedColumns!);
  }

  /// Colonnes visibles (dans l'ordre courant, avec pinning)
  List<ColumnInfo<T>> getVisibleColumns() {
    _cachedColumns ??= _buildColumns();
    return _cachedColumns!.where((c) => c.isVisible).toList();
  }

  List<ColumnInfo<T>> getLeftPinnedColumns() =>
    getVisibleColumns().where((c) => c.isPinnedLeft).toList();

  List<ColumnInfo<T>> getCenterColumns() =>
    getVisibleColumns().where((c) => !c.isPinned).toList();

  List<ColumnInfo<T>> getRightPinnedColumns() =>
    getVisibleColumns().where((c) => c.isPinnedRight).toList();

  // --- Faceting ---
  Map<dynamic, int> getColumnFacetedUniqueValues(String colId) {
    final col = options.columns.firstWhere((c) => c.id == colId);
    final rows = getRowModels().filteredRows;
    final counts = <dynamic, int>{};
    for (final row in rows) {
      final val = col.accessorFn?.call(row.original);
      counts[val] = (counts[val] ?? 0) + 1;
    }
    return counts;
  }

  (dynamic min, dynamic max) getColumnFacetedMinMax(String colId) {
    final col = options.columns.firstWhere((c) => c.id == colId);
    final rows = getRowModels().filteredRows;
    dynamic min, max;
    for (final row in rows) {
      final val = col.accessorFn?.call(row.original);
      if (val == null) continue;
      if (min == null || (val as Comparable).compareTo(min) < 0) min = val;
      if (max == null || (val as Comparable).compareTo(max) > 0) max = val;
    }
    return (min, max);
  }

  // --- Column shortcuts (pour usage courant sans dispatch) ---
  void setSort(List<SortEntry> sorting) =>
    dispatch(SetSortCommand(sorting));

  void toggleSort(String colId) =>
    dispatch(ToggleSortCommand(colId));

  void setGlobalFilter(String? value) =>
    dispatch(SetGlobalFilterCommand(value));

  void setColumnFilter(String colId, dynamic value) =>
    dispatch(SetColumnFilterCommand(colId, value));

  void clearAllFilters() =>
    dispatch(ClearAllFiltersCommand());

  void nextPage() =>
    dispatch(NextPageCommand());

  void previousPage() =>
    dispatch(PreviousPageCommand());

  void setPageIndex(int pageIndex) =>
    dispatch(SetPageIndexCommand(pageIndex));

  void setPageSize(int pageSize) =>
    dispatch(SetPageSizeCommand(pageSize));

  void toggleRowSelection(String rowId) =>
    dispatch(ToggleRowSelectionCommand(rowId));

  void toggleAllRowsSelected(bool selected) =>
    dispatch(ToggleAllRowsSelectedCommand(selected));

  void setRowExpanded(String rowId, bool expanded) =>
    dispatch(SetRowExpandedCommand(rowId, expanded));

  void toggleColumnVisibility(String colId) =>
    dispatch(ToggleColumnVisibilityCommand(colId));

  void pinColumn(String colId, ColumnPinPosition position) =>
    dispatch(PinColumnCommand(colId, position));

  void setColumnOrder(List<String> order) =>
    dispatch(SetColumnOrderCommand(order));

  void setGrouping(List<String> colIds) =>
    dispatch(SetGroupingCommand(colIds));

  void refresh() {
    _epoch++;
    _invalidateCache();
    notifyListeners();
  }

  int get currentEpoch => _epoch;

  // --- Private ---
  GridState _buildInitialState() {
    final state = GridState(
      manualSorting: options.features.whereType<SortFeature>().firstOrNull?.manual ?? false,
      manualFiltering: options.features.whereType<FilterFeature>().firstOrNull?.manual ?? false,
      manualPagination: options.features.whereType<PaginationFeature>().firstOrNull?.manual ?? false,
      pagination: PaginationState(
        pageSize: options.features.whereType<PaginationFeature>().firstOrNull?.initialPageSize ?? 10,
      ),
      enableMultiRowSelection:
        options.features.whereType<SelectionFeature>().firstOrNull?.enableMultiRowSelection ?? true,
    );
    return state;
  }

  GridState _applyCommand(GridCommand command, GridState state) {
    return switch (command) {
      SetSortCommand(:final sorting) => state.copyWith(sorting: sorting, pagination: state.pagination.copyWith(pageIndex: 0)),
      ToggleSortCommand(:final colId) => _applyToggleSort(state, colId),
      SetGlobalFilterCommand(:final value) => state.copyWith(globalFilter: value, clearGlobalFilter: value == null, pagination: state.pagination.copyWith(pageIndex: 0)),
      SetColumnFilterCommand(:final colId, :final value) => state.copyWith(columnFilters: {...state.columnFilters, colId: value}, pagination: state.pagination.copyWith(pageIndex: 0)),
      RemoveColumnFilterCommand(:final colId) => state.copyWith(columnFilters: Map.from(state.columnFilters)..remove(colId), pagination: state.pagination.copyWith(pageIndex: 0)),
      ClearAllFiltersCommand() => state.copyWith(columnFilters: {}, clearGlobalFilter: true, pagination: state.pagination.copyWith(pageIndex: 0)),
      NextPageCommand() => state.copyWith(pagination: state.pagination.copyWith(pageIndex: state.pagination.pageIndex + 1)),
      PreviousPageCommand() => state.copyWith(pagination: state.pagination.copyWith(pageIndex: (state.pagination.pageIndex - 1).clamp(0, double.maxFinite.toInt()))),
      SetPageIndexCommand(:final pageIndex) => state.copyWith(pagination: state.pagination.copyWith(pageIndex: pageIndex)),
      SetPageSizeCommand(:final pageSize) => state.copyWith(pagination: PaginationState(pageIndex: 0, pageSize: pageSize)),
      ToggleRowSelectionCommand(:final rowId) => _applyToggleRowSelection(state, rowId),
      ToggleAllRowsSelectedCommand(:final selected) => _applyToggleAllSelection(state, selected),
      ClearRowSelectionCommand() => state.copyWith(rowSelection: {}),
      SetRowExpandedCommand(:final rowId, :final expanded) => state.copyWith(expanded: {...state.expanded, rowId: expanded}),
      ToggleAllExpandedCommand(:final expanded) => _applyToggleAllExpanded(state, expanded),
      ToggleColumnVisibilityCommand(:final colId) => state.copyWith(columnVisibility: {...state.columnVisibility, colId: !(state.columnVisibility[colId] ?? true)}),
      SetColumnVisibilityCommand(:final colId, :final visible) => state.copyWith(columnVisibility: {...state.columnVisibility, colId: visible}),
      PinColumnCommand(:final colId, :final position) => _applyPinColumn(state, colId, position),
      UnpinColumnCommand(:final colId) => _applyUnpinColumn(state, colId),
      SetColumnOrderCommand(:final order) => state.copyWith(columnOrder: order),
      SetColumnSizeCommand(:final colId, :final width) => state.copyWith(columnSizing: {...state.columnSizing, colId: width}),
      SetGroupingCommand(:final colIds) => state.copyWith(grouping: colIds, pagination: state.pagination.copyWith(pageIndex: 0)),
      PinRowCommand(:final rowId, :final position) => _applyPinRow(state, rowId, position),
      UnpinRowCommand(:final rowId) => _applyUnpinRow(state, rowId),
      _ => state,
    };
  }

  GridState _applyToggleSort(GridState state, String colId) {
    final existing = state.sorting.where((s) => s.id == colId).firstOrNull;
    List<SortEntry> newSorting;
    if (existing == null) {
      // Ajouter tri asc
      newSorting = [...state.sorting, SortEntry(id: colId, desc: false)];
    } else if (!existing.desc) {
      // Passer à desc
      newSorting = state.sorting.map((s) => s.id == colId ? s.copyWith(desc: true) : s).toList();
    } else {
      // Supprimer le tri
      newSorting = state.sorting.where((s) => s.id != colId).toList();
    }
    return state.copyWith(sorting: newSorting, pagination: state.pagination.copyWith(pageIndex: 0));
  }

  GridState _applyToggleRowSelection(GridState state, String rowId) {
    final current = state.rowSelection[rowId] ?? false;
    if (!state.enableMultiRowSelection) {
      // Single select — déselectionner tout avant
      return state.copyWith(rowSelection: {rowId: !current});
    }
    return state.copyWith(rowSelection: {...state.rowSelection, rowId: !current});
  }

  GridState _applyToggleAllSelection(GridState state, bool selected) {
    if (!selected) return state.copyWith(rowSelection: {});
    final pageRows = getPageRows();
    final newSelection = Map<String, bool>.from(state.rowSelection);
    for (final row in pageRows) {
      newSelection[row.id] = true;
    }
    return state.copyWith(rowSelection: newSelection);
  }

  GridState _applyToggleAllExpanded(GridState state, bool expanded) {
    if (!expanded) return state.copyWith(expanded: {});
    final newExpanded = <String, bool>{};
    for (final row in _data) {
      final id = options.getRowId?.call(row) ?? _data.indexOf(row).toString();
      newExpanded[id] = true;
    }
    return state.copyWith(expanded: newExpanded);
  }

  GridState _applyPinColumn(GridState state, String colId, ColumnPinPosition position) {
    final pinning = state.columnPinning;
    final newLeft = position == ColumnPinPosition.left
      ? [...pinning.left.where((id) => id != colId), colId]
      : pinning.left.where((id) => id != colId).toList();
    final newRight = position == ColumnPinPosition.right
      ? [...pinning.right.where((id) => id != colId), colId]
      : pinning.right.where((id) => id != colId).toList();
    return state.copyWith(columnPinning: ColumnPinningState(left: newLeft, right: newRight));
  }

  GridState _applyUnpinColumn(GridState state, String colId) {
    return state.copyWith(
      columnPinning: ColumnPinningState(
        left: state.columnPinning.left.where((id) => id != colId).toList(),
        right: state.columnPinning.right.where((id) => id != colId).toList(),
      ),
    );
  }

  GridState _applyPinRow(GridState state, String rowId, RowPinPosition position) {
    final pinning = state.rowPinning;
    final newTop = position == RowPinPosition.top
      ? [...pinning.top.where((id) => id != rowId), rowId]
      : pinning.top.where((id) => id != rowId).toList();
    final newBottom = position == RowPinPosition.bottom
      ? [...pinning.bottom.where((id) => id != rowId), rowId]
      : pinning.bottom.where((id) => id != rowId).toList();
    return state.copyWith(rowPinning: RowPinningState(top: newTop, bottom: newBottom));
  }

  GridState _applyUnpinRow(GridState state, String rowId) {
    return state.copyWith(
      rowPinning: RowPinningState(
        top: state.rowPinning.top.where((id) => id != rowId).toList(),
        bottom: state.rowPinning.bottom.where((id) => id != rowId).toList(),
      ),
    );
  }

  RowModelSet<T> _buildRowModels() {
    // Voir section 9 — Row Model Pipeline
    final pipeline = RowModelPipeline<T>(options: options, state: _state);
    return pipeline.build(_data);
  }

  List<ColumnInfo<T>> _buildColumns() {
    // Construire l'ordre des colonnes (column order + pinning)
    // Voir implémentation dans column_info.dart
    throw UnimplementedError();
  }

  List<HeaderGroup<T>> _buildHeaderGroups(List<ColumnInfo<T>> columns) {
    throw UnimplementedError();
  }

  void _invalidateCache() {
    _cachedRowModels = null;
    _cachedColumns = null;
  }

  @override
  void dispose() {
    for (final mw in _middleware) {
      mw.dispose();
    }
    super.dispose();
  }
}
```

### 4.4 GridOptions<T>

```dart
// flutter_packages/grid_core/lib/src/controller/grid_options.dart

class GridOptions<T> {
  final List<dynamic> columns;        // List<ColumnDef<T,dynamic>> | List<ColumnDefGroup<T>>
  final List<GridFeature> features;
  final String Function(T row, int index)? getRowId;
  final List<T> Function(T row)? getSubRows;  // Pour expanding
  final void Function(GridState state)? onStateChange;  // Callback sur chaque state change
  final String? debugLabel;

  const GridOptions({
    required this.columns,
    this.features = const [],
    this.getRowId,
    this.getSubRows,
    this.onStateChange,
    this.debugLabel,
  });

  List<ColumnDef<T, dynamic>> get flatColumns {
    final result = <ColumnDef<T, dynamic>>[];
    for (final col in columns) {
      if (col is ColumnDef<T, dynamic>) {
        result.add(col);
      } else if (col is ColumnDefGroup<T>) {
        result.addAll(col.columns);
      }
    }
    return result;
  }
}
```

### 4.5 RowModel<T>

```dart
// flutter_packages/grid_core/lib/src/models/row_model.dart

class RowModel<T> {
  final String id;
  final T original;
  final int index;                    // Index dans les données filtrées/paginées courantes
  final int originalIndex;            // Index dans les données brutes
  final int depth;                    // 0 = top-level, 1+ = sous-lignes
  final List<RowModel<T>> subRows;
  final RowModel<T>? parentRow;

  // État
  final bool isSelected;
  final bool isExpanded;
  final bool isPinnedTop;
  final bool isPinnedBottom;
  final bool isGrouped;
  final bool isAggregated;

  // Grouping (si isGrouped)
  final String? groupingColumnId;
  final dynamic groupingValue;
  final int? groupedIndex;

  final GridController<T> _controller;  // Référence pour les méthodes d'action

  const RowModel._({
    required this.id,
    required this.original,
    required this.index,
    required this.originalIndex,
    required this._controller,
    this.depth = 0,
    this.subRows = const [],
    this.parentRow,
    this.isSelected = false,
    this.isExpanded = false,
    this.isPinnedTop = false,
    this.isPinnedBottom = false,
    this.isGrouped = false,
    this.isAggregated = false,
    this.groupingColumnId,
    this.groupingValue,
    this.groupedIndex,
  });

  // Actions
  void toggleSelected() => _controller.toggleRowSelection(id);
  void toggleExpanded() => _controller.setRowExpanded(id, !isExpanded);
  void pinTop() => _controller.dispatch(PinRowCommand(id, RowPinPosition.top));
  void pinBottom() => _controller.dispatch(PinRowCommand(id, RowPinPosition.bottom));
  void unpin() => _controller.dispatch(UnpinRowCommand(id));

  bool get canExpand => subRows.isNotEmpty || _controller.options.getSubRows != null;
  bool get canSelect => true;  // Override par enableRowSelection fn dans SelectionFeature

 List<CellModel<T, Object?>> getVisibleCells(
  List<ColumnInfo<T, Object?>> columns,
) {
  return columns
      .where((col) => col.isVisible)
      .map((col) {
        final value = col.def.accessorFn?.call(original);
        return CellModel<T, Object?>(
          row: this,
          column: col,
          value: value,
        );
      })
      .toList();
}
}

class CellModel<T, V> {
  final RowModel<T> row;
  final ColumnInfo<T> column;
  final V? value;
  final bool isEditing;

  const CellModel._({
    required this.row,
    required this.column,
    this.value,
    this.isEditing = false,
  });

  String get id => '${row.id}:${column.id}';

  bool get isGrouped => row.isGrouped && row.groupingColumnId == column.id;
  bool get isAggregated => row.isAggregated && column.def.aggregationFn != null;
  bool get isPlaceholder => row.isGrouped && row.groupingColumnId != column.id && !isAggregated;
}

/// Ensemble de row models produit par le pipeline
class RowModelSet<T> {
  final List<RowModel<T>> allRows;        // Toutes les lignes (après filter + sort + group)
  final List<RowModel<T>> filteredRows;   // Après filter uniquement (pour faceting)
  final List<RowModel<T>> pageRows;       // Page courante uniquement
  final List<RowModel<T>> topPinnedRows;
  final List<RowModel<T>> bottomPinnedRows;
  final int totalRows;                    // Total avant pagination (pour affichage)
  final int totalPages;

  const RowModelSet({
    required this.allRows,
    required this.filteredRows,
    required this.pageRows,
    required this.topPinnedRows,
    required this.bottomPinnedRows,
    required this.totalRows,
    required this.totalPages,
  });
}
```

---

## 5. Couche 2 — grid_flutter (Flutter bindings)

### 5.1 GridScope

```dart
// flutter_packages/grid_flutter/lib/src/scope/grid_scope.dart

/// InheritedWidget qui expose le GridController dans l'arbre de widgets.
/// Utilisé internalement par FlutterGrid et GridBuilder.
class GridScope<T> extends InheritedNotifier<GridController<T>> {
  const GridScope({
    super.key,
    required GridController<T> controller,
    required super.child,
  }) : super(notifier: controller);

  static GridController<T> of<T>(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<GridScope<T>>();
    assert(scope != null, 'No GridScope<$T> found in widget tree');
    return scope!.notifier!;
  }

  static GridController<T>? maybeOf<T>(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<GridScope<T>>()?.notifier;
  }
}
```

### 5.2 GridBuilder<T> — Headless widget

```dart
// flutter_packages/grid_flutter/lib/src/builder/grid_builder.dart

/// Widget headless — expose le controller et les row models sans UI.
/// Pour les cas où l'UI est 100% custom.
class GridBuilder<T> extends StatefulWidget {
  final GridController<T> controller;
  final GridDataSource<T>? dataSource;
  final Widget Function(BuildContext context, GridTableState<T> table) builder;

  const GridBuilder({
    super.key,
    required this.controller,
    this.dataSource,
    required this.builder,
  });

  @override
  State<GridBuilder<T>> createState() => _GridBuilderState<T>();
}

class _GridBuilderState<T> extends State<GridBuilder<T>> {
  int _fetchEpoch = 0;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onStateChange);
    if (widget.dataSource != null) _fetchData();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onStateChange);
    super.dispose();
  }

  void _onStateChange() {
    if (widget.dataSource != null) {
      _fetchData();
    }
    // Rebuild géré par ListenableBuilder
  }

  Future<void> _fetchData() async {
    final epoch = ++_fetchEpoch;
    final ctrl = widget.controller;
    ctrl.setLoading(true);

    try {
      final query = ctrl.state.toQuery();
      final page = await widget.dataSource!.fetch(query);

      if (epoch != _fetchEpoch) return;  // Epoch-based cancellation

      ctrl.setData(page.data);
      if (ctrl.state.manualPagination) {
        ctrl.setPageCount(page.totalPages ?? 1);
      }
      ctrl.setLoading(false);
    } catch (e) {
      if (epoch != _fetchEpoch) return;
      ctrl.setError(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return GridScope<T>(
      controller: widget.controller,
      child: ListenableBuilder(
        listenable: widget.controller,
        builder: (context, _) {
          final table = GridTableState<T>(controller: widget.controller);
          return widget.builder(context, table);
        },
      ),
    );
  }
}

/// Façade exposée au builder — API ergonomique
class GridTableState<T> {
  final GridController<T> controller;

  const GridTableState({required this.controller});

  GridState get state => controller.state;
  bool get isLoading => controller.isLoading;
  String? get error => controller.error;

  List<RowModel<T>> get pageRows => controller.getPageRows();
  List<RowModel<T>> get topPinnedRows => controller.getTopPinnedRows();
  List<RowModel<T>> get bottomPinnedRows => controller.getBottomPinnedRows();
  List<HeaderGroup<T>> get headerGroups => controller.getHeaderGroups();
  List<ColumnInfo<T>> get visibleColumns => controller.getVisibleColumns();
  List<ColumnInfo<T>> get leftPinnedColumns => controller.getLeftPinnedColumns();
  List<ColumnInfo<T>> get centerColumns => controller.getCenterColumns();
  List<ColumnInfo<T>> get rightPinnedColumns => controller.getRightPinnedColumns();

  int get totalRows => controller.getRowModels().totalRows;
  int get totalPages => controller.getRowModels().totalPages;
  bool get canNextPage => state.pagination.pageIndex < totalPages - 1;
  bool get canPreviousPage => state.pagination.pageIndex > 0;

  bool get hasSelection => state.hasSelection;
  int get selectedCount => state.selectedCount;
  bool get hasActiveFilters => state.hasActiveFilters;
}
```

### 5.3 Adaptive Render Strategy

```dart
// flutter_packages/grid_flutter/lib/src/rendering/adaptive_render_strategy.dart

enum RenderStrategy {
  fullRender,    // < 100 rows — Column() avec tous les widgets
  windowed,      // 100–1000 rows — ListView.builder avec buffer
  virtualized,   // > 1000 rows — VirtualizationController
}

class AdaptiveRenderStrategy {
  static const int _windowedThreshold = 100;
  static const int _virtualizedThreshold = 1000;

  static RenderStrategy resolve({
    required int totalRows,
    RenderStrategy? forced,
  }) {
    if (forced != null) return forced;
    if (totalRows < _windowedThreshold) return RenderStrategy.fullRender;
    if (totalRows < _virtualizedThreshold) return RenderStrategy.windowed;
    return RenderStrategy.virtualized;
  }
}
```

---

## 6. Couche 3 — grid_ui (Components)

### 6.1 FlutterGrid<T> — Widget principal

```dart
// flutter_packages/grid_ui/lib/src/widgets/flutter_grid.dart

/// Widget principal — drop-in complet.
/// Gère automatiquement : responsive, loading, error, empty states,
/// toolbar, pagination, et le rendu adaptatif.
class FlutterGrid<T> extends StatefulWidget {
  // --- Required ---
  final GridController<T> controller;

  // --- Data ---
  final GridDataSource<T>? dataSource;
  final Future<GridPage<T>> Function(GridQuery query)? fetchData;  // Alternative à dataSource

  // --- Layout ---
  final double breakpoint;                 // Mobile/desktop breakpoint (défaut: 900)
  final RenderStrategy? renderStrategy;    // Forcer une stratégie (défaut: auto)

  // --- Row builders ---
  /// Builder pour la vue liste (mobile). Obligatoire si breakpoint utilisé.
  final Widget Function(BuildContext context, RowModel<T> row)? rowBuilder;

  // --- Slots ---
  final GridSlots<T>? slots;

  // --- Options visuelles ---
  final bool showToolbar;
  final bool showPagination;
  final bool showFilterBar;               // Active filter chips
  final bool showLoadingOverlay;          // Overlay sur données existantes
  final bool showColumnBorders;
  final bool striped;
  final double? rowHeight;

  // --- Persistence ---
  final String? persistenceKey;           // Activer la persistence automatique

  // --- Callbacks ---
  final void Function(RowModel<T> row)? onRowTap;
  final void Function(RowModel<T> row)? onRowDoubleTap;
  final void Function(RowModel<T> row)? onRowLongPress;

  const FlutterGrid({
    super.key,
    required this.controller,
    this.dataSource,
    this.fetchData,
    this.breakpoint = 900,
    this.renderStrategy,
    this.rowBuilder,
    this.slots,
    this.showToolbar = true,
    this.showPagination = true,
    this.showFilterBar = true,
    this.showLoadingOverlay = true,
    this.showColumnBorders = false,
    this.striped = false,
    this.rowHeight,
    this.persistenceKey,
    this.onRowTap,
    this.onRowDoubleTap,
    this.onRowLongPress,
  }) : assert(
    dataSource != null || fetchData != null || controller.options.features.isEmpty,
    'Provide either dataSource or fetchData for server-side data',
  );

  @override
  State<FlutterGrid<T>> createState() => _FlutterGridState<T>();
}
```

---

## 7. Système de Commands

### 7.1 Base sealed class

```dart
// flutter_packages/grid_core/lib/src/commands/grid_command.dart

sealed class GridCommand {
  const GridCommand();

  /// Si true, la command est ajoutée à l'historique undo/redo
  bool get undoable => true;

  /// État avant la command (rempli par GridController avant dispatch)
  GridState? get prevState => null;

  GridCommand withPrevState(GridState state) => this;  // Override dans chaque subclass
}
```

### 7.2 Toutes les commands

```dart
// Sort commands
final class SetSortCommand extends GridCommand {
  final List<SortEntry> sorting;
  @override final GridState? prevState;
  const SetSortCommand(this.sorting, {this.prevState});
  @override GridCommand withPrevState(GridState s) => SetSortCommand(sorting, prevState: s);
}

final class ToggleSortCommand extends GridCommand {
  final String colId;
  @override final GridState? prevState;
  const ToggleSortCommand(this.colId, {this.prevState});
  @override GridCommand withPrevState(GridState s) => ToggleSortCommand(colId, prevState: s);
}

final class ResetSortCommand extends GridCommand {
  @override final GridState? prevState;
  const ResetSortCommand({this.prevState});
  @override GridCommand withPrevState(GridState s) => ResetSortCommand(prevState: s);
}

// Filter commands
final class SetGlobalFilterCommand extends GridCommand {
  final String? value;
  @override final GridState? prevState;
  const SetGlobalFilterCommand(this.value, {this.prevState});
  @override GridCommand withPrevState(GridState s) => SetGlobalFilterCommand(value, prevState: s);
}

final class SetColumnFilterCommand extends GridCommand {
  final String colId;
  final dynamic value;
  @override final GridState? prevState;
  const SetColumnFilterCommand(this.colId, this.value, {this.prevState});
  @override GridCommand withPrevState(GridState s) => SetColumnFilterCommand(colId, value, prevState: s);
}

final class RemoveColumnFilterCommand extends GridCommand {
  final String colId;
  @override final GridState? prevState;
  const RemoveColumnFilterCommand(this.colId, {this.prevState});
  @override GridCommand withPrevState(GridState s) => RemoveColumnFilterCommand(colId, prevState: s);
}

final class ClearAllFiltersCommand extends GridCommand {
  @override final GridState? prevState;
  const ClearAllFiltersCommand({this.prevState});
  @override GridCommand withPrevState(GridState s) => ClearAllFiltersCommand(prevState: s);
}

// Pagination commands
final class NextPageCommand extends GridCommand { @override bool get undoable => false; }
final class PreviousPageCommand extends GridCommand { @override bool get undoable => false; }
final class SetPageIndexCommand extends GridCommand {
  final int pageIndex;
  @override bool get undoable => false;
  const SetPageIndexCommand(this.pageIndex);
}
final class SetPageSizeCommand extends GridCommand {
  final int pageSize;
  @override final GridState? prevState;
  const SetPageSizeCommand(this.pageSize, {this.prevState});
  @override GridCommand withPrevState(GridState s) => SetPageSizeCommand(pageSize, prevState: s);
}

// Selection commands
final class ToggleRowSelectionCommand extends GridCommand {
  final String rowId;
  @override bool get undoable => false;
  const ToggleRowSelectionCommand(this.rowId);
}
final class ToggleAllRowsSelectedCommand extends GridCommand {
  final bool selected;
  @override bool get undoable => false;
  const ToggleAllRowsSelectedCommand(this.selected);
}
final class ClearRowSelectionCommand extends GridCommand {
  @override bool get undoable => false;
}
final class SelectAllPagesCommand extends GridCommand {
  @override bool get undoable => false;
}  // Gère la sélection cross-pages

// Row commands
final class SetRowExpandedCommand extends GridCommand {
  final String rowId;
  final bool expanded;
  @override bool get undoable => false;
  const SetRowExpandedCommand(this.rowId, this.expanded);
}
final class ToggleAllExpandedCommand extends GridCommand {
  final bool expanded;
  @override bool get undoable => false;
  const ToggleAllExpandedCommand(this.expanded);
}
final class PinRowCommand extends GridCommand {
  final String rowId;
  final RowPinPosition position;
  @override final GridState? prevState;
  const PinRowCommand(this.rowId, this.position, {this.prevState});
  @override GridCommand withPrevState(GridState s) => PinRowCommand(rowId, position, prevState: s);
}
final class UnpinRowCommand extends GridCommand {
  final String rowId;
  @override final GridState? prevState;
  const UnpinRowCommand(this.rowId, {this.prevState});
  @override GridCommand withPrevState(GridState s) => UnpinRowCommand(rowId, prevState: s);
}

// Column commands
final class ToggleColumnVisibilityCommand extends GridCommand {
  final String colId;
  @override final GridState? prevState;
  const ToggleColumnVisibilityCommand(this.colId, {this.prevState});
  @override GridCommand withPrevState(GridState s) => ToggleColumnVisibilityCommand(colId, prevState: s);
}
final class SetColumnVisibilityCommand extends GridCommand {
  final String colId;
  final bool visible;
  @override final GridState? prevState;
  const SetColumnVisibilityCommand(this.colId, this.visible, {this.prevState});
  @override GridCommand withPrevState(GridState s) => SetColumnVisibilityCommand(colId, visible, prevState: s);
}
final class PinColumnCommand extends GridCommand {
  final String colId;
  final ColumnPinPosition position;
  @override final GridState? prevState;
  const PinColumnCommand(this.colId, this.position, {this.prevState});
  @override GridCommand withPrevState(GridState s) => PinColumnCommand(colId, position, prevState: s);
}
final class UnpinColumnCommand extends GridCommand {
  final String colId;
  @override final GridState? prevState;
  const UnpinColumnCommand(this.colId, {this.prevState});
  @override GridCommand withPrevState(GridState s) => UnpinColumnCommand(colId, prevState: s);
}
final class SetColumnOrderCommand extends GridCommand {
  final List<String> order;
  @override final GridState? prevState;
  const SetColumnOrderCommand(this.order, {this.prevState});
  @override GridCommand withPrevState(GridState s) => SetColumnOrderCommand(order, prevState: s);
}
final class SetColumnSizeCommand extends GridCommand {
  final String colId;
  final double width;
  @override bool get undoable => false;
  const SetColumnSizeCommand(this.colId, this.width);
}
final class ResetColumnSizingCommand extends GridCommand {
  @override final GridState? prevState;
  const ResetColumnSizingCommand({this.prevState});
  @override GridCommand withPrevState(GridState s) => ResetColumnSizingCommand(prevState: s);
}

// Grouping
final class SetGroupingCommand extends GridCommand {
  final List<String> colIds;
  @override final GridState? prevState;
  const SetGroupingCommand(this.colIds, {this.prevState});
  @override GridCommand withPrevState(GridState s) => SetGroupingCommand(colIds, prevState: s);
}

// Editing
final class StartEditingCellCommand extends GridCommand {
  final String cellId;
  @override bool get undoable => false;
  const StartEditingCellCommand(this.cellId);
}
final class CommitEditCommand extends GridCommand {
  final String cellId;
  final dynamic newValue;
  @override final GridState? prevState;
  const CommitEditCommand(this.cellId, this.newValue, {this.prevState});
  @override GridCommand withPrevState(GridState s) => CommitEditCommand(cellId, newValue, prevState: s);
}
final class CancelEditCommand extends GridCommand {
  @override bool get undoable => false;
}

enum ColumnPinPosition { left, right }
enum RowPinPosition { top, bottom }
```

---

## 8. Middleware Chain

```dart
// flutter_packages/grid_core/lib/src/middleware/grid_middleware.dart

abstract class GridMiddleware {
  /// Appelé avant que la command soit appliquée.
  /// Retourner null = bloquer la command.
  /// Retourner une autre command = la remplacer.
  GridCommand? beforeDispatch(GridCommand command, GridState currentState) => command;

  /// Appelé après que le state a changé.
  void afterDispatch(GridCommand command, GridState prevState, GridState nextState) {}

  void dispose() {}
}

// --- Logging Middleware ---
class LoggingMiddleware extends GridMiddleware {
  final bool enabled;
  final void Function(String log)? logger;

  LoggingMiddleware({this.enabled = true, this.logger});

  @override
  void afterDispatch(GridCommand command, GridState prev, GridState next) {
    if (!enabled) return;
    final msg = '[GridLog] ${command.runtimeType} | '
        'page: ${prev.pagination.pageIndex} → ${next.pagination.pageIndex} | '
        'sort: ${next.sortString ?? "none"} | '
        'filters: ${next.columnFilters.length} active';
    if (logger != null) {
      logger!(msg);
    } else {
      assert(() { debugPrint(msg); return true; }());
    }
  }
}

// --- Analytics Middleware ---
class AnalyticsMiddleware extends GridMiddleware {
  final void Function(String event, Map<String, dynamic> params) track;

  AnalyticsMiddleware({required this.track});

  @override
  void afterDispatch(GridCommand command, GridState prev, GridState next) {
    switch (command) {
      case SetGlobalFilterCommand(:final value) when value != null && value.isNotEmpty:
        track('grid_searched', {'query': value});
      case SetColumnFilterCommand(:final colId):
        track('grid_filtered', {'column': colId});
      case SetSortCommand(:final sorting) when sorting.isNotEmpty:
        track('grid_sorted', {'column': sorting.first.id, 'desc': sorting.first.desc});
      default:
        break;
    }
  }
}
```

### 8.1 Persistence Middleware (grid_flutter)

```dart
// flutter_packages/grid_flutter/lib/src/middleware/persistence_middleware.dart

class PersistenceMiddleware extends GridMiddleware {
  final String key;
  final SharedPreferences? _prefs;  // Lazy-loaded

  PersistenceMiddleware({required this.key});

  static const _persistedCommands = {
    SetSortCommand,
    SetColumnFilterCommand,
    RemoveColumnFilterCommand,
    ClearAllFiltersCommand,
    SetPageSizeCommand,
    SetColumnVisibilityCommand,
    ToggleColumnVisibilityCommand,
    PinColumnCommand,
    UnpinColumnCommand,
    SetColumnOrderCommand,
    SetColumnSizeCommand,
    ResetColumnSizingCommand,
  };

  @override
  void afterDispatch(GridCommand command, GridState prev, GridState next) {
    if (!_persistedCommands.contains(command.runtimeType)) return;
    _save(next);
  }

  Future<void> _save(GridState state) async {
    final prefs = await SharedPreferences.getInstance();
    final data = jsonEncode({
      'sorting': state.sorting.map((s) => {'id': s.id, 'desc': s.desc}).toList(),
      'columnFilters': state.columnFilters,
      'columnVisibility': state.columnVisibility,
      'columnOrder': state.columnOrder,
      'columnSizing': state.columnSizing,
      'columnPinning': {
        'left': state.columnPinning.left,
        'right': state.columnPinning.right,
      },
      'pageSize': state.pagination.pageSize,
    });
    await prefs.setString('flutter_grid_$key', data);
  }

  /// Charger l'état persisté — appeler dans GridController initialState
  static Future<GridState?> load(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('flutter_grid_$key');
    if (raw == null) return null;

    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      return GridState(
        sorting: (data['sorting'] as List? ?? [])
          .map((s) => SortEntry(id: s['id'], desc: s['desc'] ?? false))
          .toList(),
        columnFilters: Map<String, dynamic>.from(data['columnFilters'] ?? {}),
        columnVisibility: Map<String, bool>.from(data['columnVisibility'] ?? {}),
        columnOrder: List<String>.from(data['columnOrder'] ?? []),
        columnSizing: Map<String, double>.from(
          (data['columnSizing'] ?? {}).map((k, v) => MapEntry(k, (v as num).toDouble()))
        ),
        columnPinning: ColumnPinningState(
          left: List<String>.from(data['columnPinning']?['left'] ?? []),
          right: List<String>.from(data['columnPinning']?['right'] ?? []),
        ),
        pagination: PaginationState(pageSize: data['pageSize'] ?? 10),
      );
    } catch (_) {
      await prefs.remove('flutter_grid_$key');
      return null;
    }
  }

  static Future<void> clear(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('flutter_grid_$key');
  }
}
```

---

## 9. Row Model Pipeline

```dart
// flutter_packages/grid_core/lib/src/pipeline/

/// Le pipeline applique les transformations dans cet ordre EXACT :
/// 1. Filter (column filters + global filter)
/// 2. Sort
/// 3. Group
/// 4. Expand (sub-rows)
/// 5. Paginate
///
/// En mode manual*, l'étape correspondante est skippée.

class RowModelPipeline<T> {
  final GridOptions<T> options;
  final GridState state;

  const RowModelPipeline({required this.options, required this.state});

  RowModelSet<T> build(List<T> rawData) {
    final columns = options.flatColumns;

    // Étape 1 : Filter
    var rows = state.manualFiltering
      ? rawData
      : _applyFilters(rawData, columns);

    final filteredRows = _toRowModels(rows, columns, depth: 0);

    // Étape 2 : Sort
    if (!state.manualSorting) {
      rows = _applySort(rows, columns);
    }

    // Étape 3 : Group
    List<RowModel<T>> processedRows;
    if (state.grouping.isEmpty) {
      processedRows = _toRowModels(rows, columns, depth: 0);
    } else {
      processedRows = _applyGrouping(rows, columns);
    }

    // Étape 4 : Expand (sous-lignes)
    if (options.getSubRows != null) {
      processedRows = _applyExpanding(processedRows);
    }

    // Étape 5 : Row Pinning (séparer avant pagination)
    final topPinned = processedRows.where((r) => r.isPinnedTop).toList();
    final bottomPinned = processedRows.where((r) => r.isPinnedBottom).toList();
    final centerRows = processedRows.where((r) => !r.isPinnedTop && !r.isPinnedBottom).toList();

    // Étape 6 : Paginate
    final totalRows = centerRows.length;
    final pageSize = state.pagination.pageSize;
    final totalPages = state.manualPagination
      ? (state.pageCount ?? 1)
      : (totalRows / pageSize).ceil().clamp(1, double.maxFinite.toInt());

    List<RowModel<T>> pageRows;
    if (state.manualPagination) {
      pageRows = centerRows;  // Données déjà paginées par l'API
    } else {
      final start = (state.pagination.pageIndex * pageSize).clamp(0, totalRows);
      final end = (start + pageSize).clamp(0, totalRows);
      pageRows = centerRows.sublist(start, end);
    }

    return RowModelSet(
      allRows: processedRows,
      filteredRows: filteredRows,
      pageRows: pageRows,
      topPinnedRows: topPinned,
      bottomPinnedRows: bottomPinned,
      totalRows: totalRows,
      totalPages: totalPages,
    );
  }

  List<T> _applyFilters(List<T> data, List<ColumnDef<T, dynamic>> columns) {
    var result = data;

    // Column filters
    for (final entry in state.columnFilters.entries) {
      if (entry.value == null) continue;
      final col = columns.where((c) => c.id == entry.key).firstOrNull;
      if (col == null || !col.enableFiltering || col.accessorFn == null) continue;

      final filterFn = col.filterFn ?? FilterFunctions.autoDetect(col.columnType);
      result = result.where((row) {
        final value = col.accessorFn!(row);
        return filterFn(value, entry.value);
      }).toList();
    }

    // Global filter
    if (state.globalFilter != null && state.globalFilter!.isNotEmpty) {
      final query = state.globalFilter!.toLowerCase();
      result = result.where((row) {
        return columns.where((c) => c.enableGlobalFilter && c.accessorFn != null).any((col) {
          final value = col.accessorFn!(row);
          if (value == null) return false;
          return value.toString().toLowerCase().contains(query);
        });
      }).toList();
    }

    return result;
  }

  List<T> _applySort(List<T> data, List<ColumnDef<T, dynamic>> columns) {
    if (state.sorting.isEmpty) return data;

    return [...data]..sort((a, b) {
      for (final sortEntry in state.sorting) {
        final col = columns.where((c) => c.id == sortEntry.id).firstOrNull;
        if (col?.accessorFn == null) continue;

        final valA = col!.accessorFn!(a);
        final valB = col.accessorFn!(b);
        final sortFn = col.sortingFn ?? SortFunctions.autoDetect(col.columnType);

        final result = sortFn(valA, valB);
        if (result != 0) return sortEntry.desc ? -result : result;
      }
      return 0;
    });
  }

  List<RowModel<T>> _applyGrouping(List<T> data, List<ColumnDef<T, dynamic>> columns) {
    if (state.grouping.isEmpty) return _toRowModels(data, columns, depth: 0);

    final groupColId = state.grouping.first;
    final groupCol = columns.where((c) => c.id == groupColId).firstOrNull;
    if (groupCol?.accessorFn == null) return _toRowModels(data, columns, depth: 0);

    // Grouper les données
    final groups = <dynamic, List<T>>{};
    for (final row in data) {
      final key = groupCol!.getGroupingValue?.call(row) ?? groupCol.accessorFn!(row);
      groups[key] = [...(groups[key] ?? []), row];
    }

    // Construire les row models groupés
    final result = <RowModel<T>>[];
    var idx = 0;
    for (final entry in groups.entries) {
      // Ligne de groupe (agrégation)
      final groupRow = RowModel<T>._(
        id: 'group:$groupColId:${entry.key}',
        original: entry.value.first,  // représentant du groupe
        index: idx++,
        originalIndex: -1,
        _controller: null!,
        isGrouped: true,
        groupingColumnId: groupColId,
        groupingValue: entry.key,
        subRows: _toRowModels(entry.value, columns, depth: 1),
        isExpanded: state.expanded['group:$groupColId:${entry.key}'] ?? false,
      );
      result.add(groupRow);

      // Ajouter les sous-lignes si le groupe est expanded
      if (groupRow.isExpanded) {
        result.addAll(groupRow.subRows);
      }
    }

    return result;
  }

  List<RowModel<T>> _applyExpanding(List<RowModel<T>> rows) {
    final result = <RowModel<T>>[];
    for (final row in rows) {
      result.add(row);
      if (row.isExpanded && row.canExpand) {
        final subRows = options.getSubRows?.call(row.original) ?? [];
        result.addAll(_toRowModels(subRows, options.flatColumns, depth: row.depth + 1));
      }
    }
    return result;
  }

  List<RowModel<T>> _toRowModels(List<T> data, List<ColumnDef<T, dynamic>> columns, {required int depth}) {
    return data.asMap().entries.map((entry) {
      final id = options.getRowId?.call(entry.value, entry.key) ?? entry.key.toString();
      return RowModel<T>._(
        id: id,
        original: entry.value,
        index: entry.key,
        originalIndex: entry.key,
        depth: depth,
        isSelected: state.rowSelection[id] ?? false,
        isExpanded: state.expanded[id] ?? false,
        isPinnedTop: state.rowPinning.top.contains(id),
        isPinnedBottom: state.rowPinning.bottom.contains(id),
        _controller: null!,  // Sera assigné par GridController
      );
    }).toList();
  }
}
```

---

## 10. Feature Modules — Spécification complète

### 10.1 Base interface

```dart
abstract class GridFeature {
  String get featureId;
  bool get manual => false;

  /// Initialisation — appelée une fois à la création du controller
  void init(GridController controller) {}

  /// Dispose
  void dispose() {}
}
```

### 10.2 SortFeature

```dart
class SortFeature extends GridFeature {
  @override String get featureId => 'sort';
  @override final bool manual;
  final bool enableMultiSort;          // Défaut: true
  final int maxMultiSortColCount;      // Défaut: 3
  final bool isMultiSortEvent;         // Défaut: Shift+click

  const SortFeature({
    this.manual = false,
    this.enableMultiSort = true,
    this.maxMultiSortColCount = 3,
    this.isMultiSortEvent = true,
  });
}
```

### 10.3 FilterFeature

```dart
class FilterFeature extends GridFeature {
  @override String get featureId => 'filter';
  @override final bool manual;
  final bool enableColumnFilters;
  final bool enableGlobalFilter;
  final bool enableFaceting;           // Calculer unique values + min/max
  final Duration? filterDebounce;      // Défaut: null (pas de debounce dans le core)
  final bool autoRemoveEmptyFilters;   // Défaut: true

  const FilterFeature({
    this.manual = false,
    this.enableColumnFilters = true,
    this.enableGlobalFilter = true,
    this.enableFaceting = true,
    this.filterDebounce,
    this.autoRemoveEmptyFilters = true,
  });
}
```

### 10.4 PaginationFeature

```dart
class PaginationFeature extends GridFeature {
  @override String get featureId => 'pagination';
  @override final bool manual;
  final int initialPageSize;
  final List<int> pageSizeOptions;
  final PaginationMode mode;

  const PaginationFeature({
    this.manual = false,
    this.initialPageSize = 10,
    this.pageSizeOptions = const [5, 10, 20, 50, 100],
    this.mode = PaginationMode.paged,
  });
}

enum PaginationMode {
  paged,     // Navigation par pages
  infinite,  // Infinite scroll / load more
}
```

### 10.5 SelectionFeature

```dart
class SelectionFeature extends GridFeature {
  @override String get featureId => 'selection';
  final bool enableMultiRowSelection;
  final bool enableSubRowSelection;    // Sélectionner aussi les sous-lignes
  final bool selectAllPages;           // Permettre "select all N items" cross-pages
  final bool Function(RowModel row)? enableRowSelection;  // Sélection conditionnelle

  const SelectionFeature({
    this.enableMultiRowSelection = true,
    this.enableSubRowSelection = false,
    this.selectAllPages = false,
    this.enableRowSelection,
  });
}
```

### 10.6 GroupingFeature

```dart
class GroupingFeature extends GridFeature {
  @override String get featureId => 'grouping';
  @override final bool manual;
  final GroupedColumnMode groupedColumnMode;
  final bool enableGrouping;

  const GroupingFeature({
    this.manual = false,
    this.groupedColumnMode = GroupedColumnMode.reorder,
    this.enableGrouping = true,
  });
}

enum GroupedColumnMode {
  reorder,   // Colonne groupée déplacée en tête
  remove,    // Colonne groupée retirée du tableau
  none,      // Colonne reste en place
}
```

### 10.7 ExpandingFeature

```dart
class ExpandingFeature extends GridFeature {
  @override String get featureId => 'expanding';
  @override final bool manual;
  final bool paginateExpandedRows;     // true = sous-lignes paginées avec les autres
  final bool expandOnRowClick;         // false par défaut
  final int autoExpandDepth;           // -1 = tout, 0 = rien, 1 = premier niveau

  const ExpandingFeature({
    this.manual = false,
    this.paginateExpandedRows = true,
    this.expandOnRowClick = false,
    this.autoExpandDepth = 0,
  });
}
```

### 10.8 ColumnPinningFeature

```dart
class ColumnPinningFeature extends GridFeature {
  @override String get featureId => 'columnPinning';

  const ColumnPinningFeature();
}
```

### 10.9 RowPinningFeature

```dart
class RowPinningFeature extends GridFeature {
  @override String get featureId => 'rowPinning';
  final bool keepPinnedRows;           // true = lignes pinnées toujours visibles même si filtrées

  const RowPinningFeature({this.keepPinnedRows = true});
}
```

### 10.10 ColumnSizingFeature

```dart
class ColumnSizingFeature extends GridFeature {
  @override String get featureId => 'columnSizing';
  final ColumnResizeMode resizeMode;
  final double defaultColumnSize;
  final double defaultMinSize;
  final double? defaultMaxSize;

  const ColumnSizingFeature({
    this.resizeMode = ColumnResizeMode.onChange,
    this.defaultColumnSize = 150,
    this.defaultMinSize = 40,
    this.defaultMaxSize,
  });
}

enum ColumnResizeMode {
  onChange,    // Resize live pendant le drag
  onEnd,       // Resize seulement au relâchement
}
```

### 10.11 RowDndFeature

```dart
class RowDndFeature extends GridFeature {
  @override String get featureId => 'rowDnd';
  final void Function(int oldIndex, int newIndex) onRowOrderChange;

  const RowDndFeature({required this.onRowOrderChange});
}
```

---

## 11. Cell Renderer Registry

```dart
// flutter_packages/grid_ui/lib/src/cells/cell_renderer_registry.dart

abstract class CellRenderer<V> {
  const CellRenderer();

  /// Type(s) de colonnes pour lesquels ce renderer est utilisé par défaut
  Set<ColumnType> get supportedTypes;

  Widget render(CellContext<dynamic, V> ctx);
  Widget renderSkeleton(ColumnDef def);  // Shape du skeleton
}

/// Registre global des renderers
class CellRendererRegistry {
  static final _instance = CellRendererRegistry._();
  static CellRendererRegistry get instance => _instance;

  final _renderers = <ColumnType, CellRenderer>{};

  CellRendererRegistry._() {
    // Enregistrer les renderers built-in
    register(TextCellRenderer());
    register(NumberCellRenderer());
    register(MoneyCellRenderer());
    register(DateCellRenderer());
    register(DatetimeCellRenderer());
    register(BooleanCellRenderer());
    register(BadgeCellRenderer());
    register(AvatarNameCellRenderer());
    register(ProgressCellRenderer());
    register(LinkCellRenderer());
  }

  void register(CellRenderer renderer) {
    for (final type in renderer.supportedTypes) {
      _renderers[type] = renderer;
    }
  }

  CellRenderer? getFor(ColumnType type) => _renderers[type];

  Widget renderCell(CellContext ctx) {
    final renderer = getFor(ctx.column.def.columnType);
    return renderer?.render(ctx) ?? TextCellRenderer().render(ctx);
  }

  Widget renderSkeleton(ColumnDef def) {
    final renderer = getFor(def.columnType);
    return renderer?.renderSkeleton(def) ?? _defaultSkeletonBar();
  }

  Widget _defaultSkeletonBar() => SkeletonBar(width: 120, height: 14);
}
```

### 11.1 Built-in renderers

```dart
// Chaque renderer doit implémenter render() et renderSkeleton()

class TextCellRenderer extends CellRenderer<String?> {
  @override Set<ColumnType> get supportedTypes => {ColumnType.text};

  @override
  Widget render(CellContext ctx) {
    final value = ctx.value as String?;
    final globalFilter = ctx.controller.state.globalFilter;
    if (value == null) return const SizedBox.shrink();
    // Highlight si global filter actif
    if (globalFilter != null && globalFilter.isNotEmpty) {
      return HighlightText(text: value, highlight: globalFilter);
    }
    return Text(value, overflow: TextOverflow.ellipsis);
  }

  @override Widget renderSkeleton(ColumnDef def) => SkeletonBar(width: 120, height: 14);
}

class NumberCellRenderer extends CellRenderer<num?> {
  @override Set<ColumnType> get supportedTypes => {ColumnType.number};

  @override
  Widget render(CellContext ctx) {
    final value = ctx.value as num?;
    if (value == null) return const SizedBox.shrink();
    return Text(
      value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 2),
      textAlign: TextAlign.right,
    );
  }

  @override Widget renderSkeleton(ColumnDef def) => SkeletonBar(width: 60, height: 14, alignment: Alignment.centerRight);
}

class MoneyCellRenderer extends CellRenderer<num?> {
  @override Set<ColumnType> get supportedTypes => {ColumnType.money};

  @override
  Widget render(CellContext ctx) {
    final value = ctx.value as num?;
    if (value == null) return const SizedBox.shrink();
    // Utiliser Intl.NumberFormat si disponible, sinon format basique
    final formatted = _formatMoney(value, ctx);
    return Text(formatted, textAlign: TextAlign.right, style: const TextStyle(fontFamily: 'monospace'));
  }

  String _formatMoney(num value, CellContext ctx) {
    // Lire le locale et currency depuis le contexte si disponible
    return value.toStringAsFixed(2);
  }

  @override Widget renderSkeleton(ColumnDef def) => SkeletonBar(width: 80, height: 14, alignment: Alignment.centerRight);
}

class DateCellRenderer extends CellRenderer<DateTime?> {
  @override Set<ColumnType> get supportedTypes => {ColumnType.date};

  @override
  Widget render(CellContext ctx) {
    final value = ctx.value as DateTime?;
    if (value == null) return const SizedBox.shrink();
    return Text('${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}');
  }

  @override Widget renderSkeleton(ColumnDef def) => SkeletonBar(width: 90, height: 14);
}

class BooleanCellRenderer extends CellRenderer<bool?> {
  @override Set<ColumnType> get supportedTypes => {ColumnType.boolean};

  @override
  Widget render(CellContext ctx) {
    final value = ctx.value as bool?;
    if (value == null) return const SizedBox.shrink();
    return Icon(
      value ? Icons.check_circle_outline : Icons.cancel_outlined,
      size: 18,
      color: value ? Colors.green.shade600 : Colors.grey.shade400,
    );
  }

  @override Widget renderSkeleton(ColumnDef def) => const SkeletonCircle(size: 18);
}

class BadgeCellRenderer extends CellRenderer<String?> {
  final Map<String, BadgeConfig>? config;
  const BadgeCellRenderer({this.config});

  @override Set<ColumnType> get supportedTypes => {ColumnType.badge};

  @override
  Widget render(CellContext ctx) {
    final value = ctx.value as String?;
    if (value == null) return const SizedBox.shrink();
    final badgeCfg = config?[value];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: badgeCfg?.backgroundColor ?? Colors.grey.shade100,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: badgeCfg?.borderColor ?? Colors.grey.shade300),
      ),
      child: Text(
        badgeCfg?.label ?? value,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: badgeCfg?.textColor ?? Colors.grey.shade700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  @override Widget renderSkeleton(ColumnDef def) => SkeletonBadge();
}

class AvatarNameCellRenderer extends CellRenderer<dynamic> {
  @override Set<ColumnType> get supportedTypes => {ColumnType.avatar};

  @override
  Widget render(CellContext ctx) {
    // Attend soit String (nom) soit { name: String, avatarUrl: String? }
    final value = ctx.value;
    String name;
    String? avatarUrl;
    if (value is String) {
      name = value;
    } else if (value is Map) {
      name = value['name'] as String? ?? '';
      avatarUrl = value['avatarUrl'] as String?;
    } else {
      return const SizedBox.shrink();
    }

    final initials = _initials(name);
    final seed = name.hashCode;

    return Row(
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: _colorFromSeed(seed),
          backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
          child: avatarUrl == null ? Text(initials, style: const TextStyle(fontSize: 10, color: Colors.white)) : null,
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(name, overflow: TextOverflow.ellipsis)),
      ],
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  Color _colorFromSeed(int seed) {
    final colors = [Colors.blue, Colors.purple, Colors.teal, Colors.orange, Colors.pink];
    return colors[seed.abs() % colors.length].shade400;
  }

  @override Widget renderSkeleton(ColumnDef def) => SkeletonAvatarRow();
}

class ProgressCellRenderer extends CellRenderer<double?> {
  @override Set<ColumnType> get supportedTypes => {ColumnType.progress};

  @override
  Widget render(CellContext ctx) {
    final value = (ctx.value as num?)?.toDouble() ?? 0.0;
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(value: value.clamp(0.0, 1.0), minHeight: 6),
          ),
        ),
        const SizedBox(width: 8),
        Text('${(value * 100).toStringAsFixed(0)}%', style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  @override Widget renderSkeleton(ColumnDef def) => SkeletonBar(width: double.infinity, height: 6);
}

class LinkCellRenderer extends CellRenderer<String?> {
  @override Set<ColumnType> get supportedTypes => {ColumnType.link};

  @override
  Widget render(CellContext ctx) {
    final value = ctx.value as String?;
    if (value == null) return const SizedBox.shrink();
    return GestureDetector(
      onTap: () => _launchUrl(value),
      child: Text(
        value,
        style: TextStyle(color: Theme.of(ctx.buildContext).colorScheme.primary, decoration: TextDecoration.underline),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  void _launchUrl(String url) {
    // Utiliser url_launcher si disponible
  }

  @override Widget renderSkeleton(ColumnDef def) => SkeletonBar(width: 100, height: 14);
}
```

---

## 12. Slot System — UI Composition

```dart
// flutter_packages/grid_ui/lib/src/slots/grid_slots.dart

/// Configuration de tous les slots remplaçables du tableau.
/// Chaque slot est nullable — si null, le composant par défaut est utilisé.
class GridSlots<T> {
  /// Barre supérieure : recherche, filtres, actions, column chooser
  final Widget Function(BuildContext context, GridTableState<T> table)? toolbar;

  /// Header des colonnes (toute la ligne)
  final Widget Function(BuildContext context, HeaderGroup<T> group)? headerRow;

  /// Header d'une colonne individuelle
  final Widget Function(BuildContext context, ColumnInfo<T> column)? headerCell;

  /// Une ligne de données
  final Widget Function(BuildContext context, RowModel<T> row)? dataRow;

  /// Footer d'agrégation
  final Widget Function(BuildContext context, GridTableState<T> table)? aggregationFooter;

  /// Barre de pagination
  final Widget Function(BuildContext context, GridTableState<T> table)? pagination;

  /// État vide (aucune donnée)
  final Widget Function(BuildContext context, GridEmptyContext ctx)? emptyState;

  /// État chargement initial
  final Widget Function(BuildContext context)? loadingState;

  /// État erreur
  final Widget Function(BuildContext context, String error, VoidCallback retry)? errorState;

  /// Overlay de chargement (sur données existantes)
  final Widget Function(BuildContext context)? loadingOverlay;

  /// Barre d'actions bulk (sélection active)
  final Widget Function(BuildContext context, GridTableState<T> table)? bulkActionBar;

  /// Row detail / expanded panel
  final Widget Function(BuildContext context, RowModel<T> row)? rowDetail;

  const GridSlots({
    this.toolbar,
    this.headerRow,
    this.headerCell,
    this.dataRow,
    this.aggregationFooter,
    this.pagination,
    this.emptyState,
    this.loadingState,
    this.errorState,
    this.loadingOverlay,
    this.bulkActionBar,
    this.rowDetail,
  });
}

/// Contexte passé au slot emptyState pour distinguer les cas
class GridEmptyContext {
  final EmptyReason reason;
  final VoidCallback? onClearFilters;

  const GridEmptyContext({required this.reason, this.onClearFilters});
}

enum EmptyReason {
  noData,       // Aucune donnée du tout
  filtered,     // Filtre actif masque tout
  searched,     // Recherche globale sans résultats
  error,        // Erreur réseau (doublon avec errorState, mais cohérence)
}
```

---

## 13. GridDataSource — Data abstraction

```dart
// flutter_packages/grid_core/lib/src/data_source/grid_data_source.dart

abstract class GridDataSource<T> {
  /// Fetch une page de données (REST, Dio, etc.)
  Future<GridPage<T>> fetch(GridQuery query);

  /// Stream de données realtime (Supabase, Firebase, WebSocket)
  /// Retourne null si non supporté
  Stream<GridPage<T>>? watch(GridQuery query) => null;

  /// Mutations (optionnelles)
  Future<void> insert(T item) => throw UnimplementedError();
  Future<void> update(String id, Map<String, dynamic> patch) => throw UnimplementedError();
  Future<void> delete(String id) => throw UnimplementedError();
}

class GridPage<T> {
  final List<T> data;
  final int? totalItems;
  final int? totalPages;
  final int currentPage;
  final int pageSize;
  final String? nextCursor;

  const GridPage({
    required this.data,
    this.totalItems,
    this.totalPages,
    required this.currentPage,
    required this.pageSize,
    this.nextCursor,
  });
}

class GridQuery {
  final int pageIndex;     // 0-based
  final int pageSize;
  final List<SortEntry> sorting;
  final Map<String, dynamic> columnFilters;
  final String? globalFilter;
  final List<String> grouping;

  const GridQuery({
    required this.pageIndex,
    required this.pageSize,
    this.sorting = const [],
    this.columnFilters = const {},
    this.globalFilter,
    this.grouping = const [],
  });

  factory GridQuery.fromState(GridState state) => GridQuery(
    pageIndex: state.pagination.pageIndex,
    pageSize: state.pagination.pageSize,
    sorting: state.sorting,
    columnFilters: state.columnFilters,
    globalFilter: state.globalFilter,
    grouping: state.grouping,
  );

  /// Compatibilité avec PaginationParams de ChairWatch
  Map<String, dynamic> toQueryParameters() => {
    'page': pageIndex + 1,
    'limit': pageSize,
    if (sorting.isNotEmpty) 'sort': sorting.map((s) => s.desc ? '-${s.id}' : s.id).join(','),
    ...columnFilters.map((k, v) => MapEntry('filter[$k]', v)),
    if (globalFilter != null) 'search': globalFilter,
  };
}
```

### 13.1 RestDataSource

```dart
// flutter_packages/grid_flutter/lib/src/data_sources/rest_data_source.dart

class RestDataSource<T> extends GridDataSource<T> {
  final Dio dio;
  final String endpoint;
  final T Function(Map<String, dynamic>) fromJson;
  final Map<String, dynamic> Function(GridQuery)? queryBuilder;

  RestDataSource({
    required this.dio,
    required this.endpoint,
    required this.fromJson,
    this.queryBuilder,
  });

  @override
  Future<GridPage<T>> fetch(GridQuery query) async {
    final params = queryBuilder?.call(query) ?? query.toQueryParameters();

    final response = await dio.get(endpoint, queryParameters: params);
    final data = (response.data as List).map((e) => fromJson(e)).toList();

    return GridPage(
      data: data,
      totalItems: _parseHeader(response.headers, 'x-pagination-total-items'),
      totalPages: _parseHeader(response.headers, 'x-pagination-total-pages'),
      currentPage: _parseHeader(response.headers, 'x-pagination-current-page') ?? 1,
      pageSize: query.pageSize,
    );
  }

  int? _parseHeader(Headers headers, String key) {
    return int.tryParse(headers.value(key) ?? '');
  }
}
```

### 13.2 StreamDataSource

```dart
// flutter_packages/grid_flutter/lib/src/data_sources/stream_data_source.dart

class StreamDataSource<T> extends GridDataSource<T> {
  final Stream<List<T>> Function(GridQuery query) streamBuilder;

  StreamDataSource({required this.streamBuilder});

  @override
  Future<GridPage<T>> fetch(GridQuery query) async {
    final data = await streamBuilder(query).first;
    return GridPage(data: data, currentPage: 1, pageSize: data.length);
  }

  @override
  Stream<GridPage<T>> watch(GridQuery query) {
    return streamBuilder(query).map((data) =>
      GridPage(data: data, currentPage: 1, pageSize: data.length));
  }
}
```

---

## 14. GridTheme — Theming system

```dart
// flutter_packages/grid_ui/lib/src/theme/grid_theme.dart

class GridTheme extends InheritedWidget {
  final GridThemeData data;

  const GridTheme({super.key, required this.data, required super.child});

  static GridThemeData of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<GridTheme>()?.data
        ?? GridThemeData.fromTheme(Theme.of(context));
  }

  @override
  bool updateShouldNotify(GridTheme oldWidget) => data != oldWidget.data;
}

class GridThemeData {
  // --- Row ---
  final double rowHeight;
  final Color? rowColor;
  final Color? alternatingRowColor;           // Pour striped
  final Color? selectedRowColor;
  final Color? hoveredRowColor;
  final Color? pinnedRowBackgroundColor;

  // --- Header ---
  final double headerHeight;
  final TextStyle? headerTextStyle;
  final Color? headerBackgroundColor;
  final Color? headerSortIconColor;
  final Color? pinnedColumnShadowColor;

  // --- Cell ---
  final EdgeInsets cellPadding;
  final TextStyle? cellTextStyle;
  final double? cellBorderWidth;
  final Color? cellBorderColor;

  // --- Pagination ---
  final TextStyle? paginationTextStyle;
  final Color? paginationButtonColor;

  // --- Skeleton ---
  final Color? skeletonBaseColor;
  final Color? skeletonHighlightColor;

  // --- Misc ---
  final BorderRadius rowBorderRadius;
  final BorderRadius tableBorderRadius;
  final Color? tableBorderColor;

  const GridThemeData({
    this.rowHeight = 52,
    this.rowColor,
    this.alternatingRowColor,
    this.selectedRowColor,
    this.hoveredRowColor,
    this.pinnedRowBackgroundColor,
    this.headerHeight = 48,
    this.headerTextStyle,
    this.headerBackgroundColor,
    this.headerSortIconColor,
    this.pinnedColumnShadowColor,
    this.cellPadding = const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    this.cellTextStyle,
    this.cellBorderWidth,
    this.cellBorderColor,
    this.paginationTextStyle,
    this.paginationButtonColor,
    this.skeletonBaseColor,
    this.skeletonHighlightColor,
    this.rowBorderRadius = BorderRadius.zero,
    this.tableBorderRadius = const BorderRadius.all(Radius.circular(8)),
    this.tableBorderColor,
  });

  factory GridThemeData.fromTheme(ThemeData theme) => GridThemeData(
    rowColor: theme.colorScheme.surface,
    alternatingRowColor: theme.colorScheme.surfaceContainerLowest,
    selectedRowColor: theme.colorScheme.primaryContainer.withOpacity(0.3),
    hoveredRowColor: theme.colorScheme.onSurface.withOpacity(0.04),
    headerBackgroundColor: theme.colorScheme.surfaceContainerLow,
    headerTextStyle: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
    cellTextStyle: theme.textTheme.bodyMedium,
    tableBorderColor: theme.colorScheme.outlineVariant,
    skeletonBaseColor: theme.colorScheme.surfaceContainerHighest,
    skeletonHighlightColor: theme.colorScheme.surface,
    pinnedColumnShadowColor: theme.colorScheme.shadow.withOpacity(0.1),
    pinnedRowBackgroundColor: theme.colorScheme.surfaceContainerHighest,
  );

  GridThemeData copyWith({/* tous les champs */ }) => GridThemeData(/* ... */);
}
```

---

## 15. UX Patterns — Implémentation

### 15.1 Smart Empty State

```dart
// flutter_packages/grid_ui/lib/src/slots/grid_empty_state.dart

class GridEmptyState extends StatelessWidget {
  final GridEmptyContext ctx;

  const GridEmptyState({super.key, required this.ctx});

  @override
  Widget build(BuildContext context) {
    return switch (ctx.reason) {
      EmptyReason.noData => _NoDataEmpty(context),
      EmptyReason.filtered => _FilteredEmpty(context, ctx.onClearFilters),
      EmptyReason.searched => _SearchedEmpty(context, ctx.onClearFilters),
      EmptyReason.error => const SizedBox.shrink(),
    };
  }

  Widget _NoDataEmpty(BuildContext context) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.inbox_outlined, size: 48, color: Theme.of(context).colorScheme.outline),
        const SizedBox(height: 12),
        Text('No data yet', style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        )),
      ],
    ),
  );

  Widget _FilteredEmpty(BuildContext context, VoidCallback? onClear) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.filter_list_off, size: 48, color: Theme.of(context).colorScheme.outline),
        const SizedBox(height: 12),
        Text('No results for current filters', style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        )),
        if (onClear != null) ...[
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onClear,
            icon: const Icon(Icons.clear, size: 16),
            label: const Text('Clear filters'),
          ),
        ],
      ],
    ),
  );

  Widget _SearchedEmpty(BuildContext context, VoidCallback? onClear) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.search_off, size: 48, color: Theme.of(context).colorScheme.outline),
        const SizedBox(height: 12),
        Text('No results for your search', style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        )),
        if (onClear != null) ...[
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onClear,
            icon: const Icon(Icons.clear, size: 16),
            label: const Text('Clear search'),
          ),
        ],
      ],
    ),
  );
}
```

### 15.2 Skeleton Loader (column-aware)

```dart
// flutter_packages/grid_ui/lib/src/skeleton/skeleton_row.dart

/// Génère N lignes skeleton dont les cellules correspondent
/// aux types de colonnes définies.
class GridSkeletonLoader extends StatelessWidget {
  final List<ColumnDef> columns;
  final int rowCount;
  final double rowHeight;

  const GridSkeletonLoader({
    super.key,
    required this.columns,
    this.rowCount = 8,
    this.rowHeight = 52,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(rowCount, (i) =>
        _SkeletonRow(columns: columns, height: rowHeight, opacity: 1.0 - (i * 0.08).clamp(0, 0.5)),
      ),
    );
  }
}

class _SkeletonRow extends StatelessWidget {
  final List<ColumnDef> columns;
  final double height;
  final double opacity;

  const _SkeletonRow({required this.columns, required this.height, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5))),
        ),
        child: Row(
          children: columns.map((col) => Expanded(
            flex: _flex(col),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: CellRendererRegistry.instance.renderSkeleton(col),
            ),
          )).toList(),
        ),
      ),
    );
  }

  int _flex(ColumnDef col) => col.size != null ? 1 : 1;
}

/// Shimmer animation wrapper
class SkeletonBar extends StatefulWidget {
  final double width;
  final double height;
  final Alignment alignment;

  const SkeletonBar({
    super.key,
    required this.width,
    required this.height,
    this.alignment = Alignment.centerLeft,
  });

  @override
  State<SkeletonBar> createState() => _SkeletonBarState();
}

class _SkeletonBarState extends State<SkeletonBar> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat();
    _animation = Tween<double>(begin: -1, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final theme = GridTheme.of(context);
    return Align(
      alignment: widget.alignment,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, _) => Container(
          width: widget.width == double.infinity ? null : widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                theme.skeletonBaseColor ?? Colors.grey.shade200,
                theme.skeletonHighlightColor ?? Colors.grey.shade100,
                theme.skeletonBaseColor ?? Colors.grey.shade200,
              ],
              stops: [
                (_animation.value - 0.3).clamp(0, 1),
                _animation.value.clamp(0, 1),
                (_animation.value + 0.3).clamp(0, 1),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SkeletonBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SkeletonBar(width: 60, height: 20);
  }
}

class SkeletonCircle extends StatelessWidget {
  final double size;
  const SkeletonCircle({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    final theme = GridTheme.of(context);
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: theme.skeletonBaseColor ?? Colors.grey.shade200,
      ),
    );
  }
}

class SkeletonAvatarRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SkeletonCircle(size: 28),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [SkeletonBar(width: 90, height: 12), const SizedBox(height: 4), SkeletonBar(width: 60, height: 10)],
        ),
      ],
    );
  }
}
```

### 15.3 Active Filter Chips

```dart
// flutter_packages/grid_ui/lib/src/components/grid_filter_bar.dart

class GridFilterBar<T> extends StatelessWidget {
  final GridController<T> controller;
  final Map<String, String Function(dynamic)>? labelBuilders;  // { colId: (value) → label }

  const GridFilterBar({super.key, required this.controller, this.labelBuilders});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final state = controller.state;
        if (!state.hasActiveFilters) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Wrap(
            spacing: 6,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // Global filter chip
              if (state.globalFilter != null && state.globalFilter!.isNotEmpty)
                _FilterChip(
                  label: '"${state.globalFilter}"',
                  icon: Icons.search,
                  onRemove: () => controller.setGlobalFilter(null),
                ),

              // Column filter chips
              ...state.columnFilters.entries.where((e) => e.value != null).map((entry) {
                final label = labelBuilders?[entry.key]?.call(entry.value)
                    ?? '${entry.key}: ${entry.value}';
                return _FilterChip(
                  label: label,
                  onRemove: () => controller.dispatch(RemoveColumnFilterCommand(entry.key)),
                );
              }),

              // Clear all (si 2+ filtres)
              if (state.columnFilters.length + (state.globalFilter != null ? 1 : 0) >= 2)
                TextButton(
                  onPressed: () => controller.clearAllFilters(),
                  child: const Text('Clear all', style: TextStyle(fontSize: 12)),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onRemove;

  const _FilterChip({required this.label, this.icon, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 8, right: 4, top: 4, bottom: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 14), const SizedBox(width: 4)],
          Text(label, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: Icon(Icons.close, size: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
```

### 15.4 Bulk Action Bar

```dart
// flutter_packages/grid_ui/lib/src/components/grid_bulk_action_bar.dart

class GridBulkActionBar<T> extends StatelessWidget {
  final GridController<T> controller;
  final List<BulkAction<T>> actions;
  final bool showSelectAllPages;       // true si manualPagination + selectAllPages dans SelectionFeature

  const GridBulkActionBar({
    super.key,
    required this.controller,
    required this.actions,
    this.showSelectAllPages = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        if (!controller.state.hasSelection) return const SizedBox.shrink();

        final count = controller.state.selectedCount;
        final selectedIds = controller.state.rowSelection.entries
          .where((e) => e.value)
          .map((e) => e.key)
          .toList();

        return AnimatedSlide(
          offset: const Offset(0, 0),
          duration: const Duration(milliseconds: 200),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Row(
              children: [
                Text(
                  '$count selected',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
                if (showSelectAllPages) ...[
                  const SizedBox(width: 12),
                  TextButton(
                    onPressed: () => controller.dispatch(SelectAllPagesCommand()),
                    child: const Text('Select all pages'),
                  ),
                ],
                const Spacer(),
                ...actions.map((action) => Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: OutlinedButton.icon(
                    onPressed: () => action.onPressed(selectedIds),
                    icon: Icon(action.icon, size: 16),
                    label: Text(action.label),
                    style: action.destructive
                      ? OutlinedButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error)
                      : null,
                  ),
                )),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () => controller.dispatch(ClearRowSelectionCommand()),
                  tooltip: 'Deselect all',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class BulkAction<T> {
  final String label;
  final IconData icon;
  final void Function(List<String> selectedIds) onPressed;
  final bool destructive;

  const BulkAction({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.destructive = false,
  });
}
```

### 15.5 Swipe Row Actions (Mobile)

```dart
// flutter_packages/grid_ui/lib/src/components/swipe_row_actions.dart

class SwipeRowActions<T> extends StatelessWidget {
  final RowModel<T> row;
  final Widget child;
  final List<SwipeAction<T>>? leftActions;
  final List<SwipeAction<T>>? rightActions;

  const SwipeRowActions({
    super.key,
    required this.row,
    required this.child,
    this.leftActions,
    this.rightActions,
  });

  @override
  Widget build(BuildContext context) {
    if ((leftActions == null || leftActions!.isEmpty) &&
        (rightActions == null || rightActions!.isEmpty)) {
      return child;
    }

    return Dismissible(
      key: Key('swipe_${row.id}'),
      direction: _resolveDirection(),
      confirmDismiss: (direction) async {
        // Exécuter l'action mais ne pas dismisser automatiquement
        final actions = direction == DismissDirection.startToEnd ? leftActions : rightActions;
        if (actions?.isNotEmpty == true) {
          await actions!.first.onPressed(row);
          HapticFeedback.lightImpact();
        }
        return false;  // Toujours false — pas de dismiss auto
      },
      background: _buildActionBackground(leftActions, Alignment.centerLeft),
      secondaryBackground: _buildActionBackground(rightActions, Alignment.centerRight),
      child: child,
    );
  }

  DismissDirection _resolveDirection() {
    if (leftActions != null && rightActions != null) return DismissDirection.horizontal;
    if (leftActions != null) return DismissDirection.startToEnd;
    return DismissDirection.endToStart;
  }

  Widget _buildActionBackground(List<SwipeAction<T>>? actions, Alignment align) {
    if (actions == null || actions.isEmpty) return const SizedBox.shrink();
    final action = actions.first;
    return Container(
      alignment: align,
      color: action.backgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(action.icon, color: Colors.white),
          const SizedBox(height: 4),
          Text(action.label, style: const TextStyle(color: Colors.white, fontSize: 11)),
        ],
      ),
    );
  }
}

class SwipeAction<T> {
  final String label;
  final IconData icon;
  final Color backgroundColor;
  final Future<void> Function(RowModel<T> row) onPressed;

  const SwipeAction({
    required this.label,
    required this.icon,
    required this.backgroundColor,
    required this.onPressed,
  });

  /// Factory helpers courants
  factory SwipeAction.delete({required Future<void> Function(RowModel<T>) onPressed}) =>
    SwipeAction(label: 'Delete', icon: Icons.delete_outline, backgroundColor: Colors.red.shade600, onPressed: onPressed);

  factory SwipeAction.archive({required Future<void> Function(RowModel<T>) onPressed}) =>
    SwipeAction(label: 'Archive', icon: Icons.archive_outlined, backgroundColor: Colors.orange.shade600, onPressed: onPressed);
}
```

### 15.6 Search Highlight

```dart
// flutter_packages/grid_ui/lib/src/cells/highlight_text.dart

class HighlightText extends StatelessWidget {
  final String text;
  final String highlight;
  final TextStyle? defaultStyle;
  final TextStyle? highlightStyle;

  const HighlightText({
    super.key,
    required this.text,
    required this.highlight,
    this.defaultStyle,
    this.highlightStyle,
  });

  @override
  Widget build(BuildContext context) {
    if (highlight.isEmpty) return Text(text, style: defaultStyle, overflow: TextOverflow.ellipsis);

    final lowerText = text.toLowerCase();
    final lowerHighlight = highlight.toLowerCase();
    final spans = <TextSpan>[];
    int start = 0;

    while (true) {
      final index = lowerText.indexOf(lowerHighlight, start);
      if (index == -1) {
        spans.add(TextSpan(text: text.substring(start)));
        break;
      }
      if (index > start) spans.add(TextSpan(text: text.substring(start, index)));
      spans.add(TextSpan(
        text: text.substring(index, index + highlight.length),
        style: highlightStyle ?? TextStyle(
          backgroundColor: Theme.of(context).colorScheme.tertiaryContainer,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onTertiaryContainer,
        ),
      ));
      start = index + highlight.length;
    }

    return RichText(
      overflow: TextOverflow.ellipsis,
      text: TextSpan(style: defaultStyle ?? DefaultTextStyle.of(context).style, children: spans),
    );
  }
}
```

---

## 16. Adaptive Rendering Strategy

```dart
// flutter_packages/grid_flutter/lib/src/rendering/adaptive_render_strategy.dart

class AdaptiveGridRenderer<T> extends StatelessWidget {
  final GridController<T> controller;
  final GridSlots<T> slots;
  final GridThemeData theme;
  final double breakpoint;
  final RenderStrategy? forcedStrategy;

  const AdaptiveGridRenderer({
    super.key,
    required this.controller,
    required this.slots,
    required this.theme,
    required this.breakpoint,
    this.forcedStrategy,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isSmall = width < breakpoint;

    if (isSmall && slots.dataRow != null) {
      // Mobile list view
      return _MobileListRenderer(controller: controller, slots: slots);
    }

    // Desktop table view — choisir la stratégie
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final totalRows = controller.getRowModels().totalRows;
        final strategy = forcedStrategy ?? AdaptiveRenderStrategy.resolve(totalRows: totalRows);

        return switch (strategy) {
          RenderStrategy.fullRender => _FullRenderTable(controller: controller, slots: slots, theme: theme),
          RenderStrategy.windowed => _WindowedTable(controller: controller, slots: slots, theme: theme),
          RenderStrategy.virtualized => _VirtualizedTable(controller: controller, slots: slots, theme: theme),
        };
      },
    );
  }
}
```

---

## 17. Persistence Middleware

Voir section 8.1 — `PersistenceMiddleware`.

Usage :
```dart
// Charger l'état au démarrage
final savedState = await PersistenceMiddleware.load('home_screen_appointments');

final controller = GridController<Appointment>(
  options: GridOptions(...),
  initialState: savedState,  // null = state par défaut
  middleware: [
    PersistenceMiddleware(key: 'home_screen_appointments'),
    LoggingMiddleware(enabled: kDebugMode),
  ],
);
```

---

## 18. Migration depuis AppPaginatedTable

### 18.1 Guide de migration

`AppPaginatedTable` actuel → `FlutterGrid` en 4 étapes.

**Étape 1 : Wrapper de compatibilité**

```dart
// Adapter pour utiliser fetchItems signature existante
class AppPaginatedTableAdapter<T> extends GridDataSource<T> {
  final Future<PaginatedResponse<T>> Function(PagePaginationParams, String?) fetchItems;

  AppPaginatedTableAdapter({required this.fetchItems});

  @override
  Future<GridPage<T>> fetch(GridQuery query) async {
    final response = await fetchItems(
      PagePaginationParams(page: query.pageIndex + 1, limit: query.pageSize, sort: query.sortString),
      query.globalFilter,
    );
    return GridPage(
      data: response.data,
      totalItems: response.meta.totalItems,
      totalPages: response.meta.totalPages,
      currentPage: response.meta.currentPage,
      pageSize: response.meta.itemsPerPage,
    );
  }
}
```

**Étape 2 : Remplacer la déclaration**

```dart
// AVANT
late PaginatedTableController<LoyaltyProgramModel> _tableController;

// APRÈS
late GridController<LoyaltyProgramModel> _tableController;
```

**Étape 3 : Remplacer le widget**

```dart
// AVANT
AppPaginatedTable<LoyaltyProgramModel>(
  controller: _tableController,
  fetchItems: (params, search) async { ... },
  columns: [ DataColumn2(...), ... ],
  buildRows: (context, item) => [ ... ],
  smallViewItemBuilder: (context, item) => LoyaltyProgramTile(...),
)

// APRÈS
FlutterGrid<LoyaltyProgramModel>(
  controller: _tableController,
  dataSource: AppPaginatedTableAdapter(fetchItems: (params, search) async { ... }),
  rowBuilder: (context, row) => LoyaltyProgramTile(
    loyaltyProgram: row.original,
    onTap: () => _openItemDetails(row.original),
  ),
  slots: GridSlots(
    // Colonnes définies via GridOptions dans le controller
  ),
)
```

**Étape 4 : Migrer les colonnes**

```dart
// AVANT (DataColumn2)
DataColumn2(
  label: Text('Program', style: ...),
  size: ColumnSize.L,
  onSort: (columnIndex, ascending) { ... },
)

// APRÈS (ColumnDef)
ColumnDef.accessor(
  id: 'name',
  header: 'Program',
  accessorFn: (program) => program.name,
  columnType: ColumnType.text,
  enableSorting: true,
)
```

### 18.2 Tableau de correspondance API

| AppPaginatedTable | FlutterGrid |
|---|---|
| `PaginatedTableController.refresh()` | `GridController.refresh()` |
| `PaginatedTableController.nextPage()` | `GridController.nextPage()` |
| `PaginatedTableController.previousPage()` | `GridController.previousPage()` |
| `PaginatedTableController.changeRowsPerPage(n)` | `GridController.setPageSize(n)` |
| `PaginatedTableController.toggleSort(field)` | `GridController.toggleSort(colId)` |
| `PaginatedTableController.resetToFirstPage()` | `GridController.setPageIndex(0)` |
| `fetchItems` callback | `GridDataSource.fetch()` |
| `buildRows` callback | `ColumnDef.cell` |
| `smallViewItemBuilder` | `FlutterGrid.rowBuilder` |
| `showLoadingOverlay` | `FlutterGrid.showLoadingOverlay` |
| `breakpoint` | `FlutterGrid.breakpoint` |

---

## 19. Tests — Stratégie complète

### 19.1 Tests unitaires (grid_core)

```dart
// test/controller/grid_controller_test.dart

void main() {
  group('GridController — Sorting', () {
    late GridController<Map<String, dynamic>> ctrl;

    setUp(() {
      ctrl = GridController(
        options: GridOptions(
          columns: [
            ColumnDef.accessor(id: 'name', accessorFn: (r) => r['name'] as String),
            ColumnDef.accessor(id: 'age', accessorFn: (r) => r['age'] as int, columnType: ColumnType.number),
          ],
          features: [SortFeature()],
        ),
      );
      ctrl.setData([
        {'name': 'Zara', 'age': 25},
        {'name': 'Alice', 'age': 30},
        {'name': 'Bob', 'age': 20},
      ]);
    });

    test('single column sort ascending', () {
      ctrl.setSort([SortEntry(id: 'name')]);
      final rows = ctrl.getPageRows();
      expect(rows[0].original['name'], 'Alice');
      expect(rows[1].original['name'], 'Bob');
      expect(rows[2].original['name'], 'Zara');
    });

    test('toggleSort cycles asc → desc → none', () {
      ctrl.toggleSort('name');
      expect(ctrl.state.sorting, [SortEntry(id: 'name', desc: false)]);

      ctrl.toggleSort('name');
      expect(ctrl.state.sorting, [SortEntry(id: 'name', desc: true)]);

      ctrl.toggleSort('name');
      expect(ctrl.state.sorting, isEmpty);
    });

    test('command history records sort command', () {
      ctrl.setSort([SortEntry(id: 'name')]);
      expect(ctrl.commandHistory.last, isA<SetSortCommand>());
    });

    test('undo sort', () {
      ctrl.setSort([SortEntry(id: 'name')]);
      ctrl.undo();
      expect(ctrl.state.sorting, isEmpty);
    });
  });

  group('GridController — Filtering', () {
    // ... tests de filter, global filter, faceting
  });

  group('GridController — Pagination', () {
    // ... tests de pagination client-side et manual
  });

  group('GridController — Selection', () {
    // ... tests de sélection, select-all, cross-pages
  });

  group('Row Model Pipeline', () {
    test('filter → sort → paginate order', () {
      // Vérifier que le pipeline applique les étapes dans le bon ordre
    });

    test('manual pagination skip paginate stage', () {
      // Vérifier que les données ne sont pas re-paginées en mode manual
    });
  });

  group('Middleware', () {
    test('LoggingMiddleware calls logger on dispatch', () {
      final logs = <String>[];
      final ctrl = GridController(
        options: GridOptions(columns: []),
        middleware: [LoggingMiddleware(logger: logs.add)],
      );
      ctrl.dispatch(SetGlobalFilterCommand('test'));
      expect(logs, isNotEmpty);
    });

    test('Middleware can block command (return null)', () {
      // ...
    });
  });
}
```

### 19.2 Widget tests (grid_ui)

```dart
// Tester les composants UI avec testWidgets
// FlutterGrid en mode mémoire
// Smart empty states
// Filter chips apparaissent/disparaissent
// Bulk action bar toggle
// Skeleton loader column shapes
```

### 19.3 Integration tests

```dart
// Test de bout en bout avec un MockDataSource
// Navigation pages, sort, filter, sélection multi
// Persistence: save → hot restart → restauration
```

---

## 20. Phases de développement

### Phase 1 — Core MVP (~4 semaines)

**Objectif** : Remplacer `AppPaginatedTable` dans au moins 1 screen ChairWatch.

**Deliverables :**
- [ ] `grid_core` : `ColumnDef`, `GridState`, `GridController`, `GridCommand` (sealed), Row model pipeline (filter + sort + paginate)
- [ ] `grid_core` : `SortFeature`, `FilterFeature` (global uniquement), `PaginationFeature` (manual + client-side)
- [ ] `grid_core` : `SortFunctions`, `FilterFunctions` (includesString, equals)
- [ ] `grid_core` : `GridDataSource` interface + `RestDataSource`
- [ ] `grid_flutter` : `GridScope`, `GridBuilder`
- [ ] `grid_flutter` : `AdaptiveRenderStrategy` (full + windowed)
- [ ] `grid_ui` : `FlutterGrid` (table desktop + list mobile)
- [ ] `grid_ui` : `GridTheme` + `GridThemeData.fromTheme()`
- [ ] `grid_ui` : `GridEmptyState` (3 cas), `GridSkeletonLoader` (column-aware), `GridPagination`
- [ ] `grid_ui` : `TextCellRenderer`, `NumberCellRenderer`, `BadgeCellRenderer`, `AvatarNameCellRenderer`
- [ ] `grid_ui` : `GridFilterBar` (active chips), `HighlightText`
- [ ] `grid_ui` : `ColumnVisibilityFeature` + `GridColumnChooser`
- [ ] Migration guide + `AppPaginatedTableAdapter`
- [ ] Tests unitaires core (>80% coverage)

### Phase 2 — Filtering & Selection (~3 semaines)

- [ ] Column filtering (filterFn par colonne)
- [ ] Column faceting (unique values + min/max)
- [ ] `SelectionFeature` + `GridBulkActionBar`
- [ ] `ColumnOrderingFeature` (drag-to-reorder headers)
- [ ] `SwipeRowActions` (mobile)
- [ ] `PersistenceMiddleware` + `LoggingMiddleware`
- [ ] Restants : `DateCellRenderer`, `BooleanCellRenderer`, `ProgressCellRenderer`, `LinkCellRenderer`
- [ ] `MoneyCellRenderer` avec Intl
- [ ] Keyboard navigation (desktop/web : Arrow + Enter + Escape)

### Phase 3 — Advanced Data (~4 semaines)

- [ ] `GroupingFeature` + `AggregationFunctions`
- [ ] `ExpandingFeature` (sub-rows + detail panels)
- [ ] `RowPinningFeature` (sticky top/bottom)
- [ ] `ColumnPinningFeature` (sticky left/right + shadow)
- [ ] `GridBulkActionBar` — select all pages (cross-pagination)
- [ ] Aggregation footer row
- [ ] Server-side grouping (manual mode)
- [ ] `StreamDataSource` (realtime)
- [ ] Optimistic updates pattern + rollback

### Phase 4 — Performance & UX (~3 semaines)

- [ ] `VirtualizationFeature` (row virtualization avec variable heights)
- [ ] Column virtualization (très larges tableaux)
- [ ] `ColumnSizingFeature` + drag handles
- [ ] `RowDndFeature` (drag-to-reorder)
- [ ] Infinite scroll mode (`PaginationMode.infinite`)
- [ ] Inline editing (`enableEditing` + `editCell` builder)
- [ ] Isolate computation pour sort/filter sur très grands datasets
- [ ] Long-press context menu (mobile)

### Phase 5 — Polish & Publish (~2 semaines)

- [ ] Accessibility (`Semantics` wrappers sur toutes les actions)
- [ ] Animation row insert/delete (`AnimatedList`)
- [ ] `grid_export` package (CSV + copie clipboard)
- [ ] Haptic feedback (`HapticFeedback.lightImpact()` sur selection)
- [ ] Example app complet (couvrant toutes les features)
- [ ] README + API docs (dartdoc)
- [ ] CHANGELOG
- [ ] pub.dev publication

---

## 21. pubspec.yaml — Dépendances

### grid_core/pubspec.yaml

```yaml
name: grid_core
description: Pure Dart core for flutter_grid — headless table logic
version: 0.1.0
environment:
  sdk: '>=3.3.0 <4.0.0'

dependencies: {}  # AUCUNE dépendance externe

dev_dependencies:
  test: ^1.25.0
  lints: ^4.0.0
```

### grid_flutter/pubspec.yaml

```yaml
name: grid_flutter
description: Flutter bindings for grid_core
version: 0.1.0
environment:
  sdk: '>=3.3.0 <4.0.0'
  flutter: '>=3.19.0'

dependencies:
  flutter:
    sdk: flutter
  grid_core:
    path: ../grid_core
  dio: ^5.4.0
  shared_preferences: ^2.2.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  lints: ^4.0.0
```

### grid_ui/pubspec.yaml

```yaml
name: grid_ui
description: Pre-built UI components for flutter_grid
version: 0.1.0
environment:
  sdk: '>=3.3.0 <4.0.0'
  flutter: '>=3.19.0'

dependencies:
  flutter:
    sdk: flutter
  grid_core:
    path: ../grid_core
  grid_flutter:
    path: ../grid_flutter

dev_dependencies:
  flutter_test:
    sdk: flutter
  lints: ^4.0.0
```

### flutter_grid/pubspec.yaml (meta-package)

```yaml
name: flutter_grid
description: Full-featured data table library for Flutter — TanStack Table-inspired
version: 0.1.0
homepage: https://github.com/yourorg/flutter_grid
environment:
  sdk: '>=3.3.0 <4.0.0'
  flutter: '>=3.19.0'

dependencies:
  flutter:
    sdk: flutter
  grid_core:
    path: ../grid_core
  grid_flutter:
    path: ../grid_flutter
  grid_ui:
    path: ../grid_ui
```

---

## Annexe A — Filter Functions

```dart
// flutter_packages/grid_core/lib/src/functions/filter_functions.dart

typedef FilterFn<V> = bool Function(V? cellValue, dynamic filterValue);

class FilterFunctions {
  /// Auto-détecter la fonction de filtre selon le type de colonne
  static FilterFn autoDetect(ColumnType type) => switch (type) {
    ColumnType.number || ColumnType.money => inNumberRange,
    ColumnType.date || ColumnType.datetime => inDateRange,
    ColumnType.boolean => equals,
    ColumnType.badge => equalsString,
    _ => includesString,
  };

  /// Contient (case-insensitive)
  static bool includesString(dynamic cellValue, dynamic filterValue) {
    if (cellValue == null) return false;
    return cellValue.toString().toLowerCase().contains(filterValue.toString().toLowerCase());
  }

  /// Égalité exacte (case-insensitive pour strings)
  static bool equalsString(dynamic cellValue, dynamic filterValue) {
    if (cellValue == null) return filterValue == null;
    return cellValue.toString().toLowerCase() == filterValue.toString().toLowerCase();
  }

  /// Égalité stricte
  static bool equals(dynamic cellValue, dynamic filterValue) => cellValue == filterValue;

  /// Range numérique — filterValue = [min, max] ou null pour illimité
  static bool inNumberRange(dynamic cellValue, dynamic filterValue) {
    if (cellValue == null) return false;
    if (filterValue is! List || filterValue.length < 2) return true;
    final num val = (cellValue as num);
    final min = filterValue[0] as num?;
    final max = filterValue[1] as num?;
    if (min != null && val < min) return false;
    if (max != null && val > max) return false;
    return true;
  }

  /// Range de dates — filterValue = [DateTime? start, DateTime? end]
  static bool inDateRange(dynamic cellValue, dynamic filterValue) {
    if (cellValue == null) return false;
    if (filterValue is! List || filterValue.length < 2) return true;
    final date = cellValue as DateTime;
    final start = filterValue[0] as DateTime?;
    final end = filterValue[1] as DateTime?;
    if (start != null && date.isBefore(start)) return false;
    if (end != null && date.isAfter(end)) return false;
    return true;
  }

  /// La valeur est dans une liste
  static bool arrIncludes(dynamic cellValue, dynamic filterValue) {
    if (filterValue is! List) return equals(cellValue, filterValue);
    return filterValue.contains(cellValue);
  }

  /// Commence par
  static bool startsWith(dynamic cellValue, dynamic filterValue) {
    if (cellValue == null) return false;
    return cellValue.toString().toLowerCase().startsWith(filterValue.toString().toLowerCase());
  }
}
```

## Annexe B — Sort Functions

```dart
// flutter_packages/grid_core/lib/src/functions/sort_functions.dart

typedef SortFn<V> = int Function(V? a, V? b);

class SortFunctions {
  static SortFn autoDetect(ColumnType type) => switch (type) {
    ColumnType.number || ColumnType.money || ColumnType.progress => numeric,
    ColumnType.date || ColumnType.datetime => datetime,
    ColumnType.boolean => basic,
    _ => alphanumeric,
  };

  /// Tri alphanumérique (handles "file10" > "file9" correctement)
  static int alphanumeric(dynamic a, dynamic b) {
    if (a == null && b == null) return 0;
    if (a == null) return 1;
    if (b == null) return -1;
    final strA = a.toString();
    final strB = b.toString();
    // Comparaison naturelle pour mixed alphanumeric
    return strA.compareTo(strB);
  }

  /// Tri numérique
  static int numeric(dynamic a, dynamic b) {
    if (a == null && b == null) return 0;
    if (a == null) return 1;
    if (b == null) return -1;
    return (a as num).compareTo(b as num);
  }

  /// Tri par DateTime
  static int datetime(dynamic a, dynamic b) {
    if (a == null && b == null) return 0;
    if (a == null) return 1;
    if (b == null) return -1;
    return (a as DateTime).compareTo(b as DateTime);
  }

  /// Tri basique (utilise Comparable)
  static int basic(dynamic a, dynamic b) {
    if (a == null && b == null) return 0;
    if (a == null) return 1;
    if (b == null) return -1;
    if (a is Comparable) return a.compareTo(b);
    return a.toString().compareTo(b.toString());
  }
}
```

## Annexe C — Aggregation Functions

```dart
// flutter_packages/grid_core/lib/src/functions/aggregation_functions.dart

typedef AggregationFn<V> = V? Function(List<RowModel> leafRows, List<RowModel> childRows);

class AggregationFunctions {
  static num? sum(List<RowModel> leafRows, List<RowModel> _) {
    num total = 0;
    for (final row in leafRows) { /* accéder à la valeur via context */ }
    return total;
  }

  static int count(List<RowModel> leafRows, List<RowModel> _) => leafRows.length;

  static num? min(List<RowModel> leafRows, List<RowModel> _) {
    num? min;
    for (final row in leafRows) { /* ... */ }
    return min;
  }

  static num? max(List<RowModel> leafRows, List<RowModel> _) {
    num? max;
    for (final row in leafRows) { /* ... */ }
    return max;
  }

  static num? mean(List<RowModel> leafRows, List<RowModel> _) {
    if (leafRows.isEmpty) return null;
    final s = sum(leafRows, _);
    return s != null ? s / leafRows.length : null;
  }

  static int uniqueCount(List<RowModel> leafRows, List<RowModel> _) {
    final values = <dynamic>{};
    for (final row in leafRows) { /* ... */ }
    return values.length;
  }
}
```

---

*Document généré le 04/05/2026 — Version 1.0*  
*Maintenu par l'équipe flutter_grid*  
*Pour toute question sur les choix d'architecture, se référer à la section 1.2 — Principes directeurs*
