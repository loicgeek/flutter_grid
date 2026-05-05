import 'grid_feature.dart';

class FilterFeature extends GridFeature {
  final bool enableGlobalFilter;
  final bool enableColumnFilters;
  @override
  final bool manual;

  FilterFeature({
    this.enableGlobalFilter = true,
    this.enableColumnFilters = true,
    this.manual = false,
  });

  @override
  String get featureId => 'filter';
}
