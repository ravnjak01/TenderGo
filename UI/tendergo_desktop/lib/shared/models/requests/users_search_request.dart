import 'package:tendergo/shared/models/requests/paged_search_request.dart';

class UsersSearchRequest extends PagedSearchRequest {
  final String? searchTerm;
  final bool? isBanned;
 

  UsersSearchRequest({
    this.searchTerm,
    this.isBanned,
    int page = 1,         // Dodano s defaultnom vrijednošću
    int pageSize = 10,     // Dodano s defaultnom vrijednošću
  }) : super(page: page, pageSize: pageSize); // Prosljeđivanje unesenih vrijednosti u super


  Map<String, dynamic> toJson() => {
        if (searchTerm != null) 'searchTerm': searchTerm,
        if (isBanned != null) 'isBanned': isBanned,
      };
}