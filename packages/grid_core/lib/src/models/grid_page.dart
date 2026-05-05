class GridPage<T> {
  final List<T> data;
  final int totalItems;
  final int currentPage;
  final int pageSize;
  final int? totalPages;

  const GridPage({
    required this.data,
    required this.totalItems,
    required this.currentPage,
    required this.pageSize,
    this.totalPages,
  });

  int get computedTotalPages =>
      totalPages ?? ((totalItems + pageSize - 1) ~/ pageSize).clamp(1, 999999);

  bool get hasNextPage => currentPage < computedTotalPages;
  bool get hasPreviousPage => currentPage > 1;
}
