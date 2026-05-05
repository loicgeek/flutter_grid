import '../commands/grid_command.dart' show GridCommand;
import '../models/grid_state.dart';

abstract class GridMiddleware {
  const GridMiddleware();

  void beforeDispatch(GridCommand command, GridState currentState) {}
  void afterDispatch(
      GridCommand command, GridState prevState, GridState nextState) {}
  void dispose() {}
}

class LoggingMiddleware extends GridMiddleware {
  final bool verbose;

  const LoggingMiddleware({this.verbose = false});

  @override
  void beforeDispatch(GridCommand command, GridState currentState) {
    print('[GridMiddleware] Dispatching: ${command.runtimeType}');
    if (verbose) {
      print('  sorting: ${currentState.sorting.length} entries');
    }
  }

  @override
  void afterDispatch(
      GridCommand command, GridState prevState, GridState nextState) {
    print('[GridMiddleware] Dispatched: ${command.runtimeType}');
  }
}

class AnalyticsMiddleware extends GridMiddleware {
  final void Function(String eventName, Map<String, dynamic> params)? onEvent;

  const AnalyticsMiddleware({this.onEvent});

  @override
  void afterDispatch(
      GridCommand command, GridState prevState, GridState nextState) {
    onEvent?.call('grid_command', {
      'command': command.runtimeType.toString(),
    });
  }
}
