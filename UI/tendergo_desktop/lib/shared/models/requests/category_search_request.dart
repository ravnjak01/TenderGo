import 'package:tendergo/shared/models/requests/paged_search_request.dart';

class CategorySearchRequest extends PagedSearchRequest {
  final String? searchTerm;

  CategorySearchRequest({
    this.searchTerm,
    required super.page,
    required super.pageSize,
  });

  @override
  Map<String, dynamic> toJson() {
    return {
      'Page': page,
      'PageSize': pageSize,
      if (searchTerm != null && searchTerm!.trim().isNotEmpty) 'SearchTerm': searchTerm!.trim(),
    };
  }
}