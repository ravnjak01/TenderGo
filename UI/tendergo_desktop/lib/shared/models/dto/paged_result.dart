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
      result: (json['result'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(fromJsonT)
          .toList(),
      totalCount: (json['totalCount'] as num?)?.toInt() ?? 0,
      page: (json['page'] as num?)?.toInt() ?? 1,
      pageSize: (json['pageSize'] as num?)?.toInt() ?? 0,
    );
  }
}