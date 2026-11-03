class SearchResult<T> {
  int currentPage;
  int totalItems;
  List<T> data;
  int itemsPerPage;
  int lastpage;

  SearchResult({
    required this.currentPage,
    required this.totalItems,
    required this.data,
    required this.itemsPerPage,
    required this.lastpage,
  });

  factory SearchResult.empty({
    int currentPage = 0,
    int itemsPerPage = 0,
  }) {
    return SearchResult(
      currentPage: currentPage,
      totalItems: 0,
      data: [],
      itemsPerPage: itemsPerPage,
      lastpage: 0,
    );
  }

  bool get isEmpty => data.isEmpty;

  @override
  String toString() {
    return 'SearchResult{currentPage: $currentPage, totalItems: $totalItems, data: $data, itemsPerPage: $itemsPerPage, lastpage: $lastpage}';
  }
}
