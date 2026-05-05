import 'grid_feature.dart';

enum PaginationMode { clientSide, serverSide, infinite }

class PaginationFeature extends GridFeature {
  final PaginationMode mode;
  final int defaultPageSize;
  final List<int> pageSizeOptions;

  PaginationFeature({
    this.mode = PaginationMode.clientSide,
    this.defaultPageSize = 10,
    this.pageSizeOptions = const [10, 25, 50, 100],
  });

  @override
  String get featureId => 'pagination';

  @override
  bool get manual => mode == PaginationMode.serverSide;
}
