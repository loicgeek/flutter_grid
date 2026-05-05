import 'grid_feature.dart';

class RowPinningFeature extends GridFeature {
  @override
  String get featureId => 'rowPinning';

  final bool keepPinnedRows;

  const RowPinningFeature({this.keepPinnedRows = true});
}
