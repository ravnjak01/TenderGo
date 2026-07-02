import 'package:tendergo/shared/models/requests/paged_search_request.dart';

class AdminUserSearchRequest extends PagedSearchRequest {
  final String? searchTerm;
 

  AdminUserSearchRequest({
    this.searchTerm,
    int page = 1,         
    int pageSize = 10,     
  }) : super(page: page, pageSize: pageSize); 


  Map<String, dynamic> toJson() => {
    ...super.toJson(), 
        if (searchTerm != null) 'searchTerm': searchTerm,
      };
}