import 'grid_feature.dart';

class SelectionFeature extends GridFeature {
  final bool enableMultiRowSelection;
  final bool enableSelectAll;

  SelectionFeature({
    this.enableMultiRowSelection = true,
    this.enableSelectAll = true,
  });

  @override
  String get featureId => 'selection';
}
