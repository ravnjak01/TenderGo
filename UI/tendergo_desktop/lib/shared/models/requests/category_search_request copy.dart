import 'package:tendergo/shared/models/requests/paged_search_request.dart';

class CategorySearchRequest extends PagedSearchRequest {
  final String? searchTerm;
  final bool? isActive;
  


 CategorySearchRequest({
    this.searchTerm,
    this.isActive,
    int page = 1,         // Dodano s defaultnom vrijednošću
    int pageSize = 10,     // Dodano s defaultnom vrijednošću
  }) : super(page: page, pageSize: pageSize); // Prosljeđivanje unesenih vrijednosti u super

  Map<String, dynamic> toJson() {
    return {
      'searchTerm': searchTerm,
      'isActive': isActive,
      'page': page,
      'pageSize': pageSize,
    };
  }
}