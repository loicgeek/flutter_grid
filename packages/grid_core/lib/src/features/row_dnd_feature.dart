import 'grid_feature.dart';

class RowDndFeature extends GridFeature {
  final void Function(int fromIndex, int toIndex)? onRowReorder;

  RowDndFeature({this.onRowReorder});

  @override
  String get featureId => 'rowDnd';
}
