import 'grid_feature.dart';

class ExpandingFeature extends GridFeature {
  @override
  String get featureId => 'expanding';

  @override
  final bool manual;
  final bool paginateExpandedRows;
  final bool expandOnRowClick;
  final int autoExpandDepth;

  const ExpandingFeature({
    this.manual = false,
    this.paginateExpandedRows = true,
    this.expandOnRowClick = false,
    this.autoExpandDepth = 0,
  });
}
