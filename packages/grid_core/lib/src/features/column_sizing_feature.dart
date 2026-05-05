import 'grid_feature.dart';

enum ColumnResizeMode { onChange, onEnd }

class ColumnSizingFeature extends GridFeature {
  final ColumnResizeMode resizeMode;

  ColumnSizingFeature({this.resizeMode = ColumnResizeMode.onEnd});

  @override
  String get featureId => 'columnSizing';
}
