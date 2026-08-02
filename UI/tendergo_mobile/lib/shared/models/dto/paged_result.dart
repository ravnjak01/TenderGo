class PagedResult<T> {
  final List<T> result;
  final int totalCount;
  final int page;
  final int pageSize;

  PagedResult({
    required this.result,
    required this.totalCount,
    required this.page,
    required this.pageSize,
  });

  factory PagedResult.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    return PagedResult<T>(
      result: (json['result'] as List<dynamic>?)
              ?.map((item) => fromJsonT(item as Map<String, dynamic>))
              .toList() ??
          [],
      totalCount: json['totalCount'] as int? ?? 0,
      page: json['page'] as int? ?? 1,
      pageSize: json['pageSize'] as int? ?? 10,
    );
  }

  bool get hasNextPage => (page * pageSize) < totalCount;

  int get totalPages => (totalCount / pageSize).ceil();
}