abstract class GridFeature {
  String get featureId;
  bool get manual => false;

  void init(dynamic controller) {} // GridController<T>
  void dispose() {}
}
