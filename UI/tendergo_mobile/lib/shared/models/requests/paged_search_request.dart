class PagedSearchRequest {
  final int page;
  final int pageSize;

  PagedSearchRequest({
    this.page = 1,
    this.pageSize = 3,
  });

  Map<String, dynamic> toQueryParams() {
    final params = <String, dynamic>{
      'page': page,
      'pageSize': pageSize,
    };


    return params;
  }
}