import 'grid_feature.dart';

class SortFeature extends GridFeature {
  final bool enableMultiSort;
  @override
  final bool manual;

  SortFeature({this.enableMultiSort = false, this.manual = false});

  @override
  String get featureId => 'sort';
}
