import 'package:flutter/widgets.dart';
import 'package:grid_core/grid_core.dart';

/// Provides a [GridController] down the widget tree via [InheritedNotifier].
class GridScope<T> extends InheritedNotifier<_GridControllerNotifier<T>> {
  GridScope({
    super.key,
    required GridController<T> controller,
    required super.child,
  }) : super(notifier: _GridControllerNotifier(controller));

  static GridController<T> of<T>(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<GridScope<T>>();
    assert(scope != null, 'No GridScope<$T> found in widget tree');
    return scope!.notifier!.controller;
  }

  static GridController<T>? maybeOf<T>(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<GridScope<T>>()
        ?.notifier
        ?.controller;
  }
}

/// A thin [ChangeNotifier] wrapper so [InheritedNotifier] can listen to
/// [GridController]'s internal listener list.
class _GridControllerNotifier<T> extends ChangeNotifier {
  final GridController<T> controller;

  _GridControllerNotifier(this.controller) {
    controller.addListener(_onControllerChanged);
  }

  void _onControllerChanged() {
    notifyListeners();
  }

  GridController<T> get value => controller;

  @override
  void dispose() {
    controller.removeListener(_onControllerChanged);
    super.dispose();
  }
}
