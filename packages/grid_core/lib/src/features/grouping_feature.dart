import 'grid_feature.dart';

enum GroupedColumnMode { reorder, remove, none }

class GroupingFeature extends GridFeature {
  @override
  String get featureId => 'grouping';

  @override
  final bool manual;
  
  final GroupedColumnMode groupedColumnMode;
  final bool enableGrouping;

  const GroupingFeature({
    this.manual = false,
    this.groupedColumnMode = GroupedColumnMode.reorder,
    this.enableGrouping = true,
  });
}
