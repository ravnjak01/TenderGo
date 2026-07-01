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

  factory PagedResult.fromJson(Map<String, dynamic> json, T Function(dynamic) fromJsonT) {
    return PagedResult<T>(
      result: json['result'] is List
          ? (json['result'] as List).map((item) => fromJsonT(item)).toList()
          : const [],
      totalCount: json['totalCount'] as int,
      page: json['page'] as int,
      pageSize: json['pageSize'] as int,
    );
  }
}