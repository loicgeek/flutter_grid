import 'grid_feature.dart';

class ColumnVisibilityFeature extends GridFeature {
  final Map<String, bool> defaultVisibility;

  ColumnVisibilityFeature({this.defaultVisibility = const {}});

  @override
  String get featureId => 'columnVisibility';
}
