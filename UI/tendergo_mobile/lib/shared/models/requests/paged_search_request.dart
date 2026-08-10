class PagedSearchRequest {
  final int page;
  final int pageSize;
  final String? searchTerm;
  PagedSearchRequest({
    this.page = 1,
    this.pageSize = 3,
    this.searchTerm,
  });

  Map<String, dynamic> toQueryParams() {
    final params = <String, dynamic>{
      'page': page,
      'pageSize': pageSize,
    };
if (searchTerm != null && searchTerm!.isNotEmpty) {
      params['SearchTerm'] = searchTerm;
    }

    return params;
  }
}