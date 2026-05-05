abstract class GridFeature {
  String get featureId;
  bool get manual => false;

  const GridFeature();

  void init(dynamic controller) {} // GridController<T>
  void dispose() {}
}
