import 'grid_feature.dart';

class SelectionFeature extends GridFeature {
  final bool enableMultiRowSelection;
  final bool enableSelectAll;
  final bool enableSelectAllPages;

  SelectionFeature({
    this.enableMultiRowSelection = true,
    this.enableSelectAll = true,
    this.enableSelectAllPages = true,
  });

  @override
  String get featureId => 'selection';
}
