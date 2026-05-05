import 'grid_feature.dart';

class ExpandingFeature extends GridFeature {
  final bool autoResetExpanded;

  ExpandingFeature({this.autoResetExpanded = true});

  @override
  String get featureId => 'expanding';
}
