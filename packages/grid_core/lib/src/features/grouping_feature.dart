import 'grid_feature.dart';

enum GroupedColumnMode { reorder, remove, none }

class GroupingFeature extends GridFeature {
  final GroupedColumnMode groupedColumnMode;

  GroupingFeature({this.groupedColumnMode = GroupedColumnMode.reorder});

  @override
  String get featureId => 'grouping';
}
