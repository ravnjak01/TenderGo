import 'package:tendergo/shared/models/requests/paged_search_request.dart';

class LocationSearchRequest extends PagedSearchRequest {
  final String? searchTerm;
  final bool? isActive;
 

LocationSearchRequest({
    this.searchTerm,
    this.isActive,
    required super.page,
    required super.pageSize,
  });


 @override
  Map<String, dynamic> toJson() => {
        'Page': page,
        'PageSize': pageSize,
        if (searchTerm != null && searchTerm!.trim().isNotEmpty) 'SearchTerm': searchTerm!.trim(),
        if (isActive != null) 'IsActive': isActive,
      };
}