import 'package:tendergo/shared/models/requests/paged_search_request.dart';

class CategorySearchRequest extends PagedSearchRequest {
  CategorySearchRequest({
    super.page = 1,
    super.pageSize = 10,
    super.searchTerm,
  });
}