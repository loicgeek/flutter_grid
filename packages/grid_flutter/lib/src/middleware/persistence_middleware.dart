import 'dart:convert';

import 'package:grid_core/grid_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists and restores [GridState] fields using [SharedPreferences].
class PersistenceMiddleware extends GridMiddleware {
  final String storageKey;
  final bool persistSorting;
  final bool persistFilters;
  final bool persistColumnVisibility;
  final bool persistPageSize;
  final bool persistColumnOrder;

  SharedPreferences? _prefs;

  PersistenceMiddleware({
    required this.storageKey,
    this.persistSorting = true,
    this.persistFilters = false,
    this.persistColumnVisibility = true,
    this.persistPageSize = true,
    this.persistColumnOrder = true,
  });

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Restores persisted state into the given [GridState].
  GridState restore(GridState state) {
    final prefs = _prefs;
    if (prefs == null) return state;

    final raw = prefs.getString(storageKey);
    if (raw == null) return state;

    try {
      final map = json.decode(raw) as Map<String, dynamic>;

      List<SortEntry> sorting = state.sorting;
      if (persistSorting && map['sorting'] is List) {
        sorting = (map['sorting'] as List)
            .whereType<Map<String, dynamic>>()
            .map((s) => SortEntry(
                  columnId: s['columnId'] as String,
                  descending: s['descending'] as bool,
                ))
            .toList();
      }

      Map<String, bool> columnVisibility = state.columnVisibility;
      if (persistColumnVisibility && map['columnVisibility'] is Map) {
        columnVisibility = Map<String, bool>.from(
            (map['columnVisibility'] as Map).cast<String, dynamic>().map(
                  (k, v) => MapEntry(k, v as bool),
                ));
      }

      PaginationState pagination = state.pagination;
      if (persistPageSize && map['pageSize'] is int) {
        pagination = PaginationState(pageSize: map['pageSize'] as int);
      }

      List<String> columnOrder = state.columnOrder;
      if (persistColumnOrder && map['columnOrder'] is List) {
        columnOrder = List<String>.from(map['columnOrder'] as List);
      }

      return state.copyWith(
        sorting: sorting,
        columnVisibility: columnVisibility,
        pagination: pagination,
        columnOrder: columnOrder,
      );
    } catch (_) {
      return state;
    }
  }

  @override
  void afterDispatch(
      GridCommand command, GridState prevState, GridState nextState) {
    _save(nextState);
  }

  void _save(GridState state) {
    final prefs = _prefs;
    if (prefs == null) return;

    final map = <String, dynamic>{};

    if (persistSorting) {
      map['sorting'] = state.sorting
          .map((s) => {'columnId': s.columnId, 'descending': s.descending})
          .toList();
    }
    if (persistColumnVisibility) {
      map['columnVisibility'] = state.columnVisibility;
    }
    if (persistPageSize) {
      map['pageSize'] = state.pagination.pageSize;
    }
    if (persistColumnOrder) {
      map['columnOrder'] = state.columnOrder;
    }

    prefs.setString(storageKey, json.encode(map));
  }
}
