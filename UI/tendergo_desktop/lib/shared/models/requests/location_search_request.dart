import 'package:tendergo/shared/models/requests/paged_search_request.dart';

class LocationSearchRequest extends PagedSearchRequest {
  final bool? isActive;

  LocationSearchRequest({
    this.isActive,
    super.page = 1,
    super.pageSize = 10,
    super.searchTerm,
  });

  @override
  Map<String, dynamic> toJson() {
    final map = super.toJson();
    if (isActive != null) {
      map['isActive'] = isActive;
    }
    return map;
  }
}