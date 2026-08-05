class PagedSearchRequest {
  final int page;
  final int pageSize;
  final String? searchTerm;


  PagedSearchRequest({this.page=1,  this.pageSize=10, this.searchTerm});

  Map<String, dynamic> toJson() => {
        'page': page,
        'pageSize': pageSize,
        if (searchTerm != null && searchTerm!.isNotEmpty) 'searchTerm': searchTerm,
      };
}