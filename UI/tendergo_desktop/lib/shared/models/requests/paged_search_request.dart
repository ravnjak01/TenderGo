class PagedSearchRequest {
  final int page;
  final int pageSize;

  PagedSearchRequest({this.page=1,  this.pageSize=10});

  Map<String, dynamic> toJson() => {
        'page': page,
        'pageSize': pageSize,
      };
}