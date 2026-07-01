import 'package:tendergo/shared/models/requests/paged_search_request.dart';

class AdminUserSearchRequest extends PagedSearchRequest {
  final String? searchTerm;
 

  AdminUserSearchRequest({
    this.searchTerm,
    int page = 1,         // Dodano s defaultnom vrijednošću
    int pageSize = 10,     // Dodano s defaultnom vrijednošću
  }) : super(page: page, pageSize: pageSize); // Prosljeđivanje unesenih vrijednosti u super


  Map<String, dynamic> toJson() => {
    ...super.toJson(), 
        if (searchTerm != null) 'searchTerm': searchTerm,
      };
}