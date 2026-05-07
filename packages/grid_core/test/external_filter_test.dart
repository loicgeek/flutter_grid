// ignore_for_file: prefer_const_constructors

import 'package:grid_core/grid_core.dart';
import 'package:test/test.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

GridController<String> _makeController({
  GridState? initialState,
}) {
  final c = GridController<String>(
    options: GridOptions(
      columns: [
        ColumnDef<String, String>.accessor(
          id: 'val',
          accessorFn: (s) => s,
          header: 'Value',
        ),
      ],
      features: [PaginationFeature()],
    ),
    initialState: initialState ??
        const GridState(
          pagination: PaginationState(pageSize: 5),
        ),
  );
  c.setData(['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j']);
  return c;
}

// ─────────────────────────────────────────────────────────────────────────────
// ExternalFilter — named constructors & operator field
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  group('ExternalFilter — named constructors', () {
    test('.eq sets operator to eq', () {
      final f = ExternalFilter.eq('Alice');
      expect(f.operator, FilterOperator.eq);
      expect(f.value, 'Alice');
    });

    test('.gte sets operator to gte', () {
      final f = ExternalFilter.gte(100);
      expect(f.operator, FilterOperator.gte);
      expect(f.value, 100);
    });

    test('.gt sets operator to gt', () {
      expect(ExternalFilter.gt(5).operator, FilterOperator.gt);
    });

    test('.lte sets operator to lte', () {
      expect(ExternalFilter.lte(99).operator, FilterOperator.lte);
    });

    test('.lt sets operator to lt', () {
      expect(ExternalFilter.lt(0).operator, FilterOperator.lt);
    });

    test('.contains sets operator to contains', () {
      final f = ExternalFilter.contains('foo');
      expect(f.operator, FilterOperator.contains);
      expect(f.value, 'foo');
    });

    test('.inList sets operator to in_', () {
      final f = ExternalFilter.inList(['a', 'b', 'c']);
      expect(f.operator, FilterOperator.in_);
      expect(f.value, ['a', 'b', 'c']);
    });

    test('.isNull sets operator to isNull with null value', () {
      final f = ExternalFilter.isNull();
      expect(f.operator, FilterOperator.isNull);
      expect(f.value, isNull);
    });

    test('.isNotNull sets operator to isNotNull', () {
      expect(ExternalFilter.isNotNull().operator, FilterOperator.isNotNull);
    });

    test('.dateRange() stores ISO-8601 strings in a two-element list', () {
      final from = DateTime(2024, 1, 1);
      final to = DateTime(2024, 12, 31);
      final f = ExternalFilter.dateRange(from: from, to: to);
      expect(f.operator, FilterOperator.between);
      final list = f.value as List;
      expect(list.length, 2);
      expect(list[0], from.toIso8601String());
      expect(list[1], to.toIso8601String());
    });

    test('.dateRange() with null from keeps only upper bound', () {
      final to = DateTime(2024, 6, 1);
      final f = ExternalFilter.dateRange(to: to);
      final list = f.value as List;
      expect(list[0], isNull);
      expect(list[1], to.toIso8601String());
    });

    test('.range() stores numeric bounds', () {
      final f = ExternalFilter.range(10, 50);
      expect(f.operator, FilterOperator.between);
      final list = f.value as List;
      expect(list[0], 10);
      expect(list[1], 50);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // toParams() — brackets format (default)
  // ──────────────────────────────────────────────────────────────────────────

  group('ExternalFilter.toParams() — brackets format', () {
    test('eq emits bare field[eq] key', () {
      final params = ExternalFilter.eq('Alice').toParams('name');
      expect(params, {'filter[name][eq]': 'Alice'});
    });

    test('gte emits filter[field][gte]', () {
      final params = ExternalFilter.gte(100).toParams('score');
      expect(params, {'filter[score][gte]': '100'});
    });

    test('lte emits filter[field][lte]', () {
      expect(
        ExternalFilter.lte(50).toParams('amount'),
        {'filter[amount][lte]': '50'},
      );
    });

    test('gt emits filter[field][gt]', () {
      expect(
        ExternalFilter.gt(0).toParams('age'),
        {'filter[age][gt]': '0'},
      );
    });

    test('lt emits filter[field][lt]', () {
      expect(
        ExternalFilter.lt(18).toParams('age'),
        {'filter[age][lt]': '18'},
      );
    });

    test('contains emits filter[field][contains]', () {
      expect(
        ExternalFilter.contains('foo').toParams('title'),
        {'filter[title][contains]': 'foo'},
      );
    });

    test('in_ emits comma-separated list', () {
      final params = ExternalFilter.inList(['a', 'b', 'c']).toParams('status');
      expect(params, {'filter[status][in]': 'a,b,c'});
    });

    test('notIn emits comma-separated list', () {
      final f = ExternalFilter(value: ['x', 'y'], operator: FilterOperator.notIn);
      expect(f.toParams('tag'), {'filter[tag][notIn]': 'x,y'});
    });

    test('between expands into gte + lte params', () {
      final f = ExternalFilter.range(10, 90);
      final params = f.toParams('price');
      expect(params, {
        'filter[price][gte]': '10',
        'filter[price][lte]': '90',
      });
    });

    test('between with only lower bound omits lte', () {
      final f = ExternalFilter(
        value: [10, null],
        operator: FilterOperator.between,
      );
      final params = f.toParams('price');
      expect(params.containsKey('filter[price][gte]'), isTrue);
      expect(params.containsKey('filter[price][lte]'), isFalse);
    });

    test('between with only upper bound omits gte', () {
      final f = ExternalFilter(
        value: [null, 90],
        operator: FilterOperator.between,
      );
      final params = f.toParams('price');
      expect(params.containsKey('filter[price][gte]'), isFalse);
      expect(params.containsKey('filter[price][lte]'), isTrue);
    });

    test('between with both bounds null emits empty map', () {
      final f = ExternalFilter(
        value: [null, null],
        operator: FilterOperator.between,
      );
      expect(f.toParams('date'), isEmpty);
    });

    test('isNull emits =true', () {
      expect(
        ExternalFilter.isNull().toParams('deletedAt'),
        {'filter[deletedAt][isNull]': 'true'},
      );
    });

    test('isNotNull emits =true', () {
      expect(
        ExternalFilter.isNotNull().toParams('email'),
        {'filter[email][isNotNull]': 'true'},
      );
    });

    test('dateRange expands into ISO-8601 gte + lte strings', () {
      final from = DateTime.utc(2024, 1, 1);
      final to = DateTime.utc(2024, 6, 30);
      final params = ExternalFilter.dateRange(from: from, to: to)
          .toParams('createdAt');
      expect(params['filter[createdAt][gte]'], from.toIso8601String());
      expect(params['filter[createdAt][lte]'], to.toIso8601String());
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // toParams() — alternative formats
  // ──────────────────────────────────────────────────────────────────────────

  group('ExternalFilter.toParams() — dotNotation format', () {
    test('eq emits filter.field.eq', () {
      final params = ExternalFilter.eq('Bob')
          .toParams('name', format: QueryParamFormat.dotNotation);
      expect(params, {'filter.name.eq': 'Bob'});
    });

    test('gte emits filter.field.gte', () {
      final params = ExternalFilter.gte(5)
          .toParams('count', format: QueryParamFormat.dotNotation);
      expect(params, {'filter.count.gte': '5'});
    });
  });

  group('ExternalFilter.toParams() — bare format', () {
    test('eq uses bare field name (no brackets)', () {
      final params = ExternalFilter.eq(true)
          .toParams('completed', format: QueryParamFormat.bare);
      // For bare+eq the key is just the field name.
      expect(params, {'completed': 'true'});
    });

    test('gte uses field[gte] without filter prefix', () {
      final params = ExternalFilter.gte(0)
          .toParams('score', format: QueryParamFormat.bare);
      expect(params, {'score[gte]': '0'});
    });

    test('between with bare format emits field[gte]+field[lte]', () {
      final params = ExternalFilter.range(1, 100)
          .toParams('price', format: QueryParamFormat.bare);
      expect(params, {
        'price[gte]': '1',
        'price[lte]': '100',
      });
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // ExternalFilter equality & toString
  // ──────────────────────────────────────────────────────────────────────────

  group('ExternalFilter equality', () {
    test('same operator and value are equal', () {
      expect(
        ExternalFilter.eq('Alice'),
        equals(ExternalFilter.eq('Alice')),
      );
    });

    test('different operator → not equal', () {
      expect(
        ExternalFilter.eq(5),
        isNot(equals(ExternalFilter.gte(5))),
      );
    });

    test('different value → not equal', () {
      expect(
        ExternalFilter.eq('Alice'),
        isNot(equals(ExternalFilter.eq('Bob'))),
      );
    });

    test('toString contains operator and value', () {
      final s = ExternalFilter.gte(42).toString();
      expect(s, contains('gte'));
      expect(s, contains('42'));
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // GridQuery — toQueryParameters with external filters
  // ──────────────────────────────────────────────────────────────────────────

  group('GridQuery.toQueryParameters() with external filters', () {
    test('eq filter appears in params with brackets format', () {
      final q = GridQuery(
        externalFilters: {'completed': ExternalFilter.eq(true)},
      );
      final params = q.toQueryParameters();
      expect(params['filter[completed][eq]'], 'true');
    });

    test('gte filter appears correctly', () {
      final q = GridQuery(
        externalFilters: {'amount': ExternalFilter.gte(100)},
      );
      expect(q.toQueryParameters()['filter[amount][gte]'], '100');
    });

    test('between expands to two params in toQueryParameters', () {
      final q = GridQuery(
        externalFilters: {'price': ExternalFilter.range(10, 99)},
      );
      final params = q.toQueryParameters();
      expect(params['filter[price][gte]'], '10');
      expect(params['filter[price][lte]'], '99');
    });

    test('multiple filters all appear', () {
      final q = GridQuery(
        externalFilters: {
          'status': ExternalFilter.eq('active'),
          'score': ExternalFilter.gte(80),
        },
      );
      final params = q.toQueryParameters();
      expect(params['filter[status][eq]'], 'active');
      expect(params['filter[score][gte]'], '80');
    });

    test('bare format propagates to filter serialisation', () {
      final q = GridQuery(
        externalFilters: {'userId': ExternalFilter.eq(5)},
        paramFormat: QueryParamFormat.bare,
      );
      final params = q.toQueryParameters();
      // bare + eq → field = value (no brackets)
      expect(params['userId'], '5');
    });

    test('page and pageSize always present', () {
      final q = GridQuery(pageIndex: 2, pageSize: 20);
      final params = q.toQueryParameters();
      expect(params['page'], '3'); // 0-based → 1-based
      expect(params['pageSize'], '20');
    });

    test('sorting appears as comma-separated sort param', () {
      final q = GridQuery(
        sorting: [
          SortEntry(columnId: 'name', descending: false),
          SortEntry(columnId: 'age', descending: true),
        ],
      );
      expect(q.toQueryParameters()['sort'], 'name,-age');
    });

    test('globalFilter appears as q param', () {
      final q = GridQuery(globalFilter: 'alice');
      expect(q.toQueryParameters()['q'], 'alice');
    });

    test('no external filters → no extra params beyond page/pageSize', () {
      final q = GridQuery();
      final params = q.toQueryParameters();
      expect(params.keys, containsAll(['page', 'pageSize']));
      expect(params.keys.where((k) => k.startsWith('filter')), isEmpty);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // GridQuery.fromState() picks up externalFilters
  // ──────────────────────────────────────────────────────────────────────────

  group('GridQuery.fromState()', () {
    test('includes externalFilters from GridState', () {
      final state = GridState(
        externalFilters: {'completed': ExternalFilter.eq(true)},
      );
      final q = GridQuery.fromState(state);
      expect(q.externalFilters['completed']?.operator, FilterOperator.eq);
      expect(q.externalFilters['completed']?.value, true);
    });

    test('propagates paramFormat', () {
      final state = const GridState();
      final q = GridQuery.fromState(
        state,
        paramFormat: QueryParamFormat.bare,
      );
      expect(q.paramFormat, QueryParamFormat.bare);
    });

    test('toQuery() on GridState produces equivalent result', () {
      final state = GridState(
        pagination: const PaginationState(pageIndex: 1, pageSize: 20),
        externalFilters: {'tag': ExternalFilter.inList(['a', 'b'])},
      );
      final q = state.toQuery();
      expect(q.pageIndex, 1);
      expect(q.pageSize, 20);
      expect(q.externalFilters['tag']?.operator, FilterOperator.in_);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // GridController — external filter commands
  // ──────────────────────────────────────────────────────────────────────────

  group('GridController external filter commands', () {
    test('setExternalFilter stores the filter in state', () {
      final c = _makeController();
      c.setExternalFilter('status', ExternalFilter.eq('active'));
      expect(c.state.externalFilters['status']?.value, 'active');
      expect(c.state.externalFilters['status']?.operator, FilterOperator.eq);
    });

    test('setExternalFilter resets pageIndex to 0', () {
      final c = _makeController();
      c.nextPage(); // page 1
      expect(c.state.pagination.pageIndex, 1);
      c.setExternalFilter('x', ExternalFilter.eq(1));
      expect(c.state.pagination.pageIndex, 0);
    });

    test('setExternalFilter replaces existing filter for same field', () {
      final c = _makeController();
      c.setExternalFilter('status', ExternalFilter.eq('active'));
      c.setExternalFilter('status', ExternalFilter.eq('inactive'));
      expect(c.state.externalFilters['status']?.value, 'inactive');
      expect(c.state.externalFilters.length, 1);
    });

    test('multiple distinct fields can be set independently', () {
      final c = _makeController();
      c.setExternalFilter('userId', ExternalFilter.eq(5));
      c.setExternalFilter('completed', ExternalFilter.eq(true));
      expect(c.state.externalFilters.length, 2);
      expect(c.state.externalFilters['userId']?.value, 5);
      expect(c.state.externalFilters['completed']?.value, true);
    });

    test('clearExternalFilter removes a specific field', () {
      final c = _makeController();
      c.setExternalFilter('a', ExternalFilter.eq(1));
      c.setExternalFilter('b', ExternalFilter.eq(2));
      c.clearExternalFilter('a');
      expect(c.state.externalFilters.containsKey('a'), isFalse);
      expect(c.state.externalFilters.containsKey('b'), isTrue);
    });

    test('clearExternalFilter on missing field is a no-op', () {
      final c = _makeController();
      expect(() => c.clearExternalFilter('nonexistent'), returnsNormally);
      expect(c.state.externalFilters, isEmpty);
    });

    test('clearExternalFilter resets pageIndex to 0', () {
      final c = _makeController();
      c.setExternalFilter('x', ExternalFilter.eq(1));
      c.nextPage();
      c.clearExternalFilter('x');
      expect(c.state.pagination.pageIndex, 0);
    });

    test('clearAllExternalFilters removes every filter', () {
      final c = _makeController();
      c.setExternalFilter('a', ExternalFilter.eq(1));
      c.setExternalFilter('b', ExternalFilter.gte(10));
      c.clearAllExternalFilters();
      expect(c.state.externalFilters, isEmpty);
    });

    test('clearAllExternalFilters resets pageIndex to 0', () {
      final c = _makeController();
      c.setExternalFilter('a', ExternalFilter.eq(1));
      c.nextPage();
      c.clearAllExternalFilters();
      expect(c.state.pagination.pageIndex, 0);
    });

    test('setExternalFilters replaces all filters at once', () {
      final c = _makeController();
      c.setExternalFilter('old', ExternalFilter.eq(0));
      c.setExternalFilters({
        'new1': ExternalFilter.eq(1),
        'new2': ExternalFilter.gte(50),
      });
      expect(c.state.externalFilters.containsKey('old'), isFalse);
      expect(c.state.externalFilters['new1']?.value, 1);
      expect(c.state.externalFilters['new2']?.operator, FilterOperator.gte);
    });

    test('setExternalFilters({}) is equivalent to clearAllExternalFilters', () {
      final c = _makeController();
      c.setExternalFilter('a', ExternalFilter.eq(1));
      c.setExternalFilters({});
      expect(c.state.externalFilters, isEmpty);
    });

    test('setExternalFilterValue convenience method works', () {
      final c = _makeController();
      c.setExternalFilterValue('score', 80, operator: FilterOperator.gte);
      expect(c.state.externalFilters['score']?.value, 80);
      expect(c.state.externalFilters['score']?.operator, FilterOperator.gte);
    });

    test('setExternalFilterValue defaults to eq operator', () {
      final c = _makeController();
      c.setExternalFilterValue('name', 'Alice');
      expect(c.state.externalFilters['name']?.operator, FilterOperator.eq);
    });

    test('external filters are NOT cleared by clearAllFilters()', () {
      final c = _makeController();
      c.setColumnFilter('val', 'x');
      c.setExternalFilter('status', ExternalFilter.eq('active'));
      c.clearAllFilters(); // clears column+global filters, NOT external
      expect(c.state.externalFilters.containsKey('status'), isTrue);
      expect(c.state.columnFilters, isEmpty);
    });

    test('external filters survive sort changes', () {
      final c = _makeController();
      c.setExternalFilter('status', ExternalFilter.eq('active'));
      c.toggleSort('val');
      expect(c.state.externalFilters['status']?.value, 'active');
    });

    test('external filters survive page changes', () {
      final c = _makeController();
      c.setExternalFilter('tag', ExternalFilter.inList(['a', 'b']));
      c.nextPage();
      expect(c.state.externalFilters['tag']?.operator, FilterOperator.in_);
    });

    test('toQuery() reflects current external filters', () {
      final c = _makeController();
      c.setExternalFilter('userId', ExternalFilter.eq(42));
      final q = c.state.toQuery();
      expect(q.externalFilters['userId']?.value, 42);
    });

    // ── global filter page-reset (regression) ──────────────────────────────

    test('setGlobalFilter resets pageIndex to 0', () {
      final c = _makeController();
      c.nextPage(); // move to page 1
      expect(c.state.pagination.pageIndex, 1);
      c.setGlobalFilter('alice');
      expect(c.state.pagination.pageIndex, 0);
    });

    test('setGlobalFilter with empty string resets pageIndex to 0', () {
      final c = _makeController();
      c.setGlobalFilter('something');
      c.nextPage();
      c.setGlobalFilter(''); // clear via empty string
      expect(c.state.pagination.pageIndex, 0);
    });

    test('setGlobalFilter with null resets pageIndex to 0', () {
      final c = _makeController();
      c.setGlobalFilter('something');
      c.nextPage();
      c.setGlobalFilter(null);
      expect(c.state.pagination.pageIndex, 0);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // GridState.externalFilters — copyWith behaviour
  // ──────────────────────────────────────────────────────────────────────────

  group('GridState.copyWith external filters', () {
    test('copyWith(externalFilters: ...) replaces the map', () {
      const s = GridState(
        externalFilters: {'a': ExternalFilter(value: 1)},
      );
      final next = s.copyWith(externalFilters: {'b': ExternalFilter(value: 2)});
      expect(next.externalFilters.containsKey('a'), isFalse);
      expect(next.externalFilters['b']?.value, 2);
    });

    test('copyWith(clearExternalFilters: true) empties the map', () {
      const s = GridState(
        externalFilters: {'x': ExternalFilter(value: 99)},
      );
      final next = s.copyWith(clearExternalFilters: true);
      expect(next.externalFilters, isEmpty);
    });

    test('copyWith() with no external-filter args preserves existing filters',
        () {
      const s = GridState(
        externalFilters: {'keep': ExternalFilter(value: 'yes')},
      );
      final next = s.copyWith(
        pagination: PaginationState(pageIndex: 2),
      );
      expect(next.externalFilters['keep']?.value, 'yes');
    });

    test('initial state has empty externalFilters', () {
      expect(const GridState().externalFilters, isEmpty);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // Undo/redo for external filter commands
  // ──────────────────────────────────────────────────────────────────────────

  group('Undo/redo — external filter commands', () {
    test('setExternalFilter is undoable', () {
      final c = _makeController();
      c.setExternalFilter('status', ExternalFilter.eq('active'));
      expect(c.canUndo, isTrue);
    });

    test('undo removes an added external filter', () {
      final c = _makeController();
      c.setExternalFilter('status', ExternalFilter.eq('active'));
      c.undo();
      expect(c.state.externalFilters, isEmpty);
    });

    test('redo re-applies the external filter after undo', () {
      final c = _makeController();
      c.setExternalFilter('status', ExternalFilter.eq('active'));
      c.undo();
      c.redo();
      expect(c.state.externalFilters['status']?.value, 'active');
    });

    test('clearExternalFilter is undoable', () {
      final c = _makeController();
      c.setExternalFilter('a', ExternalFilter.eq(1));
      c.clearExternalFilter('a');
      c.undo(); // undo the clear
      expect(c.state.externalFilters.containsKey('a'), isTrue);
    });

    test('clearAllExternalFilters is undoable', () {
      final c = _makeController();
      c.setExternalFilter('a', ExternalFilter.eq(1));
      c.setExternalFilter('b', ExternalFilter.eq(2));
      c.clearAllExternalFilters();
      c.undo();
      // Undo of clearAll restores the previous state (after the last setFilter)
      expect(c.state.externalFilters.containsKey('b'), isTrue);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // Listener notification — external filter commands
  // ──────────────────────────────────────────────────────────────────────────

  group('GridController listener notifications — external filters', () {
    test('setExternalFilter notifies listeners', () {
      final c = _makeController();
      int callCount = 0;
      c.addListener(() => callCount++);
      c.setExternalFilter('x', ExternalFilter.eq(1));
      expect(callCount, 1);
    });

    test('clearExternalFilter notifies listeners', () {
      final c = _makeController();
      c.setExternalFilter('x', ExternalFilter.eq(1));
      int callCount = 0;
      c.addListener(() => callCount++);
      c.clearExternalFilter('x');
      expect(callCount, 1);
    });

    test('clearAllExternalFilters notifies listeners', () {
      final c = _makeController();
      c.setExternalFilter('x', ExternalFilter.eq(1));
      int callCount = 0;
      c.addListener(() => callCount++);
      c.clearAllExternalFilters();
      expect(callCount, 1);
    });

    test('each distinct setExternalFilter call notifies once', () {
      final c = _makeController();
      int callCount = 0;
      c.addListener(() => callCount++);
      c.setExternalFilter('a', ExternalFilter.eq(1));
      c.setExternalFilter('b', ExternalFilter.eq(2));
      c.setExternalFilter('c', ExternalFilter.eq(3));
      expect(callCount, 3);
    });
  });
}
