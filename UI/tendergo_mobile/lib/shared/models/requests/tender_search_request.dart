import 'package:tendergo/shared/models/requests/paged_search_request.dart';

class TenderSearchRequest extends PagedSearchRequest {
  final String? searchTerm;
 
  TenderSearchRequest({
    this.searchTerm,
    int page = 1,
    int pageSize = 10,
  }) : super(page: page, pageSize: pageSize);

  Map<String, dynamic> toJson() => {
        if (searchTerm != null) 'searchTerm': searchTerm,
      };
}