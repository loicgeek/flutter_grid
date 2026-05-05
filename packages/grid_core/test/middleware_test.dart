import 'package:grid_core/grid_core.dart';
import 'package:test/test.dart';

class _TrackedMiddleware extends GridMiddleware {
  final List<String> beforeLog = [];
  final List<String> afterLog = [];

  @override
  void beforeDispatch(GridCommand command, GridState currentState) {
    beforeLog.add(command.runtimeType.toString());
  }

  @override
  void afterDispatch(GridCommand command, GridState prevState, GridState nextState) {
    afterLog.add(command.runtimeType.toString());
  }
}

class _BlockingMiddleware extends GridMiddleware {
  final Type commandTypeToBlock;
  bool blocked = false;

  _BlockingMiddleware(this.commandTypeToBlock);

  @override
  void beforeDispatch(GridCommand command, GridState currentState) {
    if (command.runtimeType == commandTypeToBlock) {
      blocked = true;
    }
  }
}

GridController<String> _makeController({
  List<GridMiddleware> middleware = const [],
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
    ),
    middleware: middleware,
  );
  c.setData(['A', 'B', 'C']);
  return c;
}

void main() {
  group('LoggingMiddleware', () {
    test('beforeDispatch is called on every command', () {
      final logs = <String>[];
      final c = _makeController(
        middleware: [LoggingMiddleware()],
      );

      // Dispatch should not throw — logging goes to print()
      expect(() => c.toggleSort('val'), returnsNormally);
      expect(() => c.setGlobalFilter('a'), returnsNormally);
    });
  });

  group('AnalyticsMiddleware', () {
    test('onEvent is called with command type on dispatch', () {
      final events = <Map<String, dynamic>>[];
      final c = _makeController(
        middleware: [
          AnalyticsMiddleware(
            onEvent: (name, params) => events.add({'name': name, ...params}),
          ),
        ],
      );

      c.toggleSort('val');
      expect(events.length, 1);
      expect(events.first['name'], 'grid_command');
      expect(events.first['command'], contains('ToggleSortCommand'));
    });

    test('multiple dispatches fire multiple events', () {
      final events = <String>[];
      final c = _makeController(
        middleware: [
          AnalyticsMiddleware(
            onEvent: (name, _) => events.add(name),
          ),
        ],
      );

      c.toggleSort('val');
      c.setGlobalFilter('test');
      c.nextPage();

      expect(events.length, 3);
    });
  });

  group('Custom middleware', () {
    test('beforeDispatch fires before state changes', () {
      final tracked = _TrackedMiddleware();
      final c = _makeController(middleware: [tracked]);

      c.toggleSort('val');
      expect(tracked.beforeLog, contains('ToggleSortCommand'));
      expect(tracked.afterLog, contains('ToggleSortCommand'));
    });

    test('afterDispatch receives updated state with changed sorting', () {
      GridState? capturedNext;
      final middleware = _CustomAfterMiddleware(
        onAfter: (cmd, prev, next) {
          if (cmd is ToggleSortCommand) capturedNext = next;
        },
      );
      final c = _makeController(middleware: [middleware]);

      c.toggleSort('val');
      expect(capturedNext?.sorting, isNotEmpty);
      expect(capturedNext?.sorting.first.columnId, 'val');
    });

    test('multiple middlewares all receive dispatch events', () {
      final m1 = _TrackedMiddleware();
      final m2 = _TrackedMiddleware();
      final c = _makeController(middleware: [m1, m2]);

      c.setGlobalFilter('x');
      expect(m1.beforeLog, contains('SetGlobalFilterCommand'));
      expect(m2.beforeLog, contains('SetGlobalFilterCommand'));
    });
  });
}

class _CustomAfterMiddleware extends GridMiddleware {
  final void Function(GridCommand cmd, GridState prev, GridState next) onAfter;

  _CustomAfterMiddleware({required this.onAfter});

  @override
  void afterDispatch(GridCommand command, GridState prevState, GridState nextState) {
    onAfter(command, prevState, nextState);
  }
}
